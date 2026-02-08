# 04. Component Specification

> UNO A -- 컴포넌트 카탈로그 및 사용 가이드
> 최종 수정: 2026-02-08

---

## 1. Button 체계

### Decision Tree

```
행동이 파괴적인가?
  ├─ YES → DestructiveButton (danger 색상)
  └─ NO
      ├─ 화면의 주요 CTA인가?
      │   ├─ YES → PrimaryButton (primary600, 화면당 1개)
      │   └─ NO → SecondaryButton (outlined 또는 text)
      └─ 보조 행동인가?
          └─ YES → TextButton / OutlinedButton
```

### PrimaryButton

```dart
// 사용: 화면당 1개의 핵심 CTA
// 배경: primary600 (#DE332A) -- WCAG 4.5:1 준수
// 텍스트: onPrimary (#FFFFFF)
// Radius: AppRadius.base (12px)
// 높이: 48px 이상 (터치 타겟)

ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary600,
    foregroundColor: AppColors.onPrimary,
    minimumSize: const Size(double.infinity, 48),
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.baseBR,
    ),
  ),
  onPressed: () {},
  child: const Text('구독하기'),
)
```

### SecondaryButton

```dart
// 사용: PrimaryButton 외 추가 행동
// 스타일: outlined (테두리만) 또는 text only

OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary500,
    side: const BorderSide(color: AppColors.primary500),
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.baseBR,
    ),
  ),
  onPressed: () {},
  child: const Text('자세히 보기'),
)
```

### DestructiveButton

```dart
// 사용: 삭제, 차단, 구독 취소 등 되돌릴 수 없는 행동
// 배경: danger (#B42318)
// 반드시 확인 다이얼로그와 함께 사용

ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.danger,
    foregroundColor: Colors.white,
  ),
  onPressed: _showConfirmDialog,
  child: const Text('구독 취소'),
)
```

---

## 2. State 컴포넌트

### Decision Tree

```
데이터 로딩 중인가?
  ├─ YES
  │   ├─ 최초 로딩 → SkeletonLoader (레이아웃 유지)
  │   └─ 새로고침 → RefreshIndicator (기존 데이터 유지)
  └─ NO
      ├─ 에러 발생?
      │   ├─ YES → ErrorDisplay (이유 + 재시도)
      │   └─ NO
      │       ├─ 데이터 0건?
      │       │   ├─ YES → EmptyState (안내 + 행동 유도)
      │       │   └─ NO → 정상 콘텐츠 표시
      └─ 부분 로딩?
          └─ YES → LoadingState (인라인 스피너)
```

### SkeletonLoader

```dart
import '../../shared/widgets/skeleton_loader.dart';

// 기본 형태
SkeletonLoader(width: 100, height: 20)     // 사각형
SkeletonLoader.circle(size: 48)            // 원형 (아바타)
SkeletonLoader.text(width: 120)            // 텍스트 줄
SkeletonLoader.card(width: 200, height: 100) // 카드

// 프리셋 컴포넌트
SkeletonListTile(showAvatar: true, showSubtitle: true)
SkeletonCard(width: 200, height: 120)
SkeletonMessageBubble(isFromArtist: true)
```

**사용 시점**: 화면 최초 진입, 데이터 fetch 대기 중. 콘텐츠 레이아웃을 미리 보여주어 CLS(Cumulative Layout Shift) 방지.

### ErrorDisplay

```dart
import '../../shared/widgets/error_boundary.dart';

ErrorDisplay(
  error: error,           // 에러 객체 또는 메시지
  onRetry: () => _loadData(),  // 재시도 콜백 (필수)
)
```

**사용 시점**: API 호출 실패, 네트워크 오류, 데이터 파싱 실패 등.

### EmptyState

```dart
EmptyState(
  title: '아직 메시지가 없어요',
  message: '아티스트를 구독하면 메시지를 받을 수 있어요',
  icon: Icons.inbox_outlined,
  action: TextButton(
    onPressed: () => context.go('/discover'),
    child: const Text('아티스트 탐색하기'),
  ),
)
```

**사용 시점**: 데이터가 정상적으로 0건인 경우. "무엇을 할 수 있는지" 안내.

### LoadingState

```dart
LoadingState(message: '로딩 중...')
```

**사용 시점**: 인라인 로딩 (버튼 누른 후 처리 중 등). SkeletonLoader 대신 간단한 스피너가 적합할 때.

---

## 3. Header 체계

### Root Tab Header (커스텀, 56dp)

```
┌─────────────────────────────────┐
│ UNO A          [알림] [설정]    │  ← 56dp, 뒤로가기 없음
└─────────────────────────────────┘
```

