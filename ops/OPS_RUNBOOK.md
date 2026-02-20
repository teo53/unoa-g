# OPS RUNBOOK / 운영 런북

> 온콜 엔지니어를 위한 단일 진입점 문서.
> 장애 발생 시 이 파일을 열고 해당 섹션으로 이동.

---

## 0. 빠른 참조 (Quick Reference)

### "무엇이 깨졌나?" 의사결정 트리

```
결제/환불 실패          → §3-A (Payments)
로그인/세션 장애        → §3-B (Auth/Login)
메시지 미수신/미발송    → §3-C (Messaging)
이미지/미디어 업로드 실패 → §3-D (Storage)
관리자 패널 장애        → §3-E (Admin/Ops)
크론/예약 작업 미실행   → §3-F (Cron) → runbooks/cron.md
Edge Function 배포 실패 → runbooks/edge-functions.md
```

### 심각도 분류 (Severity)

→ 상세: [incident.md §2](runbooks/incident.md)

| 등급 | 기준 | 업데이트 주기 |
|------|------|:------------:|
| P0 | 전체 중단 / 결제 장애 / 데이터 유출 | 15분 |
| P1 | 핵심 기능 부분 장애 | 30분 |
| P2 | 비핵심 기능 장애 | 필요 시 |
| P3 | 사소한 이슈 | 다음 스프린트 |

### 온콜 역할 (Roles)

→ 상세: [incident.md §0](runbooks/incident.md)

| 역할 | 핵심 책임 |
|------|----------|
| **IC** (총괄) | 인시던트 소유, 의사결정 |
| **Ops** (조치) | 기술적 완화/롤백/복구 실행 |
| **Comms** (공지) | Slack 업데이트, 이해관계자/사용자 알림 |
| **Scribe** (기록) | 타임라인 기록, Notion 포스트모템 작성 |

---

## 1. 인시던트 공통 절차 (Common Incident Procedure)

### 7단계 절차

→ 전체 상세: [incident.md](runbooks/incident.md)

```
선언(Declare) → 분류(Classify) → 완화(Mitigate) → 소통(Communicate)
→ 근본 원인(Root Cause) → 방지(Prevent) → 종결(Close)
```

### 포스트모템 템플릿 (General Post-Mortem)

> 결제 전용 포스트모템은 → [payments.md §8](runbooks/payments.md)

```markdown
## Post-Mortem: [인시던트 제목] [SEV-P?]

**일시**: YYYY-MM-DD
**지속 시간**: N분
**심각도**: P0 / P1 / P2
**IC**: [이름]
**Scribe**: [이름]

### 영향 (Impact)
- 영향 사용자 수:
- 매출 영향:
- 데이터 영향:

### 타임라인 (Timeline)
| 시각 (KST) | 이벤트 |
|-----------|--------|
| HH:MM | 최초 감지 |
| HH:MM | IC 배정 |
| HH:MM | 근본 원인 파악 |
| HH:MM | 수정 배포 |
| HH:MM | 복구 확인 |

### 근본 원인 (Root Cause)
...

### 기여 요인 (Contributing Factors)
...

### 잘된 것 (What Went Well)
...

### 재발 방지 (Action Items)
| 조치 | 담당 | 기한 |
|------|------|------|
| | | |

### 링크
- Notion WI:
- Slack Thread:
- PR:
- Deploy:
```

---

## 2. 릴리즈 & 배포 (Release & Deployment)

### 참조 문서

| 문서 | 내용 |
|------|------|
| [RELEASE_CHECKLIST.md](../docs/RELEASE_CHECKLIST.md) | 배포 전 체크리스트 (코드 품질, 환경변수, 서명, 보안) |
| [LAUNCH_RC_FREEZE.md](../docs/LAUNCH_RC_FREEZE.md) | RC 프리즈 정책, 롤백 임계값, 24시간 모니터링 |
| [edge-functions.md](runbooks/edge-functions.md) | Edge Function 배포/롤백 절차 |
| [DEV_GATES.md](../docs/DEV_GATES.md) | 3레이어 게이트 (Hook → Script → CI) |

### 배포 순서 (Safe Deploy Order)

