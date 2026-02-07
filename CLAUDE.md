# CLAUDE.md - UNO A Flutter Application

This file provides guidance for AI assistants working with the UNO A codebase.

## 로컬 개발 환경

| 항목 | 경로 |
|------|------|
| Flutter SDK | `C:\Users\mapdr\flutter_sdk\flutter` |
| Flutter 실행 | `export PATH="/c/Users/mapdr/flutter_sdk/flutter/bin:$PATH"` (bash) |

> **중요**: Flutter 명령어 실행 전 반드시 위 PATH 설정을 먼저 실행할 것.

## Project Overview

**UNO A** is a Korean artist-to-fan messaging platform built with Flutter, similar to Fromm/Bubble. It enables K-pop artists to send broadcast messages to subscribers, who can then reply using a token-based system.

### Core Features
- **Group Chat System**: Artists see all fan messages in a group chat view; fans see a personalized 1:1 chat experience
- **Token-Based Replies**: Fans get 3 reply tokens per artist broadcast
- **DT (Digital Token) Currency**: In-app currency for donations and premium features
- **Subscription Tiers**: BASIC, STANDARD, VIP with different perks
- **Character Limit Progression**: Reply limits increase based on subscription age (50-300 chars)
- **Funding/Campaigns**: Crowdfunding system for creator projects
- **Daily Question Cards**: Ice-breaker question cards for fan-creator engagement
- **AI Reply Suggestions**: AI-powered reply suggestions for creators
- **Voice Messages**: Audio recording and playback in chat

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
| State Management | Riverpod (migrating from Provider) |
| Navigation | go_router ^14.0.0 |
| Backend | Supabase (PostgreSQL + Edge Functions) |
| Error Monitoring | Sentry (sentry_flutter ^8.10.0) |
| Push Notifications | Firebase Cloud Messaging |
| Analytics | Firebase Analytics |
| Local Storage | Hive (hive_flutter ^1.1.0) |
| Fonts | Pretendard (Korean optimized) |
| UI Framework | Material Design 3 |
| Payments | TossPayments |
| Code Generation | freezed, json_serializable, riverpod_generator |
| Hosting | Firebase Hosting |

## Project Structure

