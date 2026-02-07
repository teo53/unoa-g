# CLAUDE.md - UNO A Flutter Application

This file provides guidance for AI assistants working with the UNO A codebase.

## Project Overview

**UNO A** is a Korean artist-to-fan messaging platform built with Flutter, similar to Fromm/Bubble. It enables K-pop artists to send broadcast messages to subscribers, who can then reply using a token-based system.

### Core Features
- **Group Chat System**: Artists see all fan messages in a group chat view; fans see a personalized 1:1 chat experience
- **Token-Based Replies**: Fans get 3 reply tokens per artist broadcast
- **DT (Digital Token) Currency**: In-app currency for donations and premium features
- **Subscription Tiers**: BASIC, STANDARD, VIP with different perks
- **Character Limit Progression**: Reply limits increase based on subscription age (50-300 chars)

---

## ⚠️ 채팅 시스템 핵심 컨셉 (CRITICAL - 반드시 숙지)

### 채팅 구조 = 단체 채팅방 형태 (Bubble/Fromm 스타일)

**절대로 "브로드캐스트"를 별도의 탭이나 기능으로 만들지 말 것!**
채팅 자체가 이 구조이며, 별도의 브로드캐스트 기능이 필요 없음.

```
┌─────────────────────────────────────────────────────────┐
│                    크리에이터 화면                        │
│  ┌─────────────────────────────────────────────────┐   │
│  │ [팬A] 오늘 공연 최고였어요!                        │   │
│  │ [팬B] 사랑해요 ❤️                                │   │
│  │ [나] 고마워요 여러분~                   → 전체전송  │   │
│  │ [팬C] 다음 공연 언제예요?                         │   │
│  │ [팬A] 앵콜 감사합니다!                            │   │
│  └─────────────────────────────────────────────────┘   │
│  → 단체톡방처럼 모든 팬 메시지가 타임라인에 보임          │
│  → 메시지 입력 → 모든 팬에게 전송됨                     │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                      팬A 화면                           │
│  ┌─────────────────────────────────────────────────┐   │
│  │ [나] 오늘 공연 최고였어요!                        │   │
│  │ [크리에이터] 고마워요 여러분~                      │   │
│  │ [나] 앵콜 감사합니다!                            │   │
│  └─────────────────────────────────────────────────┘   │
│  → 1:1 채팅처럼 자신의 메시지 + 크리에이터 메시지만 보임  │
└─────────────────────────────────────────────────────────┘
```

### 핵심 규칙

| 구분 | 크리에이터 | 팬 |
|------|-----------|-----|
| 메시지 전송 | 모든 팬에게 전송됨 | 해당 채팅방에만 전송 |
| 메시지 조회 | 모든 팬 메시지 + 본인 메시지 | 본인 메시지 + 크리에이터 메시지만 |
| UI 형태 | 단체톡방 | 1:1 채팅처럼 보임 |

### 크리에이터 채팅 탭 구조

```
CreatorChatTabScreen (2탭 구조)
├── 탭 1: 내 채널 (단체톡방 형태)
│   ├── 통합 메시지 리스트 (모든 팬 + 크리에이터 메시지)
│   │   - 팬 메시지: 왼쪽 정렬 + 팬 이름/티어 표시
│   │   - 크리에이터 메시지: 오른쪽 정렬 + "전체" 표시
│   ├── 메시지 입력 바 (하단 고정)
│   │   - 입력한 메시지 → 모든 팬에게 전송
│   └── 각 팬 메시지에 하트 반응 버튼
│
└── 탭 2: 구독 아티스트
    └── 크리에이터가 팬으로서 구독한 다른 아티스트 채팅 리스트
```

### ❌ 잘못된 구현 (하지 말 것)
- 별도의 "브로드캐스트" 탭 만들기
- 별도의 "브로드캐스트 작성" 버튼 만들기
- 크리에이터 채팅을 팬과 동일한 1:1 UI로 만들기
- artist_inbox를 메인 채팅 탭으로 사용하기