최소 위험을 위한 권장 순서:

```
1. 호환 코드 선배포: 새 코드가 기존+신규 스키마 모두 처리 가능하게
2. DB 마이그레이션 적용 (필요 시)  → runbooks/migrations.md
3. Edge Functions 배포 (변경 함수만) → runbooks/edge-functions.md
4. 웹 배포 (정적 빌드)
5. 모바일 릴리즈 (스토어 배포가 있는 경우)
```

> **핵심 원칙**: 각 단계에서 이전 단계와 호환되어야 함. 롤백 시 역순으로 진행.

### 브랜치 네이밍 규칙 (Branch Naming)

| 유형 | 패턴 | 예시 |
|------|------|------|
| 기능/작업 | `wi/<WI-ID>-<slug>` | `wi/WI-042-payment-retry` |
| 핫픽스 | `hotfix/<YYYY-MM-DD>-<slug>` | `hotfix/2026-02-20-webhook-fix` |

- `main` 직접 push 금지 (PR만 허용)
- 1 WI = 1 Slack thread = 1 PR (강제)

### 배포 후 관찰 (Post-Deploy — 30~60분)

- [ ] Sentry 신규 에러/급증 확인 (릴리즈 태그 기준)
- [ ] Supabase Logs에서 Edge Function 5xx/서명 실패/권한 오류 확인
- [ ] 스모크 테스트 실행 (→ §6)
- [ ] 결제/크론 관련: 대사/실패 로그 확인 (→ [payments.md](runbooks/payments.md), [cron.md](runbooks/cron.md))
- [ ] 이상 시 즉시 `#ops-incidents` 선언 (→ §1)

---

## 3. 도메인별 인시던트 런북 (Domain Incident Runbooks)

> 모든 도메인 공통 5단계: **감지 → 5분 트리아지 → 최소 완화 → 복구 → 종료 조건**

### 3-A. 결제 장애 (Payments)

→ 상세: [payments.md](runbooks/payments.md) (로깅 필드, 웹훅 검증, 에러 코드, 대사 SQL)

**감지**
- Sentry: `payment.*` 태그 에러 급증
- Supabase Logs: `payment-webhook` 서명 불일치/401/500 증가
- 대사 불일치: `payment-reconcile` 결과에서 mismatch/failed 증가

**5분 트리아지**
1. 파이프라인 어디가 끊겼는지 분리: Checkout → Confirm → Webhook → 원장 반영
2. 멱등성 키(`idempotency_key`/`webhook_id`) 충돌/중복 처리 여부 확인
3. 서명 불일치 시: 시크릿 키 불일치 의심 → 환경변수 즉시 확인

**최소 완화**
- 신규 결제 CTA 차단 (Feature flag / kill switch) → "일시 점검" 배너 표시
- Webhook 서명 실패 다발 시: 시크릿 헤더 검증 (→ [payments.md §2](runbooks/payments.md))

**복구**
- `payment-reconcile`로 "PG vs dt_purchases vs wallet_ledger" 재대사
- 환불/차지백은 `refund-process`로 감사로그 남기며 처리

**종료 조건**
- 신규 결제 성공률 정상 + webhook 실패율 정상 + ledger 반영 지연 없음 (30분 유지)

---

### 3-B. 인증/로그인 장애 (Auth/Login)

**감지**
- 로그인 화면 진입 후 무한 로딩 / 세션 획득 실패
- Sentry에서 auth 관련 에러 급증
- Supabase Logs에서 401 급증

**5분 트리아지**
1. 증상 분리: (1) 신규 로그인 실패 (2) 기존 세션 만료 후 재로그인 실패 (3) 권한(RLS)로 기능 접근 불가
2. Supabase Auth Dashboard → Users → Recent sign-ins 에러 패턴 확인
3. JWT 만료 설정 확인: Supabase → Auth → Settings → JWT Expiry
4. Rate limit 확인: Supabase → Auth → Rate Limits
5. Social auth 장애 시: OAuth 제공자 자격증명 확인 (Supabase → Auth → Providers)

