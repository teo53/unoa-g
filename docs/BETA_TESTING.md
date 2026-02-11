# UNO A Beta Testing Guide

## 베타 테스트 목표

- 코어 UI/UX 흐름 검증 (로그인 → 채팅 → 후원 → 설정)
- 다양한 디바이스/OS에서 레이아웃 깨짐 확인
- 크래시/ANR 수집 (Sentry 모니터링)
- 데모 모드 기반 기능 체험 (백엔드 미연동 상태)

## 베타 범위

| 포함 | 미포함 (다음 스프린트) |
|------|----------------------|
| 데모 로그인/회원가입 | 실결제 (DT 충전) |
| 채팅 UI (팬/크리에이터) | 실시간 Supabase 연동 |
| 구독/후원 UI | FCM 푸시 (서버 미연동) |
| 탐색/프로필/설정 | AI 답글 생성 |
| 다크 모드 | 실제 미디어 업로드 |

## 빌드 방법

### Android APK (내부 배포)

```bash
flutter build apk --release \
  --dart-define-from-file=config/beta.json
```

### Web (Firebase Hosting)

```bash
flutter build web --release \
  --dart-define-from-file=config/beta.json

firebase deploy --only hosting
```

### iOS (TestFlight)

```bash
flutter build ios --release \
  --dart-define-from-file=config/beta.json
```

Xcode에서 Archive → TestFlight 업로드

## 수동 테스트 시나리오

### 인증 (Auth)
1. **데모 로그인**: 앱 실행 → 데모 모드 진입 → 홈 화면 도달
2. **크리에이터 전환**: 프로필 → 크리에이터 모드 전환 → 대시보드 표시
3. **로그아웃**: 설정 → 로그아웃 → 로그인 화면 복귀

### 홈/탐색 (Home/Discover)
4. **홈 로딩**: 홈 화면 → 추천 아티스트/배너 정상 표시
5. **아티스트 탐색**: 탐색 탭 → 카테고리별 필터 → 아티스트 프로필 진입
6. **아티스트 프로필**: 프로필 → 구독 버튼 → 구독 UI 표시

### 채팅 (Chat)
7. **팬 채팅 목록**: 메시지 탭 → 구독 채널 목록 표시
8. **팬 채팅 스레드**: 채널 진입 → 메시지 로딩 → 1:1 형태 표시
9. **팬 답글**: 답글 입력 → 글자수 제한 표시 → 전송 → 토큰 차감
10. **크리에이터 채팅**: 크리에이터 모드 → 채팅 탭 → 단체톡 형태 표시
11. **미디어 첨부**: 이미지/동영상 첨부 버튼 → 갤러리 picker 실행

### 후원 (DT/Wallet)
12. **지갑 UI**: 프로필 → DT 잔액 표시 → 충전/사용 내역
13. **후원 메시지**: 채팅 → 후원 버튼 → 금액 선택 → 메시지 입력 → 전송 UI

### 프로필/설정 (Profile/Settings)
14. **프로필 조회**: 프로필 탭 → 닉네임/아바타/구독 정보 표시
15. **프로필 편집**: 프로필 편집 → 닉네임 변경 → 저장
16. **다크 모드**: 설정 → 다크 모드 토글 → 즉시 테마 변경
17. **알림 설정**: 설정 → 알림 항목 토글

### 크로스 플랫폼/접근성
18. **웹 프레임**: 웹 브라우저 → 폰 프레임 안에 UI 표시
19. **텍스트 크기**: 시스템 텍스트 크기 변경 → 레이아웃 유지 (clamp 1.0~1.3)
20. **스크린 리더**: TalkBack/VoiceOver → 주요 버튼 라벨 읽힘

## 디바이스 매트릭스

### Android
| 디바이스 | OS | 해상도 |
|---------|-----|--------|
| Galaxy S23 | Android 14 | 1080x2340 |
| Galaxy A54 | Android 13 | 1080x2400 |
| Pixel 7 | Android 14 | 1080x2400 |
| Galaxy Tab S9 | Android 14 | 1600x2560 |

### iOS
| 디바이스 | OS | 해상도 |
|---------|-----|--------|
| iPhone 15 Pro | iOS 17 | 1179x2556 |
| iPhone 13 mini | iOS 17 | 1080x2340 |
| iPhone SE 3 | iOS 17 | 750x1334 |
| iPad Pro 11" | iPadOS 17 | 2388x1668 |

### Web
| 브라우저 | 테스트 항목 |
|---------|-----------|
| Chrome (latest) | 기본 테스트 |
| Safari (latest) | iOS/macOS 호환성 |
| Firefox (latest) | 레이아웃 확인 |

## 버그 리포팅

### 필수 포함 정보
- **디바이스**: 모델명 + OS 버전
- **재현 경로**: 홈 → 채팅 → ... → 버그 발생
- **스크린샷/녹화**: 가능한 경우
- **Sentry 에러 코드**: `ERR-XXXXX-XXX` 형태 (에러 화면에 표시됨)

### 심각도 분류
| 심각도 | 설명 | 예시 |
|--------|------|------|
| Critical | 앱 크래시/데이터 손실 | 화면 전환 시 앱 강제 종료 |
| High | 핵심 기능 사용 불가 | 채팅 메시지 전송 안 됨 |
| Medium | 기능 일부 제한 | 다크 모드에서 텍스트 안 보임 |
| Low | UI 불편/미관 | 아이콘 정렬 미세 어긋남 |

## Sentry 모니터링

- **프로젝트**: UNO A Beta
- **환경 태그**: `beta` (ENV=beta로 빌드)
- **주요 확인 항목**:
  - Unhandled exceptions
  - ANR (Application Not Responding)
  - 느린 화면 전환 (> 500ms)
