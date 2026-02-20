// =====================================================
// Edge Function: refund-process
// Purpose: Process DT purchase refund requests
// Features:
//   - JWT authentication
//   - Purchase ownership verification
//   - Idempotent processing via DB function
//   - Comprehensive error handling
// =====================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders } from '../_shared/cors.ts'

const jsonHeaders = { 'Content-Type': 'application/json' }

interface RefundRequest {
  purchaseId: string
  reason?: string
}

interface RefundResponse {
  success: boolean
  message?: string
  orderId?: string
  refundedDt?: number
  refundAmountKrw?: number
  newBalance?: number
  alreadyProcessed?: boolean
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: getCorsHeaders(req) })
  }

  try {
    // 1. Verify JWT authentication
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, message: 'Missing authorization header' }),
        { status: 401, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Create client with user's JWT
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    // Get authenticated user
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      console.error('Auth error:', authError)
      return new Response(
        JSON.stringify({ success: false, message: 'Invalid or expired token' }),
        { status: 401, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // 2. Parse request body
    const body: RefundRequest = await req.json()
    const { purchaseId, reason } = body

    if (!purchaseId) {
      return new Response(
        JSON.stringify({ success: false, message: 'Missing purchaseId' }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // 3. Create admin client for DB operations
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 4. Verify purchase ownership
    const { data: purchase, error: purchaseError } = await supabaseAdmin
      .from('dt_purchases')
      .select('id, user_id, status, dt_amount, bonus_dt, dt_used, refund_eligible_until, price_krw, payment_provider_transaction_id')
      .eq('id', purchaseId)
      .single()

    if (purchaseError || !purchase) {
      console.error('Purchase lookup error:', purchaseError)
      return new Response(
        JSON.stringify({ success: false, message: 'Purchase not found' }),
        { status: 404, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Verify ownership
    if (purchase.user_id !== user.id) {
      console.warn(`Unauthorized refund attempt: user ${user.id} tried to refund purchase ${purchaseId} owned by ${purchase.user_id}`)
      return new Response(
        JSON.stringify({ success: false, message: 'Unauthorized: This purchase does not belong to you' }),
        { status: 403, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // 5. Pre-validation checks (for better error messages)
    if (purchase.status === 'refunded') {
      return new Response(
        JSON.stringify({
          success: true,
          alreadyProcessed: true,
          message: 'This purchase has already been refunded',
          orderId: purchaseId
        }),
        { status: 200, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    if (purchase.status !== 'paid') {
      return new Response(
        JSON.stringify({
          success: false,
          message: `Cannot refund purchase with status: ${purchase.status}. Only paid purchases can be refunded.`
        }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    if (purchase.dt_used > 0) {
      return new Response(
        JSON.stringify({
          success: false,
          message: `Cannot refund: ${purchase.dt_used} DT from this purchase has already been used`
        }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    if (purchase.refund_eligible_until && new Date(purchase.refund_eligible_until) < new Date()) {
      return new Response(
        JSON.stringify({
          success: false,
          message: `Refund period has expired. This purchase was eligible for refund until ${new Date(purchase.refund_eligible_until).toLocaleDateString('ko-KR')}`
        }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // 6. P0-02: Call PG cancel API before internal refund
    const refundReason = reason || 'User requested refund'
    const paymentKey = purchase.payment_provider_transaction_id
    const tossSecretKey = Deno.env.get('TOSSPAYMENTS_SECRET_KEY') ?? ''

    if (!paymentKey) {
      console.error(`[Refund] No payment_provider_transaction_id for purchase ${purchaseId}`)
      return new Response(
        JSON.stringify({
          success: false,
          message: 'Cannot process refund: no payment provider transaction ID found. Please contact support.'
        }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    if (!tossSecretKey) {
      console.error('[Refund] TOSSPAYMENTS_SECRET_KEY not configured')
      return new Response(
        JSON.stringify({
          success: false,
          message: 'Payment provider not configured. Please contact support.'
        }),
        { status: 503, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Call Toss cancel API
    const tossAuth = btoa(`${tossSecretKey}:`)
    const cancelRes = await fetch(
      `https://api.tosspayments.com/v1/payments/${paymentKey}/cancel`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${tossAuth}`,
          'Content-Type': 'application/json',
          'Idempotency-Key': `refund:${purchaseId}`,
        },
        body: JSON.stringify({
          cancelReason: refundReason,
          cancelAmount: purchase.price_krw,
        }),
      }
    )

    if (!cancelRes.ok) {
      const cancelError = await cancelRes.json().catch(() => ({}))
      console.error('[Refund] Toss cancel failed:', cancelRes.status, cancelError)

      // If Toss says already cancelled, proceed with internal refund
      if (cancelError.code !== 'ALREADY_CANCELED') {
        return new Response(
          JSON.stringify({
            success: false,
            message: 'Payment cancellation failed at payment provider. Please try again later.'
          }),
          { status: 502, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
        )
      }
      console.log('[Refund] Payment already cancelled at PG, proceeding with internal refund')
    }

    // 7. Process internal refund via atomic DB function (PG cancel succeeded)
    const { data: result, error: refundError } = await supabaseAdmin.rpc('process_refund_atomic', {
      p_order_id: purchaseId,
      p_refund_reason: refundReason
    })

    if (refundError) {
      console.error('Refund processing error:', refundError)

      // Handle specific error cases
      if (refundError.message?.includes('already_processed')) {
        return new Response(
          JSON.stringify({
            success: true,
            alreadyProcessed: true,
            message: 'This refund has already been processed',
            orderId: purchaseId
          }),
          { status: 200, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
        )
      }

      if (refundError.message?.includes('Insufficient balance')) {
        return new Response(
          JSON.stringify({
            success: false,
            message: 'Insufficient DT balance for refund. Some DT may have been spent.'
          }),
          { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
        )
      }

      return new Response(
        JSON.stringify({
          success: false,
          message: refundError.message || 'Refund processing failed'
        }),
        { status: 500, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // 7. Log successful refund
    console.log(`Refund processed: purchase=${purchaseId}, user=${user.id}, amount=${result.refunded_dt} DT, reason=${refundReason}`)

    // 8. Return success response
    const response: RefundResponse = {
      success: true,
      message: 'Refund processed successfully. The refund has been requested to the payment provider and processing time depends on the payment method.',
      orderId: result.order_id,
      refundedDt: result.refunded_dt,
      refundAmountKrw: result.refund_amount_krw,
      newBalance: result.new_balance,
      alreadyProcessed: result.already_processed || false
    }

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
    )

  } catch (error) {
    console.error('Unexpected error in refund-process:', error)
    return new Response(
      JSON.stringify({
        success: false,
        message: 'An unexpected error occurred. Please try again later.'
      }),
      { status: 500, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
    )
  }
})