### ✅ 올바른 구현
- 크리에이터 채팅 탭 = 단체톡방 UI
- 메시지 입력창에서 바로 전체 전송
- 모든 팬 메시지가 시간순으로 통합 표시
- 팬별 이름/티어/후원 배지 표시

---

## Technology Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.0+ |
| Language | Dart |
| State Management | Provider |
| Navigation | go_router |
| Backend | Supabase (PostgreSQL) |
| Fonts | Pretendard (Korean optimized) |
| UI Framework | Material Design 3 |

## Project Structure

```
unoa-g/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── app.dart                  # MaterialApp & ThemeProvider
│   ├── core/
│   │   ├── config/               # ⭐ 환경 설정 (반드시 사용)
│   │   │   ├── app_config.dart   # 환경별 설정 (dev/staging/prod)
│   │   │   ├── demo_config.dart  # 데모 모드 설정값
│   │   │   └── business_config.dart  # 비즈니스 로직 상수
│   │   ├── constants/
│   │   │   └── asset_paths.dart  # Image/asset path constants
│   │   ├── services/
│   │   │   └── demo_mode_service.dart  # 데모 모드 통합 관리
│   │   └── theme/
│   │       ├── app_colors.dart   # WCAG-compliant color system
│   │       ├── app_theme.dart    # Light/dark theme definitions
│   │       ├── app_typography.dart
│   │       └── premium_effects.dart  # Glow, shimmer effects
│   ├── data/
│   │   ├── mock/
│   │   │   └── mock_data.dart    # Development mock data
│   │   ├── models/
│   │   │   ├── artist.dart
│   │   │   ├── broadcast_message.dart
│   │   │   ├── channel.dart
│   │   │   ├── message.dart
│   │   │   ├── reply_quota.dart
│   │   │   └── user_profile.dart
│   │   └── repositories/
│   │       ├── chat_repository.dart      # Abstract interface
│   │       └── mock_chat_repository.dart # Mock implementation
│   ├── features/                 # Feature-based organization
│   │   ├── artist_inbox/         # Artist dashboard screens
│   │   │   ├── broadcast_compose_screen.dart  # 브로드캐스트 작성
│   │   │   └── widgets/
│   │   │       └── media_preview_confirmation.dart  # 미디어 전송 확인
│   │   ├── chat/                 # Fan chat screens
│   │   ├── creator/              # Creator-specific screens
│   │   │   ├── creator_dashboard_screen.dart  # 대시보드
│   │   │   ├── creator_profile_screen.dart    # 프로필
│   │   │   └── creator_profile_edit_screen.dart  # 프로필 편집
│   │   ├── discover/             # Artist discovery
│   │   ├── help/                 # Help center
│   │   ├── home/                 # Home screen
│   │   ├── notifications/
│   │   ├── profile/              # User & artist profiles
│   │   ├── settings/
│   │   ├── subscriptions/
│   │   └── wallet/               # DT balance & transactions
│   ├── navigation/
│   │   └── app_router.dart       # go_router configuration
│   └── shared/
│       └── widgets/
│           ├── app_scaffold.dart     # Platform-aware layout
│           ├── bottom_nav_bar.dart   # Bottom navigation
│           ├── settings_widgets.dart # Settings UI components
│           └── ...                   # Other reusable widgets
├── supabase/
│   ├── functions/
│   │   └── refresh-fallback-quotas/
│   └── migrations/
│       ├── 001_broadcast_chat_schema.sql
│       ├── 002_rls_policies.sql
│       └── 003_triggers.sql
├── stitch/                       # Design reference screenshots
├── android/                      # Android platform code
├── web/                          # Web platform code
└── test/                         # Widget tests
```

## Architecture Patterns

### Feature-First Organization
Each feature folder contains:
- `*_screen.dart` - Main screen widget
- `widgets/` - Feature-specific widgets

