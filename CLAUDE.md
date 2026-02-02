# CLAUDE.md - UNO A Flutter Application

This file provides guidance for AI assistants working with the UNO A codebase.

## Project Overview

**UNO A** is a Korean artist-to-fan messaging platform built with Flutter, similar to Fromm/Bubble. It enables K-pop artists to send broadcast messages to subscribers, who can then reply using a token-based system.

### Core Features
- **Broadcast Chat System**: Artists send messages to all subscribers; fans see a personalized 1:1 chat experience
- **Token-Based Replies**: Fans get 3 reply tokens per artist broadcast
- **DT (Digital Token) Currency**: In-app currency for donations and premium features
- **Subscription Tiers**: BASIC, STANDARD, VIP with different perks
- **Character Limit Progression**: Reply limits increase based on subscription age (50-300 chars)

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
│   │   ├── constants/
│   │   │   └── asset_paths.dart  # Image/asset path constants
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
│   │   ├── chat/                 # Fan chat screens
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
│       └── widgets/              # Reusable UI components
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
- **ThemeProvider**: Global theme state via Provider
- **Local state**: StatefulWidgets for screen-level state
- Repositories return Streams for real-time data

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

## Important Notes for AI Assistants

1. **Korean Language**: UI labels are in Korean. Preserve existing translations.
2. **WCAG Compliance**: Maintain 4.5:1 contrast ratios for text.
3. **Fromm/Bubble Style**: This mimics Korean fan messaging apps - maintain the 1:1 illusion.
4. **Token System**: Fans need tokens to reply; don't allow unlimited messaging.
5. **Subscription Age**: Character limits depend on how long a user has been subscribed.
6. **Mock vs Real**: Currently uses mock data; real Supabase integration pending.
