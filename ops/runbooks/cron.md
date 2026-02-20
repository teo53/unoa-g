# Cron / Scheduled Job Runbook

## 1. 잡 레지스트리 (Job Registry)

| 함수 | 스케줄 | 인증 방식 | 타임아웃 | 설명 |
|------|--------|----------|---------|------|
| `scheduled-dispatcher` | 매 1분 | `X-Cron-Secret` (HMAC) | 30s | pending 메시지 발송 + typing_indicators 정리 |
| `payment-reconcile` | 매 30분 | `Bearer service_role` | 60s | 미확정 결제 PG 재조회 + 원장 반영 |
| `refresh-fallback-quotas` | 매일 0시 | `X-Cron-Secret` (HMAC) | 30s | 답글 토큰 일일 리셋 |

### 환경변수 의존성

| 함수 | 필수 환경변수 |
|------|-------------|
| `scheduled-dispatcher` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `CRON_SECRET` |
| `payment-reconcile` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `TOSSPAYMENTS_SECRET_KEY` |
| `refresh-fallback-quotas` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `CRON_SECRET` |

---

## 2. 모니터링 (Monitoring)

### 정상 동작 확인
- Supabase Dashboard → Edge Functions → 함수명 → Invocations 탭
- 성공: HTTP 200 + `{ "success": true }` 응답
- `scheduled-dispatcher`: `processed: 0` (대기 메시지 없음)이면 정상

### 실패 감지 시그널
- `scheduled-dispatcher`: 예약 메시지가 `scheduled_at` 시각 이후에도 발송되지 않음
- `payment-reconcile`: `dt_purchases`에 `status='pending'` + `created_at < NOW() - interval '2 hours'` 레코드 누적
- Edge Function Logs에서 401/500 반복

---

## 3. 실패 트리아지 (Failure Triage)

### 단계별 확인

1. **로그 확인**: Supabase Dashboard → Edge Functions → 함수명 → Logs
2. **인증 확인**: 401 응답 → 아래 "알려진 실패 모드" 참조
3. **DB 상태 확인**:
   ```sql
   -- scheduled-dispatcher: 미발송 대기 메시지
   SELECT COUNT(*), MIN(scheduled_at)
   FROM messages
   WHERE scheduled_status = 'pending'
     AND scheduled_at < NOW();

   -- payment-reconcile: 미확정 결제
   SELECT COUNT(*), MIN(created_at)
   FROM dt_purchases
   WHERE status = 'pending'
     AND created_at < NOW() - interval '45 minutes';
   ```
4. **pg_cron 상태 확인** (DB 직접):
   ```sql
   SELECT jobid, schedule, command, active
   FROM cron.job
   ORDER BY jobid;
   ```
5. **수동 트리거로 격리 테스트** (아래 §4 참조)

---

## 4. 수동 트리거 (Manual Trigger)

### scheduled-dispatcher
```bash
curl -i -X POST \
  https://<PROJECT_REF>.supabase.co/functions/v1/scheduled-dispatcher \
  -H "Content-Type: application/json" \
  -H "X-Cron-Secret: <CRON_SECRET>"
```

### payment-reconcile
```bash
curl -i -X POST \
  https://<PROJECT_REF>.supabase.co/functions/v1/payment-reconcile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>"
```

> 수동 트리거 시 멱등성이 보장되므로 중복 실행에 안전함.

---

## 5. 알려진 실패 모드 (Known Failure Modes)

| 증상 | 원인 | 대응 |
|------|------|------|
| 401 (scheduled-dispatcher) | `CRON_SECRET` 미설정 또는 불일치 | Supabase Dashboard → Edge Functions → Secrets에서 확인/재설정 |
| 200 but `skipped` (payment-reconcile) | `TOSSPAYMENTS_SECRET_KEY` 미설정 | 환경변수 설정 후 재배포 불필요 (다음 실행에서 자동 반영) |
| 500 + `Failed to fetch messages` | DB 연결 실패 또는 `messages` 테이블 스키마 변경 | 마이그레이션 상태 확인 |
| Invocations = 0 (장시간) | pg_cron 잡 비활성화 또는 pg_net 확장 미설치 | `cron.job` 테이블에서 `active` 확인 |
| 부분 처리 후 중단 | 함수 타임아웃 (30/60초 초과) | 배치 크기 축소 검토 (`BATCH_LIMIT`) |

---

## 6. 완화/복구 (Mitigation & Recovery)

- **예약 발송만 장애**: 예약 기능 임시 비활성 + 즉시 발송으로 안내
- **결제 대사 장애**: 수동 대사 실행 (§4 curl) + 일일 대사 체크리스트 (→ [payments.md](payments.md) §6)
- **전체 크론 중단**: pg_cron 활성 상태 확인 → `SELECT cron.schedule(...)` 재등록

### 종료 조건
- 크론 잡 정상 실행 확인 (Invocations 탭에서 200 응답 3회 연속)
- 미처리 백로그 해소 (pending 레코드 0건 또는 정상 범위)