```
unoa-g/
├── lib/
│   ├── main.dart                    # App entry point (Sentry, Hive, Supabase, FCM init)
│   ├── app.dart                     # MaterialApp.router with Riverpod ConsumerWidget
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart   # API, pricing, chat, subscription constants
│   │   │   └── asset_paths.dart     # Image/asset path constants
│   │   ├── monitoring/
│   │   │   └── sentry_service.dart  # Sentry error monitoring integration
│   │   ├── services/
│   │   │   └── error_service.dart   # Error handling service
│   │   ├── supabase/
│   │   │   ├── supabase_auth_service.dart  # Auth (email, OAuth, session)
│   │   │   └── supabase_client.dart        # Supabase client configuration
│   │   ├── theme/
│   │   │   ├── app_colors.dart      # WCAG-compliant color system + gradients
│   │   │   ├── app_radius.dart      # Border radius constants (KRDS-inspired)
│   │   │   ├── app_spacing.dart     # 8pt grid spacing system
│   │   │   ├── app_theme.dart       # Light/dark theme + AppColorsExtension
│   │   │   ├── app_typography.dart  # Text styles with Pretendard
│   │   │   └── premium_effects.dart # Shadows, glows, elevation presets
│   │   └── utils/
│   │       ├── accessibility_helper.dart  # Semantic wrappers, screen reader
│   │       ├── animation_utils.dart       # Animation durations, curves, widgets
│   │       ├── responsive_helper.dart     # Breakpoints, device detection
│   │       └── utils.dart                 # General utilities
│   ├── data/
│   │   ├── mock/
│   │   │   └── mock_data.dart       # Development mock data (users, artists)
│   │   ├── models/
│   │   │   ├── artist.dart          # Artist/creator info
│   │   │   ├── broadcast_message.dart  # Chat messages + DeliveryScope enum
│   │   │   ├── channel.dart         # Creator channel
│   │   │   ├── creator_content.dart # Creator content/posts
│   │   │   ├── daily_question_set.dart  # Daily question sets
│   │   │   ├── dt_package.dart      # DT charging packages
│   │   │   ├── message.dart         # Base message model
│   │   │   ├── question_card.dart   # Interactive question cards
│   │   │   ├── reply_quota.dart     # Reply token tracking
│   │   │   ├── user.dart            # Basic user model
│   │   │   └── user_profile.dart    # User display profile (tier, balance)
│   │   ├── repositories/
│   │   │   ├── chat_repository.dart        # IChatRepository + IArtistInboxRepository
│   │   │   ├── mock_chat_repository.dart   # Mock implementation for development
│   │   │   ├── question_cards_repository.dart  # Daily question card system
│   │   │   ├── repositories.dart           # Barrel exports
│   │   │   ├── supabase_chat_repository.dart   # Fan chat (Supabase)
│   │   │   ├── supabase_inbox_repository.dart  # Artist inbox (Supabase)
│   │   │   ├── supabase_profile_repository.dart # User profiles (Supabase)
│   │   │   └── supabase_wallet_repository.dart  # Wallet/DT ops (Supabase)
│   │   └── services/
│   │       ├── chat_service.dart         # Chat business logic & validation
│   │       ├── notification_service.dart # Notification formatting
│   │       └── wallet_service.dart       # DT/donation calculations
│   ├── features/
│   │   ├── artist_inbox/           # Legacy artist inbox (→ use creator/ instead)
│   │   │   ├── artist_inbox_screen.dart
│   │   │   ├── broadcast_compose_screen.dart
│   │   │   └── widgets/
│   │   │       ├── fan_reply_tile.dart
│   │   │       ├── inbox_filter_bar.dart
│   │   │       └── media_preview_confirmation.dart
│   │   ├── auth/                   # Authentication flows
│   │   │   ├── auth.dart
│   │   │   ├── screens/
│   │   │   │   ├── age_verification_screen.dart
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   └── widgets/
│   │   │       ├── auth_form.dart
│   │   │       ├── identity_verification_button.dart
│   │   │       └── social_login_buttons.dart
│   │   ├── chat/                   # Fan chat experience
│   │   │   ├── chat_list_screen.dart
│   │   │   ├── chat_thread_screen.dart
│   │   │   ├── chat_thread_screen_v2.dart
│   │   │   └── widgets/
│   │   │       ├── chat_input_bar.dart
│   │   │       ├── chat_input_bar_v2.dart
│   │   │       ├── chat_list_tile.dart
│   │   │       ├── daily_question_cards_panel.dart
│   │   │       ├── disabled_composer.dart
│   │   │       ├── message_bubble.dart
│   │   │       ├── token_counter.dart
│   │   │       └── voice_message_widget.dart
│   │   ├── creator/                # Creator-specific screens (9 screens)
│   │   │   ├── creator_analytics_screen.dart
│   │   │   ├── creator_chat_screen.dart
│   │   │   ├── creator_chat_tab_screen.dart
│   │   │   ├── creator_crm_screen.dart
│   │   │   ├── creator_dashboard_screen.dart
│   │   │   ├── creator_dm_screen.dart
│   │   │   ├── creator_my_channel_screen.dart
│   │   │   ├── creator_profile_edit_screen.dart
│   │   │   ├── creator_profile_screen.dart
│   │   │   └── widgets/
│   │   │       ├── ai_reply_suggestion_sheet.dart
│   │   │       └── todays_voted_question_section.dart
│   │   ├── discover/               # Artist discovery
│   │   │   └── discover_screen.dart
│   │   ├── funding/                # Crowdfunding/campaigns (10 screens)
│   │   │   ├── campaign_backers_screen.dart
│   │   │   ├── campaign_stats_screen.dart
│   │   │   ├── create_campaign_screen.dart
│   │   │   ├── creator_funding_screen.dart
│   │   │   ├── funding_checkout_screen.dart
│   │   │   ├── funding_detail_screen.dart
│   │   │   ├── funding_result_screen.dart
│   │   │   ├── funding_screen.dart
│   │   │   ├── funding_tier_select_screen.dart
│   │   │   └── my_pledges_screen.dart
│   │   ├── help/
│   │   │   └── help_center_screen.dart
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   └── widgets/
│   │   │       ├── subscription_tile.dart
│   │   │       └── trending_artist_card.dart
│   │   ├── notifications/
│   │   │   └── notifications_screen.dart
│   │   ├── profile/
│   │   │   ├── artist_profile_screen.dart
│   │   │   └── my_profile_screen.dart
│   │   ├── settings/
│   │   │   ├── account_screen.dart
│   │   │   ├── notification_settings_screen.dart
│   │   │   └── settings_screen.dart
│   │   ├── subscriptions/
│   │   │   └── subscriptions_screen.dart
│   │   └── wallet/
│   │       ├── dt_charge_screen.dart
│   │       ├── transaction_history_screen.dart
│   │       └── wallet_screen.dart
│   ├── navigation/
│   │   └── app_router.dart          # GoRouter with ShellRoute for tabs
│   ├── providers/                   # Riverpod state management
│   │   ├── auth_provider.dart       # Authentication state
│   │   ├── chat_list_provider.dart  # Chat list state
│   │   ├── chat_provider.dart       # Chat/messaging state
│   │   ├── daily_question_set_provider.dart  # Daily question state
│   │   ├── funding_provider.dart    # Funding/campaign state
│   │   ├── providers.dart           # Barrel exports
│   │   ├── repository_providers.dart # Repository DI via Riverpod
│   │   ├── theme_provider.dart      # Dark/light theme toggle
│   │   └── wallet_provider.dart     # Wallet/DT balance state
│   ├── services/                    # App-level services
│   │   ├── analytics_service.dart   # Firebase Analytics tracking
│   │   ├── fcm_service.dart         # Firebase Cloud Messaging
│   │   ├── identity_verification_service.dart  # PASS identity verification
│   │   ├── media_service.dart       # Image/video handling
│   │   ├── realtime_service.dart    # Supabase Realtime subscriptions
│   │   ├── services.dart            # Barrel exports
│   │   └── voice_service.dart       # Voice recording/playback
│   └── shared/widgets/
│       ├── app_scaffold.dart            # Platform-aware layout (web frame / mobile full)
│       ├── avatar_with_badge.dart       # AvatarPlaceholder, AvatarWithBadge, StoryAvatar
│       ├── bottom_nav_bar.dart          # Fan bottom nav (5 tabs)
│       ├── creator_bottom_nav_bar.dart  # Creator bottom nav (5 tabs)
│       ├── error_boundary.dart          # ErrorDisplay, EmptyState, LoadingState
│       ├── message_action_sheet.dart    # Reactions, copy, pin, delete
│       ├── premium_shimmer.dart         # PremiumShimmer, GlowWrapper, PremiumContainer
│       ├── primary_button.dart          # PrimaryButton, SecondaryButton, DestructiveButton, BadgeChip
│       ├── search_field.dart            # Search input with theme
│       ├── section_header.dart          # Section titles with trailing actions
│       ├── settings_widgets.dart        # SettingsGroup, SettingsItem, SettingsSwitchItem
│       ├── skeleton_loader.dart         # Loading state placeholders
│       └── widgets.dart                 # Barrel exports
├── supabase/
│   ├── functions/                   # 13 Edge Functions
│   │   ├── _shared/                 # cors.ts, sentry.ts
│   │   ├── ai-reply-suggest/        # AI reply suggestions for creators
│   │   ├── funding-admin-review/    # Campaign review workflow
│   │   ├── funding-pledge/          # Pledge processing
│   │   ├── funding-studio-submit/   # Studio funding submission
│   │   ├── payment-checkout/        # TossPayments checkout session
│   │   ├── payment-webhook/         # Payment webhook (HMAC verification)
│   │   ├── payout-calculate/        # Creator payout calculation
│   │   ├── payout-statement/        # Payout statement generation
│   │   ├── refresh-fallback-quotas/ # Reply quota daily refresh
│   │   ├── refund-process/          # Refund processing
│   │   ├── scheduled-dispatcher/    # Cron-based scheduled tasks
│   │   └── verify-identity/         # PASS identity verification
│   └── migrations/                  # 27 SQL migrations (001-031)
│       ├── 001-003                  # Core chat schema, RLS, triggers
│       ├── 004-005                  # User & creator profiles
│       ├── 006-008                  # Wallet/ledger, messages extended, payouts
│       ├── 009-014                  # Moderation, payment safety, encryption, indexes
│       ├── 015-020                  # Identity verification, payout accounts, webhooks, consents
│       ├── 021-023                  # Funding schema, storage, image buckets
│       ├── 024-025                  # Reply token policy fix, quota optimization
│       └── 030-031                  # Question cards schema + seed data
├── content/
│   └── question_card_deck_800.jsonl # Question card content database
├── docs/
│   └── ARCHITECTURE.md              # Detailed architecture documentation
├── stitch/                          # Design reference screenshots
├── apps/web/                        # Web app configuration
├── notion-crawler-v2/               # Notion data crawler utility
├── android/                         # Android platform code
├── ios/                             # iOS platform code
├── web/                             # Web platform (index.html, manifest)
└── test/
    ├── data/models/                 # Model unit tests
    │   ├── broadcast_message_test.dart
    │   ├── dt_package_test.dart
    │   └── reply_quota_test.dart
    ├── integration/                 # Integration tests
    │   ├── chat_flow_test.dart
    │   └── payment_flow_test.dart
    ├── providers/                   # Provider tests
    │   ├── chat_provider_test.dart
    │   └── wallet_provider_test.dart
    └── widget_test.dart             # Basic widget tests
```

