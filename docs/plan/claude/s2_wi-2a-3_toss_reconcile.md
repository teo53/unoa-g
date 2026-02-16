# S2 WI-2A-3 — Payment reconcile scheduled job (P1)

Goal
- Close "window closed -> no webhook" gaps.
- Reconcile pending purchases after 45 minutes (30m window + 15m buffer).
- Repair DONE-but-not-credited safely (internal idempotency).

Hard requirements
- Target rows: dt_purchases where status='pending' AND created_at < now()-45m
- Query Toss by orderId:
  - GET /v1/payments/orders/{orderId}
- When status is DONE:
  - call process_payment_atomic with p_idempotency_key = `toss:{orderId}` (same as webhook/confirm)
- For failures/expiry:
  - update dt_purchases accordingly

Changes
1) NEW edge function: `supabase/functions/payment-reconcile/index.ts`
2) Schedule:
   - cron: every 30 minutes (configure same way as existing scheduled-dispatcher or via platform scheduler)
3) Batch limits:
   - max 50 rows per run
   - log each decision with (orderId, previousStatus, tossStatus, newStatus, action)

Official Payment.status mapping (D3 — dt_purchases CHECK 제약 준수)
- DONE -> process_payment_atomic('toss:{orderId}') ; dt_purchases='paid'
- CANCELED / PARTIAL_CANCELED -> dt_purchases='cancelled'
- ABORTED -> dt_purchases='failed'
- EXPIRED -> dt_purchases='failed' (CHECK에 'expired' 없음)
- READY / IN_PROGRESS -> if older than 45m => dt_purchases='failed'
- WAITING_FOR_DEPOSIT -> dt_purchases='failed' (CARD only이므로 비정상)
- GET fails (404 etc) -> dt_purchases='failed'

Scheduling (pg_cron + pg_net — Supabase 공식 패턴)
- NEW migration: `supabase/migrations/072_schedule_payment_reconcile.sql`
- pg_cron: `*/30 * * * *` (매 30분)
- pg_net: `net.http_post()` → Edge Function 호출
- service_role_key는 Vault 저장 권장

Verification
- pending stuck case is auto-terminated
- DONE-but-not-credited is repaired and still credits only once
- repeated reconcile runs are safe (idempotent)
- no rate_limit added to system job (or failMode:'open' if reused helper)

Commit
- `S2 WI-2A-3: add payment reconcile scheduled job`
