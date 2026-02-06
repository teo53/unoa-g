# 07. 로드맵 페이징 (Roadmap & Phasing)

## 1. 전체 타임라인

```
┌─────────────────────────────────────────────────────────────────────┐
│ Phase 0: Security Critical (즉시, 1-2일)                            │
│ ├── 암호화 키 하드코딩 제거                                          │
│ ├── 감사로그 INSERT 정책 수정                                        │
│ └── 서비스 이용약관/개인정보처리방침 초안                             │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Phase 1: Launch Ready (1-2주)                                       │
│ ├── A: 채팅 기능 완성 (편집/삭제/신고/차단)                          │
│ ├── B: 빈상태/에러상태 표준화                                        │
│ ├── C: 결제 연동 완료                                               │
│ ├── D: 푸시 알림 구현                                               │
│ └── E: 어드민 MVP                                                   │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Phase 2: Post-Launch (런칭 후 1개월)                                │
│ ├── 고급 메시지 기능 (답장, 인용, 멘션)                              │
│ ├── 자동 모더레이션                                                 │
│ ├── 분석 대시보드 고도화                                            │
│ ├── CS 티켓 시스템                                                  │
│ └── 라이브 스트리밍 설계                                            │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Phase 3: Scale (런칭 후 3개월)                                      │
│ ├── 국제화 (i18n)                                                  │
│ ├── 성능 최적화                                                     │
│ ├── 라이브 스트리밍 MVP                                             │
│ └── 크리에이터 고급 도구                                            │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. Phase 0: Security Critical (즉시)

**목표**: 보안 취약점 해결 + 법적 필수 문서 준비

**기간**: 1-2일

### 작업 목록

| ID | 작업 | 담당 | 예상 시간 | 의존성 |
|----|------|------|----------|--------|
| P0-1 | 암호화 키 fallback 제거 | Backend | 2h | - |
| P0-2 | 감사로그 INSERT 정책 수정 | Backend | 1h | - |
| P0-3 | Service Role Key 사용처 감사 | Backend | 2h | - |
| P0-4 | 서비스 이용약관 초안 | Legal/PM | 4h | - |
| P0-5 | 개인정보처리방침 초안 | Legal/PM | 4h | - |
| P0-6 | 환불 정책 문서화 | PM | 2h | P0-4 |

### P0-1: 암호화 키 fallback 제거

**파일**: `supabase/migrations/011_encrypt_sensitive_data.sql`

```sql
-- AS-IS (현재)
CREATE OR REPLACE FUNCTION get_encryption_key()
RETURNS TEXT AS $$
  SELECT COALESCE(
    current_setting('app.encryption_key', true),
    'DEVELOPMENT_KEY_DO_NOT_USE_IN_PRODUCTION_32B!'
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- TO-BE (수정)
CREATE OR REPLACE FUNCTION get_encryption_key()
RETURNS TEXT AS $$
DECLARE
  key TEXT;
BEGIN
  key := current_setting('app.encryption_key', true);
  IF key IS NULL OR key = '' THEN
    RAISE EXCEPTION 'CRITICAL: app.encryption_key not configured. Set via: ALTER SYSTEM SET app.encryption_key = ''your-32-byte-key'';';
  END IF;
  RETURN key;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;
```

### P0-2: 감사로그 INSERT 정책 수정

**파일**: `supabase/migrations/014_admin_policies.sql`

```sql
-- AS-IS (현재)
CREATE POLICY "admin_audit_insert" ON admin_audit_log
  FOR INSERT WITH CHECK (true);

-- TO-BE (수정)
CREATE POLICY "admin_audit_insert" ON admin_audit_log
  FOR INSERT WITH CHECK (
    auth.jwt()->>'role' = 'service_role'
    OR auth.uid() IN (
      SELECT id FROM user_profiles WHERE role = 'admin'
    )
  );
```

---

## 3. Phase 1: Launch Ready (1-2주)

**목표**: MVP 런칭에 필요한 핵심 기능 완성

**기간**: 1-2주

### Phase 1-A: 채팅 기능 완성

| ID | 작업 | 담당 | 예상 시간 | 의존성 |
|----|------|------|----------|--------|
| P1-A1 | 메시지 편집 API | Backend | 4h | - |
| P1-A2 | 메시지 편집 UI | Flutter | 6h | P1-A1 |
| P1-A3 | 메시지 삭제 API | Backend | 3h | - |
| P1-A4 | 메시지 삭제 UI + "삭제됨" 표시 | Flutter | 4h | P1-A3 |
| P1-A5 | 신고 테이블/RLS 추가 | Backend | 4h | - |
| P1-A6 | 신고 다이얼로그 UI | Flutter | 4h | P1-A5 |
| P1-A7 | 차단 테이블/RLS 추가 | Backend | 3h | - |
| P1-A8 | 차단 기능 UI | Flutter | 4h | P1-A7 |
| P1-A9 | 차단 사용자 메시지 필터링 | Flutter | 4h | P1-A8 |

### Phase 1-B: 빈상태/에러상태 표준화

| ID | 작업 | 담당 | 예상 시간 | 의존성 |
|----|------|------|----------|--------|
| P1-B1 | EmptyState 위젯 생성 | Flutter | 3h | - |
| P1-B2 | LoadingState 위젯 생성 | Flutter | 2h | - |
| P1-B3 | 모든 스크린 상태 점검 및 적용 | Flutter | 8h | P1-B1, P1-B2 |

### Phase 1-C: 결제 연동 완료

| ID | 작업 | 담당 | 예상 시간 | 의존성 |
|----|------|------|----------|--------|
| P1-C1 | TossPayments 결제 생성 API 완성 | Backend | 6h | - |
| P1-C2 | 결제 실패 처리 로직 | Backend | 4h | P1-C1 |
| P1-C3 | 환불 API 구현 | Backend | 6h | P1-C1 |
| P1-C4 | Flutter 결제 플로우 연동 | Flutter | 6h | P1-C1 |
| P1-C5 | 결제 테스트 (sandbox) | QA | 4h | P1-C4 |

### Phase 1-D: 푸시 알림 구현

| ID | 작업 | 담당 | 예상 시간 | 의존성 |
|----|------|------|----------|--------|
| P1-D1 | FCM 서버 설정 | Backend | 3h | - |
| P1-D2 | FCM 토큰 저장 API | Backend | 2h | P1-D1 |
| P1-D3 | 알림 전송 Edge Function | Backend | 4h | P1-D1 |
| P1-D4 | Flutter FCM 연동 완료 | Flutter | 4h | P1-D2 |
| P1-D5 | 딥링크 라우팅 | Flutter | 4h | P1-D4 |

### Phase 1-E: 어드민 MVP

| ID | 작업 | 담당 | 예상 시간 | 의존성 |
|----|------|------|----------|--------|
| P1-E1 | 어드민 대시보드 UI | Web | 8h | - |
| P1-E2 | 캠페인 심사 큐 | Web | 8h | P1-E1 |
| P1-E3 | 신고 트리아지 UI | Web | 8h | P1-A5 |
| P1-E4 | 사용자 제재 UI | Web | 6h | P1-E1 |
| P1-E5 | 감사로그 조회 UI | Web | 4h | P0-2 |

---

## 4. Phase 2: Post-Launch (런칭 후 1개월)

**목표**: 운영 효율화 + 사용자 경험 개선

### 고급 메시지 기능

| ID | 작업 | 예상 시간 |
|----|------|----------|
| P2-M1 | 답장 (Reply) 기능 | 16h |
| P2-M2 | 인용 (Quote) 기능 | 12h |
| P2-M3 | 멘션 (@) 기능 | 16h |
| P2-M4 | 링크 프리뷰 | 12h |
| P2-M5 | 리액션 다중화 | 8h |

### 자동 모더레이션

| ID | 작업 | 예상 시간 |
|----|------|----------|
| P2-MOD1 | 욕설 필터 Edge Function | 8h |
| P2-MOD2 | 스팸 패턴 탐지 | 12h |
| P2-MOD3 | 이미지 검수 (AWS Rekognition) | 16h |
| P2-MOD4 | 자동 제재 트리거 | 8h |

### 분석 대시보드 고도화

| ID | 작업 | 예상 시간 |
|----|------|----------|
| P2-A1 | 실제 데이터 연동 (데모 → 프로덕션) | 12h |
| P2-A2 | ARPPU/리텐션 계산 | 8h |
| P2-A3 | 전환 퍼널 분석 | 12h |
| P2-A4 | 실시간 대시보드 | 16h |

### CS 시스템

| ID | 작업 | 예상 시간 |
|----|------|----------|
| P2-CS1 | 문의 티켓 시스템 | 16h |
| P2-CS2 | 답변 템플릿 | 4h |
| P2-CS3 | SLA 대시보드 | 8h |

---

## 5. Phase 3: Scale (런칭 후 3개월)

**목표**: 확장성 + 글로벌 준비

### 국제화 (i18n)

| ID | 작업 | 예상 시간 |
|----|------|----------|
| P3-i18n1 | ARB 파일 구조 설정 | 4h |
| P3-i18n2 | 한국어 문자열 추출 | 8h |
| P3-i18n3 | 영어 번역 | 외주 |
| P3-i18n4 | 일본어 번역 | 외주 |
| P3-i18n5 | 언어 선택 UI | 4h |

### 성능 최적화

| ID | 작업 | 예상 시간 |
|----|------|----------|
| P3-PERF1 | 오프라인 캐싱 (Hive) | 16h |
| P3-PERF2 | 이미지 최적화 (캐시/압축) | 8h |
| P3-PERF3 | 리스트 가상화 최적화 | 8h |
| P3-PERF4 | 번들 사이즈 최적화 (웹) | 8h |

### 라이브 스트리밍 MVP

| ID | 작업 | 예상 시간 |
|----|------|----------|
| P3-LIVE1 | 기술 검토 (IVS/Agora 비교) | 8h |
| P3-LIVE2 | 인프라 설계 | 16h |
| P3-LIVE3 | 스트리밍 SDK 통합 | 40h |
| P3-LIVE4 | 채팅 연동 | 16h |
| P3-LIVE5 | 녹화/VOD | 24h |

---

## 6. 의존성 그래프

```
Phase 0
├── P0-1 (암호화 키) ──────────────────────────────────┐
├── P0-2 (감사로그 정책) ──────────────────────────────┤
├── P0-3 (Service Role 감사) ─────────────────────────┤
├── P0-4 (이용약관) ──┬── P0-6 (환불정책)              │
└── P0-5 (개인정보)   │                               │
                      │                               │
Phase 1               ▼                               │
├── P1-A1 (편집 API) ──── P1-A2 (편집 UI)             │
├── P1-A3 (삭제 API) ──── P1-A4 (삭제 UI)             │
├── P1-A5 (신고 테이블) ── P1-A6 (신고 UI) ────────────┼── P1-E3 (신고 트리아지)
├── P1-A7 (차단 테이블) ── P1-A8 (차단 UI) ── P1-A9    │
├── P1-B1 (EmptyState) ───┬── P1-B3 (스크린 적용)      │
├── P1-B2 (LoadingState) ─┘                           │
├── P1-C1 (결제 API) ──┬── P1-C2 (실패 처리)          │
│                      ├── P1-C3 (환불)               │
│                      └── P1-C4 (Flutter) ── P1-C5   │
├── P1-D1 (FCM 설정) ── P1-D2 (토큰) ── P1-D4 (Flutter) ── P1-D5 (딥링크)
│                      └── P1-D3 (전송 함수)          │
└── P1-E1 (어드민 대시) ──┬── P1-E2 (심사 큐)         │
                          ├── P1-E4 (제재)            │
                          └── P1-E5 (감사로그) ◀──────┘
```

---

## 7. 리스크 및 완화

| 리스크 | 영향 | 확률 | 완화 방안 |
|--------|------|------|----------|
| 결제사 연동 지연 | 런칭 지연 | 중 | TossPayments 테스트 계정 조기 확보 |
| 앱스토어 심사 거절 | 런칭 지연 | 중 | 신고/차단 필수 구현, 정책 사전 검토 |
| 보안 취약점 추가 발견 | 긴급 패치 필요 | 저 | Phase 0에서 보안 감사 완료 |
| 법적 이슈 | 서비스 중단 가능 | 저 | 약관 법률 검토, DT 성격 확인 |
| 크리에이터 정산 세무 이슈 | 과태료 | 중 | 세무사 자문, 원천징수 시스템 구축 |

---

## 8. 런칭 체크리스트

### 기능

- [ ] 핵심 채팅 기능 완료 (편집/삭제/신고/차단)
- [ ] 결제 연동 완료 및 테스트 통과
- [ ] 푸시 알림 작동 확인
- [ ] 어드민 MVP 운영 가능 상태

### 보안

- [ ] 암호화 키 fallback 제거됨
- [ ] 감사로그 정책 수정됨
- [ ] RLS 전체 테이블 적용 확인
- [ ] 웹훅 서명검증 확인

### 법적

- [ ] 서비스 이용약관 게시
- [ ] 개인정보처리방침 게시
- [ ] 환불 정책 게시
- [ ] 앱스토어 정책 컴플라이언스 확인

### 운영

- [ ] 고객 문의 채널 준비
- [ ] 장애 대응 절차 문서화
- [ ] 모니터링 대시보드 설정
- [ ] 에러 알림 설정 (Sentry/Slack)

### QA

- [ ] 전체 기능 E2E 테스트
- [ ] 결제 플로우 테스트 (성공/실패/환불)
- [ ] 푸시 알림 테스트 (Android/iOS)
- [ ] 크로스 브라우저 테스트 (웹)
