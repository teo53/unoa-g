import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../core/config/app_config.dart';
import '../features/home/home_screen.dart';
import '../features/chat/chat_list_screen.dart';
import '../features/chat/chat_thread_screen_v2.dart';
import '../features/funding/funding_screen.dart';
import '../features/discover/discover_screen.dart';
import '../features/profile/my_profile_screen.dart';
import '../features/profile/artist_profile_screen.dart';
import '../features/profile/fan_profile_edit_screen.dart';
import '../features/wallet/wallet_screen.dart';
import '../features/wallet/dt_charge_screen.dart';
import '../features/wallet/transaction_history_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/notification_settings_screen.dart';
import '../features/settings/account_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/subscriptions/subscriptions_screen.dart';
import '../features/help/help_center_screen.dart';
import '../features/artist_inbox/artist_inbox_screen.dart';
import '../features/creator/creator_crm_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/age_verification_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/funding/creator_funding_screen.dart';
import '../features/funding/create_campaign_screen.dart';
import '../features/creator/creator_dashboard_screen.dart';
import '../features/creator/creator_profile_screen.dart';
import '../features/creator/creator_chat_tab_screen.dart';
import '../features/creator/creator_my_channel_screen.dart';
import '../features/creator/settlement_history_screen.dart';
import '../features/settings/tax_settings_screen.dart';

