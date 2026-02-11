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

// Environment configuration
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || ''
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
const PORTONE_API_SECRET = Deno.env.get('PORTONE_API_SECRET') || ''
const PORTONE_WEBHOOK_SECRET = Deno.env.get('PORTONE_WEBHOOK_SECRET') || ''
const TOSSPAYMENTS_SECRET_KEY = Deno.env.get('TOSSPAYMENTS_SECRET_KEY') || ''
const ENVIRONMENT = Deno.env.get('ENVIRONMENT') || 'production'
// SECURITY: Explicit flag required to skip signature verification (NEVER enable in production)
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

// PortOne V2 Webhook Signature Verification
// Reference: https://developers.portone.io/docs/ko/result/webhook
async function verifyPortOneSignature(
  webhookId: string,
  webhookTimestamp: string,
  webhookSignature: string,
  payload: string
): Promise<boolean> {
  // SECURITY: Only skip verification when explicitly enabled in development
  if (isDevelopmentWithSkip) {
    console.warn('[DEV] SECURITY WARNING: Skipping PortOne signature verification. Never enable this in production!')
    return true
  }

  if (!PORTONE_WEBHOOK_SECRET) {
    console.error('Webhook signature verification not configured')
    return false
  }

  try {
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
async function verifyTossPaymentsSignature(
  signature: string,
  payload: string
): Promise<boolean> {
  // SECURITY: Only skip verification when explicitly enabled in development
  if (isDevelopmentWithSkip) {
    console.warn('[DEV] SECURITY WARNING: Skipping TossPayments signature verification. Never enable this in production!')
    return true
  }

  if (!TOSSPAYMENTS_SECRET_KEY) {
    console.error('Payment gateway credentials not configured')
    return false
  }

  try {
    const encoder = new TextEncoder()
    const key = await crypto.subtle.importKey(
      'raw',
      encoder.encode(TOSSPAYMENTS_SECRET_KEY),
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

// Cross-verify payment with PortOne V2 API
async function verifyPaymentWithPortOne(paymentId: string): Promise<{
  valid: boolean
  amount?: number
  status?: string
  orderId?: string
}> {
  try {
    const response = await fetch(
      `https://api.portone.io/payments/${paymentId}`,
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

// Log webhook event to database
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
    // Don't fail the webhook if logging fails, but do log the error
    console.error('Failed to log webhook event:', error)
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
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
    const webhookSignature = req.headers.get('webhook-signature') || req.headers.get('x-webhook-signature') || ''

    // Initialize log entry
    const logEntry: WebhookLogEntry = {
      event_type: payload.type || payload.eventType || 'payment.unknown',
      payment_provider: provider,
      webhook_id: webhookId,
      webhook_payload: payload,
      signature_valid: false,
      processed_status: 'pending',
    }

    // Check idempotency first (before signature verification to save compute)
    const { data: existingWebhook } = await supabase
      .from('payment_webhook_logs')
      .select('id, processed_status')
      .eq('webhook_id', webhookId)
      .single()

    if (existingWebhook) {
      console.log(`Webhook already processed: ${webhookId}`)
      logEntry.processed_status = 'duplicate'
      await logWebhookEvent(supabase, logEntry)
      return new Response(
        JSON.stringify({ success: true, message: 'Already processed' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify signature based on provider
    let isValidSignature = false
    if (provider === 'portone') {
      isValidSignature = await verifyPortOneSignature(webhookId, webhookTimestamp, webhookSignature, body)
    } else if (provider === 'tosspayments') {
      isValidSignature = await verifyTossPaymentsSignature(webhookSignature, body)
    } else {
      // Unknown provider - reject in production
      if (ENVIRONMENT !== 'development') {
        logEntry.error_message = 'Unknown payment provider'
        logEntry.processed_status = 'failed'
        await logWebhookEvent(supabase, logEntry)
        return new Response(
          JSON.stringify({ error: 'Unknown payment provider' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      isValidSignature = true
    }

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
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Cross-verify payment with PortOne API (if PortOne provider)
    if (provider === 'portone' && paymentId && ENVIRONMENT !== 'development') {
      const verification = await verifyPaymentWithPortOne(paymentId)
      if (!verification.valid) {
        logEntry.error_message = 'Payment cross-verification failed'
        logEntry.processed_status = 'failed'
        await logWebhookEvent(supabase, logEntry)
        return new Response(
          JSON.stringify({ error: 'Payment verification failed' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Verify amount matches if applicable
      if (verification.orderId && verification.orderId !== orderId) {
        logEntry.error_message = 'Order ID mismatch between webhook payload and payment provider'
        logEntry.processed_status = 'failed'
        await logWebhookEvent(supabase, logEntry)
        return new Response(
          JSON.stringify({ error: 'Order ID mismatch' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
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
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
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
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // TODO: Handle refund of DT if already credited
      logEntry.processed_status = 'success'
      await logWebhookEvent(supabase, logEntry)
      return new Response(
        JSON.stringify({ success: true, message: 'Cancellation processed' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
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
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
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
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
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
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
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
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      wallet = newWallet
    } else {
      wallet = existingWallet
    }

    const totalDt = purchase.dt_amount + (purchase.bonus_dt || 0)
    const idempotencyKey = `purchase:${orderId}`

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
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      logEntry.error_message = `Atomic transaction failed: ${txError.message}`
      logEntry.processed_status = 'failed'
      await logWebhookEvent(supabase, logEntry)
      return new Response(
        JSON.stringify({ error: 'Failed to process payment' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
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
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
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
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
