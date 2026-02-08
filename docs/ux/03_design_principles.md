# 03. Design Principles

> UNO A -- 디자인 원칙 및 토큰 시스템
> 최종 수정: 2026-02-08

---

## 1. Color Tokens

### Primary Ramp (Brand)

| Token | HEX | 용도 | 비고 |
|-------|-----|------|------|
| `primary100` | `#FFE6E4` | 프로모 칩 배경, 하이라이트 | 제한적 사용 |
| `primary500` | `#FF3B30` | Active 상태 (탭, 인디케이터) | Key Color |
| `primary600` | `#DE332A` | **Filled CTA 배경** | WCAG 4.5:1 준수 |
| `primary700` | `#C92D25` | Pressed/active 강조 상태 | |
| `onPrimary` | `#FFFFFF` | Primary 배경 위 텍스트 | |

### Semantic Colors

| Token | HEX | 용도 | 주의사항 |
|-------|-----|------|----------|
| `danger` | `#B42318` | 삭제, 차단, 구독 취소 | **절대** 긍정 행동에 사용 금지 |
| `danger100` | `#FEE2E2` | Danger 배경 틴트 | |
| `success` | `#16A34A` | 성공 상태, 완료 표시 | |
| `success100` | `#DCFCE7` | Success 배경 틴트 | |
| `warning` | `#D97706` | 경고, 주의 필요 | |
| `warning100` | `#FEF3C7` | Warning 배경 틴트 | |

### Foundation (Neutral)

| Token | HEX | 용도 |
|-------|-----|------|
| `background` | `#F8F8F8` | 메인 화면 배경 |
| `surface` | `#FFFFFF` | 카드, 시트 배경 |
| `surfaceAlt` | `#F3F4F6` | 입력 필드, 보조 카드 |
| `border` | `#E5E7EB` | 구분선, 카드 테두리 |
| `text` | `#111827` | 본문 텍스트 |
| `textMuted` | `#6B7280` | 보조 텍스트 |
| `iconMuted` | `#9CA3AF` | 비활성 아이콘 |

### Special

| Token | HEX | 용도 |
|-------|-----|------|
| `online` | `#22C55E` | 온라인 상태 표시 |
| `verified` | `#3B82F6` | 인증 배지 |
| `star` | `#FBBF24` | 즐겨찾기, 별점 |
| `vip` | `#8B5CF6` | VIP 티어 배지 |
| `standard` | `#3B82F6` | STANDARD 티어 배지 |

### Gradient

| 이름 | 구성 | 용도 |
|------|------|------|
| `primaryGradient` | `#DE332A` -> `#FF6B6B` | CTA 버튼, 배너 |
| `premiumGradient` | `#DE332A` -> `#FF8E53` | VIP 카드, DT 잔액 |
| `subtleGradient` | `#FF6B6B` -> `#FF8E8E` | Featured 배너 |
| `privateCardGradient` | `#E8B5FF` -> `#FF8FAB` | 프라이빗 카드 |

### 사용 규칙

```
CTA 버튼 배경    -> primary600 (WCAG 준수)
활성 탭/인디케이터 -> primary500
위험 행동 (삭제)  -> danger
성공 피드백       -> success
경고 표시         -> warning

절대 하지 말 것:
  danger 색상으로 "구독하기" 버튼 만들기
  primary100을 넓은 영역 배경으로 사용
```

---

## 2. Typography

### 서체: Pretendard (단일 시스템)

- **한국어 최적화** 서체
- `web/index.html`에서 Dynamic Subsetting으로 로드
- `Theme.of(context).textTheme`으로 접근

### 사용법

```dart
// 올바른 사용
Text('제목', style: Theme.of(context).textTheme.titleLarge)
Text('본문', style: Theme.of(context).textTheme.bodyMedium)

// 잘못된 사용 (삭제 대상)
Text('제목', style: AppTypography.heading1)  // Noto Sans KR 잔재, 사용 금지
```

### 텍스트 스타일 가이드

| 용도 | TextTheme | 크기 (참고) |
|------|-----------|------------|
| 화면 제목 | `titleLarge` | 22sp |
| 섹션 제목 | `titleMedium` | 16sp |
| 소제목 | `titleSmall` | 14sp |
| 본문 | `bodyMedium` | 14sp |
| 보조 텍스트 | `bodySmall` | 12sp |
| 버튼 텍스트 | `labelLarge` | 14sp |
| 캡션 | `labelSmall` | 11sp |

### 이중 타이포그래피 문제