import '../data/models/poll_draft.dart';
import '../features/creator/creator_content_screen.dart';
import '../features/creator/creator_profile_edit_screen.dart';
import '../features/private_card/private_card_compose_screen.dart';
import '../features/settings/birthday_settings_screen.dart';
import '../features/settings/terms_screen.dart';
import '../features/settings/privacy_screen.dart';
import '../features/settings/company_info_screen.dart';
import '../features/settings/refund_policy_screen.dart';
import '../features/settings/fee_policy_screen.dart';
import '../features/settings/funding_terms_screen.dart';
import '../features/settings/moderation_policy_screen.dart';
import '../features/settings/consent_history_screen.dart';
import '../features/settings/blocked_users_screen.dart';
import '../features/moments/moments_screen.dart';
import '../features/challenges/challenges_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/admin_creators_screen.dart';
import '../features/admin/admin_settlements_screen.dart';
import '../features/admin/admin_settings_screen.dart';
import '../features/fan_ads/fan_ad_purchase_screen.dart';
import '../features/fan_ads/my_ads_screen.dart';
import '../shared/widgets/app_scaffold.dart';
import '../shared/widgets/bottom_nav_bar.dart';
import '../shared/widgets/creator_bottom_nav_bar.dart';
import '../shared/widgets/admin_bottom_nav_bar.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String chat = '/chat';
  static const String chatThread = '/chat/:artistId';
  static const String funding = '/funding';
  static const String discover = '/discover';
  static const String profile = '/profile';
  static const String artistProfile = '/artist/:artistId';
  static const String wallet = '/wallet';
  static const String walletCharge = '/wallet/charge';
  static const String walletHistory = '/wallet/history';
  static const String settings = '/settings';
  static const String settingsNotifications = '/settings/notifications';
  static const String settingsAccount = '/settings/account';
  static const String notifications = '/notifications';
  static const String subscriptions = '/subscriptions';
  static const String help = '/help';

  // Legacy Artist Inbox Routes (kept for backward compatibility)
  static const String artistInbox = '/artist/inbox';
  static const String artistInboxThread = '/artist/inbox/:fanUserId';

  // Creator Routes (with bottom navigation) - 5탭 구조
  static const String creatorDashboard = '/creator/dashboard';
  static const String creatorChat = '/creator/chat';
  static const String creatorFunding = '/creator/funding';
  static const String creatorDiscover = '/creator/discover';
  static const String creatorProfile = '/creator/profile';
  static const String createCampaign = '/creator/funding/create';
  static const String editCampaign = '/creator/funding/edit/:campaignId';
  static const String creatorContent = '/creator/content';
  static const String creatorPrivateCard = '/creator/private-card';
  static const String creatorPrivateCardCompose =
      '/creator/private-card/compose';
  static const String birthdaySettings = '/settings/birthday';
  static const String settingsTerms = '/settings/terms';
  static const String settingsPrivacy = '/settings/privacy';
  static const String settingsCompanyInfo = '/settings/company-info';
  static const String settingsRefundPolicy = '/settings/refund-policy';
  static const String settingsFeePolicy = '/settings/fee-policy';
  static const String settingsFundingTerms = '/settings/funding-terms';
  static const String forgotPassword = '/forgot-password';
  static const String guardianConsent = '/guardian-consent';
  static const String settingsModerationPolicy = '/settings/moderation-policy';
  static const String settingsConsentHistory = '/settings/consent-history';
  static const String settingsBlockedUsers = '/settings/blocked-users';
  static const String settingsTax = '/settings/tax';
  static const String creatorSettlement = '/creator/settlement';

  // Admin Routes (with bottom navigation) - 4탭 구조
  static const String adminDashboard = '/admin/dashboard';
  static const String adminCreators = '/admin/creators';
  static const String adminSettlements = '/admin/settlements';
  static const String adminSettings = '/admin/settings';

  // Fan Ad Routes (full screen)
  static const String fanAdsPurchase = '/fan-ads/purchase';
  static const String myAds = '/my-ads';
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _creatorShellNavigatorKey =
    GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _adminShellNavigatorKey =
    GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    try {
      final container = ProviderScope.containerOf(context);
      final authState = container.read(authProvider);
      final isLoggedIn =
          authState is AuthAuthenticated || authState is AuthDemoMode;
      final path = state.uri.path;
      final isAuthRoute = path == '/login' || path == '/register';

      // 데모 모드 활성화 시 비로그인 홈화면 스킵 → 바로 로그인(팬/크리에이터 선택)으로
      if (!isLoggedIn && path == '/' && AppConfig.enableDemoMode) {
        return '/login';
      }

      // Creator routes require authentication
      if (!isLoggedIn && path.startsWith('/creator/')) {
        return '/login?next=${Uri.encodeComponent(state.uri.toString())}';
      }

      // Fan users cannot access creator routes
      if (isLoggedIn && path.startsWith('/creator/')) {
        final authState = container.read(authProvider);
        UserAuthProfile? profile;
        if (authState is AuthAuthenticated) {
          profile = authState.profile;
        } else if (authState is AuthDemoMode) {
          profile = authState.demoProfile;
        }
        if (profile != null && !profile.isCreator) {
          return '/'; // 팬은 홈으로 리다이렉트
        }
      }

      // Admin routes require authentication + admin role
      if (!isLoggedIn && path.startsWith('/admin/')) {
        return '/login?next=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (isLoggedIn && path.startsWith('/admin/')) {
        final authState = container.read(authProvider);
        UserAuthProfile? profile;
        if (authState is AuthAuthenticated) {
          profile = authState.profile;
        } else if (authState is AuthDemoMode) {
          profile = authState.demoProfile;
        }
        if (profile != null && !profile.isAdmin) {
          return '/'; // 비관리자는 홈으로 리다이렉트
        }
      }

      // CRM은 데모 모드에서 접근 불가 (관리자 계정 전용)
      if (authState is AuthDemoMode && path == '/creator/crm') {
        return '/creator/dashboard';
      }

      // Redirect authenticated users away from login/register
      if (isLoggedIn && isAuthRoute) {
        final auth = container.read(authProvider);
        if (auth is AuthDemoMode) {
          if (auth.demoProfile.role == 'admin') {
            return '/admin/dashboard';
          }
          if (auth.demoProfile.role == 'creator') {
            return '/creator/dashboard';
          }
        }
        return '/';
      }
    } catch (e) {
      // ProviderScope not available yet (e.g., during initial build)
      assert(() {
        debugPrint('[AppRouter] redirect error: $e');
        return true;
      }());
    }
    return null;
  },
  routes: [
    // ============================================
    // Fan Shell Route (with fan bottom navigation)
    // ============================================
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainShell(
          currentPath: state.uri.path,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/chat',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ChatListScreen(),
          ),
        ),
        GoRoute(
          path: '/funding',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FundingScreen(),
          ),
        ),
        GoRoute(
          path: '/discover',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DiscoverScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MyProfileScreen(),
          ),
        ),
      ],
    ),

    // ================================================
    // Creator Shell Route (with creator bottom navigation)
    // 5탭 구조: 대시보드, 채팅, 펀딩, 탐색, 프로필
    // ================================================
    ShellRoute(
      navigatorKey: _creatorShellNavigatorKey,
      builder: (context, state, child) {
        return CreatorShell(
          currentPath: state.uri.path,
          child: child,
        );
      },
      routes: [
        // 대시보드 - CRM 통합 (수익, 통계, 팬 관리)
        GoRoute(
          path: '/creator/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CreatorDashboardScreen(),
          ),
        ),
        // 채팅 - 내 채널 + 프라이빗 카드 + 구독 아티스트 (3서브탭)
        GoRoute(
          path: '/creator/chat',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final prefillText = extra?['prefillText'] as String?;
            final pollDraft = extra?['pollDraft'] as PollDraft?;
            final pollComment = extra?['pollComment'] as String?;
            return NoTransitionPage(
              child: CreatorChatTabScreen(
                prefillText: prefillText,
                pollDraft: pollDraft,
                pollComment: pollComment,
              ),
            );
          },
        ),
        // 펀딩 - 내 캠페인 관리 + 탐색
        GoRoute(
          path: '/creator/funding',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CreatorFundingScreen(),
          ),
        ),
        // 탐색 - 다른 아티스트 탐색 (팬용 탐색 화면 재사용)
        GoRoute(
          path: '/creator/discover',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DiscoverScreen(),
          ),
        ),
        // 프로필
        GoRoute(
          path: '/creator/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CreatorProfileScreen(),
          ),
        ),
      ],
    ),

    // ============================================
    // Admin Shell Route (with admin bottom navigation)
    // 4탭 구조: 대시보드, 크리에이터, 정산, 설정
    // ============================================
    ShellRoute(
      navigatorKey: _adminShellNavigatorKey,
      builder: (context, state, child) {
        return AdminShell(
          currentPath: state.uri.path,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/admin/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminDashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/creators',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminCreatorsScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/settlements',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminSettlementsScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminSettingsScreen(),
          ),
        ),
      ],
    ),

    // ============================================
    // Full Screen Routes (no bottom navigation)
    // ============================================
    GoRoute(
      path: '/chat/:artistId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final artistId = state.pathParameters['artistId'];
        if (artistId == null || artistId.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('잘못된 접근입니다.')),
          );
        }
        return ChatThreadScreenV2(channelId: artistId);
      },
    ),
    GoRoute(
      path: '/artist/:artistId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final artistId = state.pathParameters['artistId'];
        if (artistId == null || artistId.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('잘못된 접근입니다.')),
          );
        }
        return ArtistProfileScreen(artistId: artistId);
      },
    ),
    // Fan Profile Edit
    GoRoute(
      path: '/profile/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FanProfileEditScreen(),
    ),
    GoRoute(
      path: '/wallet',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const WalletScreen(),
    ),
    GoRoute(
      path: '/wallet/charge',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DtChargeScreen(),
    ),
    GoRoute(
      path: '/wallet/history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TransactionHistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/account',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: '/settings/birthday',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return BirthdaySettingsScreen(
          channelId: extra?['channelId'] as String? ?? '',
          initialMonth: extra?['initialMonth'] as int?,
          initialDay: extra?['initialDay'] as int?,
          initialVisible: extra?['initialVisible'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      path: '/settings/terms',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TermsScreen(),
    ),
    GoRoute(
      path: '/settings/privacy',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PrivacyScreen(),
    ),
    GoRoute(
      path: '/settings/company-info',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CompanyInfoScreen(),
    ),
    GoRoute(
      path: '/settings/refund-policy',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RefundPolicyScreen(),
    ),
    GoRoute(
      path: '/settings/fee-policy',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FeePolicyScreen(),
    ),
    GoRoute(
      path: '/settings/funding-terms',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FundingTermsScreen(),
    ),
    GoRoute(
      path: '/settings/moderation-policy',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ModerationPolicyScreen(),
    ),
    GoRoute(
      path: '/settings/consent-history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ConsentHistoryScreen(),
    ),
    GoRoute(
      path: '/settings/blocked-users',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BlockedUsersScreen(),
    ),
    GoRoute(
      path: '/moments',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MomentsScreen(),
    ),
    GoRoute(
      path: '/challenges',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ChallengesScreen(
        channelId: state.uri.queryParameters['channelId'],
      ),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/subscriptions',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SubscriptionsScreen(),
    ),
    GoRoute(
      path: '/help',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const HelpCenterScreen(),
    ),

    // Legacy Artist Inbox Routes (for backward compatibility from profile)
    GoRoute(
      path: '/artist/inbox',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final channelId = state.uri.queryParameters['channelId'] ?? 'channel_1';
        return ArtistInboxScreen(channelId: channelId, showBackButton: true);
      },
    ),
    GoRoute(
      path: '/artist/inbox/:fanUserId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        return ArtistInboxScreen(
          channelId: state.uri.queryParameters['channelId'] ?? 'channel_1',
          showBackButton: true,
        );
      },
    ),
    // Auth Routes
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/guardian-consent',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AgeVerificationScreen(),
    ),

    // Creator Settlement History (full screen)
    GoRoute(
      path: '/creator/settlement',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettlementHistoryScreen(),
    ),

    // Tax Settings (full screen)
    GoRoute(
      path: '/settings/tax',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TaxSettingsScreen(),
    ),

    // Creator Private Card Compose (full screen)
    GoRoute(
      path: '/creator/private-card/compose',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PrivateCardComposeScreen(),
    ),

    // Creator CRM (full screen)
    GoRoute(
      path: '/creator/crm',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreatorCRMScreen(),
    ),

    // Creator My Channel (broadcast chat)
    GoRoute(
      path: '/creator/my-channel',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreatorMyChannelScreen(),
    ),

    // Creator Profile Edit (3-tab: 기본 정보, 콘텐츠, 테마 & 소셜)
    GoRoute(
      path: '/creator/profile/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreatorProfileEditScreen(),
    ),

    // Creator Content Management (WYSIWYG)
    GoRoute(
      path: '/creator/content',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreatorContentScreen(),
    ),

    // Creator Funding Detail Routes (full screen)
    GoRoute(
      path: '/creator/funding/create',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreateCampaignScreen(),
    ),
    GoRoute(
      path: '/creator/funding/edit/:campaignId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => CreateCampaignScreen(
        campaignId: state.pathParameters['campaignId'],
      ),
    ),

    // Fan Ad Purchase (full screen)
    GoRoute(
      path: '/fan-ads/purchase',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => FanAdPurchaseScreen(
        artistId: state.uri.queryParameters['artistId'],
      ),
    ),

    // My Ads (full screen)
    GoRoute(
      path: '/my-ads',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MyAdsScreen(),
    ),
  ],
);