## Architecture Patterns

### Feature-First Organization
Each feature folder contains:
- `*_screen.dart` - Main screen widget
- `widgets/` - Feature-specific widgets

### Layered Architecture
```
UI Layer (features/, shared/widgets/)
    ↓
State Management (providers/)
    ↓
Business Logic (data/services/, services/)
    ↓
Data Layer (data/repositories/, data/models/)
    ↓
Backend (Supabase: PostgreSQL + Edge Functions + Realtime)
```

### Repository Pattern
```dart
// Abstract interfaces in chat_repository.dart
abstract class IChatRepository {
  Stream<List<BroadcastMessage>> watchMessages(String channelId);
  Future<BroadcastMessage> sendReply(String channelId, String content);
  Future<ReplyQuota> getQuota(String channelId);
  Future<int> getCharacterLimit(String channelId);
  // ...
}

abstract class IArtistInboxRepository {
  Future<List<BroadcastMessage>> getFanMessages(String channelId, ...);
  Stream<List<BroadcastMessage>> watchFanMessages(String channelId);
  Future<BroadcastMessage> sendBroadcast(String channelId, String content, ...);
  // ...
}

// Implementations: MockChatRepository (dev), SupabaseChatRepository (prod)
```

### State Management (Riverpod)
The project uses **Riverpod** (`flutter_riverpod`) as the primary state management, with some legacy **Provider** usage being migrated.