- 하단 네비게이션의 **루트 탭** 화면에서 사용
- 뒤로가기 버튼 없음
- 앱 로고 또는 화면 제목 왼쪽 정렬
- 오른쪽에 알림/설정 등 액션 아이콘

### Sub-Screen AppBar (Material, 뒤로가기 포함)

```
┌─────────────────────────────────┐
│ ← 채팅                         │  ← 표준 AppBar, 자동 뒤로가기
└─────────────────────────────────┘
```

- 전체화면 (하단 네비게이션 없음)에서 사용
- `AppBar` + `leading: BackButton()`
- 라우트: `/chat/:artistId`, `/wallet`, `/settings` 등

### 판단 기준

| 조건 | Header 유형 |
|------|------------|
| Bottom nav에 포함된 탭 | Root Tab Header (56dp) |
| 전체화면 (nav 없음) | Sub-Screen AppBar |
| 모달/바텀시트 | 없음 또는 핸들바 |

---

## 4. Toast / Snackbar

### 표준 함수

```dart
// 에러 토스트 -- 빨간 배경, 흰 텍스트
showAppError(context, '네트워크 연결을 확인해 주세요');

// 성공 토스트 -- 초록 배경, 흰 텍스트
showAppSuccess(context, '메시지를 보냈습니다');
```

### 사용 규칙

| 상황 | 함수 | 메시지 패턴 |
|------|------|------------|
| API 호출 실패 | `showAppError` | "이유 + 다음 행동" |
| 전송 성공 | `showAppSuccess` | "결과 확인" |
| 유효성 검사 실패 | `showAppError` | "무엇이 잘못되었는지" |
| 토큰 부족 | `showAppError` | "이유 + 언제 충전되는지" |

### 하지 말 것

```dart
// 제네릭 에러 (원인 불명)
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('전송 실패')),
);

// 개발자용 에러 노출
showAppError(context, 'Error: userId is null');
```

---

## 5. Card 스타일

### 기본 카드

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.lgBR,        // 16px
    border: Border.all(color: AppColors.border),
    // elevation: 0 -- 그림자 없음, flat design
  ),
  padding: const EdgeInsets.all(AppSpacing.base), // 16px
  child: content,
)
```

### 카드 변형

| 유형 | 배경 | 테두리 | 용도 |
|------|------|--------|------|
| 기본 | `surface` | `border` | 일반 정보 카드 |
| 강조 | `primary100` | `primary500` | 프로모, CTA 배너 |
| 위험 | `danger100` | `danger` | 삭제 확인, 경고 |
| Premium | Gradient | 없음 | VIP 전용, DT 잔액 |

---

## 6. Bottom Sheet

### 표준 패턴

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(AppRadius.lg), // 16px
    ),
  ),
  builder: (context) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
    ),
    child: content,
  ),
);
```

### 용도별 바텀시트

| 용도 | 높이 | 내용 |
|------|------|------|
| Auth Gate | 자동 | 로그인/가입/데모 버튼 |
| 토큰 안내 | 자동 | 토큰 시스템 설명 + 잔여량 |
| 확인 다이얼로그 | 자동 | 파괴적 행동 확인 |
| 미디어 선택 | 50% | 사진/동영상 선택 |

---

## 7. 채팅 메시지 버블

### Fan 화면 (1:1 환상)

```
┌──────────────────────────────────┐
│         [아티스트 메시지]         │  ← 왼쪽, 아바타 표시
│                   [내 메시지]    │  ← 오른쪽, primary100 배경
│         [아티스트 메시지]         │
└──────────────────────────────────┘
```

### Creator 화면 (단체톡방)

```
┌──────────────────────────────────┐
│ [팬A/BASIC] 메시지               │  ← 왼쪽, 이름+티어 표시
│ [팬B/VIP] 메시지                 │  ← 왼쪽, VIP 배지
│                  [내 메시지 전체] │  ← 오른쪽, "전체" 라벨
│ [팬C/STANDARD] 메시지            │  ← 왼쪽
└──────────────────────────────────┘
```

### 메시지 버블 색상

| 발신자 | 정렬 | 배경색 | 텍스트색 |
|--------|------|--------|----------|
| 내 메시지 (Fan) | 오른쪽 | `primary100` | `text` |
| 아티스트 메시지 | 왼쪽 | `surface` | `text` |
| 팬 메시지 (Creator 뷰) | 왼쪽 | `surfaceAlt` | `text` |
| 후원 메시지 | 왼쪽 | `star` 틴트 | `text` |
