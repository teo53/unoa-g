import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';

/// Wallet model
class Wallet {
  final String id;
  final String userId;
  final int balanceDt;
  final int lifetimePurchasedDt;
  final int lifetimeSpentDt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Wallet({
    required this.id,
    required this.userId,
    required this.balanceDt,
    this.lifetimePurchasedDt = 0,
    this.lifetimeSpentDt = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Format balance for display
  String get formattedBalance => _formatNumber(balanceDt);

  /// Balance in KRW (1 DT = 100 KRW)
  int get balanceKrw => balanceDt * 100;

  String get formattedBalanceKrw => '${_formatNumber(balanceKrw)}원';

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      balanceDt: json['balance_dt'] as int? ?? 0,
      lifetimePurchasedDt: json['lifetime_purchased_dt'] as int? ?? 0,
      lifetimeSpentDt: json['lifetime_spent_dt'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'balance_dt': balanceDt,
      'lifetime_purchased_dt': lifetimePurchasedDt,
      'lifetime_spent_dt': lifetimeSpentDt,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Wallet copyWith({
    String? id,
    String? userId,
    int? balanceDt,
    int? lifetimePurchasedDt,
    int? lifetimeSpentDt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balanceDt: balanceDt ?? this.balanceDt,
      lifetimePurchasedDt: lifetimePurchasedDt ?? this.lifetimePurchasedDt,
      lifetimeSpentDt: lifetimeSpentDt ?? this.lifetimeSpentDt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    this.status = 'completed',
    required this.createdAt,
  });

  bool get isPurchase => entryType == 'purchase';
  bool get isTip => entryType == 'tip';
  bool get isRefund => entryType == 'refund';
  bool get isPayout => entryType == 'payout';

  /// Get display icon based on entry type
  String get displayIcon {
    switch (entryType) {
      case 'purchase':
        return '💳';
      case 'tip':
        return '💝';
      case 'paid_reply':
        return '💬';
      case 'private_card':
        return '🎴';
      case 'refund':
        return '↩️';
      case 'payout':
        return '💰';
      case 'bonus':
        return '🎁';
      default:
        return '📝';
    }
  }

  /// Get display title based on entry type
  String get displayTitle {
    switch (entryType) {
      case 'purchase':
        return 'DT 구매';
      case 'tip':
        return '후원';
      case 'paid_reply':
        return '유료 답장';
      case 'private_card':
        return '프라이빗 카드';
      case 'refund':
        return '환불';
      case 'payout':
        return '정산';
      case 'bonus':
        return '보너스';
      default:
        return '거래';
    }
  }

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
      status: json['status'] as String? ?? 'completed',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idempotency_key': idempotencyKey,
      'from_wallet_id': fromWalletId,
      'to_wallet_id': toWalletId,
      'amount_dt': amountDt,
      'entry_type': entryType,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// DT Package model
class DtPackage {
  final String id;
  final String name;
  final int dtAmount;
  final int bonusDt;
  final int priceKrw;
  final bool isPopular;
  final bool isActive;

  const DtPackage({
    required this.id,
    required this.name,
    required this.dtAmount,
    this.bonusDt = 0,
    required this.priceKrw,
    this.isPopular = false,
    this.isActive = true,
  });

  int get totalDt => dtAmount + bonusDt;

  String get formattedPrice => '${_formatNumber(priceKrw)}원';

  String get formattedDt => '${_formatNumber(totalDt)} DT';

  String get bonusText => bonusDt > 0 ? '+${_formatNumber(bonusDt)} 보너스' : '';

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  factory DtPackage.fromJson(Map<String, dynamic> json) {
    return DtPackage(
      id: json['id'] as String,
      name: json['name'] as String,
      dtAmount: json['dt_amount'] as int,
      bonusDt: json['bonus_dt'] as int? ?? 0,
      priceKrw: json['price_krw'] as int,
      isPopular: json['is_popular'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// DT Purchase model
class DtPurchase {
  final String id;
  final String userId;
  final String packageId;
  final int dtAmount;
  final int bonusDt;
  final int priceKrw;
  final String? paymentMethod;
  final String? paymentProvider;
  final String? paymentProviderTransactionId;
  final String status;
  final int dtUsed;
  final DateTime? refundEligibleUntil;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? refundedAt;

  const DtPurchase({
    required this.id,
    required this.userId,
    required this.packageId,
    required this.dtAmount,
    this.bonusDt = 0,
    required this.priceKrw,
    this.paymentMethod,
    this.paymentProvider,
    this.paymentProviderTransactionId,
    this.status = 'pending',
    this.dtUsed = 0,
    this.refundEligibleUntil,
    required this.createdAt,
    this.paidAt,
    this.refundedAt,
  });

  int get totalDt => dtAmount + bonusDt;
  int get unusedDt => totalDt - dtUsed;

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isRefunded => status == 'refunded';
  bool get isCancelled => status == 'cancelled';
  bool get isFailed => status == 'failed';

  bool get canRefund {
    if (status != 'paid') return false;
    if (dtUsed > 0) return false;
    if (refundEligibleUntil == null) return false;
    return DateTime.now().isBefore(refundEligibleUntil!);
  }

  factory DtPurchase.fromJson(Map<String, dynamic> json) {
    return DtPurchase(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      packageId: json['package_id'] as String,
      dtAmount: json['dt_amount'] as int,
      bonusDt: json['bonus_dt'] as int? ?? 0,
      priceKrw: json['price_krw'] as int,
      paymentMethod: json['payment_method'] as String?,
      paymentProvider: json['payment_provider'] as String?,
      paymentProviderTransactionId:
          json['payment_provider_transaction_id'] as String?,
      status: json['status'] as String? ?? 'pending',
      dtUsed: json['dt_used'] as int? ?? 0,
      refundEligibleUntil: json['refund_eligible_until'] != null
          ? DateTime.parse(json['refund_eligible_until'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      refundedAt: json['refunded_at'] != null
          ? DateTime.parse(json['refunded_at'] as String)
          : null,
    );
  }
}

/// Supabase Wallet Repository
class SupabaseWalletRepository {
  final SupabaseClient _supabase;

  SupabaseWalletRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseConfig.client;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    return user.id;
  }

  // ============================================
  // Wallet Operations
  // ============================================

  /// Get current user's wallet
  Future<Wallet> getWallet() async {
    final response = await _supabase
        .from('wallets')
        .select()
        .eq('user_id', _currentUserId)
        .maybeSingle();

    if (response == null) {
      // Create wallet if doesn't exist
      final newWallet = await _supabase
          .from('wallets')
          .insert({
            'user_id': _currentUserId,
            'balance_dt': 0,
            'lifetime_purchased_dt': 0,
            'lifetime_spent_dt': 0,
          })
          .select()
          .single();
      return Wallet.fromJson(newWallet);
    }

    return Wallet.fromJson(response);
  }

  /// Watch wallet balance changes
  Stream<Wallet> watchWallet() {
    return _supabase
        .from('wallets')
        .stream(primaryKey: ['id'])
        .eq('user_id', _currentUserId)
        .map((rows) {
          if (rows.isEmpty) {
            // Return empty wallet, will be created on first access
            return Wallet(
              id: '',
              userId: _currentUserId,
              balanceDt: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
          return Wallet.fromJson(rows.first);
        });
  }

  // ============================================
  // DT Packages
  // ============================================

  /// Get available DT packages
  Future<List<DtPackage>> getPackages() async {
    final response = await _supabase
        .from('dt_packages')
        .select()
        .eq('is_active', true)
        .order('price_krw', ascending: true);

    return response.map((row) => DtPackage.fromJson(row)).toList();
  }

  // ============================================
  // Purchases
  // ============================================

  /// Create checkout session for DT purchase
  Future<Map<String, dynamic>> createCheckout(String packageId) async {
    // Call edge function to create checkout
    final response = await _supabase.functions.invoke(
      'payment-checkout',
      body: {
        'userId': _currentUserId,
        'packageId': packageId,
      },
    );

    if (response.status != 200) {
      throw StateError(response.data['error'] ?? 'Checkout failed');
    }

    return response.data as Map<String, dynamic>;
  }

  /// Get purchase history
  Future<List<DtPurchase>> getPurchaseHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _supabase
        .from('dt_purchases')
        .select()
        .eq('user_id', _currentUserId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return response.map((row) => DtPurchase.fromJson(row)).toList();
  }

  /// Get a specific purchase
  Future<DtPurchase?> getPurchase(String purchaseId) async {
    final response = await _supabase
        .from('dt_purchases')
        .select()
        .eq('id', purchaseId)
        .eq('user_id', _currentUserId)
        .maybeSingle();

    if (response == null) return null;
    return DtPurchase.fromJson(response);
  }

  /// Request refund for a purchase
  Future<void> requestRefund(String purchaseId) async {
    final response = await _supabase.functions.invoke(
      'refund-process',
      body: {
        'purchaseId': purchaseId,
        'userId': _currentUserId,
      },
    );

    if (response.status != 200) {
      throw StateError(response.data['error'] ?? 'Refund failed');
    }
  }

  // ============================================
  // Ledger / Transaction History
  // ============================================

  /// Get transaction history
  Future<List<LedgerEntry>> getTransactionHistory({
    int limit = 50,
    int offset = 0,
    String? entryType,
  }) async {
    // Get wallet ID first
    final wallet = await getWallet();

    var query = _supabase
        .from('ledger_entries')
        .select()
        .or('from_wallet_id.eq.${wallet.id},to_wallet_id.eq.${wallet.id}');

    if (entryType != null) {
      query = query.eq('entry_type', entryType);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return response.map((row) => LedgerEntry.fromJson(row)).toList();
  }

  /// Watch transaction history
  Stream<List<LedgerEntry>> watchTransactions() async* {
    final wallet = await getWallet();

    // Supabase stream doesn't support 'or' filter,
    // so we use stream without filter and filter in Dart
    yield* _supabase
        .from('ledger_entries')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) {
          // Filter by wallet_id in Dart (either from or to)
          return rows
              .where((row) =>
                  row['from_wallet_id'] == wallet.id ||
                  row['to_wallet_id'] == wallet.id)
              .map((row) => LedgerEntry.fromJson(row))
              .toList();
        });
  }

  // ============================================
  // Donations
  // ============================================

  /// Send a DT donation to a creator
  Future<Map<String, dynamic>> sendDonation({
    required String channelId,
    required String creatorId,
    required int amountDt,
    String? messageId,
    bool isAnonymous = false,
  }) async {
    final wallet = await getWallet();

    if (wallet.balanceDt < amountDt) {
      throw StateError('Insufficient balance');
    }

    // Calculate creator share (80%) and platform fee (20%)
    final creatorShare = (amountDt * 0.8).floor();
    final platformFee = amountDt - creatorShare;

    final idempotencyKey =
        'donation:${wallet.id}:$channelId:${DateTime.now().millisecondsSinceEpoch}';

    // Create donation record
    final donation = await _supabase
        .from('dt_donations')
        .insert({
          'from_user_id': _currentUserId,
          'to_channel_id': channelId,
          'to_creator_id': creatorId,
          'amount_dt': amountDt,
          'message_id': messageId,
          'is_anonymous': isAnonymous,
          'creator_share_dt': creatorShare,
          'platform_fee_dt': platformFee,
        })
        .select()
        .single();

    // Create ledger entry
    await _supabase.from('ledger_entries').insert({
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
    await _supabase.from('wallets').update({
      'balance_dt': wallet.balanceDt - amountDt,
      'lifetime_spent_dt': wallet.lifetimeSpentDt + amountDt,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', wallet.id);

    return donation;
  }

  /// Get donation history (sent by user)
  Future<List<Map<String, dynamic>>> getDonationHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _supabase
        .from('dt_donations')
        .select('''
          *,
          channels!to_channel_id (
            name,
            avatar_url
          )
        ''')
        .eq('from_user_id', _currentUserId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get donations received (for creators)
  Future<List<Map<String, dynamic>>> getReceivedDonations({
    int limit = 50,
    int offset = 0,
    DateTime? since,
  }) async {
    var query = _supabase.from('dt_donations').select('''
          *,
          user_profiles!from_user_id (
            display_name,
            avatar_url
          ),
          messages!message_id (
            content
          )
        ''').eq('to_creator_id', _currentUserId);

    if (since != null) {
      query = query.gte('created_at', since.toIso8601String());
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // Private Cards
  // ============================================

  /// Purchase a private card
  Future<Map<String, dynamic>> purchasePrivateCard(String cardId) async {
    final wallet = await getWallet();

    // Get card info
    final card = await _supabase
        .from('private_cards')
        .select()
        .eq('id', cardId)
        .single();

    final priceDt = card['price_dt'] as int;

    if (wallet.balanceDt < priceDt) {
      throw StateError('Insufficient balance');
    }

    // Check if already purchased
    final existing = await _supabase
        .from('private_card_purchases')
        .select()
        .eq('card_id', cardId)
        .eq('user_id', _currentUserId)
        .maybeSingle();

    if (existing != null) {
      throw StateError('Already purchased');
    }

    final idempotencyKey =
        'private_card:${wallet.id}:$cardId:${DateTime.now().millisecondsSinceEpoch}';

    // Create purchase record
    final purchase = await _supabase
        .from('private_card_purchases')
        .insert({
          'card_id': cardId,
          'user_id': _currentUserId,
          'price_paid_dt': priceDt,
        })
        .select()
        .single();

    // Create ledger entry
    await _supabase.from('ledger_entries').insert({
      'idempotency_key': idempotencyKey,
      'from_wallet_id': wallet.id,
      'amount_dt': priceDt,
      'entry_type': 'private_card',
      'reference_type': 'private_card',
      'reference_id': cardId,
      'description': '프라이빗 카드: ${card['title']}',
      'status': 'completed',
    });

    // Update wallet balance
    await _supabase.from('wallets').update({
      'balance_dt': wallet.balanceDt - priceDt,
      'lifetime_spent_dt': wallet.lifetimeSpentDt + priceDt,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', wallet.id);

    // Update card purchase count
    await _supabase.from('private_cards').update({
      'purchase_count': (card['purchase_count'] as int? ?? 0) + 1,
    }).eq('id', cardId);

    return purchase;
  }

  /// Get purchased private cards
  Future<List<Map<String, dynamic>>> getPurchasedCards() async {
    final response = await _supabase
        .from('private_card_purchases')
        .select('''
          *,
          private_cards (
            *,
            channels!channel_id (
              name,
              avatar_url
            )
          )
        ''')
        .eq('user_id', _currentUserId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