### Repository Pattern
```dart
// Abstract interface allows swapping implementations
abstract class IChatRepository {
  Stream<List<BroadcastMessage>> watchMessages(String channelId);
  Future<BroadcastMessage> sendReply(String channelId, String content);
  // ...
}
```

### State Management
- **ThemeProvider**: Global theme state via Provider (toggle in Settings)
- **Local state**: StatefulWidgets for screen-level state
- Repositories return Streams for real-time data

### Platform-Aware Rendering
`AppScaffold` automatically detects platform:
- **Web**: Shows phone frame UI for demo/preview
- **Mobile (Android/iOS)**: Full screen without borders

```dart
// AppScaffold handles platform detection automatically
AppScaffold(
  child: YourScreen(),
  bottomNavigationBar: BottomNavBar(...),
);
```

## Key Conventions

### Naming Conventions
| Type | Convention | Example |
|------|------------|---------|
| Files | snake_case | `chat_list_screen.dart` |
| Classes | PascalCase | `ChatListScreen` |
| Variables | camelCase | `isVerified` |
| Constants | camelCase | `AppColors.primary500` |
| Routes | camelCase paths | `/chat/:artistId` |

### Color System (WCAG 2.1 AA Compliant)
```dart
// Primary colors - for active states and CTAs
AppColors.primary500  // #FF3B30 - Key color
AppColors.primary600  // #DE332A - Filled CTAs (4.5:1 contrast)
AppColors.primary700  // #C92D25 - Pressed state

// Semantic colors
AppColors.danger      // Destructive actions ONLY
AppColors.success     // Success states
AppColors.warning     // Warning states

// Theme-aware access via extension
Theme.of(context).extension<AppColorsExtension>()!.surface
```

**Important**: Never use `danger` color for positive actions. Use `primary600` for CTAs.

### Typography
- Font: Pretendard (Korean-optimized)
- Loaded via web/index.html with dynamic subsetting
- Use `Theme.of(context).textTheme` for consistent typography

### UI Guidelines
- Border radius: 16px for cards, 12px for buttons
- Card elevation: 0 (flat design with borders)
- Bottom nav uses Korean labels: 홈, 메시지, 탐색, 프로필
- Support both light and dark themes

## Routing

Routes defined in `lib/navigation/app_router.dart`:

```dart
// Main tabs (with bottom navigation)
'/'           // Home
'/chat'       // Chat list
'/discover'   // Discover artists
'/profile'    // My profile

// Detail screens (full screen, no bottom nav)
'/chat/:artistId'     // Chat thread
'/artist/:artistId'   // Artist profile
'/wallet'             // DT wallet
'/settings'           // Settings

// Artist inbox (for artist users)
'/artist/inbox'            // Artist inbox
'/artist/broadcast/compose' // Compose broadcast
```

## Data Models

### BroadcastMessage DeliveryScope
```dart
enum DeliveryScope {
  broadcast,       // Artist -> all subscribers
  directReply,     // Fan reply (uses token)
  donationMessage, // Fan message with DT donation
  donationReply,   // Artist reply to donation (1:1)
}
```

### Character Limits by Subscription Age
| Days Subscribed | Max Characters |
|-----------------|----------------|
| 1-49 | 50 |
| 50-76 | 50 |
| 77-99 | 77 |
| 100-149 | 100 |
| 150-199 | 150 |
| 200-299 | 200 |
| 300+ | 300 |

## Development Commands

```bash
# Run the app
flutter run

# Run on web
flutter run -d chrome

# Run tests
flutter test

# Analyze code
flutter analyze

# Build for production
flutter build web
flutter build apk
```

## Supabase Database

### Key Tables
- `channels` - One per artist
- `subscriptions` - User-channel subscriptions with tier and age
- `messages` - All messages with delivery_scope
- `message_delivery` - Per-user read state for broadcasts
- `reply_quota` - Token tracking per user-channel
- `policy_config` - JSON-based configurable rules