```dart
// Repository dependency injection via Riverpod
// See: lib/providers/repository_providers.dart

// State providers for each domain:
// - auth_provider.dart     → Authentication state
// - chat_provider.dart     → Chat/messaging state
// - wallet_provider.dart   → Wallet/DT balance
// - funding_provider.dart  → Funding campaigns
// - theme_provider.dart    → Dark/light theme toggle
```

### Platform-Aware Rendering
`AppScaffold` automatically detects platform:
- **Web**: Shows phone frame UI (400x844) for demo/preview with fake status bar
- **Mobile (Android/iOS)**: Full screen with SafeArea

```dart
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
AppColors.primary500  // #FF3B30 - Key color, active states
AppColors.primary600  // #DE332A - Filled CTAs (4.5:1 contrast)
AppColors.primary700  // #C92D25 - Pressed state

// Semantic colors
AppColors.danger      // #B42318 - Destructive actions ONLY
AppColors.success     // Success states
AppColors.warning     // Warning states
AppColors.online      // Online status indicator
AppColors.verified    // Verification badge

// Gradients
AppColors.primaryGradient   // Main gradient
AppColors.premiumGradient   // VIP/premium elements
AppColors.subtleGradient    // Subtle backgrounds

// Theme-aware access via extension
Theme.of(context).extension<AppColorsExtension>()!.surface
```

**Important**: Never use `danger` color for positive actions. Use `primary600` for CTAs.

### Spacing & Radius
```dart
// 8pt grid system (lib/core/theme/app_spacing.dart)
AppSpacing.xs   // 4px
AppSpacing.sm   // 8px
AppSpacing.md   // 12px
AppSpacing.lg   // 16px
AppSpacing.xl   // 20px
AppSpacing.xxl  // 24px
// ... up to xxxxxl (48px)

// KRDS-inspired border radius (lib/core/theme/app_radius.dart)
AppRadius.xs    // 4px
AppRadius.sm    // 8px
AppRadius.md    // 10px
AppRadius.lg    // 14px
AppRadius.xl    // 18px
AppRadius.xxl   // 24px
AppRadius.full  // 999px (pill shape)
```

