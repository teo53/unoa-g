// =====================================================
// Edge Function: funding-payment-webhook
// Purpose: 펀딩 KRW 결제 전용 웹훅 (PortOne V2)
//
// 기존 payment-webhook은 DT 구매 전용으로 유지.
// 이 웹훅은 funding_payments 테이블만 처리.
//
// Events:
//   Transaction.Paid          → pledge 확정, campaign 금액 업데이트
//   Transaction.Cancelled     → pledge 취소, 전액 환불 처리
//   Transaction.PartialCancelled → 부분 환불 처리
//
// SECURITY:
//   - PortOne V2 HMAC-SHA256 서명 검증
//   - 멱등성 (webhook_id 기반)
//   - Cross-verification via PortOne API
// =====================================================

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || ''
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
const PORTONE_API_SECRET = Deno.env.get('PORTONE_API_SECRET') || ''
const PORTONE_WEBHOOK_SECRET = Deno.env.get('PORTONE_WEBHOOK_SECRET') || ''
const ENVIRONMENT = Deno.env.get('ENVIRONMENT') || 'production'
const SKIP_SIGNATURE_VERIFICATION = Deno.env.get('SKIP_WEBHOOK_SIGNATURE') === 'true'
const isDevelopmentWithSkip = ENVIRONMENT === 'development' && SKIP_SIGNATURE_VERIFICATION

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, webhook-id, webhook-timestamp, webhook-signature',
}

interface WebhookLogEntry {
  event_type: string
  payment_provider: string
  payment_order_id?: string
  webhook_id?: string
  webhook_payload: Record<string, unknown>
  signature_valid: boolean
  processed_status: 'pending' | 'success' | 'failed' | 'duplicate'
  error_message?: string
}

/**
 * PortOne V2 Webhook 서명 검증 (HMAC-SHA256)
 */
async function verifyPortOneSignature(
  webhookId: string,
  webhookTimestamp: string,
  webhookSignature: string,
  payload: string
): Promise<boolean> {
  if (isDevelopmentWithSkip) {
    console.warn('[DEV] Skipping PortOne signature verification')
    return true
  }

  if (!PORTONE_WEBHOOK_SECRET) {
    console.error('Missing PORTONE_WEBHOOK_SECRET')
    return false
  }

  try {
    const signedPayload = `${webhookTimestamp}.${payload}`
    const encoder = new TextEncoder()
    const key = await crypto.subtle.importKey(
      'raw',
      encoder.encode(PORTONE_WEBHOOK_SECRET),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    )

    const signatureBuffer = await crypto.subtle.sign(
      'HMAC',
      key,
      encoder.encode(signedPayload)
    )

    const computedSignature = btoa(String.fromCharCode(...new Uint8Array(signatureBuffer)))
    const received = webhookSignature.replace('v1,', '')

    if (computedSignature.length !== received.length) return false

    let result = 0
    for (let i = 0; i < computedSignature.length; i++) {
      result |= computedSignature.charCodeAt(i) ^ received.charCodeAt(i)
    }

    return result === 0
  } catch (error) {
    console.error('Signature verification error:', error)
    return false
  }
}

/**
 * PortOne API로 결제 상태 확인
 */
async function verifyPaymentWithPortOne(paymentId: string): Promise<{
  valid: boolean
  amount?: number
  status?: string
  orderId?: string
  currency?: string
}> {
  try {
    const response = await fetch(
      `https://api.portone.io/v2/payments/${paymentId}`,
      {
        method: 'GET',
        headers: {
          'Authorization': `PortOne ${PORTONE_API_SECRET}`,
          'Content-Type': 'application/json',
        },
      }
    )

    if (!response.ok) {
      console.error('PortOne API error:', response.status)
      return { valid: false }
    }

    const data = await response.json()
    return {
      valid: true,
      amount: data.amount?.total,
      status: data.status,
      orderId: data.orderId,
      currency: data.currency,
    }
  } catch (error) {
    console.error('PortOne API verification failed:', error)
    return { valid: false }
  }
}

/**
 * 웹훅 이벤트 로깅
 */
