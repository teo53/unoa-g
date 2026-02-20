// =====================================================
// Funding Pledge Edge Function (KRW Version)
// Processes funding pledges with KRW payment via PG (PortOne/TossPayments)
//
// FLOW:
//   1. Client initiates PG payment (PortOne SDK)
//   2. Client sends paymentId + pledgeInfo to this function
//   3. This function verifies payment with PortOne API
//   4. Creates funding_payment + funding_pledge records
//   5. Updates campaign stats
//
// IMPORTANT: No DT wallet deduction. Funding is KRW-only.
// =====================================================

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders } from '../_shared/cors.ts'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || ''
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
const PORTONE_API_SECRET = Deno.env.get('PORTONE_API_SECRET') || ''

const jsonHeaders = { 'Content-Type': 'application/json' }

interface PledgeRequest {
  campaignId: string
  tierId?: string
  amountKrw: number
  paymentId: string          // PortOne paymentId (결제 완료 후 받은 ID)
  paymentOrderId: string     // 가맹점 주문번호
  paymentMethod: string      // 'card', 'bank_transfer', etc
  idempotencyKey: string
  isAnonymous?: boolean
  supportMessage?: string
}

interface PledgeResponse {
  success: boolean
  pledgeId?: string
  paymentId?: string
  totalAmountKrw?: number
  message?: string
  error?: string
}

/**
 * PortOne API로 결제 검증
 */