### Typography
- Font: **Pretendard** (Korean-optimized)
- Line height: 1.5 for readability
- Use `Theme.of(context).textTheme` for consistent typography
- Categories: display, heading, body, label, caption, button

### UI Guidelines
- Card elevation: 0 (flat design with borders)
- Fan bottom nav: 홈, 메시지, 펀딩, 탐색, 프로필 (5 tabs)
- Creator bottom nav: 대시보드, 채팅, 펀딩, 탐색, 프로필 (5 tabs)
- Support both light and dark themes
- Locale locked to ko_KR

## Routing

Routes defined in `lib/navigation/app_router.dart` using GoRouter with ShellRoute:

```dart
// ─── Fan Shell Routes (with BottomNavBar) ───
'/'              // Home
'/chat'          // Chat list
'/funding'       // Funding/sponsorship campaigns
'/discover'      // Discover artists
'/profile'       // My profile

// ─── Creator Shell Routes (with CreatorBottomNavBar) ───
'/creator/dashboard'   // Dashboard (CRM + analytics)
'/creator/chat'        // Chat (my channel + subscribed artists)
'/creator/funding'     // Funding campaign management
'/creator/discover'    // Discover artists (reused fan screen)
'/creator/profile'     // Creator profile

// ─── Full Screen Routes (no bottom nav) ───
'/chat/:artistId'      // Chat thread with artist
'/artist/:artistId'    // Artist profile page
'/wallet'              // DT wallet
'/wallet/charge'       // DT charge/purchase
'/wallet/history'      // Transaction history
'/settings'            // Settings
'/settings/notifications'  // Notification settings
'/settings/account'    // Account settings
'/notifications'       // Notifications list
'/subscriptions'       // Manage subscriptions
'/help'                // Help center

// ─── Creator Full Screen Routes ───
'/creator/crm'                         // Advanced CRM
'/creator/my-channel'                  // Broadcast chat management
'/creator/profile/edit'                // Profile editor
'/creator/funding/create'              // Create funding campaign
'/creator/funding/edit/:campaignId'    // Edit campaign

// ─── Auth Routes ───
'/login'               // Login
'/register'            // Registration
'/forgot-password'     // Password reset (placeholder)
'/terms'               // Terms of service (placeholder)
'/privacy'             // Privacy policy (placeholder)
'/guardian-consent'     // Guardian consent (placeholder)

// ─── Legacy Routes (backward compatibility) ───
'/artist/inbox'              // Legacy artist inbox
'/artist/inbox/:fanUserId'   // Legacy inbox thread
'/artist/broadcast/compose'  // Legacy broadcast compose
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

enum BroadcastMessageType {
  text, image, video, emoji, voice
}
```

### All Models (lib/data/models/)

| Model | Purpose |
|-------|---------|
| `artist.dart` | Artist/creator information |
| `broadcast_message.dart` | Chat messages with delivery scope, type, reactions, edit history |
| `channel.dart` | Creator channel data |
| `creator_content.dart` | Creator content/posts |
| `daily_question_set.dart` | Daily ice-breaker question sets |
| `dt_package.dart` | DT charging/purchase packages |
| `message.dart` | Base message model |
| `question_card.dart` | Interactive question cards |
| `reply_quota.dart` | Daily reply token tracking per user-channel |
| `user.dart` | Basic user information |
| `user_profile.dart` | User display profile (tier, balance, subscription info) |

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

### App Constants (lib/core/constants/app_constants.dart)
```dart
// Key constants:
ApiConstants.pageSize       // 50
ApiConstants.timeout         // 30s
PricingConstants.defaultMonthly  // 4900₩
PricingConstants.vipMonthly      // 9900₩
PricingConstants.dtRate          // 100₩ per DT
ChatConstants.defaultTokens      // 3 reply tokens
SubscriptionTiers: BASIC, STANDARD, VIP
UserRoles: fan, creator, admin, moderator
```

## Environment Setup

Copy `.env.example` to `.env.local` and configure:

