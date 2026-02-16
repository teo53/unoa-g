# S2 WI-2A-1 — Toss checkout (Create payment window)

Goal
- Replace mock checkout URL with TossPayments Create payment API (POST /v1/payments).
- Return `checkout.url` to client.

Hard requirements
- `method` must be enumerated value: use `CARD` (NOT '카드').
- Do NOT pre-attach query params to successUrl/failUrl.
  - Toss appends `paymentKey`, `orderId`, `amount` to successUrl.
- `orderId` must be 6~64 chars from [A-Za-z0-9_-].
- Use `Idempotency-Key` header:
  - `checkout:{purchase.id}` (valid for 15 days at Toss API layer)

Changes
1) MODIFY `supabase/functions/payment-checkout/index.ts`
2) Replace mock URL with:
   - POST https://api.tosspayments.com/v1/payments
   - Headers:
     - Authorization: Basic base64(secretKey + ':')
     - Content-Type: application/json
     - Idempotency-Key: `checkout:${purchase.id}`
   - Body:
     - method: 'CARD'
     - amount: pkg.priceKrw
     - currency: 'KRW'
     - orderId: purchase.id (ensure it matches constraints; otherwise map to a compliant ID)
     - orderName: pkg.name
     - successUrl: `${APP_BASE_URL}/payment/success` (confirm 트리거 지점 — 이 라우트가 paymentKey/orderId/amount 쿼리를 받아서 payment-confirm Edge Function 호출)
     - failUrl: `${APP_BASE_URL}/payment/fail`
     - appScheme: `<yourapp>://` (optional, if mobile ISP redirect needed)

Env vars
- TOSSPAYMENTS_SECRET_KEY
- APP_BASE_URL
- 환경변수 미설정 시(`TOSSPAYMENTS_SECRET_KEY` 빈값): Toss API 호출 스킵, dt_purchases.status='failed' 업데이트 + 에러 로그

Verification
- staging test key: checkout.url returned
- checkout.url opens Toss payment window
- failure path sets dt_purchases status='failed' as designed
- 환경변수 미설정 시 graceful failure 확인

Commit
- `S2 WI-2A-1: Toss checkout (create payment window)`
