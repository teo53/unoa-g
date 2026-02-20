// Payment Confirm Edge Function
// Called after Toss redirects user to successUrl with paymentKey/orderId/amount.
// Confirms the payment with TossPayments and atomically credits DT.
//
// Two-layer idempotency:
//   External: Idempotency-Key: confirm:{orderId} (Toss API, 15 days)
//   Internal: process_payment_atomic p_idempotency_key = toss:{orderId}
//
// Same internal key used by webhook and reconcile, so whichever
// path runs first credits DT; subsequent paths become no-ops.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders } from '../_shared/cors.ts'
import { checkRateLimit, rateLimitHeaders } from '../_shared/rate_limit.ts'

const jsonHeaders = { 'Content-Type': 'application/json' }
const DT_PURCHASE_ENABLED = (Deno.env.get('DT_PURCHASE_ENABLED') ?? '').toLowerCase() === 'true'

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: getCorsHeaders(req) })
  }

  const corsHeaders = getCorsHeaders(req)

  try {
    // --- Auth: extract user from JWT ---
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, ...jsonHeaders } }
      )
    }

    const supabaseAuth = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )
    const { data: { user }, error: authError } = await supabaseAuth.auth.getUser()
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired token' }),
        { status: 401, headers: { ...corsHeaders, ...jsonHeaders } }
      )
    }

    // Fix 2.6: Rate limit confirm attempts — prevents abuse of the confirm endpoint
    const supabaseRl = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    const rlResult = await checkRateLimit(supabaseRl, {
      key: `confirm:${user.id}`,
      limit: 10,
      windowSeconds: 3600,
    })
    if (!rlResult.allowed) {
      return new Response(
        JSON.stringify({ error: 'Too many requests', retryAfter: rlResult.retryAfterSeconds }),
        { status: 429, headers: { ...getCorsHeaders(req), 'Content-Type': 'application/json', ...rateLimitHeaders(rlResult) } }
      )
    }

    // --- Input: paymentKey, orderId, amount from request body ---
    const { paymentKey, orderId, amount } = await req.json()

    if (!paymentKey || !orderId || amount == null) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: paymentKey, orderId, amount' }),
        { status: 400, headers: { ...corsHeaders, ...jsonHeaders } }
      )
    }

    if (!DT_PURCHASE_ENABLED) {
      return new Response(
        JSON.stringify({
          error: 'Payments are disabled',
          errorCode: 'PAYMENTS_DISABLED',
        }),
        { status: 503, headers: { ...corsHeaders, ...jsonHeaders } }
      )
    }

    const tossSecretKey = Deno.env.get('TOSSPAYMENTS_SECRET_KEY') ?? ''
    if (!tossSecretKey) {
      console.error('[Confirm] TOSSPAYMENTS_SECRET_KEY not configured')
      return new Response(
        JSON.stringify({
          error: 'Payment provider not configured',
          errorCode: 'PAYMENT_PROVIDER_NOT_READY',
        }),
        { status: 503, headers: { ...corsHeaders, ...jsonHeaders } }
      )
    }

    // --- Service-role client for DB operations ---
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // --- Validate purchase (4 checks) ---
    const { data: purchase, error: purchaseError } = await supabase
      .from('dt_purchases')
      .select('*')
      .eq('id', orderId)
      .single()

    if (purchaseError || !purchase) {
      return new Response(
        JSON.stringify({ error: 'Purchase not found' }),
        { status: 404, headers: { ...corsHeaders, ...jsonHeaders } }
      )
    }

    // Check 1: user_id matches
    if (purchase.user_id !== user.id) {
      return new Response(
        JSON.stringify({ error: 'Purchase does not belong to this user' }),
        { status: 403, headers: { ...corsHeaders, ...jsonHeaders } }
      )
    }

    // Check 2: status must be pending
    if (purchase.status !== 'pending') {
      // Already processed (paid/failed/cancelled) — return success for idempotency
      return new Response(
        JSON.stringify({
          success: true,
          already_processed: true,
          status: purchase.status,
        }),
        { status: 200, headers: { ...corsHeaders, ...jsonHeaders } }
      )
    }

    // Check 3: amount matches price_krw
    if (Number(amount) !== purchase.price_krw) {
      console.error(`[Confirm] Amount mismatch: expected ${purchase.price_krw}, got ${amount}`)
      await supabase
        .from('dt_purchases')
        .update({ status: 'failed' })
        .eq('id', orderId)

      return new Response(
        JSON.stringify({ error: 'Amount mismatch' }),
        { status: 400, headers: { ...corsHeaders, ...jsonHeaders } }
      )
    }

    // --- Call TossPayments Confirm API ---
    const tossAuth = btoa(`${tossSecretKey}:`)
    const confirmRes = await fetch('https://api.tosspayments.com/v1/payments/confirm', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${tossAuth}`,
        'Content-Type': 'application/json',
        'Idempotency-Key': `confirm:${orderId}`,
      },
      body: JSON.stringify({ paymentKey, orderId, amount: Number(amount) }),
    })

    const confirmData = await confirmRes.json().catch(() => ({}))

    if (!confirmRes.ok) {
      console.error('[Confirm] Toss confirm failed:', confirmRes.status, confirmData)

      // Map Toss status to our CHECK constraint values
      // D3: no 'expired' in CHECK — use 'failed'
      await supabase
        .from('dt_purchases')
        .update({
          status: 'failed',
          payment_provider_transaction_id: paymentKey,
        })
        .eq('id', orderId)

      return new Response(
        JSON.stringify({
          error: 'Payment confirmation failed',
          detail: confirmData.message ?? 'Unknown PG error',
        }),
        { status: 502, headers: { ...corsHeaders, ...jsonHeaders } }
      )
    }

    // --- Map Toss status (D3) ---
    // DONE → 'paid', CANCELED → 'cancelled', ABORTED/EXPIRED → 'failed'
    const tossStatus = confirmData.status
    let mappedStatus: string

    if (tossStatus === 'DONE') {
      mappedStatus = 'paid'
    } else if (tossStatus === 'CANCELED') {
      mappedStatus = 'cancelled'
    } else {
      // ABORTED, EXPIRED, WAITING_FOR_DEPOSIT, etc. → 'failed'
      mappedStatus = 'failed'
    }

    if (mappedStatus !== 'paid') {
      // Not a successful payment — update status, no credit
      await supabase
        .from('dt_purchases')
        .update({
          status: mappedStatus,
          payment_provider_transaction_id: paymentKey,
        })
        .eq('id', orderId)

      return new Response(
        JSON.stringify({
          success: false,
          status: mappedStatus,
          message: `Payment status: ${tossStatus}`,
        }),
        { status: 200, headers: { ...corsHeaders, ...jsonHeaders } }
      )
    }

    // --- Credit DT atomically (internal idempotency key: toss:{orderId}) ---
    // Get or create wallet
    let wallet = null
    const { data: existingWallet } = await supabase
      .from('wallets')
      .select('*')
      .eq('user_id', purchase.user_id)
      .single()

    if (!existingWallet) {
      const { data: newWallet, error: createError } = await supabase
        .from('wallets')
        .insert({ user_id: purchase.user_id, balance_dt: 0 })
        .select()
        .single()

      if (createError) {
        console.error('[Confirm] Failed to create wallet:', createError)
        return new Response(
          JSON.stringify({ error: 'Failed to process payment' }),
          { status: 500, headers: { ...corsHeaders, ...jsonHeaders } }
        )
      }
      wallet = newWallet
    } else {
      wallet = existingWallet
    }

    const totalDt = purchase.dt_amount + (purchase.bonus_dt || 0)
    const internalIdempotencyKey = `toss:${orderId}`

    const { data: txResult, error: txError } = await supabase.rpc('process_payment_atomic', {
      p_order_id: orderId,
      p_transaction_id: paymentKey,
      p_wallet_id: wallet.id,
      p_user_id: purchase.user_id,
      p_total_dt: totalDt,
      p_dt_amount: purchase.dt_amount,
      p_bonus_dt: purchase.bonus_dt || 0,
      p_idempotency_key: internalIdempotencyKey,
    })

    if (txError) {
      // Already processed (idempotency) — treat as success
      if (txError.code === '23505' || txError.message?.includes('already_processed')) {
        console.log(`[Confirm] Already credited (idempotent): ${internalIdempotencyKey}`)
        return new Response(
          JSON.stringify({
            success: true,
            already_processed: true,
            purchaseId: orderId,
          }),
          { status: 200, headers: { ...corsHeaders, ...jsonHeaders } }
        )
      }

      console.error('[Confirm] Atomic transaction failed:', txError)
      return new Response(
        JSON.stringify({ error: 'Failed to credit DT' }),
        { status: 500, headers: { ...corsHeaders, ...jsonHeaders } }
      )
    }

    const newBalance = txResult?.new_balance ?? (wallet.balance_dt + totalDt)
    console.log(`[Confirm] Credited ${totalDt} DT to user ${purchase.user_id} (balance: ${newBalance})`)

    return new Response(
      JSON.stringify({
        success: true,
        purchaseId: orderId,
        creditedDt: totalDt,
        newBalance: newBalance,
      }),
      { status: 200, headers: { ...corsHeaders, ...jsonHeaders } }
    )
  } catch (error) {
    console.error('[Confirm] Unexpected error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
    )
  }
})
