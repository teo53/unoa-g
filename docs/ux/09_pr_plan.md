# 09. PR Plan

> UNO A -- UX 개선 PR 로드맵 (PR-01 ~ PR-06)
> 최종 수정: 2026-02-08

---

## 전체 일정 개요

```
PR-01  디자인 토큰 추출           ████░░░░░░░░░░░░░░  기반 작업
PR-02  로그인 강제 해제 + 행동 게이트  ░░░████░░░░░░░░░░  핵심 UX
PR-03  표준 컴포넌트 정리           ░░░░░░████░░░░░░░░  컴포넌트
PR-04  온보딩 라이트 + 게스트 경험    ░░░░░░░░░████░░░░░  첫인상
PR-05  핵심 플로우 마찰 감소         ░░░░░░░░░░░░████░░  사용성
PR-06  spacing 마이그레이션 + 최종 검증 ░░░░░░░░░░░░░░████  정리
```

**의존 관계**:
- PR-02는 PR-01 이후 (토큰 시스템 필요)
- PR-03은 PR-01 이후 (컴포넌트가 토큰 참조)
- PR-04는 PR-02 이후 (auth gate 필요)
- PR-05는 PR-03 이후 (표준 컴포넌트 사용)
- PR-06은 PR-01 이후 (토큰 정의 필요), 마지막 실행

---

## PR-01: 디자인 토큰 추출

### 목적

중앙화된 spacing/radius 토큰 생성 및 이중 타이포그래피 정리.
Friction #5, #6 해결.

### 변경 파일

| 파일 | 변경 내용 |
|------|----------|
| `lib/core/theme/app_spacing.dart` | `AppSpacing`, `AppRadius` 토큰 클래스 생성 |
| `lib/core/theme/app_typography.dart` | **삭제** (Noto Sans KR 잔재) |
| `lib/core/theme/app_colors.dart` | `AppColorsContext` extension 추가 (선택) |

### Acceptance Criteria

- [ ] `AppSpacing` 클래스에 xs(4), sm(8), md(12), base(16), lg(20), xl(24), xxl(32), xxxl(40) 토큰 정의
- [ ] `AppRadius` 클래스에 sm(4), md(8), base(12), lg(16), xl(20) 토큰 및 `BorderRadius` getter 정의
- [ ] `AppTypography` 파일 삭제 및 모든 import 제거
- [ ] `flutter analyze` 에러 0건 (기존 info/warning 제외)
- [ ] 기존 UI 렌더링 변화 없음 (시각적 regression 없음)

### Rollback

토큰 파일 삭제 + `AppTypography` 복원. 토큰을 참조하는 코드가 없으므로 단순 revert 가능.

---

## PR-02: 로그인 강제 해제 + 행동 게이트

### 목적

비로그인 사용자의 자유 탐색 허용 + 행동 시점 인증 게이트 도입.
Friction #1, #2, #3 해결.

### 변경 파일

| 파일 | 변경 내용 |
|------|----------|
| `lib/navigation/app_router.dart` | `initialLocation: '/'`로 변경, Open 라우트 정의 |
| `lib/shared/widgets/auth_gate.dart` | **신규** -- Auth Gate 바텀시트 컴포넌트 |
| `lib/features/chat/widgets/chat_input_bar_v2.dart` | 전송 시 auth gate 체크 추가 |
| `lib/features/funding/funding_checkout_screen.dart` | 결제 진입 시 auth gate 체크 추가 |

### Acceptance Criteria

- [ ] 첫 앱 진입 시 `/` (홈) 표시, `/login` 강제 이동 없음
- [ ] 비로그인 상태에서 `/discover`, `/funding`, `/artist/:id` 접근 가능
- [ ] 메시지 전송 시도 시 Auth Gate 바텀시트 표시 (로그인/가입/데모)
- [ ] 펀딩 결제 시도 시 Auth Gate 바텀시트 표시 (silent fail 제거)
- [ ] Auth Gate에서 "데모 체험" 선택 시 데모 모드 진입 후 원래 행동 가능

### Rollback

`initialLocation`을 `'/login'`으로 복원, `auth_gate.dart` 삭제, 기존 guard 로직 복원. 단순 revert.

---

## PR-03: 표준 컴포넌트 정리

### 목적

Bottom nav 배지 로직 수정, 접근성 강화, Toast 표준화.
Friction #10 해결.

### 변경 파일

| 파일 | 변경 내용 |
|------|----------|
| `lib/shared/widgets/bottom_nav_bar.dart` | 배지 표시 로직에서 `isSelected` 조건 제거 |
| `lib/shared/widgets/creator_bottom_nav_bar.dart` | 동일 배지 로직 수정 |
| `lib/shared/widgets/app_toast.dart` | **신규** -- `showAppError()`, `showAppSuccess()` 표준 함수 |
| 각 화면의 `SnackBar` 사용부 | `showAppError()` / `showAppSuccess()`로 교체 |

### Acceptance Criteria

- [ ] 미읽은 메시지 배지가 탭 비선택 상태에서도 표시
- [ ] `showAppError()` 함수: 빨간 배경, 흰 텍스트, 자동 dismiss
- [ ] `showAppSuccess()` 함수: 초록 배경, 흰 텍스트, 자동 dismiss
- [ ] 모든 인터랙티브 요소에 `semanticLabel` 설정 (주요 화면)
- [ ] 기존 제네릭 `SnackBar` 코드 3곳 이상 표준 함수로 교체

### Rollback

배지 로직 `isSelected` 조건 복원, `app_toast.dart` 삭제, 기존 `SnackBar` 코드 복원.