async function logWebhookEvent(
  supabase: ReturnType<typeof createClient>,
  entry: WebhookLogEntry
): Promise<void> {
  try {
    await supabase.from('payment_webhook_logs').insert({
      event_type: entry.event_type,
      payment_provider: entry.payment_provider,
      payment_order_id: entry.payment_order_id,
      webhook_id: entry.webhook_id,
      webhook_payload: entry.webhook_payload,
      signature_valid: entry.signature_valid,
      processed_status: entry.processed_status,
      error_message: entry.error_message,
      processed_at: entry.processed_status !== 'pending' ? new Date().toISOString() : null,
    })
  } catch (error) {
    console.error('Failed to log webhook event:', error)
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

  try {
    const body = await req.text()
    const payload = JSON.parse(body)

    // Extract webhook headers
    const webhookId = req.headers.get('webhook-id') || payload.webhookId || `funding-${Date.now()}`
    const webhookTimestamp = req.headers.get('webhook-timestamp') || ''
    const webhookSignature = req.headers.get('webhook-signature') || ''

    const logEntry: WebhookLogEntry = {
      event_type: payload.type || 'funding.unknown',
      payment_provider: 'portone',
      webhook_id: webhookId,
      webhook_payload: payload,
      signature_valid: false,
      processed_status: 'pending',
    }

    // === 1. 멱등성 체크 ===
    const { data: existingWebhook } = await supabase
      .from('payment_webhook_logs')
      .select('id, processed_status')
      .eq('webhook_id', webhookId)
      .single()

    if (existingWebhook) {
      logEntry.processed_status = 'duplicate'
      await logWebhookEvent(supabase, logEntry)
      return new Response(
        JSON.stringify({ success: true, message: 'Already processed' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // === 2. 서명 검증 ===
    const isValidSignature = await verifyPortOneSignature(webhookId, webhookTimestamp, webhookSignature, body)
    logEntry.signature_valid = isValidSignature

    if (!isValidSignature) {
      logEntry.error_message = 'Invalid webhook signature'
      logEntry.processed_status = 'failed'
      await logWebhookEvent(supabase, logEntry)
      return new Response(
        JSON.stringify({ error: 'Invalid signature' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // === 3. 결제 정보 추출 ===
    const paymentData = payload.data || payload
    const pgPaymentId = paymentData.paymentId || paymentData.paymentKey
    const orderId = paymentData.orderId || paymentData.merchant_uid
    const eventType = payload.type || 'payment.unknown'

    logEntry.payment_order_id = orderId

    if (!orderId) {
      logEntry.error_message = 'Missing order ID'
      logEntry.processed_status = 'failed'
      await logWebhookEvent(supabase, logEntry)
      return new Response(
        JSON.stringify({ error: 'Missing order ID' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // === 4. funding_payments에서 해당 결제 조회 ===
    const { data: fundingPayment, error: paymentError } = await supabase
      .from('funding_payments')
      .select('*, funding_pledges!inner(id, campaign_id, user_id, status, amount_krw, extra_support_krw)')
      .eq('payment_order_id', orderId)
      .single()

    if (paymentError || !fundingPayment) {
      // funding_payments에 없으면 DT 결제 웹훅일 수 있음 → 무시
      console.log(`Funding payment not found for order ${orderId}, may be DT purchase`)
      logEntry.error_message = `Funding payment not found: ${orderId}`
      logEntry.processed_status = 'failed'
      await logWebhookEvent(supabase, logEntry)
      return new Response(
        JSON.stringify({ error: 'Funding payment not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // === 5. PortOne API로 교차 검증 ===
    if (pgPaymentId && ENVIRONMENT !== 'development') {
      const verification = await verifyPaymentWithPortOne(pgPaymentId)

      if (!verification.valid) {
        logEntry.error_message = 'Cross-verification failed'
        logEntry.processed_status = 'failed'
        await logWebhookEvent(supabase, logEntry)
        return new Response(
          JSON.stringify({ error: 'Payment verification failed' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // 금액 불일치 체크
      if (verification.amount && verification.amount !== fundingPayment.amount_krw) {
        logEntry.error_message = `Amount mismatch: expected=${fundingPayment.amount_krw}, actual=${verification.amount}`
        logEntry.processed_status = 'failed'
        await logWebhookEvent(supabase, logEntry)
        return new Response(
          JSON.stringify({ error: 'Amount mismatch' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // === 6. 이벤트별 처리 ===
    const isPaymentSuccess =
      eventType === 'Transaction.Paid' ||
      paymentData.status === 'PAID' ||
      paymentData.status === 'paid'

    const isPaymentCancelled =
      eventType === 'Transaction.Cancelled' ||
      paymentData.status === 'CANCELED' ||
      paymentData.status === 'CANCELLED'

    const isPartialCancelled =
      eventType === 'Transaction.PartialCancelled' ||
      paymentData.status === 'PARTIAL_CANCELED'

    // --- 6a. 결제 성공 ---
    if (isPaymentSuccess) {
      // funding_payment가 이미 paid 상태면 스킵
      if (fundingPayment.status === 'paid') {
        logEntry.processed_status = 'duplicate'
        await logWebhookEvent(supabase, logEntry)
        return new Response(
          JSON.stringify({ success: true, message: 'Payment already confirmed' }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // funding_payments 상태 업데이트
      const { error: updatePaymentError } = await supabase
        .from('funding_payments')
        .update({
          status: 'paid',
          pg_transaction_id: paymentData.transactionId || paymentData.pgTxId || pgPaymentId,
          pg_payment_id: pgPaymentId,
          paid_at: new Date().toISOString(),
          pg_response: paymentData,
        })
        .eq('id', fundingPayment.id)

      if (updatePaymentError) {
        logEntry.error_message = `Failed to update payment: ${updatePaymentError.message}`
        logEntry.processed_status = 'failed'
        await logWebhookEvent(supabase, logEntry)
        return new Response(
          JSON.stringify({ error: 'Failed to update payment status' }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // pledge 상태도 confirmed로
      if (fundingPayment.funding_pledges?.status === 'pending') {
        await supabase
          .from('funding_pledges')
          .update({ status: 'confirmed' })
          .eq('id', fundingPayment.pledge_id)
      }

      console.log(`Funding payment confirmed: ${orderId}, amount=${fundingPayment.amount_krw} KRW`)

      logEntry.processed_status = 'success'
      await logWebhookEvent(supabase, logEntry)
      return new Response(
        JSON.stringify({ success: true, message: 'Payment confirmed' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // --- 6b. 결제 전액 취소 ---
    if (isPaymentCancelled) {
      const pledge = fundingPayment.funding_pledges

      // funding_payments 환불 처리
      const { error: refundError } = await supabase
        .from('funding_payments')
        .update({
          status: 'refunded',
          refunded_amount_krw: fundingPayment.amount_krw,
          refund_reason: 'payment_cancelled_by_pg',
          refunded_at: new Date().toISOString(),
          pg_response: paymentData,
        })
        .eq('id', fundingPayment.id)

      if (refundError) {
        logEntry.error_message = `Failed to process refund: ${refundError.message}`
        logEntry.processed_status = 'failed'
        await logWebhookEvent(supabase, logEntry)
        return new Response(
          JSON.stringify({ error: 'Failed to process refund' }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // pledge 상태 업데이트
      await supabase
        .from('funding_pledges')
        .update({ status: 'refunded' })
        .eq('id', fundingPayment.pledge_id)

      // campaign 금액 차감
      if (pledge?.campaign_id) {
        const totalPledgeKrw = (pledge.amount_krw || 0) + (pledge.extra_support_krw || 0)
        await supabase.rpc('decrement_campaign_amount', {
          p_campaign_id: pledge.campaign_id,
          p_amount_krw: totalPledgeKrw,
        })
      }

      console.log(`Funding payment cancelled: ${orderId}, refund=${fundingPayment.amount_krw} KRW`)

      logEntry.processed_status = 'success'
      await logWebhookEvent(supabase, logEntry)
      return new Response(
        JSON.stringify({ success: true, message: 'Cancellation processed' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // --- 6c. 부분 환불 ---
    if (isPartialCancelled) {
      const cancelAmount = paymentData.cancels?.[0]?.cancelAmount || 0
      const cancelReason = paymentData.cancels?.[0]?.cancelReason || 'partial_refund'

      const { error: partialRefundError } = await supabase
        .from('funding_payments')
        .update({
          status: 'partial_refunded',
          refunded_amount_krw: (fundingPayment.refunded_amount_krw || 0) + cancelAmount,
          refund_reason: cancelReason,
          refunded_at: new Date().toISOString(),
          pg_response: paymentData,
        })
        .eq('id', fundingPayment.id)

      if (partialRefundError) {
        logEntry.error_message = `Failed to process partial refund: ${partialRefundError.message}`
        logEntry.processed_status = 'failed'
        await logWebhookEvent(supabase, logEntry)
        return new Response(
          JSON.stringify({ error: 'Failed to process partial refund' }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      console.log(`Funding partial refund: ${orderId}, amount=${cancelAmount} KRW`)

      logEntry.processed_status = 'success'
      await logWebhookEvent(supabase, logEntry)
      return new Response(
        JSON.stringify({ success: true, message: 'Partial refund processed' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // --- 6d. 기타 이벤트 ---
    console.log(`Unhandled funding webhook event: ${eventType}`)
    logEntry.processed_status = 'success'
    await logWebhookEvent(supabase, logEntry)
    return new Response(
      JSON.stringify({ success: true, message: `Event ${eventType} acknowledged` }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Funding payment webhook error:', error)

    try {
      await supabase.from('payment_webhook_logs').insert({
        event_type: 'funding_webhook.error',
        payment_provider: 'portone',
        webhook_payload: { error: String(error) },
        signature_valid: false,
        processed_status: 'failed',
        error_message: String(error),
      })
    } catch {
      // Ignore logging errors
    }

    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
