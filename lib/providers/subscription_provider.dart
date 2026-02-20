import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/business_config.dart';
import '../data/mock/mock_data.dart';
import 'auth_provider.dart';

/// Subscription data model (lightweight view for list screens)
class SubscriptionInfo {
  final String id;
  final String artistId;
  final String artistName;
  final String avatarUrl;
  final String tier;
  final int price;
  final DateTime nextBillingDate;
  final bool isExpiringSoon;

  const SubscriptionInfo({
    required this.id,
    required this.artistId,
    required this.artistName,
    required this.avatarUrl,
    required this.tier,
    required this.price,
    required this.nextBillingDate,
    this.isExpiringSoon = false,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    // DB column: expires_at (nullable timestamp)
    final nextBilling = DateTime.tryParse(
          json['expires_at'] as String? ?? '',
        ) ??
        DateTime.now().add(const Duration(days: 30));

    final daysUntilExpiry = nextBilling.difference(DateTime.now()).inDays;

    // Extract channel info from joined data
    final channel = json['channels'] as Map<String, dynamic>?;

    // Derive price from tier via BusinessConfig (no price_krw column in subscriptions)
    final tier = json['tier'] as String? ?? 'BASIC';
    final price = BusinessConfig.tierPricesKrw[tier.toUpperCase()] ?? 0;

    return SubscriptionInfo(
      id: json['id'] as String,
      artistId: json['channel_id'] as String? ?? '',
      artistName: channel?['name'] as String? ?? '',
      avatarUrl: channel?['avatar_url'] as String? ?? '',
      tier: tier,
      price: price,
      nextBillingDate: nextBilling,
      isExpiringSoon: daysUntilExpiry <= 7,
    );
  }

  String get formattedPrice {
    return '${price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        )}원';
  }

  String get formattedNextBilling {
    return '${nextBillingDate.year}.${nextBillingDate.month.toString().padLeft(2, '0')}.${nextBillingDate.day.toString().padLeft(2, '0')}';
  }
}

/// Subscription state
sealed class SubscriptionState {
  const SubscriptionState();
}

class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();
}

class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();
}

class SubscriptionLoaded extends SubscriptionState {
  final List<SubscriptionInfo> subscriptions;

  const SubscriptionLoaded({required this.subscriptions});
}

class SubscriptionError extends SubscriptionState {
  final String message;
  final Object? error;

  const SubscriptionError(this.message, [this.error]);
}

/// Subscription notifier
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final Ref _ref;

  SubscriptionNotifier(this._ref) : super(const SubscriptionInitial()) {
    _initialize();
  }

  void _initialize() {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated || next is AuthDemoMode) {
        loadSubscriptions();
      } else if (next is AuthUnauthenticated) {
        state = const SubscriptionInitial();
      }
    });

    final authState = _ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      loadSubscriptions();
    } else if (authState is AuthDemoMode) {
      _loadDemoSubscriptions();
    }
  }

  /// Load subscriptions from Supabase
  Future<void> loadSubscriptions() async {
    final authState = _ref.read(authProvider);

    // Demo fallback
    if (authState is AuthDemoMode) {
      _loadDemoSubscriptions();
      return;
    }

    if (authState is! AuthAuthenticated) return;

    state = const SubscriptionLoading();

    try {
      final client = _ref.read(supabaseClientProvider);
      final uid = authState.user.id;

      final response = await client
          .from('subscriptions')
          .select('*, channels!channel_id(*)')
          .eq('user_id', uid)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final subs = (response as List)
          .map((json) => SubscriptionInfo.fromJson(json))
          .toList();

      state = SubscriptionLoaded(subscriptions: subs);
    } catch (e) {
      state = SubscriptionError('구독 정보를 불러오는데 실패했습니다.', e);
    }
  }

  /// Demo mode fallback
  void _loadDemoSubscriptions() {
    final demoSubs = MockData.mySubscriptions
        .map((sub) => SubscriptionInfo(
              id: sub.id,
              artistId: sub.artistId,
              artistName: sub.artistName,
              avatarUrl: sub.avatarUrl,
              tier: sub.tier,
              price: sub.price,
              nextBillingDate: sub.nextBillingDate,
              isExpiringSoon: sub.isExpiringSoon,
            ))
        .toList();

    state = SubscriptionLoaded(subscriptions: demoSubs);
  }

  /// Refresh
  Future<void> refresh() async {
    await loadSubscriptions();
  }
}

/// Main subscription provider
final mySubscriptionsProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier(ref);
});

/// Subscription list convenience provider
final subscriptionListProvider = Provider<List<SubscriptionInfo>>((ref) {
  final state = ref.watch(mySubscriptionsProvider);
  if (state is SubscriptionLoaded) {
    return state.subscriptions;
  }
  return const [];
});

/// Subscription count convenience provider
final subscriptionCountProvider = Provider<int>((ref) {
  return ref.watch(subscriptionListProvider).length;
});