현재 `AppTypography` (Noto Sans KR 기반)가 미사용 잔재로 존재.
**PR-01**에서 삭제 예정. 모든 곳에서 `Theme.of(context).textTheme` 사용.

---

## 3. Spacing Tokens

> 정의: `lib/core/theme/app_spacing.dart`

### AppSpacing

| Token | 값 | 용도 |
|-------|----|------|
| `xs` | 4px | 아이콘과 텍스트 간격, 인라인 요소 간격 |
| `sm` | 8px | 리스트 아이템 내부 패딩, 칩 간격 |
| `md` | 12px | 카드 간 간격 (`cardGap`), 섹션 내 요소 간격 |
| `base` | 16px | 기본 패딩, 카드 내부 패딩 |
| `lg` | 20px | 섹션 간 여백 (소) |
| `xl` | 24px | 화면 좌우 패딩 (`screenH`), 섹션 간 간격 (`sectionGap`) |
| `xxl` | 32px | 큰 섹션 간 간격 |
| `xxxl` | 40px | 화면 상단/하단 여백 |

### 편의 상수

```dart
AppSpacing.screenH    // EdgeInsets.symmetric(horizontal: 24.0)
AppSpacing.sectionGap // 24.0 (섹션 간)
AppSpacing.cardGap    // 12.0 (카드 간)
```

### AppRadius

| Token | 값 | 용도 |
|-------|----|------|
| `sm` | 4px | 칩, 작은 태그 |
| `md` | 8px | 입력 필드, 작은 버튼 |
| `base` | 12px | 일반 버튼, 토스트 |
| `lg` | 16px | 카드, 바텀시트 |
| `xl` | 20px | 모달, 큰 카드 |

```dart
// BorderRadius 편의 getter
AppRadius.smBR    // BorderRadius.circular(4)
AppRadius.mdBR    // BorderRadius.circular(8)
AppRadius.baseBR  // BorderRadius.circular(12)
AppRadius.lgBR    // BorderRadius.circular(16)
AppRadius.xlBR    // BorderRadius.circular(20)
```

---

## 4. Elevation & Shadow

| 용도 | Elevation | 비고 |
|------|-----------|------|
| 카드 | 0 | **Flat design** -- 테두리(`border`)로 구분 |
| Bottom Sheet | 8 | Material default |
| FAB | 6 | Material default |
| AppBar | 0 | 투명 또는 surface 배경 |

```dart
// 카드 스타일 표준
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.lgBR,
    border: Border.all(color: AppColors.border),
  ),
)
```

---

## 5. Microcopy 원칙

### 언어 규칙

| 규칙 | 설명 | 예시 |
|------|------|------|
| **한국어** | 모든 UI 텍스트는 한국어 | "보내기", "구독하기" |
| **존댓말** | 사용자에게 존댓말 사용 | "메시지를 보냈습니다" |
| **간결성** | 핵심만 전달 | "전송 완료" (O), "메시지가 성공적으로 전송되었습니다" (X) |

### 에러 메시지 패턴

```
실패 시: "이유 + 다음 행동"

좋은 예:
  "네트워크 연결을 확인해 주세요"
  "토큰이 부족합니다. 다음 브로드캐스트 때 충전됩니다"
  "로그인 후 메시지를 보낼 수 있습니다"

나쁜 예:
  "전송 실패"
  "오류가 발생했습니다"
  "Error: null userId"
```

### 빈 상태 메시지

```
목적: 무엇을 할 수 있는지 안내

좋은 예:
  title: "아직 메시지가 없어요"
  message: "아티스트를 구독하면 메시지를 받을 수 있어요"
  action: "아티스트 탐색하기"

나쁜 예:
  "데이터 없음"
  "No messages"
```

### 확인 다이얼로그

```
파괴적 행동 시: 결과를 명확히 설명

구독 취소:
  title: "구독을 취소하시겠습니까?"
  body: "남은 구독 기간({date}까지)에도 메시지를 받을 수 있습니다"
  confirm: "구독 취소" (danger 색상)
  cancel: "유지하기"
```

---

## 6. Dark Theme 고려사항

| Light | Dark | 비고 |
|-------|------|------|
| `background #F8F8F8` | `backgroundDark #111111` | |
| `surface #FFFFFF` | `surfaceDark #1A1A1A` | |
| `text #111827` | `textDark #F9FAFB` | |
| `border #E5E7EB` | `borderDark #374151` | |
| Primary ramp | 동일 유지 | 브랜드 색상 불변 |

```dart
// Theme-aware 접근 (권장)
final colors = Theme.of(context).extension<AppColorsExtension>()!;
colors.surface  // 자동으로 Light/Dark 전환
```