### Row Level Security (RLS)
All tables have RLS policies. Fans can only see:
- Broadcasts from subscribed channels
- Their own replies
- Artist replies directed to them

## Linting Rules

From `analysis_options.yaml`:
- `prefer_const_constructors: true`
- `prefer_const_literals_to_create_immutables: true`
- `avoid_print: true`
- `prefer_single_quotes: true`

## Common Tasks

### Adding a New Screen
1. Create `lib/features/{feature}/{feature}_screen.dart`
2. Add route in `lib/navigation/app_router.dart`
3. Create widgets in `lib/features/{feature}/widgets/`

### Adding a New Model
1. Create `lib/data/models/{model}.dart`
2. Include `fromJson()` and `toJson()` if needed
3. Add mock data in `lib/data/mock/mock_data.dart`

### Working with Theme Colors
```dart
// Direct access (static)
AppColors.primary500
AppColors.surfaceLight

// Theme-aware (recommended)
final isDark = Theme.of(context).brightness == Brightness.dark;
final colors = Theme.of(context).extension<AppColorsExtension>()!;
colors.surface  // Auto-switches between light/dark
```

### Creating Reusable Widgets
Place in `lib/shared/widgets/` with:
- Clear constructor parameters
- Theme-aware colors
- Support for both light and dark modes

### Using Settings Widgets
Reusable settings components in `lib/shared/widgets/settings_widgets.dart`:

```dart
import '../../shared/widgets/settings_widgets.dart';

// Section title
SettingsSectionTitle(title: '계정'),

// Group container
SettingsGroup(
  children: [
    SettingsItem(
      icon: Icons.person_outline,
      title: '프로필 편집',
      onTap: () {},
    ),
    SettingsSwitchItem(
      icon: Icons.dark_mode_outlined,
      title: '다크 모드',
      value: isDark,
      onChanged: (v) => themeProvider.toggleTheme(),
    ),
  ],
),
```

## Testing Notes

- Widget tests in `test/` directory
- Mock data available via `MockData` class
- Repository interfaces allow easy mocking

## Design References

The `stitch/` directory contains design reference screenshots:
- `uno_a_home_screen/` - Home screen designs
- `uno_a_chat_list_screen/` - Chat list designs
- `uno_a_artist_chat_thread/` - Chat thread designs
- etc.

Each folder contains `screen.png` and `code.html` for reference.

## Enterprise Components

### Skeleton Loading
```dart
import '../../shared/widgets/skeleton_loader.dart';

// Basic skeleton
SkeletonLoader(width: 100, height: 20)
SkeletonLoader.circle(size: 48)
SkeletonLoader.text(width: 120)
SkeletonLoader.card(width: 200, height: 100)

// Preset components
SkeletonListTile(showAvatar: true, showSubtitle: true)
SkeletonCard(width: 200, height: 120)
SkeletonMessageBubble(isFromArtist: true)
```

### Error Handling
```dart
import '../../shared/widgets/error_boundary.dart';

// Error display
ErrorDisplay(
  error: error,
  onRetry: () => _loadData(),
)

// Empty state
EmptyState(
  title: '아직 메시지가 없어요',
  message: '첫 메시지를 보내보세요',
  icon: Icons.inbox_outlined,
)

// Loading state
LoadingState(message: '로딩 중...')
```

### Animation Utilities
```dart
import '../../core/utils/animation_utils.dart';

// Fade in animation
FadeInAnimation(child: widget, delay: Duration(milliseconds: 100))

// Slide + fade animation
SlideFadeAnimation.fromBottom(child: widget)
SlideFadeAnimation.fromLeft(child: widget)

// Tap scale effect
ScaleOnTap(
  onTap: () => handleTap(),
  child: widget,
)

// Staggered list
StaggeredListAnimation(children: listWidgets)

// Animated counter
AnimatedCounter(value: 1250, prefix: '₩', suffix: ' DT')
```

