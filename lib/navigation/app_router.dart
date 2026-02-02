import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/chat/chat_list_screen.dart';
import '../features/chat/chat_thread_screen.dart';
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
import '../features/artist_inbox/broadcast_compose_screen.dart';
import '../shared/widgets/app_scaffold.dart';
import '../shared/widgets/bottom_nav_bar.dart';

class AppRoutes {
  static const String home = '/';
  static const String chat = '/chat';
  static const String chatThread = '/chat/:artistId';
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

  // Artist Inbox Routes
  static const String artistInbox = '/artist/inbox';
  static const String artistInboxThread = '/artist/inbox/:fanUserId';
  static const String broadcastCompose = '/artist/broadcast/compose';
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.home,
  routes: [
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
    GoRoute(
      path: '/chat/:artistId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ChatThreadScreen(
        artistId: state.pathParameters['artistId']!,
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
    // Artist Inbox Routes
    GoRoute(
      path: '/artist/inbox',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final channelId = state.uri.queryParameters['channelId'] ?? 'channel_1';
        return ArtistInboxScreen(channelId: channelId);
      },
    ),
    GoRoute(
      path: '/artist/inbox/:fanUserId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        // Fan thread screen - would show conversation with specific fan
        // For now, redirect back to inbox
        return ArtistInboxScreen(
          channelId: state.uri.queryParameters['channelId'] ?? 'channel_1',
        );
      },
    ),
    GoRoute(
      path: '/artist/broadcast/compose',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final channelId = state.uri.queryParameters['channelId'];
        return BroadcastComposeScreen(channelId: channelId);
      },
    ),
  ],
);

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
    if (path.startsWith('/discover')) return 2;
    if (path.startsWith('/profile')) return 3;
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
        context.go('/discover');
        break;
      case 3:
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
