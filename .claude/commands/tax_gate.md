# /tax_gate — 세무/회계 게이트

## 목표
거래흐름/증빙/수익인식/정산 로그 요구사항을 산출한다.

## 규칙
- **레포 수정 금지** — 읽기 전용
- `tax-accounting-gate` subagent를 호출하여 산출물 생성

## 점검 항목
1. 거래흐름 — 현금 → DT/포인트 → 사용 → 정산 단계별 증빙
2. 수익인식 — 선불/이연/환불/부분취소
3. 정산 로그 — 누가/언제/무엇을/왜
4. 세금계산/영수증 — 필요한 필드

## 참고
```
docs/legal/                                   → 세금/정산 가이드
tools/unoa-review-mcp/checklists/tax_kr.md    → 세무 체크리스트
supabase/migrations/046_settlement_tax.sql    → 정산 스키마
supabase/functions/payout-calculate/          → 정산 계산
```

## 출력 → Slack thread 게시 + Notion WI 기록
```
Blockers / Required / Nice-to-have / Evidence / Risk Rating(P0~P3)
```
