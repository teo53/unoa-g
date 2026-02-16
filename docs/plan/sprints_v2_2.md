# UNOA Production Hardening Plan v2.3 (using v2.2 file package)

## Context
- GPT-5.2 코드 리뷰에서 P0/P1 이슈 10건 식별 → 코드 검증 후 6건 CONFIRMED, 1건 PARTIAL, 3건 FALSE POSITIVE.
- 사용자/코드 대조 검증 완료. 프롬프트 vs 실제 코드 불일치 2건 발견 → 반영:
  1) reactions RPC 파라미터: p_reaction_type 아님, p_emoji (028: toggle_message_reaction)
  2) pin vs highlight 분리: pin_message(is_pinned/pinned_at) vs highlight(is_highlighted/highlighted_at)
  3) quota: migration 025가 refresh_reply_quotas() 이미 수정 → 070은 process_quota_refresh_job/reset_daily_quotas만 패치

---

## Global Invariants (v2.3)
1) 이미 적용된 migration 파일은 절대 수정하지 않는다 → 신규 patch migration만 추가
2) service_role은 RLS bypass → "service_role-only 정책" 금지, own-row only 사용
3) TossPayments confirm은 success redirect 후 10분 이내 서버 호출 필수 (webhook 보조)
4) Toss successUrl/failUrl에는 쿼리 사전 부착 금지 (Toss가 paymentKey/orderId/amount append)
5) Web/TS 코드는 flutter analyze가 아닌 npm build/lint/type-check로 검증
6) SECURITY DEFINER 함수에는 SET search_path = public 필수
7) 금전 RPC는 auth.uid() 내부 추출 (from_user_id 파라미터 금지)
8) idempotency_key는 REQUIRED + DB에서 UNIQUE 강제
9) rate_limit 기본 fail-closed (에러 시 차단), system endpoint만 fail-open 선택 가능
10) 1 WI = 1 PR = 1 Notion Work Item
11) API 키/비밀정보는 클라이언트/커밋 포함 절대 금지
12) webhook + confirm + reconcile 3곳 도달해도 credit 정확히 1회
    - 외부(Toss API) Idempotency-Key(15일): checkout:{purchase.id}, confirm:{orderId}
    - 내부 credit 멱등키: process_payment_atomic.p_idempotency_key = toss:{orderId} (3곳 공통)
+ donation idempotency_key:
    - UI 액션(버튼 탭) 단위로 1회 생성, 실패 시 유지(재시도 동일 키), 성공/최종 실패 확정 시 소비

## v2.3 DELTA (소스코드 검증 후 수정 5건)

### D1. process_payment_atomic 파라미터명
- 실제 시그니처 (010:12-20): p_order_id UUID (NOT p_purchase_id)
- p_order_id는 dt_purchases.id (UUID PK)를 받는다

### D2. dt_purchases 컬럼 매핑
- dt_purchases.id (UUID PK) → process_payment_atomic의 p_order_id로 전달
- dt_purchases.payment_provider_order_id (TEXT) → Toss orderId 저장/조회용
- orderId = purchase.id (UUID 36자) → Toss 6~64 제약 만족

### D3. dt_purchases status CHECK 매핑
- CHECK 제약 (006:105-112): 'pending', 'paid', 'cancelled', 'refunded', 'partial_refund', 'failed'
- 'done', 'expired', 'canceled'는 CHECK에 없으므로 사용 금지
- Toss DONE → 'paid', CANCELED → 'cancelled', ABORTED/EXPIRED → 'failed'

### D4. Edge Function에서 supabaseAdmin 사용 필수
- process_payment_atomic은 service_role에만 GRANT (010:112)
- payment-confirm, payment-reconcile 모두 supabaseAdmin 클라이언트로 RPC 호출

### D5. WI-2A-2 스코프 확장: webhook 멱등키 변경 포함
- webhook idempotencyKey: `purchase:${orderId}` → `toss:${orderId}`

---

## Definition of Done (WI당 7개)
1) DB 변경 시: supabase db reset 클린 부팅 성공
2) 보안/RLS 변경 시: 악성 케이스 3종 테스트 (타 user_id write, 타 tenant 접근, 재전송 중복)
3) 원장/결제/후원 WI: idempotency 2회 호출 → 2번째 no-op, 실패 시 부분 기록 0
4) 롤백 플랜: 기능 플래그 또는 SQL down 등 최소 "차단" 가능
5) 관측성: 서버/앱 로그에 결과코드 + 원인 남김
6) 문서: MEMORY.md 또는 runbook에 운영자 확인 사항 추가
7) 플랫폼별 검증 게이트 전체 통과

---

## Verification Gates (PR 공통)
Flutter
- flutter analyze
- flutter test

Web (Next.js) — Web 변경 시
- cd apps/web && npm run build
- cd apps/web && npm run lint
- cd apps/web && npm run type-check

Repo / Supabase / Security
- mcp__repo_doctor__run_all
- mcp__supabase_guard__prepush_report (migration lint + RLS audit)
- mcp__security_guard__precommit_gate (secrets scan)

---

# Sprint 0: Preflight (DB Reset + Runtime Smoke)
Goal: Sprint 1 진입 조건 판정

Run:
- supabase start
- supabase db reset
- psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/preflight_db_smoke.sql

Decision:
- WARNING 0건 → Sprint 1 정상 진행
- remaining_replies/period_* 참조 WARNING → WI-1C를 Sprint 1 첫 번째로 수행
- db reset 자체 실패 → 해당 migration 패치 우선

---

# Sprint 1: Security + Data Integrity (병렬)