/// Fan Shell - Main shell for fan users with bottom navigation
class MainShell extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const MainShell({
    super.key,
    required this.child,
    required this.currentPath,
  });

  int _calculateIndex(String path) {
    if (path == '/') return 0;
    if (path.startsWith('/chat')) return 1;
    if (path.startsWith('/funding')) return 2;
    if (path.startsWith('/discover')) return 3;
    if (path.startsWith('/profile')) return 4;
    return 0;
  }

  void _navigateToTab(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/chat');
        break;
      case 2:
        context.go('/funding');
        break;
      case 3:
        context.go('/discover');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomNavigationBar: BottomNavBar(
        currentIndex: _calculateIndex(currentPath),
        onTap: (index) => _navigateToTab(context, index),
      ),
      child: child,
    );
  }
}

/// Creator Shell - Shell for creator users with creator bottom navigation
/// 5탭 구조: 대시보드, 채팅, 펀딩, 탐색, 프로필
class CreatorShell extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const CreatorShell({
    super.key,
    required this.child,
    required this.currentPath,
  });

  int _calculateIndex(String path) {
    if (path.startsWith('/creator/dashboard')) return 0;
    if (path.startsWith('/creator/chat')) return 1;
    if (path.startsWith('/creator/funding')) return 2;
    if (path.startsWith('/creator/discover')) return 3;
    if (path.startsWith('/creator/profile')) return 4;
    return 0;
  }

  void _navigateToTab(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/creator/dashboard'); // 대시보드 - CRM 통합
        break;
      case 1:
        context.go('/creator/chat'); // 채팅 - 내 채널 + 프라이빗 카드 + 구독
        break;
      case 2:
        context.go('/creator/funding'); // 펀딩 - 내 캠페인 + 탐색
        break;
      case 3:
        context.go('/creator/discover'); // 탐색 - 아티스트 탐색
        break;
      case 4:
        context.go('/creator/profile'); // 프로필
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomNavigationBar: CreatorBottomNavBar(
        currentIndex: _calculateIndex(currentPath),
        onTap: (index) => _navigateToTab(context, index),
      ),
      child: child,
    );
  }
}

/// Admin Shell - Shell for admin users with admin bottom navigation
/// 4탭 구조: 대시보드, 크리에이터, 정산, 설정
class AdminShell extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const AdminShell({
    super.key,
    required this.child,
    required this.currentPath,
  });

  int _calculateIndex(String path) {
    if (path.startsWith('/admin/dashboard')) return 0;
    if (path.startsWith('/admin/creators')) return 1;
    if (path.startsWith('/admin/settlements')) return 2;
    if (path.startsWith('/admin/settings')) return 3;
    return 0;
  }

  void _navigateToTab(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/admin/dashboard');
        break;
      case 1:
        context.go('/admin/creators');
        break;
      case 2:
        context.go('/admin/settlements');
        break;
      case 3:
        context.go('/admin/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: _calculateIndex(currentPath),
        onTap: (index) => _navigateToTab(context, index),
      ),
      child: child,
    );
  }
}
