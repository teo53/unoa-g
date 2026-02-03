import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_client.dart';
import 'auth_provider.dart';

/// Wallet data model
class Wallet {
  final String id;
  final String userId;
  final int balanceDt;
  final int lifetimePurchasedDt;
  final int lifetimeSpentDt;
  final int lifetimeEarnedDt;
  final int lifetimeRefundedDt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Wallet({
    required this.id,
    required this.userId,
    required this.balanceDt,
    this.lifetimePurchasedDt = 0,
    this.lifetimeSpentDt = 0,
    this.lifetimeEarnedDt = 0,
    this.lifetimeRefundedDt = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      balanceDt: json['balance_dt'] as int? ?? 0,
      lifetimePurchasedDt: json['lifetime_purchased_dt'] as int? ?? 0,
      lifetimeSpentDt: json['lifetime_spent_dt'] as int? ?? 0,
      lifetimeEarnedDt: json['lifetime_earned_dt'] as int? ?? 0,
      lifetimeRefundedDt: json['lifetime_refunded_dt'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Format balance for display
  String get formattedBalance => '${balanceDt.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      )} DT';

  /// Balance in KRW (1 DT = 100 KRW)
  int get balanceKrw => balanceDt * 100;

  String get formattedBalanceKrw => '${balanceKrw.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      )}원';

  Wallet copyWith({
    int? balanceDt,
    int? lifetimePurchasedDt,
    int? lifetimeSpentDt,
    int? lifetimeEarnedDt,
  }) {
    return Wallet(
      id: id,
      userId: userId,
      balanceDt: balanceDt ?? this.balanceDt,
      lifetimePurchasedDt: lifetimePurchasedDt ?? this.lifetimePurchasedDt,
      lifetimeSpentDt: lifetimeSpentDt ?? this.lifetimeSpentDt,
      lifetimeEarnedDt: lifetimeEarnedDt ?? this.lifetimeEarnedDt,
      lifetimeRefundedDt: lifetimeRefundedDt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Ledger entry model
class LedgerEntry {
  final String id;
  final String idempotencyKey;
  final String? fromWalletId;
  final String? toWalletId;
  final int amountDt;
  final String entryType;
  final String? referenceType;
  final String? referenceId;
  final String? description;
  final String status;
  final DateTime createdAt;

  const LedgerEntry({
    required this.id,
    required this.idempotencyKey,
    this.fromWalletId,
    this.toWalletId,
    required this.amountDt,
    required this.entryType,
    this.referenceType,
    this.referenceId,
    this.description,
    required this.status,
    required this.createdAt,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id'] as String,
      idempotencyKey: json['idempotency_key'] as String,
      fromWalletId: json['from_wallet_id'] as String?,
      toWalletId: json['to_wallet_id'] as String?,
      amountDt: json['amount_dt'] as int,
      entryType: json['entry_type'] as String,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      description: json['description'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get formattedAmount => '${amountDt.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      )} DT';

  String get typeDisplayName {
    switch (entryType) {
      case 'purchase':
        return '충전';
      case 'tip':
        return '선물';
      case 'paid_reply':
        return '유료 답장';
      case 'private_card':
        return '프라이빗 카드';
      case 'refund':
        return '환불';
      case 'payout':
        return '출금';
      case 'bonus':
        return '보너스';
      case 'subscription':
        return '구독';
      default:
        return entryType;
    }
  }

  bool get isCredit => toWalletId != null;
  bool get isDebit => fromWalletId != null;
}

/// DT Package model
class DtPackage {
  final String id;
  final String name;
  final String? description;
  final int dtAmount;
  final int bonusDt;
  final int priceKrw;
  final String? badgeText;
  final int displayOrder;

  const DtPackage({
    required this.id,
    required this.name,
    this.description,
    required this.dtAmount,
    this.bonusDt = 0,
    required this.priceKrw,
    this.badgeText,
    this.displayOrder = 0,
  });

  factory DtPackage.fromJson(Map<String, dynamic> json) {
    return DtPackage(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      dtAmount: json['dt_amount'] as int,
      bonusDt: json['bonus_dt'] as int? ?? 0,
      priceKrw: json['price_krw'] as int,
      badgeText: json['badge_text'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  int get totalDt => dtAmount + bonusDt;

  String get formattedPrice => '${priceKrw.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      )}원';

  String get formattedDt => '${dtAmount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      )} DT';

  String? get formattedBonus =>
      bonusDt > 0 ? '+${bonusDt.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (match) => '${match[1]},',
          )} 보너스' : null;
}

/// Wallet state
sealed class WalletState {
  const WalletState();

  /// Convenience getter for wallet (returns null if not loaded)
  Wallet? get wallet {
    if (this is WalletLoaded) {
      return (this as WalletLoaded)._wallet;
    }
    return null;
  }
}

class WalletInitial extends WalletState {
  const WalletInitial();
}

class WalletLoading extends WalletState {
  const WalletLoading();
}

class WalletLoaded extends WalletState {
  final Wallet _wallet;
  final List<LedgerEntry> recentTransactions;
  final List<DtPackage> packages;

  const WalletLoaded({
    required Wallet wallet,
    this.recentTransactions = const [],
    this.packages = const [],
  }) : _wallet = wallet;

  @override
  Wallet get wallet => _wallet;
}

class WalletError extends WalletState {
  final String message;
  final Object? error;

  const WalletError(this.message, [this.error]);
}

/// Wallet notifier
class WalletNotifier extends StateNotifier<WalletState> {
  final Ref _ref;
  StreamSubscription? _walletSubscription;

  WalletNotifier(this._ref) : super(const WalletInitial()) {
    _initialize();
  }

  void _initialize() {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        loadWallet();
      } else if (next is AuthUnauthenticated) {
        _walletSubscription?.cancel();
        state = const WalletInitial();
      }
    });

    // Initial load if already authenticated
    final authState = _ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      loadWallet();
    }
  }

  Future<void> loadWallet() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = const WalletLoading();

    try {
      final client = _ref.read(supabaseClientProvider);

      // Load wallet
      final walletResponse = await client
          .from('wallets')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (walletResponse == null) {
        // Create wallet if doesn't exist
        final newWallet = await client.from('wallets').insert({
          'user_id': user.id,
        }).select().single();

        state = WalletLoaded(
          wallet: Wallet.fromJson(newWallet),
          recentTransactions: const [],
          packages: await _loadPackages(),
        );
      } else {
        final wallet = Wallet.fromJson(walletResponse);

        // Load recent transactions
        final transactions = await _loadRecentTransactions(wallet.id);

        // Load packages
        final packages = await _loadPackages();

        state = WalletLoaded(
          wallet: wallet,
          recentTransactions: transactions,
          packages: packages,
        );

        // Subscribe to wallet changes
        _subscribeToWallet(wallet.id);
      }
    } catch (e) {
      state = WalletError('지갑을 불러오는데 실패했습니다.', e);
    }
  }

  Future<List<LedgerEntry>> _loadRecentTransactions(String walletId) async {
    try {
      final client = _ref.read(supabaseClientProvider);

      final response = await client
          .from('ledger_entries')
          .select()
          .or('from_wallet_id.eq.$walletId,to_wallet_id.eq.$walletId')
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List)
          .map((json) => LedgerEntry.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<DtPackage>> _loadPackages() async {
    try {
      final client = _ref.read(supabaseClientProvider);

      final response = await client
          .from('dt_packages')
          .select()
          .eq('is_active', true)
          .order('display_order');

      return (response as List).map((json) => DtPackage.fromJson(json)).toList();
    } catch (e) {
      // Return default packages if loading fails
      return const [
        DtPackage(id: 'dt_10', name: '10 DT', dtAmount: 10, priceKrw: 1000),
        DtPackage(id: 'dt_50', name: '50 DT', dtAmount: 50, priceKrw: 5000),
        DtPackage(
            id: 'dt_100', name: '100 DT', dtAmount: 100, bonusDt: 5, priceKrw: 10000),
        DtPackage(
            id: 'dt_500',
            name: '500 DT',
            dtAmount: 500,
            bonusDt: 50,
            priceKrw: 50000,
            badgeText: '인기'),
        DtPackage(
            id: 'dt_1000',
            name: '1,000 DT',
            dtAmount: 1000,
            bonusDt: 150,
            priceKrw: 100000,
            badgeText: 'BEST'),
      ];
    }
  }

  void _subscribeToWallet(String walletId) {
    _walletSubscription?.cancel();

    final client = _ref.read(supabaseClientProvider);

    _walletSubscription = client
        .from('wallets')
        .stream(primaryKey: ['id'])
        .eq('id', walletId)
        .listen((data) {
          if (data.isNotEmpty && state is WalletLoaded) {
            final currentState = state as WalletLoaded;
            state = WalletLoaded(
              wallet: Wallet.fromJson(data.first),
              recentTransactions: currentState.recentTransactions,
              packages: currentState.packages,
            );
          }
        });
  }

  /// Check if user can afford amount
  bool canAfford(int amountDt) {
    final currentState = state;
    if (currentState is! WalletLoaded) return false;
    return currentState.wallet.balanceDt >= amountDt;
  }

  /// Request checkout URL for DT purchase
  Future<String?> createPurchaseCheckout(String packageId) async {
    try {
      final client = _ref.read(supabaseClientProvider);
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');

      final response = await client.functions.invoke(
        'payment-checkout',
        body: {
          'userId': user.id,
          'packageId': packageId,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to create checkout');
      }

      return response.data['checkoutUrl'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Request refund for a purchase
  Future<bool> requestRefund(String purchaseId) async {
    try {
      final client = _ref.read(supabaseClientProvider);
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');

      final response = await client.functions.invoke(
        'refund-process',
        body: {
          'userId': user.id,
          'purchaseId': purchaseId,
        },
      );

      if (response.status == 200) {
        // Reload wallet
        await loadWallet();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Send a DT donation to a creator
  Future<Map<String, dynamic>?> sendDonation({
    required String channelId,
    required String creatorId,
    required int amountDt,
    String? messageId,
    bool isAnonymous = false,
  }) async {
    final currentState = state;
    if (currentState is! WalletLoaded) {
      throw Exception('Wallet not loaded');
    }

    if (currentState.wallet.balanceDt < amountDt) {
      throw Exception('Insufficient balance');
    }

    try {
      final client = _ref.read(supabaseClientProvider);
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');

      final wallet = currentState.wallet;

      // Calculate creator share (80%) and platform fee (20%)
      final creatorShare = (amountDt * 0.8).floor();
      final platformFee = amountDt - creatorShare;

      final idempotencyKey =
          'donation:${wallet.id}:$channelId:${DateTime.now().millisecondsSinceEpoch}';

      // Create donation record
      final donation = await client.from('dt_donations').insert({
        'from_user_id': user.id,
        'to_channel_id': channelId,
        'to_creator_id': creatorId,
        'amount_dt': amountDt,
        'message_id': messageId,
        'is_anonymous': isAnonymous,
        'creator_share_dt': creatorShare,
        'platform_fee_dt': platformFee,
      }).select().single();

      // Create ledger entry
      await client.from('ledger_entries').insert({
        'idempotency_key': idempotencyKey,
        'from_wallet_id': wallet.id,
        'amount_dt': amountDt,
        'entry_type': 'tip',
        'reference_type': 'donation',
        'reference_id': donation['id'],
        'description': '후원: $amountDt DT',
        'status': 'completed',
      });

      // Update wallet balance
      await client.from('wallets').update({
        'balance_dt': wallet.balanceDt - amountDt,
        'lifetime_spent_dt': wallet.lifetimeSpentDt + amountDt,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', wallet.id);

      // Reload wallet
      await loadWallet();

      return donation;
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _walletSubscription?.cancel();
    super.dispose();
  }
}

/// Wallet provider
final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(ref);
});

/// Current balance provider (convenience)
final currentBalanceProvider = Provider<int>((ref) {
  final walletState = ref.watch(walletProvider);
  if (walletState is WalletLoaded) {
    return walletState.wallet.balanceDt;
  }
  return 0;
});

/// Formatted balance provider
final formattedBalanceProvider = Provider<String>((ref) {
  final balance = ref.watch(currentBalanceProvider);
  return '${balance.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      )} DT';
});

/// DT packages provider
final dtPackagesProvider = Provider<List<DtPackage>>((ref) {
  final walletState = ref.watch(walletProvider);
  if (walletState is WalletLoaded) {
    return walletState.packages;
  }
  return const [];
});

/// Recent transactions provider
final recentTransactionsProvider = Provider<List<LedgerEntry>>((ref) {
  final walletState = ref.watch(walletProvider);
  if (walletState is WalletLoaded) {
    return walletState.recentTransactions;
  }
  return const [];
});