### Responsive Design
```dart
import '../../core/utils/responsive_helper.dart';

// Check device type
final helper = ResponsiveHelper(context);
if (helper.isPhone) { ... }
if (helper.isTablet) { ... }
if (helper.isLandscape) { ... }

// Responsive layout
ResponsiveLayout(
  phone: PhoneWidget(),
  tablet: TabletWidget(),
  desktop: DesktopWidget(),
)

// Adaptive container (centers on large screens)
AdaptiveContainer(
  maxWidth: 600,
  child: content,
)

// Extension for quick access
context.responsive.isPhone
context.responsiveValue(phone: 2, tablet: 3, desktop: 4)
```

### Accessibility
```dart
import '../../core/utils/accessibility_helper.dart';

// Semantic wrappers
SemanticButton(label: '보내기', child: button)
SemanticImage(label: '아티스트 프로필', child: image)

// Screen reader announcements
ScreenReaderAnnouncement.announce(context, '메시지를 보냈습니다')

// Accessible tap targets (48x48 minimum)
AccessibleTapTarget(
  semanticLabel: '뒤로가기',
  onTap: () => context.pop(),
  child: Icon(Icons.arrow_back),
)

// Extensions
widget.withButtonSemantics('버튼 설명')
decorativeWidget.excludeSemantics()
```

## Creator Routes (크리에이터 라우트)

```dart
// 크리에이터 메인 탭 (하단 네비게이션 포함)
'/creator/dashboard'      // 대시보드 - CRM 통합
'/creator/chat'           // 채팅 - 내 채널 + 구독
'/creator/funding'        // 펀딩 - 내 캠페인 + 탐색
'/creator/discover'       // 탐색 - 아티스트 탐색
'/creator/profile'        // 프로필

// 전체 화면 (하단 네비게이션 없음)
'/creator/crm'            // CRM 상세
'/creator/my-channel'     // 내 채널 브로드캐스트
'/creator/profile/edit'   // 프로필 편집
'/creator/funding/create' // 캠페인 생성
'/creator/funding/edit/:campaignId' // 캠페인 편집
```

---

## ⚠️ 환경 설정 시스템 (CRITICAL - 반드시 숙지)

### 설정 파일 구조

```
lib/core/config/
├── app_config.dart      # 환경별 설정 (dev/staging/prod)
├── demo_config.dart     # 데모 모드 전용 설정값
└── business_config.dart # 비즈니스 로직 상수
```

### AppConfig - 환경 설정
```dart
import '../../core/config/app_config.dart';

// 환경 확인
AppConfig.isDevelopment  // 개발 환경
AppConfig.isProduction   // 프로덕션 환경
AppConfig.enableDemoMode // 데모 모드 활성화 여부

// Supabase 설정
AppConfig.supabaseUrl
AppConfig.supabaseAnonKey

// Firebase 설정
AppConfig.firebaseProjectId
```

### DemoConfig - 데모 데이터
```dart
import '../../core/config/demo_config.dart';

// 데모 사용자 ID
DemoConfig.demoCreatorId    // 'demo_creator_001'
DemoConfig.demoFanId        // 'demo_user_001'

// 데모 사용자 이름
DemoConfig.demoCreatorName  // '하늘달 (데모)'
DemoConfig.demoFanName      // '데모 팬'

// 데모 초기값
DemoConfig.initialDtBalance      // 15000
DemoConfig.initialStarBalance    // 50
DemoConfig.demoSubscriberCount   // 1234
DemoConfig.demoMonthlyRevenue    // 1250000

// 아바타 URL 생성
DemoConfig.avatarUrl('vtuber1', size: 200)
DemoConfig.bannerUrl('banner1', width: 400, height: 200)
```

