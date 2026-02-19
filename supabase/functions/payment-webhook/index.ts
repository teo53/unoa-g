// Payment Webhook Edge Function
// Handles callbacks from payment providers (PortOne V2, TossPayments)
// Implements idempotent ledger writes with atomic transactions
//
// SECURITY:
// - Webhook signature verification (PortOne V2 standard)
// - Idempotency check via webhook_id
// - Cross-verification with payment provider API
// - All events logged to payment_webhook_logs table

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getWebhookCorsHeaders } from '../_shared/cors.ts'

// Environment configuration
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || ''
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
const PORTONE_API_SECRET = Deno.env.get('PORTONE_API_SECRET') || ''
const PORTONE_WEBHOOK_SECRET = Deno.env.get('PORTONE_WEBHOOK_SECRET') || ''
const TOSSPAYMENTS_SECRET_KEY = Deno.env.get('TOSSPAYMENTS_SECRET_KEY') || ''

const webhookCorsHeaders = getWebhookCorsHeaders()

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

// PortOne V2 Webhook Signature Verification
// Reference: https://developers.portone.io/docs/ko/result/webhook
async function verifyPortOneSignature(
  webhookId: string,
  webhookTimestamp: string,
  webhookSignature: string,
  payload: string
): Promise<boolean> {
  if (!PORTONE_WEBHOOK_SECRET) {
    console.error('Webhook signature verification not configured')
    return false
  }

  try {
    // B8: Validate timestamp is within 5-minute window (replay attack prevention)
    const timestampMs = parseInt(webhookTimestamp) * 1000
    if (isNaN(timestampMs) || Math.abs(Date.now() - timestampMs) > 5 * 60 * 1000) {
      console.error('Webhook timestamp outside 5-minute window')
      return false
    }

    // PortOne V2 signature format: {timestamp}.{payload}
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

    // Convert to base64
    const computedSignature = btoa(String.fromCharCode(...new Uint8Array(signatureBuffer)))

    // Timing-safe comparison
    const expected = computedSignature
    const received = webhookSignature.replace('v1,', '') // Remove version prefix if present

    if (expected.length !== received.length) {
      console.error('Signature length mismatch')
      return false
    }

    let result = 0
    for (let i = 0; i < expected.length; i++) {
      result |= expected.charCodeAt(i) ^ received.charCodeAt(i)
    }

    const isValid = result === 0
    if (!isValid) {
      console.error('PortOne signature verification failed')
    }
    return isValid
  } catch (error) {
    console.error('PortOne signature verification error:', error)
    return false
  }
}

// TossPayments Webhook Signature Verification
// NOTE: TossPayments only sends `tosspayments-webhook-signature` on payout/seller events.
// For standard payment webhooks, signature is NOT included — use API cross-verification instead.
const TOSSPAYMENTS_WEBHOOK_SECRET = Deno.env.get('TOSSPAYMENTS_WEBHOOK_SECRET') || ''

async function verifyTossPaymentsSignature(
  signature: string,
  payload: string
): Promise<boolean> {
  // No signature provided and no secret configured — rely on API cross-verification
  if (!signature && !TOSSPAYMENTS_WEBHOOK_SECRET) {
    console.log('TossPayments: no signature header, will use API cross-verification')
    return true // Signature check passes; caller must do API cross-verify
  }

  // Signature header present — verify it
  if (signature && TOSSPAYMENTS_WEBHOOK_SECRET) {
    try {
      const encoder = new TextEncoder()
      const key = await crypto.subtle.importKey(
        'raw',
        encoder.encode(TOSSPAYMENTS_WEBHOOK_SECRET),
        { name: 'HMAC', hash: 'SHA-256' },
        false,
        ['sign']
      )

      const signatureBuffer = await crypto.subtle.sign(
        'HMAC',
        key,
        encoder.encode(payload)
      )

      const computedSignature = btoa(String.fromCharCode(...new Uint8Array(signatureBuffer)))

      // Timing-safe comparison
      if (computedSignature.length !== signature.length) {
        return false
      }

      let result = 0
      for (let i = 0; i < computedSignature.length; i++) {
        result |= computedSignature.charCodeAt(i) ^ signature.charCodeAt(i)
      }

      return result === 0
    } catch (error) {
      console.error('TossPayments signature verification error:', error)
      return false
    }
  }

  // Signature present but no secret configured — cannot verify, reject
  if (signature && !TOSSPAYMENTS_WEBHOOK_SECRET) {
    console.error('TossPayments: signature present but TOSSPAYMENTS_WEBHOOK_SECRET not configured')
    return false
  }

  // No signature, but secret is configured — allow (payment events don't include signature)
  return true
}

