import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/chat/chat_list_screen.dart';
import '../features/chat/chat_thread_screen_v2.dart';
import '../features/funding/funding_screen.dart';
import '../features/discover/discover_screen.dart';
import '../features/profile/my_profile_screen.dart';
import '../features/profile/artist_profile_screen.dart';
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
import '../features/creator/creator_analytics_screen.dart';
import '../features/creator/creator_dm_screen.dart';
import '../features/creator/creator_crm_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/funding/creator_funding_screen.dart';
import '../features/funding/create_campaign_screen.dart';
import '../features/creator/creator_dashboard_screen.dart';
import '../features/creator/creator_profile_screen.dart';
import '../features/creator/creator_chat_tab_screen.dart';
import '../features/creator/creator_my_channel_screen.dart';
import '../features/creator/creator_profile_edit_screen.dart';
import '../shared/widgets/app_scaffold.dart';
import '../shared/widgets/bottom_nav_bar.dart';
import '../shared/widgets/creator_bottom_nav_bar.dart';

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
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _creatorShellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.login,
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
        // 채팅 - 내 채널 + 구독 아티스트 리스트
        GoRoute(
          path: '/creator/chat',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CreatorChatTabScreen(),
          ),
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
    // Full Screen Routes (no bottom navigation)
    // ============================================
    GoRoute(
      path: '/chat/:artistId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ChatThreadScreenV2(
        channelId: state.pathParameters['artistId']!,
      ),
    ),
    GoRoute(
      path: '/artist/:artistId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ArtistProfileScreen(
        artistId: state.pathParameters['artistId']!,
      ),
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

    // Creator Profile Edit
    GoRoute(
      path: '/creator/profile/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreatorProfileEditScreen(),
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
        context.go('/creator/dashboard');  // 대시보드 - CRM 통합
        break;
      case 1:
        context.go('/creator/chat');  // 채팅 - 내 채널 + 구독
        break;
      case 2:
        context.go('/creator/funding');  // 펀딩 - 내 캠페인 + 탐색
        break;
      case 3:
        context.go('/creator/discover');  // 탐색 - 아티스트 탐색
        break;
      case 4:
        context.go('/creator/profile');  // 프로필
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