### BusinessConfig - 비즈니스 규칙
```dart
import '../../core/config/business_config.dart';

// 구독 티어
BusinessConfig.subscriptionTiers  // ['BASIC', 'STANDARD', 'VIP']
BusinessConfig.tierPricesKrw      // {'BASIC': 4900, 'STANDARD': 9900, 'VIP': 19900}

// 답글 토큰
BusinessConfig.defaultReplyTokens    // 3
BusinessConfig.getTokensForTier('VIP')  // 5

// 글자 제한 (구독 일수별)
BusinessConfig.getCharacterLimit(120)  // 100

// DT 관련
BusinessConfig.dtPerKrw           // 1 (1 KRW = 1 DT)
BusinessConfig.chargeAmounts      // [1000, 3000, 5000, ...]
BusinessConfig.platformCommissionPercent  // 20.0
BusinessConfig.creatorPayoutPercent       // 80.0
```

### 하드코딩 금지 규칙

❌ **절대 하지 말 것**
```dart
// 하드코딩된 ID
userId: 'demo_creator_001'

// 하드코딩된 URL
avatarUrl: 'https://picsum.photos/seed/vtuber1/200'

// 하드코딩된 금액
balanceDt: 15000
```

✅ **올바른 방법**
```dart
// DemoConfig 사용
userId: DemoConfig.demoCreatorId

// DemoConfig URL 생성기 사용
avatarUrl: DemoConfig.avatarUrl('vtuber1')

// DemoConfig 초기값 사용
balanceDt: DemoConfig.initialDtBalance
```

### 프로덕션 빌드 시 환경 변수

**⚠️ 필수 환경 변수 (빌드 시 반드시 지정):**

| 변수 | 설명 | 필수 |
|------|------|:----:|
| `ENV` | `production` / `staging` / `development` | ✅ |
| `SUPABASE_URL` | Supabase 프로젝트 URL | ✅ |
| `SUPABASE_ANON_KEY` | Supabase 익명 키 | ✅ |
| `SENTRY_DSN` | Sentry 에러 추적 DSN | ✅ |
| `FIREBASE_PROJECT_ID` | Firebase 프로젝트 ID | ✅ |
| `ENABLE_DEMO` | 데모 모드 (프로덕션에서는 `false`) | ✅ |
| `ENABLE_ANALYTICS` | 분석 활성화 (기본: 프로덕션에서 true) | |
| `ENABLE_CRASH_REPORTING` | 크래시 리포팅 (기본: 프로덕션에서 true) | |

**프로덕션 빌드 명령어 (전체):**
```bash
flutter build web --release \
  --dart-define=ENV=production \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=SENTRY_DSN=https://xxx@sentry.io/xxx \
  --dart-define=FIREBASE_PROJECT_ID=your-firebase-project \
  --dart-define=ENABLE_DEMO=false \
  --dart-define=ENABLE_ANALYTICS=true
```

**⚠️ 주의사항:**
- `ENABLE_DEMO=false` 없이 빌드하면 프로덕션에서도 데모 모드가 활성화될 수 있음
- `SENTRY_DSN` 없이 빌드하면 에러 추적이 비활성화됨 (조용히 실패)
- Firebase 사용 시 `google-services.json` (Android), `GoogleService-Info.plist` (iOS) 필요

### 프로덕션 배포 체크리스트

**빌드 전:**
- [ ] 모든 환경 변수가 `--dart-define`으로 제공됨
- [ ] `ENABLE_DEMO=false` 확인
- [ ] Sentry DSN 설정됨
- [ ] Firebase 설정 파일 준비 (모바일 빌드 시)

**Supabase:**
- [ ] 모든 마이그레이션 적용됨 (`supabase db push`)
- [ ] RLS 정책 활성화됨
- [ ] Edge Functions 배포됨

**배포 후:**
- [ ] Sentry에서 에러 수신 확인
- [ ] 데모 모드가 비활성화되었는지 확인
- [ ] 실제 결제 테스트 (스테이징 환경)

### 데모 모드 지원 파일들

데모 모드를 지원해야 하는 Provider/Service:
- `auth_provider.dart` - `AuthDemoMode` 상태 및 `updateDemoProfile()` 메서드
- `wallet_provider.dart` - `_loadDemoWallet()`, `addDemoBalance()`, `spendDemoBalance()` 메서드

