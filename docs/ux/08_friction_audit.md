# 08. Friction Audit

> UNO A -- 마찰 지점 감사 (Top 10)
> 최종 수정: 2026-02-08

---

## 마찰 지점 요약

| # | 증상 | 원인 | 해결 | 수정 파일 | PR |
|---|------|------|------|-----------|:---:|
| 1 | 첫 방문자가 탐색 불가 | `initialLocation: '/login'` | `'/'`로 변경 | `app_router.dart` | PR-02 |
| 2 | DM 전송 실패 시 "전송 실패" 토스트 | `userId == null` -> `return false` -> 제네릭 SnackBar | 로그인 바텀시트 | `chat_input_bar_v2.dart`, `auth_gate.dart` | PR-02 |
| 3 | 펀딩 결제 시 silent fail | `currentUser?.id` null -> 아무 반응 없음 | 결제 진입 전 auth gate | `funding_checkout_screen.dart` | PR-02 |
| 4 | 프로필에 가짜 유저정보 노출 | `MockData.currentUser` 무조건 사용 | 비로그인 시 게스트 뷰 | `my_profile_screen.dart` | PR-04 |
| 5 | spacing/radius 300+ 하드코딩 | 중앙화된 토큰 없음 | `AppSpacing`, `AppRadius` 추출 | `app_spacing.dart` | PR-01 |
| 6 | 이중 타이포그래피 시스템 | `AppTypography` (Noto Sans KR) 미사용 잔재 | 삭제 | `app_typography.dart` | PR-01 |
| 7 | 대시보드 9섹션 과밀 | Progressive Disclosure 미적용 | 비즈니스 섹션 접기/펼치기 | `creator_dashboard_screen.dart` | PR-05 |
| 8 | 토큰 시스템 미설명 | 답글 토큰 개념 사전 안내 없음 | 첫 채팅 진입 시 안내 바텀시트 | `chat_thread_screen_v2.dart` | PR-05 |
| 9 | 회원가입 14개 입력 한 페이지 | Progressive Disclosure 미적용 | 2단계 분리 | `register_screen.dart` | PR-05 |
| 10 | Bottom nav 배지 선택 시만 표시 | `if (showBadge && isSelected)` 로직 | `isSelected` 조건 제거 | `bottom_nav_bar.dart` | PR-03 |

---

## 상세 분석

### Friction #1: 첫 방문자 탐색 차단

**증상**: 앱 진입 즉시 `/login` 화면으로 이동. 아티스트 탐색, 홈 콘텐츠 열람 불가.

**원인**:
```dart
// app_router.dart
final appRouter = GoRouter(
  initialLocation: AppRoutes.login,  // '/login'
  // ...
);
```

**영향**: 가치를 경험하기 전에 로그인 요구 -> 이탈률 증가. Fromm/Bubble 등 경쟁 앱은 탐색 후 행동 시점에 가입 유도.

**해결**:
```dart
final appRouter = GoRouter(
  initialLocation: AppRoutes.home,  // '/'
  // ...
);
```

**관련 PR**: PR-02

---

### Friction #2: 메시지 전송 실패 시 제네릭 에러

**증상**: 비로그인 상태에서 메시지 전송 시도 -> "전송 실패" 토스트만 표시. 사용자는 왜 실패했는지 모름.

**원인**:
```dart
// chat_input_bar_v2.dart (의사코드)
if (userId == null) {
  return false;  // silent return
}
// 이후 제네릭 SnackBar
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('전송 실패')),
);
```

**해결**: `userId == null` 시 Auth Gate 바텀시트 표시. "로그인 후 메시지를 보낼 수 있습니다" 안내.

**관련 PR**: PR-02

---

### Friction #3: 펀딩 결제 Silent Fail

**증상**: 비로그인 상태에서 펀딩 결제 버튼 탭 -> 아무 반응 없음 (화면 변화 0).

**원인**:
```dart
// funding_checkout_screen.dart (의사코드)
final userId = currentUser?.id;
if (userId == null) return;  // 아무 피드백 없이 종료
```

**영향**: 사용자는 버튼이 고장났다고 판단. 최악의 UX 패턴 (silent fail).

**해결**: 결제 프로세스 진입 전 auth gate 체크. 비로그인 시 Auth Gate 바텀시트로 로그인 유도.

**관련 PR**: PR-02

---

### Friction #4: 프로필 가짜 유저정보

**증상**: 비로그인 상태에서 `/profile` 접근 시 `MockData.currentUser`의 이름, 잔액, 구독 정보가 표시됨.

**원인**: 인증 상태 확인 없이 `MockData.currentUser`를 무조건 사용.