// Cross-verify payment with PortOne V2 API
async function verifyPaymentWithPortOne(paymentId: string): Promise<{
  valid: boolean
  amount?: number
  status?: string
  orderId?: string
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
    }
  } catch (error) {
    console.error('PortOne API verification failed:', error)
    return { valid: false }
  }
}

// Log webhook event to database (UPSERT to handle retries safely)
async function logWebhookEvent(
  supabase: ReturnType<typeof createClient>,
  entry: WebhookLogEntry
): Promise<void> {
  try {
    await supabase.from('payment_webhook_logs').upsert(
      {
        event_type: entry.event_type,
        payment_provider: entry.payment_provider,
        payment_order_id: entry.payment_order_id,
        webhook_id: entry.webhook_id,
        webhook_payload: entry.webhook_payload,
        signature_valid: entry.signature_valid,
        processed_status: entry.processed_status,
        error_message: entry.error_message,
        processed_at: entry.processed_status !== 'pending' ? new Date().toISOString() : null,
      },
      { onConflict: 'webhook_id' }
    )
  } catch (error) {
    // Don't fail the webhook if logging fails, but do log the error
    console.error('Failed to log webhook event:', error)
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: webhookCorsHeaders })
  }

  // Initialize Supabase client
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

  try {
    const body = await req.text()
    const payload = JSON.parse(body)

    // Determine provider from headers or payload
    const providerHeader = req.headers.get('x-payment-provider')
    const isPortOne = req.headers.get('webhook-id') !== null || payload.type?.startsWith('Transaction.')
    const provider = providerHeader || (isPortOne ? 'portone' : 'tosspayments')

    // Extract webhook identification
    const webhookId = req.headers.get('webhook-id') || payload.webhookId || payload.eventId || `${provider}-${Date.now()}`
    const webhookTimestamp = req.headers.get('webhook-timestamp') || ''
    const webhookSignature = req.headers.get('webhook-signature') || req.headers.get('tosspayments-webhook-signature') || req.headers.get('x-webhook-signature') || ''

    // Initialize log entry
    const logEntry: WebhookLogEntry = {
      event_type: payload.type || payload.eventType || 'payment.unknown',
      payment_provider: provider,
      webhook_id: webhookId,
      webhook_payload: payload,
      signature_valid: false,
      processed_status: 'pending',
    }

    // Idempotency check: only skip if previously succeeded or marked duplicate.
    // If a previous attempt failed, allow reprocessing (retry).
    const { data: existingWebhook } = await supabase
      .from('payment_webhook_logs')
      .select('id, processed_status')
      .eq('webhook_id', webhookId)
      .single()

    if (existingWebhook) {
      if (existingWebhook.processed_status === 'success' || existingWebhook.processed_status === 'duplicate') {
        console.log(`Webhook already processed (${existingWebhook.processed_status}): ${webhookId}`)
        logEntry.processed_status = 'duplicate'
        await logWebhookEvent(supabase, logEntry)
        return new Response(
          JSON.stringify({ success: true, message: 'Already processed' }),
          { status: 200, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      // Previous attempt failed — allow retry
      console.log(`Retrying previously failed webhook: ${webhookId} (was: ${existingWebhook.processed_status})`)
    }

    // Verify signature based on provider
    let isValidSignature = false
    if (provider === 'portone') {
      isValidSignature = await verifyPortOneSignature(webhookId, webhookTimestamp, webhookSignature, body)
    } else if (provider === 'tosspayments') {
      isValidSignature = await verifyTossPaymentsSignature(webhookSignature, body)
    } else {
      // Unknown provider - always reject
      logEntry.error_message = 'Unknown payment provider'
      logEntry.processed_status = 'failed'
      await logWebhookEvent(supabase, logEntry)
      return new Response(
        JSON.stringify({ error: 'Unknown payment provider' }),
        { status: 400, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    logEntry.signature_valid = isValidSignature

    if (!isValidSignature) {
      logEntry.error_message = 'Invalid webhook signature'
      logEntry.processed_status = 'failed'
      await logWebhookEvent(supabase, logEntry)
      return new Response(
        JSON.stringify({ error: 'Invalid signature' }),
        { status: 401, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Extract payment information based on provider
    // PortOne V2: data.paymentId, data.transactionId
    // TossPayments: paymentKey, orderId
    const paymentData = payload.data || payload
    const paymentId = paymentData.paymentId || paymentData.paymentKey || paymentData.imp_uid
    const orderId = paymentData.orderId || paymentData.merchant_uid || paymentData.purchaseId
    const eventType = payload.type || payload.eventType || 'payment.completed'

    logEntry.payment_order_id = orderId

    if (!orderId) {
      logEntry.error_message = 'Missing order ID in webhook payload'
      logEntry.processed_status = 'failed'
      await logWebhookEvent(supabase, logEntry)
      return new Response(
        JSON.stringify({ error: 'Missing order ID' }),
        { status: 400, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Cross-verify payment with provider API
    let verification: { valid: boolean; amount?: number; status?: string; orderId?: string } | undefined

    if (provider === 'portone' && paymentId) {
      verification = await verifyPaymentWithPortOne(paymentId)
      if (!verification.valid) {
        logEntry.error_message = 'Payment cross-verification failed'
        logEntry.processed_status = 'failed'
        await logWebhookEvent(supabase, logEntry)
        return new Response(
          JSON.stringify({ error: 'Payment verification failed' }),
          { status: 400, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      if (verification.orderId && verification.orderId !== orderId) {
        logEntry.error_message = 'Order ID mismatch between webhook payload and payment provider'
        logEntry.processed_status = 'failed'
        await logWebhookEvent(supabase, logEntry)
        return new Response(
          JSON.stringify({ error: 'Order ID mismatch' }),
          { status: 400, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // TossPayments API cross-verification (essential when no webhook signature)
    if (provider === 'tosspayments' && orderId && TOSSPAYMENTS_SECRET_KEY) {
      try {
        const tossAuth = btoa(`${TOSSPAYMENTS_SECRET_KEY}:`)
        const tossVerifyRes = await fetch(
          `https://api.tosspayments.com/v1/payments/orders/${orderId}`,
          {
            method: 'GET',
            headers: {
              'Authorization': `Basic ${tossAuth}`,
              'Content-Type': 'application/json',
            },
          }
        )

        if (tossVerifyRes.ok) {
          const tossVerifyData = await tossVerifyRes.json()
          verification = {
            valid: true,
            amount: tossVerifyData.totalAmount,
            status: tossVerifyData.status,
            orderId: tossVerifyData.orderId,
          }
        } else {
          console.error(`[Webhook] TossPayments API verification failed: ${tossVerifyRes.status}`)
          logEntry.error_message = 'TossPayments cross-verification failed'
          logEntry.processed_status = 'failed'
          await logWebhookEvent(supabase, logEntry)
          return new Response(
            JSON.stringify({ error: 'Payment verification failed' }),
            { status: 400, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
          )
        }
      } catch (error) {
        console.error('[Webhook] TossPayments API verification error:', error)
        // SECURITY: Fail-closed on network errors — return 503 so PG retries
        logEntry.error_message = `TossPayments API network error: ${error}`
        logEntry.processed_status = 'failed'
        await logWebhookEvent(supabase, logEntry)
        return new Response(
          JSON.stringify({ error: 'Payment verification temporarily unavailable' }),
          { status: 503, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // Handle different event types
    // PortOne V2 events: Transaction.Paid, Transaction.Ready, Transaction.Cancelled, etc.
    // TossPayments events: DONE, CANCELED, etc.
    const isPaymentSuccess =
      eventType === 'Transaction.Paid' ||
      eventType === 'payment.completed' ||
      paymentData.status === 'DONE' ||
      paymentData.status === 'PAID' ||
      paymentData.status === 'paid'

    const isPaymentCancelled =
      eventType === 'Transaction.Cancelled' ||
      eventType === 'payment.cancelled' ||
      paymentData.status === 'CANCELED' ||
      paymentData.status === 'CANCELLED'

    // Chargeback detection
    // PortOne V2: Transaction.PartialCancelled, Transaction.CancelPending
    // TossPayments: PARTIAL_CANCELED status, cancels array with chargeback reason
    const isChargeback =
      eventType === 'Transaction.PartialCancelled' ||
      eventType === 'Transaction.CancelPending' ||
      eventType === 'payment.chargeback' ||
      paymentData.status === 'PARTIAL_CANCELED' ||
      (paymentData.cancels && paymentData.cancels[0]?.cancelReason?.toUpperCase().includes('CHARGEBACK'))

    // Get purchase record
    const { data: purchase, error: purchaseError } = await supabase
      .from('dt_purchases')
      .select('*')
      .eq('id', orderId)
      .single()

    if (purchaseError || !purchase) {
      logEntry.error_message = `Purchase not found: ${orderId}`
      logEntry.processed_status = 'failed'
      await logWebhookEvent(supabase, logEntry)
      return new Response(
        JSON.stringify({ error: 'Purchase not found' }),
        { status: 404, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // S-P1-1: Cross-verify PG amount matches purchase record
    const pgAmount = verification?.amount ?? paymentData.totalAmount ?? paymentData.amount
    if (pgAmount != null && purchase.price_krw != null && pgAmount !== purchase.price_krw) {
      console.error(
        `[Webhook] Amount mismatch: purchase.price_krw=${purchase.price_krw}, PG amount=${pgAmount}, orderId=${orderId}`
      )
      logEntry.error_message = `Amount mismatch: expected=${purchase.price_krw}, got=${pgAmount}`
      logEntry.processed_status = 'failed'
      await logWebhookEvent(supabase, logEntry)

      await supabase
        .from('dt_purchases')
        .update({ status: 'failed', updated_at: new Date().toISOString() })
        .eq('id', orderId)

      return new Response(
        JSON.stringify({ error: 'Payment amount verification failed' }),
        { status: 400, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Handle cancellation/refund
    if (isPaymentCancelled) {
      const { error: cancelError } = await supabase
        .from('dt_purchases')
        .update({
          status: 'cancelled',
          payment_provider_transaction_id: paymentId,
          updated_at: new Date().toISOString(),
        })
        .eq('id', orderId)

      if (cancelError) {
        logEntry.error_message = `Failed to update purchase status: ${cancelError.message}`
        logEntry.processed_status = 'failed'
        await logWebhookEvent(supabase, logEntry)
        return new Response(
          JSON.stringify({ error: 'Failed to process cancellation' }),
          { status: 500, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Handle refund of DT if already credited
      if (purchase.status === 'paid') {
        const refundReason = paymentData.cancels?.[0]?.cancelReason || paymentData.cancelReason || 'Payment cancelled'

        console.log(`Processing DT refund for cancelled purchase ${orderId}`)

        const { data: refundResult, error: refundError } = await supabase.rpc('process_refund_atomic', {
          p_order_id: orderId,
          p_refund_reason: refundReason,
        })

        if (refundError) {
          // Check if already processed (idempotency)
          if (refundError.code === '23505' || refundError.message?.includes('already_processed')) {
            console.log(`Refund already processed for purchase ${orderId}`)
            logEntry.processed_status = 'success'
            await logWebhookEvent(supabase, logEntry)
            return new Response(
              JSON.stringify({ success: true, message: 'Cancellation already processed' }),
              { status: 200, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
            )
          }

          // Log the error but still return 200 to avoid webhook retries
          console.error(`Refund processing failed for purchase ${orderId}:`, refundError)
          logEntry.error_message = `Refund failed: ${refundError.message}`
          logEntry.processed_status = 'failed'
          await logWebhookEvent(supabase, logEntry)
          return new Response(
            JSON.stringify({ error: 'Refund processing failed', details: refundError.message }),
            { status: 200, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
          )
        }

        console.log(`DT refund processed for purchase ${orderId}: ${refundResult?.refunded_dt || 0} DT refunded`)
        logEntry.processed_status = 'success'
        await logWebhookEvent(supabase, logEntry)
        return new Response(
          JSON.stringify({
            success: true,
            message: 'Cancellation and refund processed',
            refundedDt: refundResult?.refunded_dt || 0,
          }),
          { status: 200, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Purchase was not paid yet, just mark as cancelled
      logEntry.processed_status = 'success'
      await logWebhookEvent(supabase, logEntry)
      return new Response(
        JSON.stringify({ success: true, message: 'Cancellation processed' }),
        { status: 200, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Handle chargeback dispute
    if (isChargeback) {
      const disputeAmountKrw = paymentData.cancels?.[0]?.cancelAmount || purchase.price_krw || 0
      const disputeReason = paymentData.cancels?.[0]?.cancelReason || paymentData.failReason || 'Chargeback'

      console.log(`Processing chargeback for purchase ${orderId}: ${disputeAmountKrw} KRW`)

      const { data: chargebackResult, error: chargebackError } = await supabase.rpc('process_chargeback', {
        p_purchase_id: orderId,
        p_provider_dispute_id: paymentId || webhookId,
        p_payment_provider: provider,
        p_dispute_amount_krw: disputeAmountKrw,
        p_dispute_reason: disputeReason,
      })

      if (chargebackError) {
        console.error(`Chargeback processing failed for purchase ${orderId}:`, chargebackError)
        logEntry.error_message = `Chargeback processing failed: ${chargebackError.message}`
        logEntry.processed_status = 'failed'
        await logWebhookEvent(supabase, logEntry)
        return new Response(
          JSON.stringify({ error: 'Chargeback processing failed' }),
          { status: 500, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      console.log(`Chargeback processed for purchase ${orderId}:`, JSON.stringify(chargebackResult))
      logEntry.processed_status = 'success'
      await logWebhookEvent(supabase, logEntry)
      return new Response(
        JSON.stringify({
          success: true,
          message: 'Chargeback processed',
          disputeId: chargebackResult?.dispute_id,
          dtFrozen: chargebackResult?.dt_frozen,
        }),
        { status: 200, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Handle failed payment
    if (!isPaymentSuccess) {
      const { error: failError } = await supabase
        .from('dt_purchases')
        .update({
          status: 'failed',
          payment_provider_transaction_id: paymentId,
          updated_at: new Date().toISOString(),
        })
        .eq('id', orderId)

      if (failError) {
        logEntry.error_message = `Failed to update purchase status: ${failError.message}`
      }

      logEntry.processed_status = 'success'
      await logWebhookEvent(supabase, logEntry)
      return new Response(
        JSON.stringify({ success: true, message: 'Payment failure recorded' }),
        { status: 200, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get or create user's wallet
    let wallet = null
    const { data: existingWallet, error: walletError } = await supabase
      .from('wallets')
      .select('*')
      .eq('user_id', purchase.user_id)
      .single()

    if (walletError || !existingWallet) {
      const { data: newWallet, error: createError } = await supabase
        .from('wallets')
        .insert({ user_id: purchase.user_id, balance_dt: 0 })
        .select()
        .single()

      if (createError) {
        logEntry.error_message = `Failed to create wallet: ${createError.message}`
        logEntry.processed_status = 'failed'
        await logWebhookEvent(supabase, logEntry)
        return new Response(
          JSON.stringify({ error: 'Failed to process payment' }),
          { status: 500, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      wallet = newWallet
    } else {
      wallet = existingWallet
    }

    const totalDt = purchase.dt_amount + (purchase.bonus_dt || 0)
    const idempotencyKey = `toss:${orderId}`

    // Execute atomic transaction via stored procedure
    const { data: txResult, error: txError } = await supabase.rpc('process_payment_atomic', {
      p_order_id: orderId,
      p_transaction_id: paymentId,
      p_wallet_id: wallet.id,
      p_user_id: purchase.user_id,
      p_total_dt: totalDt,
      p_dt_amount: purchase.dt_amount,
      p_bonus_dt: purchase.bonus_dt || 0,
      p_idempotency_key: idempotencyKey,
    })

    if (txError) {
      // Check if it's a duplicate key error (already processed - idempotency)
      if (txError.code === '23505' || txError.message?.includes('already_processed')) {
        console.log(`Transaction already processed (idempotent): ${idempotencyKey}`)
        logEntry.processed_status = 'duplicate'
        await logWebhookEvent(supabase, logEntry)
        return new Response(
          JSON.stringify({ success: true, message: 'Already processed' }),
          { status: 200, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      logEntry.error_message = `Atomic transaction failed: ${txError.message}`
      logEntry.processed_status = 'failed'
      await logWebhookEvent(supabase, logEntry)
      return new Response(
        JSON.stringify({ error: 'Failed to process payment' }),
        { status: 500, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const newBalance = txResult?.new_balance ?? (wallet.balance_dt + totalDt)
    console.log(`Successfully processed payment for user ${purchase.user_id}: ${totalDt} DT (new balance: ${newBalance})`)

    logEntry.processed_status = 'success'
    await logWebhookEvent(supabase, logEntry)

    return new Response(
      JSON.stringify({
        success: true,
        purchaseId: orderId,
        creditedDt: totalDt,
        newBalance: newBalance,
      }),
      { status: 200, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Payment webhook error:', error)

    // Try to log the error
    try {
      await supabase.from('payment_webhook_logs').insert({
        event_type: 'webhook.error',
        payment_provider: 'unknown',
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
      { status: 500, headers: { ...webhookCorsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