async function verifyPortOnePayment(paymentId: string, expectedAmountKrw: number): Promise<{
  verified: boolean
  pgTransactionId?: string
  cardCompany?: string
  cardNumberMasked?: string
  cardType?: string
  installmentMonths?: number
  error?: string
}> {
  try {
    // PortOne V2 API: GET /payments/{paymentId}
    const response = await fetch(`https://api.portone.io/v2/payments/${paymentId}`, {
      method: 'GET',
      headers: {
        'Authorization': `PortOne ${PORTONE_API_SECRET}`,
        'Content-Type': 'application/json',
      },
    })

    if (!response.ok) {
      const errorBody = await response.text()
      console.error('PortOne API error:', response.status, errorBody)
      return { verified: false, error: `PortOne API error: ${response.status}` }
    }

    const payment = await response.json()

    // 결제 상태 확인
    if (payment.status !== 'PAID') {
      return { verified: false, error: `Payment not completed: status=${payment.status}` }
    }

    // 금액 검증
    if (payment.amount?.total !== expectedAmountKrw) {
      return {
        verified: false,
        error: `Amount mismatch: expected=${expectedAmountKrw}, actual=${payment.amount?.total}`,
      }
    }

    // 통화 검증
    if (payment.currency !== 'KRW') {
      return { verified: false, error: `Currency mismatch: expected=KRW, actual=${payment.currency}` }
    }

    return {
      verified: true,
      pgTransactionId: payment.pgTxId || payment.transactionId,
      cardCompany: payment.card?.publisher,
      cardNumberMasked: payment.card?.number,
      cardType: payment.card?.type,
      installmentMonths: payment.card?.installmentMonth || 0,
    }
  } catch (error) {
    console.error('PortOne verification error:', error)
    return { verified: false, error: `Verification failed: ${String(error)}` }
  }
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: getCorsHeaders(req) })
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ success: false, error: 'Method not allowed' }),
      { status: 405, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
    )
  }

  try {
    // Auth verification
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing authorization header' }),
        { status: 401, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Verify user
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(
      authHeader.replace('Bearer ', '')
    )

    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid authentication' }),
        { status: 401, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Parse request
    const body: PledgeRequest = await req.json()
    const {
      campaignId,
      tierId,
      amountKrw,
      paymentId,
      paymentOrderId,
      paymentMethod,
      idempotencyKey,
      isAnonymous = false,
      supportMessage,
    } = body

    // Validate required fields
    if (!campaignId || !amountKrw || amountKrw <= 0 || !paymentId || !paymentOrderId || !idempotencyKey) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Missing required fields: campaignId, amountKrw, paymentId, paymentOrderId, idempotencyKey',
        }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // S-P1-3: Validate amount is integer within reasonable bounds
    if (!Number.isInteger(amountKrw) || amountKrw < 1000 || amountKrw > 10_000_000) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Amount must be an integer between 1,000 and 10,000,000 KRW',
        }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    const totalAmountKrw = amountKrw

    // Check idempotency
    const { data: existingPledge } = await supabaseAdmin
      .from('funding_pledges')
      .select('id, status, total_amount_krw')
      .eq('idempotency_key', idempotencyKey)
      .single()

    if (existingPledge) {
      // B7: Verify amount consistency on idempotency key reuse
      if (existingPledge.total_amount_krw !== amountKrw) {
        return new Response(
          JSON.stringify({
            success: false,
            error: 'Conflict: amount mismatch for existing idempotency key',
          }),
          { status: 409, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
        )
      }
      return new Response(
        JSON.stringify({
          success: true,
          pledgeId: existingPledge.id,
          totalAmountKrw: existingPledge.total_amount_krw,
          message: 'Pledge already processed',
        }),
        { status: 200, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Validate campaign
    const { data: campaign, error: campaignError } = await supabaseAdmin
      .from('funding_campaigns')
      .select('id, status, end_at, creator_id, current_amount_krw, backer_count')
      .eq('id', campaignId)
      .single()

    if (campaignError || !campaign) {
      return new Response(
        JSON.stringify({ success: false, error: 'Campaign not found' }),
        { status: 404, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    if (campaign.status !== 'active') {
      return new Response(
        JSON.stringify({ success: false, error: 'Campaign is not active' }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    if (campaign.end_at && new Date(campaign.end_at) < new Date()) {
      return new Response(
        JSON.stringify({ success: false, error: 'Campaign has ended' }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    if (campaign.creator_id === user.id) {
      return new Response(
        JSON.stringify({ success: false, error: 'Cannot pledge to your own campaign' }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Validate tier
    if (tierId) {
      const { data: tier, error: tierError } = await supabaseAdmin
        .from('funding_reward_tiers')
        .select('id, price_krw, is_active, remaining_quantity')
        .eq('id', tierId)
        .eq('campaign_id', campaignId)
        .single()

      if (tierError || !tier) {
        return new Response(
          JSON.stringify({ success: false, error: 'Reward tier not found' }),
          { status: 404, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
        )
      }

      if (!tier.is_active) {
        return new Response(
          JSON.stringify({ success: false, error: 'Reward tier is not available' }),
          { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
        )
      }

      if (tier.remaining_quantity !== null && tier.remaining_quantity <= 0) {
        return new Response(
          JSON.stringify({ success: false, error: 'Reward tier is sold out' }),
          { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
        )
      }

      if (amountKrw < tier.price_krw) {
        return new Response(
          JSON.stringify({
            success: false,
            error: `Amount must be at least ${tier.price_krw.toLocaleString()} KRW for this tier`,
          }),
          { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
        )
      }
    }

    // === KRW PAYMENT VERIFICATION ===
    // Verify payment with PortOne API (DT 지갑 차감 아님!)
    const verification = await verifyPortOnePayment(paymentId, totalAmountKrw)

    if (!verification.verified) {
      console.error('Payment verification failed:', verification.error)
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Payment verification failed',
          message: verification.error,
        }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // === ATOMIC TRANSACTION: Create pledge + payment + update stats ===
    const { data: pledgeResult, error: txError } = await supabaseAdmin.rpc(
      'process_funding_pledge_krw',
      {
        p_campaign_id: campaignId,
        p_tier_id: tierId || null,
        p_user_id: user.id,
        p_amount_krw: amountKrw,
        p_extra_support_krw: 0, // deprecated: extra support removed
        p_payment_order_id: paymentOrderId,
        p_payment_method: paymentMethod || 'card',
        p_pg_transaction_id: verification.pgTransactionId || null,
        p_idempotency_key: idempotencyKey,
        p_is_anonymous: isAnonymous,
        p_support_message: supportMessage || null,
      }
    )

    if (txError) {
      console.error('Pledge transaction error:', txError)

      const errorMap: Record<string, string> = {
        'tier_sold_out': 'Reward tier is sold out',
        'campaign_not_active': 'Campaign is no longer active',
        'campaign_ended': 'Campaign has ended',
        'tier_not_found': 'Reward tier not found',
        'tier_not_active': 'Reward tier is not available',
      }

      for (const [key, msg] of Object.entries(errorMap)) {
        if (txError.message?.includes(key)) {
          return new Response(
            JSON.stringify({ success: false, error: msg }),
            { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
          )
        }
      }

      return new Response(
        JSON.stringify({ success: false, error: 'Failed to process pledge. Please try again.' }),
        { status: 500, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Create funding_payment record
    const { error: paymentInsertError } = await supabaseAdmin
      .from('funding_payments')
      .insert({
        pledge_id: pledgeResult.pledge_id,
        campaign_id: campaignId,
        user_id: user.id,
        amount_krw: totalAmountKrw,
        payment_method: paymentMethod || 'card',
        payment_provider: 'portone',
        payment_order_id: paymentOrderId,
        pg_transaction_id: verification.pgTransactionId,
        pg_payment_id: paymentId,
        status: 'paid',
        paid_at: new Date().toISOString(),
        card_company: verification.cardCompany,
        card_number_masked: verification.cardNumberMasked,
        card_type: verification.cardType,
        installment_months: verification.installmentMonths || 0,
        idempotency_key: `payment:${idempotencyKey}`,
      })

    if (paymentInsertError) {
      // P0-03: Check for duplicate pg_payment_id (payment replay attack)
      if (paymentInsertError.code === '23505' &&
          (paymentInsertError.message?.includes('idx_funding_payments_unique_pg_payment') ||
           paymentInsertError.message?.includes('pg_payment_id'))) {
        console.warn(`[Pledge] Payment ID replay detected: ${paymentId} already used for another pledge`)
        return new Response(
          JSON.stringify({
            success: false,
            error: 'This payment has already been used for another pledge',
          }),
          { status: 409, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
        )
      }

      console.error('Payment record insert error:', paymentInsertError)
      // Pledge was created successfully, payment record is supplementary
      // Don't fail the whole transaction for this
    }

    const response: PledgeResponse = {
      success: true,
      pledgeId: pledgeResult.pledge_id,
      paymentId: paymentId,
      totalAmountKrw: totalAmountKrw,
      message: '후원이 완료되었습니다!',
    }

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
    )

  } catch (error) {
    console.error('Funding pledge error:', error)
    return new Response(
      JSON.stringify({ success: false, error: 'Internal server error' }),
      { status: 500, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
    )
  }
})
