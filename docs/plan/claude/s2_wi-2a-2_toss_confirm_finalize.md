# S2 WI-2A-2 — Toss confirm + finalize (10-min window, two-layer idempotency)

Goal
- Implement confirm flow: call POST /v1/payments/confirm within 10 minutes after success redirect.
- Finalize credit exactly once even if webhook/confirm/reconcile all run.

Two-layer idempotency (non-negotiable)
1) External (Toss API POST)
   - confirm: `Idempotency-Key: confirm:{orderId}` (15 days)
2) Internal credit (DB)
   - ALWAYS call process_payment_atomic with:
     - p_idempotency_key = `toss:{orderId}`
   - webhook / confirm / reconcile must use the SAME internal key.

Changes
1) NEW edge function: `supabase/functions/payment-confirm/index.ts`
2) Function behavior:
   - Auth: getUser() from Authorization header
   - Input: read from query params appended by Toss:
     - paymentKey, orderId, amount
   - Validate dt_purchases (4 checks):
     - orderId matches
     - user_id matches
     - status == 'pending'
     - price_krw == amount
   - Call Toss confirm:
     - POST https://api.tosspayments.com/v1/payments/confirm
     - Headers include `Idempotency-Key: confirm:{orderId}`
     - Body { paymentKey, orderId, amount }
   - On success:
     - call `process_payment_atomic` with internal key `toss:{orderId}`
   - On failure/expiry:
     - set dt_purchases status to 'failed' (D3: no 'expired' in CHECK, use 'failed')
     - never credit wallet
   - Status mapping (D3): DONE→'paid', CANCELED→'cancelled', ABORTED/EXPIRED→'failed'

3) MODIFY `supabase/functions/payment-webhook/index.ts`
   - D5: L543 idempotencyKey: `purchase:${orderId}` → `toss:${orderId}` (내부 키 통일)

Verification
- confirm then webhook -> webhook path becomes duplicate/no-op
- webhook then confirm -> confirm becomes duplicate/no-op
- confirm called after 10 minutes -> failed, no credit
- dt_purchases status values strictly match CHECK constraint
- run all gates; ensure no secrets committed

Commit
- `S2 WI-2A-2: Toss confirm + finalize (idempotent credit)`
