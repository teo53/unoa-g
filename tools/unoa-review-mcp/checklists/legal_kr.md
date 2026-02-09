# Legal/Compliance Issue-Spotting Checklist (KR) — UNO-A

> (주의) 본 체크는 "자문"이 아니라 스포팅. 최종은 변호사 검토 필요.

## Must-have disclosures/docs
- 이용약관/개인정보처리방침/환불정책/수수료 정책/정산 정책(크리에이터) 존재 여부
- 사업자 정보/통신판매/고객센터/청약철회(가능/불가) 고지 위치(앱/웹) 일관성
- 유료결제 전: 상품/서비스 내용, 가격, 자동갱신 여부, 환불 조건 고지

## Personal data & consent
- 필수/선택 동의 분리 + 기록(user_consents 등) + 버전 관리(동의 문서 변경 이력)
- 본인인증/신원확인 데이터 처리(보관기간/암호화/접근통제) 점검
- 미성년/법정대리 동의 필요 가능성(서비스 성격상 결제 포함)

## Payments / wallet / refunds
- "DT/크레딧"의 법적 성격(선불/포인트/유상서비스) 오인 방지 문구
- 결제취소/환불/부분환불/중복결제 처리의 기준과 프로세스가 UI/약관/백엔드 로직과 일치
- 결제/환불 이벤트 로그 보존(분쟁 대응)

## Crowdfunding-like flows
- 펀딩 성공/실패 조건, 환불 타이밍, 리워드 성격(디지털/서비스), 책임 주체(플랫폼 vs 크리에이터) 구분
- 크리에이터 검수/승인/반려(심사) 기준의 최소 고지
- 커뮤니티/채팅/콘텐츠 신고/제재(모더레이션) 정책 존재 및 집행 로그

## Risk hotspots (code)
- verify-identity, encrypt_sensitive_data, consent migrations, refund-process, payout functions: 정책 문서와 불일치 여부
