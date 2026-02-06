# UNO A 전체 감사 요약 (Executive Summary)

**감사 일자**: 2025-02-05
**감사 범위**: Flutter 앱 + Supabase 백엔드 + 설계/문서
**감사 수준**: Principal Product Engineer + Staff UX + Security/Compliance Lead

---

## 1. 프로젝트 개요

**UNO A**는 한국 아티스트-팬 메시징 플랫폼으로, Fromm/Bubble과 유사한 서비스입니다.
- **핵심 기능**: 브로드캐스트 DM, 토큰 기반 답장, DT(디지털 토큰) 화폐, 구독 티어, 펀딩/캠페인
- **기술 스택**: Flutter 3.0+, Riverpod, Supabase (PostgreSQL + RLS), Firebase, Material 3

---

## 2. 전체 구현 현황

| 영역 | 완성도 | 상태 |
|------|--------|------|
| **채팅 시스템** | 75% | ✅ 핵심 완료, 편집/삭제/신고/차단 UI 미구현 |
| **크리에이터 기능** | 85% | ✅ 대시보드/CRM/브로드캐스트 완료 |
| **팬 기능** | 80% | ✅ 구독/지갑/펀딩 완료 |
| **인증/보안** | 90% | ✅ OAuth/RLS 완료, 키관리 개선 필요 |
| **결제 통합** | 40% | ⚠️ UI만 완료, 백엔드 연동 미완 |
| **어드민/운영** | 10% | ❌ 거의 미구현 |
| **모더레이션** | 5% | ❌ 신고/차단/필터링 미구현 |

---

## 3. 🔴 즉시 조치 필요 (Phase 0 - Security Critical)

### 3.1 암호화 키 하드코딩 제거
- **위치**: `supabase/migrations/011_encrypt_sensitive_data.sql` (lines 50-58, 106-112)
- **문제**: 프로덕션 키 미설정시 개발용 하드코딩 키로 fallback
- **위험도**: CRITICAL
- **조치**: fallback 키 제거, 키 없으면 즉시 실패하도록 수정

### 3.2 감사로그 INSERT 정책 수정
- **위치**: `supabase/migrations/014_admin_policies.sql` (line 230)
- **문제**: `WITH CHECK (true)` - 누구나 가짜 감사로그 삽입 가능
- **위험도**: HIGH
- **조치**: `WITH CHECK (auth.jwt()->>'role' = 'service_role')` 로 변경

### 3.3 Service Role Key 노출 점검
- **상태**: ✅ 현재 안전 (NEXT_PUBLIC_에 없음)
- **주의**: `createAdminClient()` 사용처 제한 필요

---

## 4. 🟡 Phase 1 - 기능 완성 (런칭 전 필수)

### 4.1 채팅 기능 (편집/삭제/신고/차단)
| 기능 | 현재 상태 | 필요 작업 |
|------|----------|----------|
| 메시지 편집 | 모델만 있음 (isEdited, editHistory) | UI + API 구현 |
| 메시지 삭제 | 모델만 있음 (deletedAt) | UI + "삭제됨" 표시 |
| 신고 | ❌ 없음 | 신고 다이얼로그 + report 테이블 |
| 차단 | ❌ 없음 | 차단 API + 차단 사용자 필터링 |

### 4.2 빈상태/에러상태 표준화
- `EmptyState` 위젯 누락 (CLAUDE.md에 언급되나 실제 없음)
- `LoadingState` 위젯 누락
- 모든 스크린에 일관된 상태 적용 필요

### 4.3 결제 통합 (TossPayments)
- 웹훅 서명 검증: ✅ 구현됨
- Idempotency: ✅ 구현됨
- 실제 결제 API 연동: ❌ 미완성
- 테스트 모드 검증: ❌ 미완성

---

## 5. 🟢 Phase 2 - 운영/확장 (런칭 후)