**최소 완화**
- 긴급 공지: "로그인 점검 중, 재시도/업데이트 안내" (→ §1 소통 템플릿)
- 데모 모드를 임시 활성화하는 것은 **정책적으로 금지** (신뢰/권한/데이터 오염 리스크)

**복구**
- Supabase 프로젝트 설정/키 롤오버/환경변수 상태 확인
- anon key 유효성 테스트: `curl` 로 Supabase REST API 직접 호출

**종료 조건**
- 로그인 성공률 >= 95% (10분 연속 유지)

---

### 3-C. 메시지/리얼타임 장애 (Messaging)

**감지**
- 실시간 메시지 미수신 (Realtime)
- 예약 메시지 미발송 (cron/dispatcher)
- `message_delivery` 누락

**5분 트리아지**
1. **3단 분리**:
   - Realtime 연결 (채널 subscribe 상태)
   - DB insert/update 자체
   - `scheduled-dispatcher`가 pending→sent 전환 못함
2. Supabase Realtime Dashboard에서 연결 수/에러율 확인
3. 미발송 쿼리:
   ```sql
   SELECT COUNT(*) FROM messages
   WHERE scheduled_status = 'pending'
     AND scheduled_at < NOW();
   ```
4. RLS 정책이 팬 읽기를 차단하는지 확인

**최소 완화**
- 스케줄 발송만 장애: 스케줄 기능 임시 비활성 + 즉시 발송 안내
- `dispatcher` 401: Vault secret ↔ Edge secret 불일치 즉시 수정 (→ [cron.md](runbooks/cron.md))

**복구**
- `scheduled-dispatcher` 수동 트리거 (→ [cron.md §4](runbooks/cron.md))
- Realtime 연결 문제: Supabase Dashboard에서 Realtime restart

**종료 조건**
- 메시지 전달 지연 < 2초 (5분 연속 유지)

---

### 3-D. 스토리지 장애 (Storage)

**감지**
- 이미지/미디어 업로드 실패
- 미디어 로딩 실패 (403/404)
- Sentry: `storage_upload_failed` 이벤트

**5분 트리아지**
1. 증상 분리: (1) 업로드(put) 실패 (2) URL 생성 실패 (public/signed) (3) 권한(RLS/정책)으로 읽기 실패
2. Supabase Storage 버킷 권한 확인 (Dashboard → Storage → Policies)
3. `service_role` 키로 직접 업로드 테스트 (RLS vs 네트워크 격리)
4. 버킷 용량 한도 확인

**최소 완화**
- 임시 presigned URL 우회
- 공개 URL 노출 리스크 시: public 접근 제한 + signed URL 전환

**복구**
- Supabase Logs Explorer에서 Storage 관련 에러 추적
- CORS 설정 확인 (웹 업로드 실패 시)

**종료 조건**
- 업로드 성공률 >= 99% (5분 연속 유지)

---

### 3-E. 관리자/운영툴 장애 (Admin/Ops)

**감지**
- 배너/플래그/자산 업로드/퍼블리시 불가
- 감사로그 누락
- `ops-manage` Edge Function 에러

**5분 트리아지**
1. 관리자 로그인/권한 확인 (`user_profiles.role = 'admin'`)
2. `ops-manage` 함수 로그 확인 (Dashboard → Edge Functions → ops-manage)
3. `SUPABASE_SERVICE_ROLE_KEY` 환경변수 설정 확인
4. `rate_limits` 테이블에서 관리자 rate-limit 여부 확인

**최소 완화**
- "publish" 기능만 임시 차단 (읽기는 유지)
- 관리자 접근 복구: DB 직접 쿼리로 역할 확인/복원

**복구**
- `ops-manage` 로그 확인 + 문제 RPC/정책 롤백 (→ [migrations.md](runbooks/migrations.md))

**종료 조건**
- Admin 대시보드 접근 가능 + `ops-manage` HTTP 200 응답

---

### 3-F. 크론/스케줄 잡 장애 (Cron)

→ 전체 상세: [cron.md](runbooks/cron.md)

잡 레지스트리, 모니터링, 트리아지, 수동 트리거, 실패 모드 모두 해당 문서 참조.

---

