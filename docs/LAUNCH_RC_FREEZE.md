# UNO A — Release Candidate Freeze (RC 동결)

> **문서 버전**: 1.0
> **생성일**: 2026-02-18
> **RC 기준 커밋**: `d974876` (main 브랜치)

---

## 1. RC 동결 정의

RC(Release Candidate) 동결 이후에는 **P0 수정만** 허용된다.
P1 이하 변경은 feature flag 뒤에 배치하거나 다음 릴리스로 연기한다.

### 허용 변경 기준

| 우선도 | 허용 여부 | 예시 |
|--------|----------|------|
| **P0** (크래시/데이터 손실/보안) | ✅ 즉시 | DB 크래시, RLS 누출, 결제 데이터 손실 |
| **P1** (기능 결함) | ⚠️ feature flag 뒤로 | UI 깨짐, 비핵심 기능 오류 |
| **P2** (개선) | ❌ 다음 릴리스 | UX 개선, 성능 최적화 |
| **P3** (희망사항) | ❌ 다음 릴리스 | 새 기능, 디자인 변경 |

---

## 2. 배포 대상

| 플랫폼 | 배포 방법 | 대상 |
|--------|----------|------|
| **Web** | Firebase Hosting | `unoa-app-demo.web.app` |
| **Android** | Google Play Store (Internal → Open) | APK / AAB |
| **iOS** | App Store Connect (TestFlight → 제출) | IPA |

---

## 3. 롤백 기준

아래 **하나라도** 해당되면 즉시 롤백:

| 항목 | 기준 | 롤백 방법 |
|------|------|----------|
| **크래시율** | ≥ 1% (Sentry) | `firebase hosting:rollback` / Play Console 이전 빌드 |
| **결제 데이터 손실** | webhook 실패율 > 5% 또는 원장 불일치 | Edge Function 이전 버전 배포 |
| **RLS 권한 누출** | 비인가 데이터 접근 확인 | 마이그레이션 롤백 + RLS 정책 복구 |
| **인증 장애** | 로그인 실패율 > 10% | Supabase Auth 설정 확인 + 롤백 |

### 롤백 명령어

```bash
# Web (Firebase)
firebase hosting:rollback

# Android
# Play Console → Release Management → 이전 빌드 활성화

# iOS
# App Store Connect → TestFlight → 이전 빌드 활성화

# Supabase Edge Functions
supabase functions deploy <function-name> --version <previous-version>

# Database (마이그레이션 롤백)
# 주의: 데이터 손실 위험. 반드시 백업 후 진행
```

---

## 4. 24시간 모니터링 체크리스트

출시 후 24시간 동안 아래 항목을 **2시간 간격**으로 확인:

### 에러 모니터링 (Sentry)
- [ ] 새 에러 이슈 0건 확인
- [ ] 크래시-프리 세션 비율 ≥ 99%
- [ ] P0 에러 발생 시 즉시 Slack `#ops-incidents` 알림

### 결제 (Webhook)
- [ ] `payment_webhook_logs` 성공률 ≥ 95%
- [ ] `wallet_ledger` 잔액 정합성 확인
- [ ] `dt_purchases` 미완료 건 추적

### 인증 / 채팅
- [ ] 로그인 성공률 ≥ 95% (Supabase Auth 대시보드)
- [ ] 실시간 채팅 지연 < 2초 (Supabase Realtime)
- [ ] FCM 푸시 전송 성공률 확인

### 인프라
- [ ] Supabase DB 응답 시간 < 200ms (P95)
- [ ] Edge Function 콜드 스타트 < 3초
- [ ] Firebase Hosting CDN 응답 < 500ms

---

## 5. 비상 연락

| 역할 | 담당 | 채널 |
|------|------|------|
| **온콜 엔지니어** | TBD | Slack `#ops-incidents` |
| **결제 담당** | TBD | Slack `#ops-payments` |
| **인프라 담당** | TBD | Slack `#ops-infra` |

---

## 6. RC 이후 P0 수정 절차

1. `#ops-incidents` 스레드에 이슈 보고
2. 근본 원인 분석 (RCA) 작성
3. hotfix 브랜치 생성 (`hotfix/p0-<description>`)
4. 코드 리뷰 (최소 1명)
5. `flutter analyze` + `flutter test` 통과
6. main 머지 후 즉시 배포
7. 배포 후 15분 모니터링
8. Notion WI에 RCA + 수정 내용 기록
