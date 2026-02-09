# Tax/Accounting Issue-Spotting Checklist (KR) — UNO-A

> (주의) 본 체크는 "자문"이 아니라 스포팅. 최종은 세무사/회계사 검토 필요.

## Revenue model clarity
- 플랫폼 매출(수수료) vs 크리에이터 정산금(패스스루) 구분이 장부/DB/정산서에서 명확한가
- DT/크레딧 판매: 선수금/매출 인식 시점(사용 시점/구매 시점) 정책 정의 여부
- 펀딩 수익: 성공 시점/환불 시점/취소 시점의 인식 로직 일관성

## VAT / receipts (high level)
- 과세/면세 가능성 분기 필요 여부(디지털 서비스/수수료/대행)
- 결제 영수증/세금계산서/현금영수증 등 발행 책임 주체(플랫폼 vs 크리에이터) 정의

## Refunds / chargebacks
- 환불/취소/차지백이 원거래와 매칭되고(atomicity), ledgers가 역분개 되는가
- 부분환불/쿠폰/DT 혼합결제 케이스에서 정산 오류 가능성

## Payouts
- 크리에이터 정산 기준(수수료/세액/보류/정산주기) 문서화 및 백엔드 계산 로직 일치
- 지급 계좌/정산내역 보관/변경 이력 관리
- 지급 실패/보류/분쟁 홀드 처리 정책

## Audit trail
- payment-webhook logs, payout statements, refund logs가 충분한 감사 추적성을 제공하는가(분쟁/세무 대응)