데모 모드 확인 방법:
```dart
final isDemoMode = ref.watch(isDemoModeProvider);
final authState = ref.read(authProvider);
if (authState is AuthDemoMode) {
  // 데모 모드 전용 로직
}
```

---

## Firebase 배포

### 배포 명령어
```bash
# 웹 빌드
flutter build web --release

# Firebase 배포
firebase deploy --only hosting
```

### 현재 배포 URL
- **호스팅**: https://unoa-app-demo.web.app
- **Firebase 프로젝트**: unoa-app-demo

---

## Important Notes for AI Assistants

1. **Korean Language**: UI labels are in Korean. Preserve existing translations.
2. **WCAG Compliance**: Maintain 4.5:1 contrast ratios for text.
3. **Fromm/Bubble Style**: This mimics Korean fan messaging apps - maintain the 1:1 illusion.
4. **Token System**: Fans need tokens to reply; don't allow unlimited messaging.
5. **Subscription Age**: Character limits depend on how long a user has been subscribed.
6. **Mock vs Real**: Currently uses mock data; real Supabase integration pending.
7. **Theme Toggle**: Dark/light mode toggle is in Settings screen (`/settings`), not in bottom nav.
8. **Platform Detection**: `AppScaffold` shows phone frame on web only; mobile gets full screen.
9. **Use Enterprise Components**: For new features, use the skeleton loaders, error boundaries, and animation utilities.
10. **Accessibility**: All interactive elements should have semantic labels for screen readers.
11. **Responsive**: Use ResponsiveLayout for screens that need tablet/desktop support.
12. **Config 사용 필수**: 하드코딩 대신 반드시 `DemoConfig`, `BusinessConfig`, `AppConfig` 사용.
13. **데모 모드 지원**: 새 Provider 작성 시 `AuthDemoMode` 상태 처리 필수.

---

## ⛔ API 키 보안 규칙 (CRITICAL - 절대 위반 금지)

### 원칙: API 키는 절대로 클라이언트에 노출되면 안 됨

**절대 하지 말 것 (NEVER DO):**
- API 키(Anthropic, OpenAI, Supabase service_role 등)를 Dart 소스코드에 하드코딩
- API 키를 `defaultValue`에 넣기
- API 키를 Firebase Hosting에 JSON 파일로 배포
- API 키를 JavaScript/HTML 파일에 포함
- API 키를 git 커밋에 포함 (소스코드, config 파일, .env 등)
- 클라이언트에서 직접 AI API(Anthropic, OpenAI 등)를 호출하는 코드 작성 (프로덕션)
- API 키를 로그에 출력

**올바른 방법 (ALWAYS DO):**
- API 키는 **서버 환경변수**에만 저장 (Supabase Edge Function 환경변수, Cloud Function 등)
- 클라이언트 → 서버(Edge Function) → AI API 구조로 호출
- 데모 모드에서는 **로컬 예시 답변**을 사용하여 API 호출 없이 기능 체험 제공
- `.env` 파일은 반드시 `.gitignore`에 포함
- 빌드 시 `--dart-define`으로 주입하는 키도 CI/CD 시크릿으로 관리

### AI 답글 시스템 아키텍처

```
[프로덕션 환경]
클라이언트 → Supabase Edge Function → Claude API
              (ANTHROPIC_API_KEY는 서버 환경변수)

[데모/개발 환경]
클라이언트 → 로컬 예시 답변 반환 (API 호출 없음)
```

### 키 유형별 관리 방법

| 키 유형 | 저장 위치 | 절대 금지 |
|---------|----------|----------|
| `ANTHROPIC_API_KEY` | Supabase Edge Function 환경변수 | 클라이언트 코드에 포함 |
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Function 서버 | 클라이언트에 전달 |
| `SUPABASE_ANON_KEY` | 빌드타임 주입 (공개 가능) | - |
| `SENTRY_DSN` | 빌드타임 주입 (공개 가능) | - |