```bash
# Required
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJ...
SENTRY_DSN=https://xxxxx@o123456.ingest.sentry.io/1234567

# Payment (TossPayments - requires business registration)
TOSS_CLIENT_KEY=test_ck_xxxxx
TOSS_SECRET_KEY=test_sk_xxxxx

# Optional
FIREBASE_PROJECT_ID=unoa-xxxxx
PASS_CLIENT_ID=xxxxx           # Korean identity verification
PII_ENCRYPTION_KEY=...         # 32+ char encryption key
USE_MOCK_DATA=false            # Set true for mock data development
PAYMENT_TEST_MODE=true
```

Flutter build with dart-define:
```bash
flutter run --dart-define=SENTRY_DSN=$SENTRY_DSN \
             --dart-define=SUPABASE_URL=$SUPABASE_URL \
             --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
             --dart-define=ENVIRONMENT=development
```

## Development Commands

```bash
# Run the app
flutter run

# Run on web
flutter run -d chrome

# Run tests
flutter test

# Run specific test
flutter test test/data/models/broadcast_message_test.dart

# Analyze code
flutter analyze

# Build for production
flutter build web
flutter build apk
flutter build appbundle  # Google Play

# Code generation (freezed, json_serializable, riverpod_generator)
dart run build_runner build --delete-conflicting-outputs

# Supabase
supabase db push                              # Apply migrations
supabase functions deploy payment-checkout    # Deploy edge function
supabase functions deploy payment-webhook
```

## Supabase Database

### Key Tables
- `user_profiles` - User profiles with role-based access
- `channels` - One per artist/creator
- `subscriptions` - User-channel subscriptions with tier and age tracking
- `messages` - All messages with delivery_scope
- `message_delivery` - Per-user read state for broadcasts
- `reply_quota` - Token tracking per user-channel
- `wallets` - User DT balances
- `dt_donations` - Donation records
- `ledger_entries` - Financial transaction log
- `policy_config` - JSON-based configurable rules
- `identity_verifications` - Korean identity verification records
- `creator_payout_accounts` - Creator payout bank info (encrypted)
- `funding_campaigns` - Crowdfunding campaigns
- `question_cards` / `daily_question_sets` - Question card system

### Row Level Security (RLS)
All tables have RLS policies. Key rules:
- Users can only update their own profile
- Fans can only see: broadcasts from subscribed channels, their own replies, artist replies to them
- Artists can see all fan messages in their channel
- Wallet/ledger restricted to own records
- Admin policies for moderation

### Edge Functions (13 total)
| Function | Purpose |
|----------|---------|
| `payment-checkout` | TossPayments checkout session creation |
| `payment-webhook` | Payment webhook with HMAC-SHA256 verification |
| `refund-process` | Refund processing |
| `payout-calculate` | Creator payout calculation |
| `payout-statement` | Payout statement (PDF) generation |
| `funding-pledge` | Campaign pledge processing |
| `funding-studio-submit` | Studio funding submission |
| `funding-admin-review` | Campaign review workflow |
| `ai-reply-suggest` | AI-powered reply suggestions for creators |
| `verify-identity` | PASS identity verification |
| `refresh-fallback-quotas` | Daily reply token refresh |
| `scheduled-dispatcher` | Cron-based scheduled tasks |

## External Services

| Service | Purpose | Config |
|---------|---------|--------|
| Supabase | Backend (DB, Auth, Storage, Realtime, Edge Functions) | `SUPABASE_URL`, `SUPABASE_ANON_KEY` |
| Sentry | Error monitoring | `SENTRY_DSN` |
| Firebase | FCM push notifications + Analytics | `FIREBASE_PROJECT_ID` |
| TossPayments | Payment processing (Korean PG) | `TOSS_CLIENT_KEY`, `TOSS_SECRET_KEY` |
| PASS | Korean identity verification | `PASS_CLIENT_ID` |

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
4. Add provider in `lib/providers/` if state management needed

### Adding a New Model
1. Create `lib/data/models/{model}.dart`
2. Include `fromJson()` and `toJson()` methods
3. Add mock data in `lib/data/mock/mock_data.dart`
4. If using freezed: run `dart run build_runner build --delete-conflicting-outputs`