## 4. 로깅·지표·알림 표준 (Logging / Metrics / Alerting)

### 4-A. 로그 레벨 표준

| 레벨 | 용도 | Sentry 연동 |
|------|------|:----------:|
| `DEBUG` | 개발/verbose만 (기본 OFF) | - |
| `INFO` | 정상 이벤트 기록 | - |
| `WARN` | 사용자 영향 가능 이벤트 | Sentry 메시지로 승격 |
| `ERROR` | 사용자 영향/데이터 위험/결제 실패/권한 위반 | **항상 Sentry capture** |

- Flutter: `AppLogger.debug/info/warning/error` (→ `lib/core/utils/app_logger.dart`)
- Edge Functions: `console.log/warn/error` → Supabase Function Logs

### 4-B. 공통 로그 필드 표준

모든 로그/이벤트에 "가능한 범위에서" 포함:

| 필드 | 타입 | 설명 | 예시 |
|------|------|------|------|
| `env` | string | 환경 | `production` / `staging` / `development` |
| `release` | string | 앱 버전 / git SHA | `2.1.0` |
| `platform` | string | 클라이언트 플랫폼 | `ios` / `android` / `web` / `edge` |
| `actor_id` | string | 요청자 ID (마스킹) | `user_abc...` |
| `session_id` | string | 세션 식별자 | `sess_xyz` |
| `request_id` | string | 요청 단위 추적 ID | `req_123` |
| `trace_id` | string | 프론트→백엔드 상관관계 | `trace_...` |
| `event` | string | 정규화된 이벤트명 | `payment.webhook.received` |
| `severity` | string | 로그 레벨 | `info` / `warn` / `error` |
| `domain` | string | 비즈니스 도메인 | `payment` / `auth` / `chat` / `storage` / `admin` |
| `entity_id` | string | 주 엔티티 ID (마스킹) | `order_...` / `msg_...` |

### 4-C. 결제/정산 전용 필드

→ 상세: [payments.md §1](runbooks/payments.md)

필수: `payer_id`, `amount`, `currency`, `provider`, `order_id`, `idempotency_key`, `status`, `timestamp`

### 4-D. 로그 저장 위치 (Sources of Truth)

| 레이어 | 주 저장소 | 보조 |
|--------|----------|------|
| Flutter/Web 프론트엔드 | Sentry (에러/성능) | 콘솔 (개발만) |
| Edge Functions | Supabase Function Logs | Sentry (에러) |
| DB 감사/운영 이력 | `ops_audit_log`, `admin_audit_log` 테이블 | - |
| 중앙 수집 (옵션) | Supabase Log Drains | 요금제 제한 |

### 4-E. 알림 임계값 (Alert Thresholds)

최소 5개 도메인에 각 1개 이상:

| 도메인 | 지표 | 경고 | 위험 (P0) | 소스 |
|--------|------|:----:|:--------:|------|
| 결제 | webhook 성공률 | < 98% | < 95% | `payment_webhook_logs` |
| 결제 | wallet_ledger 음수 잔액 | any | any | `wallet_ledger` |
| 인증 | 로그인 실패율 | > 5% | > 10% | Supabase Auth Dashboard |
| 메시지 | 예약 메시지 백로그 | > 50건 | > 200건 | `messages WHERE scheduled_status='pending'` |
| 메시지 | Realtime 지연 | > 2s | > 5s | Supabase Realtime |
| 인프라 | DB P95 응답 시간 | > 200ms | > 500ms | Supabase Dashboard |
| 인프라 | Edge Function 콜드 스타트 | > 3s | > 10s | Sentry |
| 크래시 | crash-free session rate | < 99.5% | < 99% | Sentry |

> 현재 Slack/Pager 자동 연동은 UNVERIFIED → Sentry/Supabase 대시보드 확인 + `#ops-incidents` 수동 선언으로 운영.

---

## 5. 코드 변경 규칙 (Code Change Rules)

### 브랜치 정책

