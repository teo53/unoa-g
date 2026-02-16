// Payment Reconcile Edge Function
// Scheduled every 30 minutes via pg_cron + pg_net (migration 072).
// Closes "window closed / no webhook" gaps by querying TossPayments
// for pending purchases older than 45 minutes.
//
// Internal idempotency key: toss:{orderId} — same as confirm and webhook,
// so whichever path credits first wins; others become no-ops.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const BATCH_LIMIT = 50

serve(async (req) => {
  try {
    // Auth: service_role via Authorization header (from pg_net schedule)
    const authHeader = req.headers.get('Authorization')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

    // Simple bearer check — only service_role should call this
    if (!authHeader?.includes(serviceRoleKey) && serviceRoleKey) {
      const token = authHeader?.replace('Bearer ', '') ?? ''
      if (token !== serviceRoleKey) {
        return new Response(
          JSON.stringify({ error: 'Unauthorized' }),
          { status: 401, headers: { 'Content-Type': 'application/json' } }
        )
      }
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      serviceRoleKey
    )

    const tossSecretKey = Deno.env.get('TOSSPAYMENTS_SECRET_KEY') ?? ''
    if (!tossSecretKey) {
      console.log('[Reconcile] TOSSPAYMENTS_SECRET_KEY not set, skipping')
      return new Response(
        JSON.stringify({ success: true, message: 'PG not configured, skipped', processed: 0 }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Find pending purchases older than 45 minutes
    const cutoff = new Date(Date.now() - 45 * 60 * 1000).toISOString()

    const { data: stalePurchases, error: queryError } = await supabase
      .from('dt_purchases')
      .select('id, user_id, dt_amount, bonus_dt, price_krw')
      .eq('status', 'pending')
      .lt('created_at', cutoff)
      .order('created_at', { ascending: true })
      .limit(BATCH_LIMIT)

    if (queryError) {
      console.error('[Reconcile] Query error:', queryError)
      return new Response(
        JSON.stringify({ error: 'Failed to query pending purchases' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (!stalePurchases || stalePurchases.length === 0) {
      return new Response(
        JSON.stringify({ success: true, message: 'No stale purchases', processed: 0 }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[Reconcile] Processing ${stalePurchases.length} stale purchases`)

    const tossAuth = btoa(`${tossSecretKey}:`)
    const results: Array<{ orderId: string; tossStatus: string; newStatus: string; action: string }> = []

    for (const purchase of stalePurchases) {
      const orderId = purchase.id

      try {
        // Query Toss for payment status
        const tossRes = await fetch(
          `https://api.tosspayments.com/v1/payments/orders/${orderId}`,
          {
            method: 'GET',
            headers: {
              'Authorization': `Basic ${tossAuth}`,
            },
          }
        )

        if (!tossRes.ok) {
          // Toss doesn't know about this order → mark failed
          console.log(`[Reconcile] Toss GET failed for ${orderId}: ${tossRes.status}`)
          await supabase
            .from('dt_purchases')
            .update({ status: 'failed' })
            .eq('id', orderId)

          results.push({ orderId, tossStatus: `HTTP_${tossRes.status}`, newStatus: 'failed', action: 'marked_failed' })
          continue
        }

        const tossData = await tossRes.json()
        const tossStatus = tossData.status as string

        // D3 status mapping (dt_purchases CHECK constraint)
        if (tossStatus === 'DONE') {
          // Credit DT atomically
          const paymentKey = tossData.paymentKey

          // Get or create wallet
          let wallet = null
          const { data: existingWallet } = await supabase
            .from('wallets')
            .select('*')
            .eq('user_id', purchase.user_id)
            .single()

          if (!existingWallet) {
            const { data: newWallet, error: createErr } = await supabase
              .from('wallets')
              .insert({ user_id: purchase.user_id, balance_dt: 0 })
              .select()
              .single()

            if (createErr) {
              console.error(`[Reconcile] Wallet create failed for ${orderId}:`, createErr)
              results.push({ orderId, tossStatus, newStatus: 'error', action: 'wallet_create_failed' })
              continue
            }
            wallet = newWallet
          } else {
            wallet = existingWallet
          }

          const totalDt = purchase.dt_amount + (purchase.bonus_dt || 0)
          const internalKey = `toss:${orderId}`

          const { error: txError } = await supabase.rpc('process_payment_atomic', {
            p_order_id: orderId,
            p_transaction_id: paymentKey,
            p_wallet_id: wallet.id,
            p_user_id: purchase.user_id,
            p_total_dt: totalDt,
            p_dt_amount: purchase.dt_amount,
            p_bonus_dt: purchase.bonus_dt || 0,
            p_idempotency_key: internalKey,
          })

          if (txError) {
            if (txError.code === '23505' || txError.message?.includes('already_processed')) {
              console.log(`[Reconcile] Already credited: ${internalKey}`)
              results.push({ orderId, tossStatus, newStatus: 'paid', action: 'already_credited' })
            } else {
              console.error(`[Reconcile] Atomic tx failed for ${orderId}:`, txError)
              results.push({ orderId, tossStatus, newStatus: 'error', action: 'tx_failed' })
            }
          } else {
            console.log(`[Reconcile] Credited ${totalDt} DT for ${orderId}`)
            results.push({ orderId, tossStatus, newStatus: 'paid', action: 'credited' })
          }

        } else if (tossStatus === 'CANCELED' || tossStatus === 'PARTIAL_CANCELED') {
          await supabase
            .from('dt_purchases')
            .update({ status: 'cancelled' })
            .eq('id', orderId)
          results.push({ orderId, tossStatus, newStatus: 'cancelled', action: 'marked_cancelled' })

        } else if (tossStatus === 'ABORTED' || tossStatus === 'EXPIRED') {
          // D3: no 'expired' in CHECK — use 'failed'
          await supabase
            .from('dt_purchases')
            .update({ status: 'failed' })
            .eq('id', orderId)
          results.push({ orderId, tossStatus, newStatus: 'failed', action: 'marked_failed' })

        } else {
          // READY, IN_PROGRESS, WAITING_FOR_DEPOSIT — stale after 45m → failed
          await supabase
            .from('dt_purchases')
            .update({ status: 'failed' })
            .eq('id', orderId)
          results.push({ orderId, tossStatus, newStatus: 'failed', action: 'stale_timeout' })
        }

      } catch (err) {
        console.error(`[Reconcile] Error processing ${orderId}:`, err)
        results.push({ orderId, tossStatus: 'ERROR', newStatus: 'error', action: 'exception' })
      }
    }

    console.log(`[Reconcile] Done: ${results.length} processed`, JSON.stringify(results))

    return new Response(
      JSON.stringify({ success: true, processed: results.length, results }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('[Reconcile] Unexpected error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