## WI-1A: message_delivery RLS own-row 강화 (068)
- NEW: supabase/migrations/068_fix_message_delivery_rls.sql
- 취약 정책 제거 + 3개 정책 재생성 (TO authenticated 명시) + pg_policies assert
- upsert 경로(INSERT ... ON CONFLICT)는 SELECT 정책 검사도 필요 → SELECT own-row 유지
- Commit: fix(security): restrict message_delivery to own rows [WI-1A]

## WI-1B: Donation atomic RPC + idempotency (069)
- NEW: supabase/migrations/069_donation_atomic_rpc.sql
- MODIFY: lib/providers/wallet_provider.dart
- process_donation_atomic: auth.uid() 내부 추출 (규칙 #7) + SELECT FOR UPDATE + 원자 처리
- _pendingDonationKey: UI 액션 단위 멱등키
- Commit: fix(payments): atomic donation RPC with idempotency key [WI-1B]

## WI-1C: Quota PATCH (070) — scope reduced
- NEW: supabase/migrations/070_fix_quota_refresh_columns.sql
- refresh_reply_quotas()는 025에서 이미 수정됨 → 070에서는 아래 2개만 패치:
  - process_quota_refresh_job()
  - reset_daily_quotas()
- remaining_replies/period_* → tokens_available/tokens_used로 교정
- Commit: fix(quota): patch async quota functions to tokens_* [WI-1C]

## WI-1D: rate_limit fail-closed (shared)
- MODIFY: supabase/functions/_shared/rate_limit.ts
- failMode 옵션 추가 (default closed)
- DB 에러 시 allowed:false (429)
- Commit: fix(security): rate limiter fail-closed default + failMode option [WI-1D]

---

# Sprint 2: Payments — TossPayments (순차)

## WI-2A-1: Toss checkout (payment window)
- MODIFY: supabase/functions/payment-checkout/index.ts
- mock URL 제거 → POST /v1/payments
- method: 'CARD', orderId: purchase.id (UUID), Idempotency-Key: checkout:{purchase.id}
- successUrl: ${APP_BASE_URL}/payment/success (confirm 트리거 지점)
- 환경변수 미설정 시: Toss API 스킵 + status='failed' + 에러 로그
- Commit: feat(payments): integrate TossPayments checkout session [WI-2A-1]

## WI-2A-2: Toss confirm + finalize (+ webhook 내부 키 통일)
- NEW: supabase/functions/payment-confirm/index.ts
- MODIFY: supabase/functions/payment-webhook/index.ts (L543: purchase: → toss:)
- 외부 confirm Idempotency-Key: confirm:{orderId}
- 내부 credit 멱등키: toss:{orderId} (webhook/confirm/reconcile 공통)
- supabaseAdmin (service_role) 사용 [D4]
- 상태 매핑 [D3]: DONE→paid, CANCELED→cancelled, ABORTED/EXPIRED→failed
- Commit: feat(payments): add payment-confirm Edge Function (idempotent credit) [WI-2A-2]

## WI-2A-3: Payment reconcile (P1)
- NEW: supabase/functions/payment-reconcile/index.ts
- NEW: supabase/migrations/072_schedule_payment_reconcile.sql (pg_cron + pg_net)
- cron: 매 30분, pending + 45분 초과, max 50/batch
- GET /v1/payments/orders/{orderId}
- 내부 멱등키: toss:{orderId}
- 스케줄: pg_cron + net.http_post (Supabase 공식 패턴)
- Commit: feat(payments): add payment reconcile scheduled function [WI-2A-3]

## WI-2B: Flutter 결제 플로우 연결
- MODIFY: lib/features/wallet/dt_charge_screen.dart
- Demo: 기존 2초 delay 유지
- Prod: checkout → url_launcher → status polling → UI 반영
- Commit: feat(payments): connect Flutter DT charge to TossPayments [WI-2B]

---

# Sprint 3: Feature Wiring (병렬)

## WI-3A: Reactions via RPC + Highlight via NEW RPC
- Reactions: toggle_message_reaction(p_message_id, p_emoji) — 028에 이미 존재
- Highlight: set_message_highlight (신규 071) — is_highlighted/highlighted_at
- Pin: pin_message (007에 이미 존재) — 별개 기능으로 유지
- MODIFY: lib/providers/chat_provider.dart

## WI-3B: Agency web pages → Edge Function
- NEW: apps/web/lib/agency/agency-client.ts
- MODIFY: 12개 agency pages (mock → callAgencyManage())

---

# Sprint 4: Observability

## WI-4A: Firebase Analytics 활성화
- MODIFY: lib/services/analytics_service.dart
- Dev/Demo no-op, Prod only 전송

---

## Dependency Graph
```text
Sprint 0: supabase start → db reset → smoke ─── Sprint 1 진입

Sprint 1 (병렬):
  WI-1A (068 RLS)
  WI-1B (069 Donation RPC + wallet_provider)
  WI-1C (070 Quota patch)
  WI-1D (rate_limit.ts)

Sprint 2 (순차):
  WI-2A-1 → WI-2A-2 → WI-2A-3 → WI-2B

Sprint 3 (병렬, Sprint 1 이후):
  WI-3A (Reactions/Highlight + chat_provider)
  WI-3B (Agency web pages)

Sprint 4 (독립):
  WI-4A (Analytics)
```

## P2 백로그 (Sprint 5+)
| 항목 | 파일 |
|---|---|
| FCM 실구현 | lib/services/fcm_service.dart |
| ai-reply-suggest 프롬프트 인젝션 | supabase/functions/ai-reply-suggest/index.ts |
| firebase.json CSP | firebase.json |
| 통합 테스트 placeholder 교체 | test/integration/payment_flow_test.dart |