---

## PR-04: 온보딩 라이트 + 게스트 경험

### 목적

비로그인 프로필 게스트 뷰, 홈 가치 제안 배너 추가.
Friction #4 해결.

### 변경 파일

| 파일 | 변경 내용 |
|------|----------|
| `lib/features/profile/my_profile_screen.dart` | 비로그인 시 게스트 뷰 분기 |
| `lib/features/profile/widgets/guest_profile_view.dart` | **신규** -- 게스트 프로필 위젯 |
| `lib/features/home/home_screen.dart` | 비로그인 시 가치 제안 배너 추가 |
| `lib/features/home/widgets/value_prop_banner.dart` | **신규** -- 가치 제안 배너 위젯 |

### Acceptance Criteria

- [ ] 비로그인 상태 `/profile` 접근 시 게스트 뷰 표시 (MockData 미노출)
- [ ] 게스트 뷰에 "로그인하고 시작하기" CTA 버튼 포함
- [ ] 게스트 뷰에 UNO A 주요 기능 소개 (아티스트 채팅, 후원 등)
- [ ] 홈 화면에 비로그인 사용자 대상 가치 제안 배너 표시
- [ ] 배너 dismiss 가능, dismiss 후 세션 내 재표시 없음

### Rollback

프로필 화면 기존 코드 복원 (MockData 사용), 신규 위젯 파일 삭제. 홈 배너 코드 제거.

---

## PR-05: 핵심 플로우 마찰 감소

### 목적

토큰 설명 시트, 대시보드 Progressive Disclosure, 회원가입 2단계 분리.
Friction #7, #8, #9 해결.

### 변경 파일

| 파일 | 변경 내용 |
|------|----------|
| `lib/features/chat/chat_thread_screen_v2.dart` | 첫 진입 시 토큰 안내 바텀시트 호출 |
| `lib/features/chat/widgets/token_explanation_sheet.dart` | **신규** -- 토큰 설명 바텀시트 |
| `lib/features/creator/creator_dashboard_screen.dart` | 섹션 접기/펼치기 (`ExpansionTile` 등) 적용 |
| `lib/features/auth/screens/register_screen.dart` | 2단계 분리 (기본정보 + 선호도) |

### Acceptance Criteria

- [ ] 팬이 채팅 첫 진입 시 토큰 안내 바텀시트 표시 (재진입 시 미표시)
- [ ] 토큰 시트에 토큰 개념, 충전 주기, 티어별 차이 안내 포함
- [ ] 대시보드 비즈니스 섹션 기본 접힘 상태, 핵심 지표만 펼침
- [ ] 섹션 토글 시 부드러운 애니메이션
- [ ] 회원가입 Step 1 (필수 5개 이하) -> Step 2 (선택적 선호도)
- [ ] Step 1 완료 -> Step 2 자동 전환, 건너뛰기 가능

### Rollback

토큰 시트 호출 코드 제거, 대시보드 `ExpansionTile` -> 기존 레이아웃 복원, 회원가입 단일 페이지 복원.

---

## PR-06: Spacing 마이그레이션 + 최종 검증

### 목적

하드코딩된 spacing/radius 값을 `AppSpacing`/`AppRadius` 토큰으로 교체. 최종 통합 검증.

### 변경 파일

| 범위 | 대상 | 예상 수량 |
|------|------|----------|
| `lib/features/**/*.dart` | `EdgeInsets.all(16)` -> `AppSpacing.base` | ~150건 |
| `lib/features/**/*.dart` | `BorderRadius.circular(12)` -> `AppRadius.baseBR` | ~100건 |
| `lib/shared/widgets/*.dart` | 동일 교체 | ~50건 |

### Acceptance Criteria

- [ ] `EdgeInsets` 하드코딩 사용률 90% 이상 감소
- [ ] `BorderRadius.circular()` 하드코딩 사용률 90% 이상 감소
- [ ] 모든 교체 후 시각적 regression 없음 (pixel-level 동일)
- [ ] `flutter analyze` 에러 0건
- [ ] `flutter build web --release` 빌드 성공

### Rollback

Git revert. 토큰 참조를 하드코딩 값으로 되돌림. 시각적 변화 없으므로 안전.

---

## 위험 관리

| PR | 위험도 | 주요 위험 | 완화 전략 |
|----|--------|----------|----------|
| PR-01 | Low | `AppTypography` 삭제 시 미발견 참조 | `flutter analyze`로 사전 검증 |
| PR-02 | **High** | 기존 인증 플로우 깨짐 | 단계적 배포 + feature flag |
| PR-03 | Low | Toast 교체 시 누락 | `grep`으로 기존 SnackBar 전수 조사 |
| PR-04 | Medium | 게스트 뷰에서 데이터 접근 에러 | null 체크 강화 + ErrorDisplay |
| PR-05 | Medium | 대시보드 레이아웃 깨짐 | 크리에이터 계정 E2E 테스트 |
| PR-06 | Low | 시각적 미세 차이 | 토큰 값 = 기존 하드코딩 값 동일 |

---

## 성공 지표

| 지표 | 현재 (추정) | PR-06 완료 후 목표 |
|------|------------|-------------------|
| 신규 사용자 이탈률 (첫 화면) | ~60% (로그인 강제) | < 30% |
| 가입 완료율 | ~40% (14필드 한 페이지) | > 65% |
| Silent fail 발생 건수 | 2건 (메시지, 펀딩) | 0건 |
| Spacing 하드코딩 수 | 300+건 | < 30건 |
| 토큰 관련 CS 문의 | 높음 (추정) | 감소 |
