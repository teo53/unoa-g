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

## 2. 환불 규칙

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ 환불 요청    │ ──▶ │ 멱등성 체크  │ ──▶ │ PG 환불 호출 │
│ (idempotent) │     │ (중복 방지)  │     │ (audit trail)│
└──────────────┘     └──────────────┘     └──────────────┘
```

- 멱등 엔드포인트: 동일 `idempotency_key`로 재요청 시 기존 결과 반환
- 이중 환불 방지: `status` 체크 후 처리
- 감사 추적: 모든 환불에 사유/처리자/시각 기록

## 3. 일일 정산 대사

- 매일 총액 비교: PG 정산 vs 내부 원장
- 미매칭 건 → `#ops-incidents` 보고
- 차지백 추적: 별도 테이블 관리

## 4. 고객 지원

- 참조 ID (order_id, purchase_id) 기반 조회
- 증빙 링크 제공 (영수증, 거래내역)
- SLA: P0 결제 장애 → 1시간 내 1차 응답