**영향**: 사용자가 다른 사람의 정보를 자기 것으로 착각. 신뢰도 하락.

**해결**: 비로그인 시 게스트 뷰 표시 (로그인 유도 CTA + 기능 소개).

**관련 PR**: PR-04

---

### Friction #5: Spacing/Radius 하드코딩

**증상**: 앱 전체에서 `EdgeInsets.all(16)`, `BorderRadius.circular(12)` 등 300건 이상 하드코딩.

**원인**: 중앙화된 디자인 토큰 부재. 각 화면에서 개별적으로 값 지정.

**영향**: 디자인 일관성 저하, 변경 시 300+ 곳 수동 수정 필요.

**해결**: `AppSpacing` / `AppRadius` 토큰 클래스 추출 및 마이그레이션.

```dart
// Before
EdgeInsets.all(16)
BorderRadius.circular(12)

// After
EdgeInsets.all(AppSpacing.base)
AppRadius.baseBR
```

**관련 PR**: PR-01 (토큰 정의), PR-06 (마이그레이션)

---

### Friction #6: 이중 타이포그래피

**증상**: `AppTypography` 클래스가 Noto Sans KR 기반으로 존재하지만 실제 사용되지 않음. Pretendard가 `Theme.textTheme`으로 사용 중.

**원인**: 폰트 전환 시 `AppTypography` 미삭제.

**영향**: 개발자 혼란 (어떤 걸 써야 하지?), 코드 사이즈 불필요한 증가.

**해결**: `AppTypography` 클래스 파일 삭제. 모든 참조를 `Theme.of(context).textTheme`으로 통일.

**관련 PR**: PR-01

---

### Friction #7: 대시보드 9섹션 과밀

**증상**: `/creator/dashboard` 진입 시 9개 섹션이 동시에 펼쳐져 표시. 스크롤 길이가 과도.

**원인**: Progressive Disclosure 미적용. 모든 섹션이 기본 펼침 상태.

**영향**: 정보 과부하. 크리에이터가 핵심 지표를 빠르게 파악 불가.

**해결**: 핵심 섹션 (구독자, 수익) 기본 펼침 + 나머지 접기 상태. 탭으로 섹션 토글.

**관련 PR**: PR-05

---

### Friction #8: 토큰 시스템 미설명

**증상**: 팬이 첫 채팅 진입 시 답글 토큰 개념을 모름. "왜 3개밖에 못 보내지?" 혼란.

**원인**: 토큰 시스템에 대한 사전 안내 UI 부재.

**영향**: 토큰 소진 후 당혹감. CS 문의 증가. "버그인가?" 오해.

**해결**: 첫 채팅 진입 시 안내 바텀시트 표시:
- 토큰 개념 설명
- 브로드캐스트당 3개 충전
- 구독 티어별 토큰 수 안내

**관련 PR**: PR-05

---

### Friction #9: 회원가입 14개 입력 한 페이지

**증상**: `/register` 화면에 14개 입력 필드가 한 페이지에 나열. 스크롤 필요.

**원인**: Progressive Disclosure 미적용. 모든 정보를 한 번에 수집.

**영향**: 가입 이탈률 증가. "이렇게 많이 입력해야 해?" 거부감.

**해결**: 2단계 분리:
- Step 1: 필수 정보 (이메일, 비밀번호, 닉네임) -- 5개 이하
- Step 2: 선호도 (관심 장르, 좋아하는 아티스트) -- 선택적

**관련 PR**: PR-05

---

### Friction #10: Bottom Nav 배지 선택 시만 표시

**증상**: 새 메시지 배지가 해당 탭 선택 시에만 표시됨. 다른 탭에 있으면 안 보임.

**원인**:
```dart
// bottom_nav_bar.dart (의사코드)
if (showBadge && isSelected) {
  // 배지 표시
}
```

**영향**: 사용자가 새 메시지 도착을 인지 불가. 앱 재방문 동기 감소.

**해결**: `isSelected` 조건 제거. 배지는 항상 표시.

```dart
// 수정 후
if (showBadge) {
  // 배지 표시 (탭 선택 여부 무관)
}
```

**관련 PR**: PR-03

---

## 심각도 분류

| 심각도 | 마찰 # | 설명 |
|--------|--------|------|
| **Critical** | #1, #3 | 핵심 플로우 차단 또는 silent fail |
| **High** | #2, #4, #10 | 사용자 혼란 유발, 기능 오인 |
| **Medium** | #7, #8, #9 | 사용성 저하, 이탈 위험 |
| **Low** | #5, #6 | 개발 효율성, 코드 품질 |
