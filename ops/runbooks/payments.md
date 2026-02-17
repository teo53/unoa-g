# Payments / Settlement Runbook

## 1. 필수 로깅 필드

모든 결제/정산 이벤트에 반드시 기록:

| 필드 | 설명 | 예시 |
|------|------|------|
| `payer_id` | 결제자 UUID | `user_abc123` |
| `amount` | 금액 | `5000` |
| `currency` | 통화 | `KRW` |
| `provider` | PG사 | `tosspayments` |
| `order_id` | 주문 ID | `dt_purchase_xyz` |
| `idempotency_key` | 멱등 키 | `uuid-v4` |
| `timestamp` | 시각 | ISO 8601 |
| `status` | 상태 | `pending` / `completed` / `failed` |

## 2. Webhook 서명 검증

### PortOne V2 / TossPayments HMAC-SHA256

```
수신: POST /payment-webhook
  Headers: x-portone-signature (HMAC-SHA256)
  Body: { paymentId, transactionId, status, ... }

검증 플로우:
1. TOSSPAYMENTS_SECRET_KEY로 HMAC-SHA256 계산
2. 서명 헤더 값과 비교
3. 불일치 → 403 응답 + Sentry 경고
4. 일치 → payment_webhook_logs INSERT + 처리

코드 참조: supabase/functions/payment-checkout/index.ts
```

### 서명 불일치 대응

- Sentry에 `payment.webhook.signature_mismatch` 태그 기록
- `#ops-payments` Slack 알림
- 해당 요청 IP/User-Agent 로깅 (위조 시도 추적)

## 3. 멱등성 키 처리

```
payment_webhook_logs 테이블:
  webhook_id VARCHAR UNIQUE  ← 멱등성 보장

처리 플로우:
1. webhook_id로 기존 레코드 조회
2. 이미 존재 → 기존 결과 반환 (재처리 안 함)
3. 미존재 → INSERT + 결제 처리 + wallet_ledger UPDATE
4. 실패 시 → status='failed', error_message 기록

코드 참조: supabase/functions/payment-webhook/
```

## 4. TossPayments 주요 에러 코드

| 에러 코드 | 설명 | 대응 |
|----------|------|------|
| `ALREADY_PROCESSED_PAYMENT` | 이미 처리된 결제 | 멱등 — 성공 응답 |
| `PROVIDER_ERROR` | PG 내부 오류 | 3회 재시도 후 수동 확인 |
| `REJECT_CARD_PAYMENT` | 카드 거절 | 사용자에게 다른 결제 수단 안내 |
| `INVALID_CARD_EXPIRATION` | 만료된 카드 | 사용자에게 카드 갱신 안내 |
| `EXCEED_MAX_DAILY_PAYMENT_COUNT` | 일일 한도 초과 | 사용자에게 다음날 재시도 안내 |
| `NOT_FOUND_PAYMENT` | 결제 정보 없음 | order_id 확인 후 재조회 |
| `UNAUTHORIZED_KEY` | 인증 실패 | 시크릿 키 설정 확인 |

## 5. 환불 규칙

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ 환불 요청    │ ──▶ │ 멱등성 체크  │ ──▶ │ PG 환불 호출 │
│ (idempotent) │     │ (중복 방지)  │     │ (audit trail)│
└──────────────┘     └──────────────┘     └──────────────┘
```

- 멱등 엔드포인트: 동일 `idempotency_key`로 재요청 시 기존 결과 반환
- 이중 환불 방지: `status` 체크 후 처리
- 감사 추적: 모든 환불에 사유/처리자/시각 기록
- 부분 환불: `refund-process` Edge Function에서 금액 검증

## 6. 일일 대사 체크리스트

### 자동 대사 (payment-reconcile Edge Function)

- [ ] `dt_purchases` 총액 vs PG 정산 총액 비교
- [ ] `wallet_ledger` 잔액 합계 vs 기대 잔액 비교
- [ ] `payment_webhook_logs`에서 status='failed' 건 확인
- [ ] 미매칭 건 → `#ops-incidents` 자동 보고

### 수동 확인 (매일 10:00 KST)

- [ ] Supabase Dashboard → `payment_webhook_logs` 최근 24시간
- [ ] 실패 건 중 수동 재처리 필요한 건 식별
- [ ] 차지백 건 확인 및 `chargeback_cases` 테이블 업데이트

### SQL 조회 예시

```sql
-- 최근 24시간 결제 요약
SELECT status, COUNT(*), SUM(amount_krw)
FROM dt_purchases
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY status;

-- 실패한 webhook 목록
SELECT webhook_id, order_id, error_message, created_at
FROM payment_webhook_logs
WHERE status = 'failed'
  AND created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

-- 원장 잔액 검증
SELECT user_id, SUM(amount) as balance
FROM wallet_ledger
GROUP BY user_id
HAVING SUM(amount) < 0;  -- 음수 잔액 = 이상
```

## 7. 인시던트 대응 템플릿

```markdown
## 결제 인시던트 보고

**시각**: YYYY-MM-DD HH:MM KST
**심각도**: P0 / P1 / P2
**영향 범위**: N명 사용자, N건 거래, N원 영향

### 증상
- [구체적 증상 기술]

### 타임라인
- HH:MM - 최초 감지 (Sentry / 모니터링 / 사용자 신고)
- HH:MM - 1차 대응 시작
- HH:MM - 근본 원인 파악
- HH:MM - 수정 배포
- HH:MM - 정상 확인

### 근본 원인 (RCA)
- [원인 분석]

### 수정 내용
- [적용한 수정]

### 재발 방지
- [ ] [조치 1]
- [ ] [조치 2]
```

## 8. 고객 지원

- 참조 ID (order_id, purchase_id) 기반 조회
- 증빙 링크 제공 (영수증, 거래내역)
- SLA: P0 결제 장애 → 1시간 내 1차 응답
- SLA: P1 결제 문의 → 4시간 내 1차 응답
- 환불 처리: 영업일 기준 3일 이내