### 5.1 어드민 패널
- 캠페인 승인/반려/수정요청
- 신고 트리아지
- 환불 처리
- 제재 관리
- 감사로그 조회

### 5.2 모더레이션 자동화
- 스팸/욕설 필터링 훅
- 이미지/영상 콘텐츠 검수
- 자동 제재 트리거

### 5.3 라이브 스트리밍 (설계만)
- IVS/Agora/WebRTC 옵션 분석
- 비용 변수 정의

---

## 6. 보안 감사 요약

| 항목 | 상태 | 비고 |
|------|------|------|
| RLS 활성화 | ✅ 100% (15/15 테이블) | 정책 검토 필요 |
| 민감정보 암호화 | ✅ AES-256-GCM | 키관리 개선 필요 |
| 웹훅 서명검증 | ✅ HMAC-SHA256 | 타이밍 안전 비교 적용 |
| Idempotency | ✅ 구현됨 | payment_webhook_logs 테이블 |
| 감사로그 | ⚠️ 부분 | INSERT 정책 수정 필요 |
| CSRF 보호 | ❌ 미구현 | 어드민 엔드포인트 추가 필요 |
| Rate Limiting | ❌ 미구현 | Edge Function에 추가 필요 |

---

## 7. 법무/세무 체크리스트 (자문 아님)

### 필수 고지/약관
- [ ] 서비스 이용약관
- [ ] 개인정보처리방침
- [ ] 청약철회/환불 정책
- [ ] 커뮤니티 가이드라인
- [ ] 수수료/정산 정책 고지

### DT(디지털 토큰) 리스크
- [ ] 선불식 결제수단 해당 여부 검토
- [ ] 양도불가 조건 명시
- [ ] 환불 규정 명확화
- [ ] 충전금 별도 관리 고려

---

## 8. 권장 로드맵

```
Phase 0 (즉시, 1-2일)
├── 보안 취약점 수정 (암호화 키, 감사로그 정책)
├── Service Role Key 사용처 감사
└── RLS 최소권한 검증

Phase 1 (1-2주)
├── 채팅 편집/삭제/신고/차단 구현
├── 빈상태/에러상태 위젯 표준화
├── 결제 API 통합 완료
└── 푸시 알림 구현

Phase 2 (런칭 후 1개월)
├── 어드민 패널 MVP
├── 모더레이션 자동화
├── 분석/대시보드 고도화
└── 국제화 (i18n) 준비
```

---

## 9. 파일 참조

| 문서 | 경로 |
|------|------|
| 아키텍처 현황 | docs/audit/01-architecture-as-is.md |
| 사용자 여정/UX 갭 | docs/audit/02-user-journeys-and-ux-gaps.md |
| 기능 갭 매트릭스 | docs/audit/03-feature-gap-matrix.md |
| 보안/결제 감사 | docs/audit/04-security-privacy-payments-audit.md |
| 운영/어드민 감사 | docs/audit/05-ops-admin-moderation-audit.md |
| 법무/세무 체크리스트 | docs/audit/06-legal-tax-checklist.md |
| 로드맵 페이징 | docs/audit/07-roadmap-phasing.md |
| PRD 변경사항 | docs/audit/08-prd-spec-deltas.md |
| 구현 계획 | docs/audit/09-implementation-plan.md |
| 미해결 질문 | docs/audit/10-open-questions.md |

---

## 10. 결론

UNO A는 **아키텍처적으로 탄탄한 기반** 위에 구축되었으며, 핵심 메시징/구독 기능은 **런칭 가능 수준**입니다.

**즉시 조치**가 필요한 보안 이슈 2건과 **런칭 전 필수** 기능 (채팅 편집/삭제, 결제 연동)을 완료하면 **MVP 출시 가능**합니다.

어드민/모더레이션 기능은 **런칭 후 빠르게 구축**해야 하며, 특히 신고/차단 기능 없이 운영하면 리스크가 있습니다.