- `main` 직접 push 금지 (PR만 허용)
- 브랜치 네이밍: [§2 참조](#브랜치-네이밍-규칙-branch-naming)

### PR 규칙

→ 상세: [PROCESS_GUIDE.md](workflow/PROCESS_GUIDE.md)

- **1 WI = 1 Slack thread = 1 PR** (강제)
- PR 템플릿 필수 항목 미기입 시 리뷰 불가 (→ [.github/pull_request_template.md](../.github/pull_request_template.md))
- 기능 추가 + 리팩토링 혼합 금지 (최소 변경 우선)

### 리뷰 기준

→ 상세: [DEV_GATES.md](../docs/DEV_GATES.md)

- CI 4잡 (Flutter/Android/Web/Security) green 필수
- Gate 산출물 체크 (또는 면제 사유) 없으면 머지 금지

### DB/보안 변경 추가 규칙

→ 상세: [migrations.md](runbooks/migrations.md)

- 마이그레이션은 런북 절차 (로컬 → 스테이징 → 프로덕션) 준수
- 파괴적 변경 (`DROP`/`ALTER TYPE`) 금지 — 롤백/백필 플랜 포함 시만 허용
- 시크릿/개인정보 키는 `.env` / Supabase secrets만 사용 (git 금지)

---

## 6. 스모크 테스트 SOP (Smoke Test)

### 테스트 항목

→ 전체 50개 항목: [FINAL_SMOKE_TEST.md](../docs/FINAL_SMOKE_TEST.md)

### 실행 원칙

- 모든 프로덕션 배포 직후 **10~15분 내** 수행 (배포자 책임)
- 실패 시: "원인 분석"보다 먼저 **롤백/킬스위치로 stop-the-bleed**

### 핵심 테스트 케이스 (Quick 7)

| # | 영역 | 확인 사항 | 증적 |
|---|------|----------|------|
| T1 | 인증 | 로그인 → 홈 진입, 로그아웃 후 보호 라우트 리다이렉트 | 스크린샷 |
| T2 | 결제 | `/wallet/charge` 패키지 로딩/선택 정상 | 스크린샷 + `dt_purchases` 쿼리 |
| T3 | 구독 | `/subscriptions` 로딩/에러가 빈상태로 위장되지 않는지 | 스크린샷 |
| T4 | 메시지 | 채팅 스레드 메시지 송수신 (Realtime) | 스크린샷 (2디바이스) |
| T5 | 프로필 | 공유 버튼 동작 (또는 비활성 정책 준수) | 스크린샷 |
| T6 | 펀딩 | 캠페인 목록 로딩 + 상세 진입 | 스크린샷 |
| T7 | 관리자 | `/admin/dashboard` 핵심 리스트/퍼블리시 확인 | 스크린샷 |

### 판단 기준

| 판정 | 조건 |
|------|------|
| **PASS** | 모든 핵심 테스트 성공, 에러 없음 |
| **CONDITIONAL PASS** | 비핵심(P2+) 이슈 1~2건, 즉시 수정 불필요 |
| **FAIL** | P0/P1 이슈 발견 → 즉시 롤백 + `#ops-incidents` 선언 |

### 증적 요구사항 (필수)

- 각 테스트 케이스별: 성공 스크린샷 1장
- 실패 시: 에러/로그 링크 (Sentry issue URL, Supabase log timestamp)
- PR 또는 Notion WI에 증적 첨부

---

## 7. 알려진 이슈 & 기술 부채 (Known Issues)

### Edge Function Sentry `setUser` 버그

- **위치**: `supabase/functions/_shared/sentry.ts`
- **증상**: `globalThis.__sentryUser`가 모듈 레벨 상태 → 동시 요청 시 사용자 컨텍스트 오염
- **영향**: Sentry 에러 리포트에서 User A의 에러가 User B로 표시될 수 있음
- **완화**: 동시 요청이 많은 Edge Function에서는 `setUser()` 호출 자제
- **해결**: `AsyncLocalStorage` 도입 필요 (코드 내 주석으로 명시됨)

### `payment-reconcile` 인증 패턴

- `Bearer service_role` 직접 비교 방식 → `cron_auth.ts`의 timing-safe 비교보다 약함
- 기능적으로는 동작하지만, `requireCronAuth()` 패턴으로 통일 권장

### 감사 문서

→ 전체 감사 보고서: [docs/audit/](../docs/audit/)
→ DB RLS 감사: [docs/DB_RLS_AUDIT.md](../docs/DB_RLS_AUDIT.md)

---

## 8. 문서 색인 (Document Index)

### 운영 런북 (ops/runbooks/)

| 파일 | 내용 |
|------|------|
| [incident.md](runbooks/incident.md) | 인시던트 7단계 절차 + 역할 매트릭스 |
| [payments.md](runbooks/payments.md) | 결제 로깅/웹훅/멱등성/에러코드/대사/SLA |
| [migrations.md](runbooks/migrations.md) | DB 마이그레이션 4단계 절차 + 위험 SQL |
| [cron.md](runbooks/cron.md) | 크론 잡 레지스트리/모니터링/트리아지/수동 트리거 |
| [edge-functions.md](runbooks/edge-functions.md) | Edge Function 배포/롤백/환경변수/장애 대응 |

### 워크플로우 (ops/workflow/)

| 파일 | 내용 |
|------|------|
| [PROCESS_GUIDE.md](workflow/PROCESS_GUIDE.md) | WI 워크플로우 + 역할/권한 + FAQ |
| [slack.md](workflow/slack.md) | Slack 10개 채널 + 운영 규칙 + 핀 메시지 |
| [notion.md](workflow/notion.md) | Notion 3개 DB + WI 스키마 + 템플릿 |
| [bootstrap.md](workflow/bootstrap.md) | 온보딩 + 스택 개요 + 블로커 처리 |

### 릴리즈/배포 (docs/)

| 파일 | 내용 |
|------|------|
| [RELEASE_CHECKLIST.md](../docs/RELEASE_CHECKLIST.md) | 프로덕션 릴리즈 체크리스트 |
| [LAUNCH_RC_FREEZE.md](../docs/LAUNCH_RC_FREEZE.md) | RC 프리즈 정책 + 롤백 임계값 |
| [FINAL_SMOKE_TEST.md](../docs/FINAL_SMOKE_TEST.md) | 30분 스모크 테스트 (50항목) |
| [DEV_GATES.md](../docs/DEV_GATES.md) | 개발 게이트 3레이어 |

### 규정/감사 (docs/)

| 파일 | 내용 |
|------|------|
| [DB_RLS_AUDIT.md](../docs/DB_RLS_AUDIT.md) | RLS 감사 (94/95 테이블 적용) |
| [SAFETY_BLOCK_RULES.md](../docs/SAFETY_BLOCK_RULES.md) | 신고/차단/숨기기 규칙 |
| [LEGAL_MARKETING_RULES.md](../docs/LEGAL_MARKETING_RULES.md) | 마케팅 동의/발송 규칙 |
| [STORE_PRIVACY_CHECKLIST.md](../docs/STORE_PRIVACY_CHECKLIST.md) | 스토어 개인정보 체크리스트 |

---

## 부록: VERIFIED / UNVERIFIED 운영 범위

### VERIFIED (코드로 확인)

- 모바일 앱 (Flutter): `lib/`, 라우팅 `lib/navigation/app_router.dart`
- 웹 (Next.js): `apps/web/`
- 백엔드 (Supabase): 마이그레이션 `supabase/migrations/`, Edge Functions `supabase/functions/`
- 관측성: Sentry (`lib/core/monitoring/sentry_service.dart`), AppLogger, Supabase Logs
- 결제/정산 Edge Functions + 런북 `ops/runbooks/payments.md`
- 메시징: Supabase Realtime + `scheduled-dispatcher` + `cron.md`
- 운영 툴: `ops-manage`, `apps/web/app/(admin)/admin/`, 감사로그 테이블

### UNVERIFIED (가능성만 확인)

- 웹 호스팅: Firebase Hosting 지원 가능 (실제 프로덕션 여부 미확인)
- 푸시 (FCM): `.env.example`에 옵션으로 존재 (실제 사용 여부 미확인)
- PG 선택: PortOne/TossPayments 옵션 존재 (실제 상용 선택 미확인)
- Slack/Pager 자동 알림 연동 (수동 선언으로 운영 중)
