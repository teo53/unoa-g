// Payment Webhook Edge Function
// Handles callbacks from payment providers (TossPayments, Iamport, etc.)
// Implements idempotent ledger writes with atomic transactions

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { crypto } from 'https://deno.land/std@0.168.0/crypto/mod.ts'
import { encode } from 'https://deno.land/std@0.168.0/encoding/hex.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Verify webhook signature using HMAC-SHA256
async function verifySignature(payload: string, signature: string, provider: string): Promise<boolean> {
  // Skip verification in development mode only
  const environment = Deno.env.get('ENVIRONMENT') || 'production'
  if (environment === 'development') {
    console.log(`[DEV] Skipping signature verification for provider: ${provider}`)
    return true
  }

  // Get the appropriate secret based on provider
  let secret: string | undefined
  switch (provider) {
    case 'tosspayments':
      secret = Deno.env.get('TOSSPAYMENTS_WEBHOOK_SECRET')
      break
    case 'iamport':
      secret = Deno.env.get('IAMPORT_WEBHOOK_SECRET')
      break
    default:
      secret = Deno.env.get('PAYMENT_WEBHOOK_SECRET')
  }

  if (!secret) {
    console.error(`Missing webhook secret for provider: ${provider}`)
    return false
  }

  if (!signature) {
    console.error('Missing signature in request')
    return false
  }

  try {
    // Create HMAC-SHA256 signature
    const encoder = new TextEncoder()
    const keyData = encoder.encode(secret)
    const messageData = encoder.encode(payload)

    const key = await crypto.subtle.importKey(
      'raw',
      keyData,
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    )

    const signatureBuffer = await crypto.subtle.sign('HMAC', key, messageData)
    const computedSignature = new TextDecoder().decode(encode(new Uint8Array(signatureBuffer)))

    // Timing-safe comparison
    if (computedSignature.length !== signature.length) {
      return false
    }

    let result = 0
    for (let i = 0; i < computedSignature.length; i++) {
      result |= computedSignature.charCodeAt(i) ^ signature.charCodeAt(i)
    }

    const isValid = result === 0
    if (!isValid) {
      console.error('Signature verification failed')
    }
    return isValid
  } catch (error) {
    console.error('Signature verification error:', error)
    return false
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.text()
    const signature = req.headers.get('x-webhook-signature') || ''
    const provider = req.headers.get('x-payment-provider') || 'tosspayments'

    // Verify webhook signature (now async with proper HMAC verification)
    const isValidSignature = await verifySignature(body, signature, provider)
    if (!isValidSignature) {
      return new Response(
        JSON.stringify({ error: 'Invalid signature' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const payload = JSON.parse(body)

    // Extract order ID based on provider format
    // TossPayments: orderId
    // Iamport: merchant_uid
    const orderId = payload.orderId || payload.merchant_uid || payload.purchaseId
    const transactionId = payload.paymentKey || payload.imp_uid || payload.transactionId
    const status = payload.status || payload.pay_status || 'DONE'

    if (!orderId) {
      return new Response(
        JSON.stringify({ error: 'Missing order ID' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Idempotency key for this transaction
    const idempotencyKey = `purchase:${orderId}`

    // Check if already processed (idempotency)
    const { data: existingEntry } = await supabase
      .from('ledger_entries')
      .select('id')
      .eq('idempotency_key', idempotencyKey)
      .single()

    if (existingEntry) {
      console.log(`Transaction already processed: ${idempotencyKey}`)
      return new Response(
        JSON.stringify({ success: true, message: 'Already processed' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get purchase record
    const { data: purchase, error: purchaseError } = await supabase
      .from('dt_purchases')
      .select('*')
      .eq('id', orderId)
      .single()

    if (purchaseError || !purchase) {
      console.error('Purchase not found:', orderId)
      return new Response(
        JSON.stringify({ error: 'Purchase not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if payment was successful
    if (status !== 'DONE' && status !== 'paid') {
      // Update purchase as failed
      await supabase
        .from('dt_purchases')
        .update({
          status: 'failed',
          payment_provider_transaction_id: transactionId,
        })
        .eq('id', orderId)

      return new Response(
        JSON.stringify({ success: true, message: 'Payment failed' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get user's wallet
    const { data: wallet, error: walletError } = await supabase
      .from('wallets')
      .select('*')
      .eq('user_id', purchase.user_id)
      .single()

    if (walletError || !wallet) {
      // Create wallet if doesn't exist
      const { data: newWallet, error: createError } = await supabase
        .from('wallets')
        .insert({ user_id: purchase.user_id })
        .select()
        .single()

      if (createError) {
        console.error('Failed to create wallet:', createError)
        return new Response(
          JSON.stringify({ error: 'Failed to process payment' }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      wallet.id = newWallet.id
      wallet.balance_dt = 0
      wallet.lifetime_purchased_dt = 0
    }

    const totalDt = purchase.dt_amount + purchase.bonus_dt

    // Execute atomic transaction via stored procedure
    // This ensures all operations succeed or all fail together
    const { data: txResult, error: txError } = await supabase.rpc('process_payment_atomic', {
      p_order_id: orderId,
      p_transaction_id: transactionId,
      p_wallet_id: wallet.id,
      p_user_id: purchase.user_id,
      p_total_dt: totalDt,
      p_dt_amount: purchase.dt_amount,
      p_bonus_dt: purchase.bonus_dt,
      p_idempotency_key: idempotencyKey,
    })

    if (txError) {
      // Check if it's a duplicate key error (already processed - idempotency)
      if (txError.code === '23505' || txError.message?.includes('already_processed')) {
        console.log(`Transaction already processed (idempotent): ${idempotencyKey}`)
        return new Response(
          JSON.stringify({ success: true, message: 'Already processed' }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      console.error('Atomic transaction failed:', txError)
      return new Response(
        JSON.stringify({ error: 'Failed to process payment' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const newBalance = txResult?.new_balance ?? (wallet.balance_dt + totalDt)
    console.log(`Successfully processed payment for user ${purchase.user_id}: ${totalDt} DT (new balance: ${newBalance})`)

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
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