### Adding a New Repository
1. Define abstract interface in `lib/data/repositories/`
2. Create mock implementation for development
3. Create Supabase implementation for production
4. Register via Riverpod in `lib/providers/repository_providers.dart`
5. Export from `lib/data/repositories/repositories.dart`

### Adding a New Provider
1. Create `lib/providers/{feature}_provider.dart`
2. Use Riverpod patterns (StateNotifier, FutureProvider, etc.)
3. Export from `lib/providers/providers.dart`

### Working with Theme Colors
```dart
// Direct access (static)
AppColors.primary500
AppColors.surfaceLight

// Theme-aware (recommended)
final colors = Theme.of(context).extension<AppColorsExtension>()!;
colors.surface  // Auto-switches between light/dark
```

### Creating Reusable Widgets
Place in `lib/shared/widgets/` with:
- Clear constructor parameters
- Theme-aware colors
- Support for both light and dark modes
- Export from `lib/shared/widgets/widgets.dart`

### Using Settings Widgets
```dart
import '../../shared/widgets/settings_widgets.dart';

SettingsSectionTitle(title: '계정'),
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

## Testing

### Test Structure
```
test/
├── data/models/         # Model unit tests (serialization, equality)
├── integration/         # Flow tests (chat, payment)
├── providers/           # Provider state tests
└── widget_test.dart     # Basic widget tests
```

- Mock data available via `MockData` class
- Repository interfaces allow easy mocking (use `MockChatRepository`)
- Use `mockito` for mocking dependencies

## Design References

The `stitch/` directory contains design reference screenshots:
- `uno_a_home_screen/` - Home screen designs
- `uno_a_chat_list_screen/` - Chat list designs
- `uno_a_artist_chat_thread/` - Chat thread designs
- `uno_a_discover_screen/` - Discover screen designs
- `uno_a_my_profile_screen/` - Profile screen designs
- `uno_a_wallet_&_dt_screen/` - Wallet/DT designs
- `uno_a_artist_profile_screen/` - Artist profile designs
- `uno_a_chat_list_empty_state/` - Empty state designs

Each folder contains `screen.png` and `code.html` for reference.

## Enterprise Components

### Skeleton Loading
```dart
import '../../shared/widgets/skeleton_loader.dart';

SkeletonLoader(width: 100, height: 20)
SkeletonLoader.circle(size: 48)
SkeletonLoader.text(width: 120)
SkeletonLoader.card(width: 200, height: 100)

SkeletonListTile(showAvatar: true, showSubtitle: true)
SkeletonCard(width: 200, height: 120)
SkeletonMessageBubble(isFromArtist: true)
```

### Error Handling
```dart
import '../../shared/widgets/error_boundary.dart';

ErrorDisplay(error: error, onRetry: () => _loadData())
EmptyState(title: '아직 메시지가 없어요', message: '첫 메시지를 보내보세요', icon: Icons.inbox_outlined)
LoadingState(message: '로딩 중...')

// Custom exceptions
NetworkException, TimeoutException, NotFoundException, UnauthorizedException
```

### Buttons & Badges
```dart
import '../../shared/widgets/primary_button.dart';

PrimaryButton(text: '보내기', onPressed: () {})  // Uses primary600 for WCAG
SecondaryButton(text: '취소', onPressed: () {})
DestructiveButton(text: '삭제', onPressed: () {})
PrimaryButton.premium(text: 'VIP', onPressed: () {})  // Shimmer/glow effect

BadgeChip(type: BadgeType.vip, label: 'VIP')
```

### Premium Effects
```dart
import '../../shared/widgets/premium_shimmer.dart';

PremiumShimmer.balance(child: widget)   // Subtle shimmer for balance
PremiumShimmer.vip(child: widget)       // VIP badge shimmer
PremiumShimmer.button(child: widget)    // CTA button shimmer
GlowWrapper(child: widget)             // Ambient glow effect
PremiumContainer(child: widget)        // Premium card container
```

### Message Actions
```dart
import '../../shared/widgets/message_action_sheet.dart';

// 6 emoji reactions: ❤️👍🎉😂✨🔥
// Actions: Copy, Edit, Pin, Delete
MessageActionSheet.show(context, message: msg, onReaction: ..., onAction: ...)
```

### Animation Utilities
```dart
import '../../core/utils/animation_utils.dart';

FadeInAnimation(child: widget, delay: Duration(milliseconds: 100))
SlideFadeAnimation.fromBottom(child: widget)
SlideFadeAnimation.fromLeft(child: widget)
ScaleOnTap(onTap: () => handleTap(), child: widget)
StaggeredListAnimation(children: listWidgets)
AnimatedCounter(value: 1250, prefix: '₩', suffix: ' DT')
```

### Responsive Design
```dart
import '../../core/utils/responsive_helper.dart';

final helper = ResponsiveHelper(context);
if (helper.isPhone) { ... }
if (helper.isTablet) { ... }

ResponsiveLayout(phone: PhoneWidget(), tablet: TabletWidget(), desktop: DesktopWidget())
AdaptiveContainer(maxWidth: 600, child: content)

// Extension
context.responsive.isPhone
context.responsiveValue(phone: 2, tablet: 3, desktop: 4)
```

### Accessibility
```dart
import '../../core/utils/accessibility_helper.dart';

SemanticButton(label: '보내기', child: button)
SemanticImage(label: '아티스트 프로필', child: image)
ScreenReaderAnnouncement.announce(context, '메시지를 보냈습니다')
AccessibleTapTarget(semanticLabel: '뒤로가기', onTap: () => context.pop(), child: Icon(Icons.arrow_back))

widget.withButtonSemantics('버튼 설명')
decorativeWidget.excludeSemantics()
```

## Key Dependencies

### Core
- `flutter_riverpod: ^2.4.10` - State management
- `go_router: ^14.0.0` - Navigation
- `supabase_flutter: ^2.3.4` - Backend
- `provider: ^6.1.2` - Legacy state management (being migrated)

### UI
- `google_fonts: ^6.1.0` - Pretendard font
- `cached_network_image: ^3.3.1` - Image caching
- `shimmer: ^3.0.0` - Shimmer effects

### Media
- `image_picker: ^1.0.7` - Image selection
- `video_player: ^2.8.2` / `chewie: ^1.7.4` - Video playback
- `record: ^5.1.2` - Audio recording
- `just_audio: ^0.9.40` - Audio playback

### Monitoring
- `sentry_flutter: ^8.10.0` - Error monitoring
- `firebase_core: ^3.8.1` / `firebase_messaging: ^15.1.7` / `firebase_analytics: ^11.3.6`

### Code Generation (dev)
- `freezed: ^2.4.7` / `freezed_annotation: ^2.4.1` - Immutable data classes
- `json_serializable: ^6.7.1` / `json_annotation: ^4.8.1` - JSON serialization
- `riverpod_generator: ^2.3.11` / `riverpod_annotation: ^2.3.5` - Riverpod codegen
- `build_runner: ^2.4.8` - Code generation runner
- `mockito: ^5.4.4` - Test mocking

## Important Notes for AI Assistants

1. **Korean Language**: UI labels are in Korean. Preserve existing translations.
2. **WCAG Compliance**: Maintain 4.5:1 contrast ratios for text.
3. **Fromm/Bubble Style**: This mimics Korean fan messaging apps - maintain the 1:1 illusion for fans.
4. **Token System**: Fans need tokens to reply; don't allow unlimited messaging.
5. **Subscription Age**: Character limits depend on how long a user has been subscribed.
6. **Mock vs Real**: Both mock and Supabase repository implementations exist. Mock is used for dev, Supabase for prod.
7. **Theme Toggle**: Dark/light mode toggle is in Settings screen (`/settings`), not in bottom nav.
8. **Platform Detection**: `AppScaffold` shows phone frame on web only; mobile gets full screen.
9. **Use Enterprise Components**: For new features, use skeleton loaders, error boundaries, animation utilities, and premium effects.
10. **Accessibility**: All interactive elements should have semantic labels for screen readers.
11. **Responsive**: Use ResponsiveLayout for screens that need tablet/desktop support.
12. **Riverpod**: Use Riverpod for new state management. Avoid creating new Provider-based code.
13. **Code Generation**: After modifying freezed/json_serializable models, run `dart run build_runner build --delete-conflicting-outputs`.
14. **Architecture Docs**: See `docs/ARCHITECTURE.md` for detailed system architecture, data flows, and security design.
15. **Two User Modes**: The app has distinct Fan and Creator experiences with separate bottom nav bars and route shells.
