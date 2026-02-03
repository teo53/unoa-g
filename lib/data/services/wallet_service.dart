/// Result type for wallet operations
class WalletResult {
  final bool success;
  final String? errorCode;
  final String? errorMessage;
  final int? newBalance;
  final String? transactionId;

  const WalletResult._({
    required this.success,
    this.errorCode,
    this.errorMessage,
    this.newBalance,
    this.transactionId,
  });

  factory WalletResult.success({int? newBalance, String? transactionId}) =>
      WalletResult._(
        success: true,
        newBalance: newBalance,
        transactionId: transactionId,
      );

  factory WalletResult.error(String code, String message) => WalletResult._(
        success: false,
        errorCode: code,
        errorMessage: message,
      );

  // Common error factories
  static WalletResult insufficientBalance() =>
      WalletResult.error('INSUFFICIENT_BALANCE', '잔액이 부족합니다.');

  static WalletResult invalidAmount() =>
      WalletResult.error('INVALID_AMOUNT', '유효하지 않은 금액입니다.');

  static WalletResult unauthorized() =>
      WalletResult.error('UNAUTHORIZED', '로그인이 필요합니다.');

  static WalletResult refundNotAllowed() =>
      WalletResult.error('REFUND_NOT_ALLOWED', '환불이 불가능합니다. DT가 이미 사용되었습니다.');

  static WalletResult refundExpired() =>
      WalletResult.error('REFUND_EXPIRED', '환불 가능 기간(7일)이 지났습니다.');
}

/// Wallet service for handling payment and donation business logic
///
/// Separates business rules (donation distribution, refund policies)
/// from data access and state management.
class WalletService {
  /// Creator's share of donation (80%)
  static const double creatorShareRate = 0.80;

  /// Platform's share of donation (20%)
  static const double platformShareRate = 0.20;

  /// DT to KRW conversion rate (1 DT = 100 KRW)
  static const int dtToKrwRate = 100;

  /// Minimum donation amount in DT
  static const int minimumDonationDt = 10;

  /// Maximum donation amount in DT
  static const int maximumDonationDt = 100000;

  /// Refund period in days
  static const int refundPeriodDays = 7;

  /// Check if user has sufficient balance for donation
  WalletResult? validateDonation({
    required int amountDt,
    required int currentBalance,
  }) {
    // Check minimum amount
    if (amountDt < minimumDonationDt) {
      return WalletResult.error(
        'MINIMUM_AMOUNT',
        '최소 후원 금액은 ${minimumDonationDt} DT입니다.',
      );
    }

    // Check maximum amount
    if (amountDt > maximumDonationDt) {
      return WalletResult.error(
        'MAXIMUM_AMOUNT',
        '최대 후원 금액은 ${maximumDonationDt} DT입니다.',
      );
    }

    // Check balance
    if (currentBalance < amountDt) {
      return WalletResult.insufficientBalance();
    }

    return null;
  }

  /// Calculate donation distribution
  DonationDistribution calculateDonationDistribution(int amountDt) {
    final creatorShare = (amountDt * creatorShareRate).floor();
    final platformShare = amountDt - creatorShare; // Remaining to platform

    return DonationDistribution(
      totalDt: amountDt,
      creatorShareDt: creatorShare,
      platformShareDt: platformShare,
      creatorShareKrw: creatorShare * dtToKrwRate,
      platformShareKrw: platformShare * dtToKrwRate,
    );
  }

  /// Convert DT to KRW
  int dtToKrw(int dt) => dt * dtToKrwRate;

  /// Convert KRW to DT
  int krwToDt(int krw) => krw ~/ dtToKrwRate;

  /// Format DT amount for display
  String formatDt(int amount) {
    return _formatNumber(amount) + ' DT';
  }

  /// Format KRW amount for display
  String formatKrw(int amount) {
    return '₩' + _formatNumber(amount);
  }

  /// Check if refund is allowed
  WalletResult? validateRefund({
    required DateTime purchaseDate,
    required int purchasedDt,
    required int usedDt,
  }) {
    // Check if within refund period
    final daysSincePurchase = DateTime.now().difference(purchaseDate).inDays;
    if (daysSincePurchase > refundPeriodDays) {
      return WalletResult.refundExpired();
    }

    // Check if DT has been used
    if (usedDt > 0) {
      return WalletResult.refundNotAllowed();
    }

    return null;
  }

  /// Calculate refundable amount (may be partial)
  int calculateRefundAmount({
    required int purchasedDt,
    required int bonusDt,
    required int usedDt,
  }) {
    // Only purchased DT is refundable, not bonus
    final refundableDt = purchasedDt - usedDt;
    return refundableDt > 0 ? refundableDt : 0;
  }

  /// Format number with comma separators
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

/// Distribution breakdown for a donation
class DonationDistribution {
  final int totalDt;
  final int creatorShareDt;
  final int platformShareDt;
  final int creatorShareKrw;
  final int platformShareKrw;

  const DonationDistribution({
    required this.totalDt,
    required this.creatorShareDt,
    required this.platformShareDt,
    required this.creatorShareKrw,
    required this.platformShareKrw,
  });

  @override
  String toString() {
    return 'DonationDistribution(total: $totalDt DT, '
        'creator: $creatorShareDt DT (${(creatorShareDt / totalDt * 100).toStringAsFixed(0)}%), '
        'platform: $platformShareDt DT (${(platformShareDt / totalDt * 100).toStringAsFixed(0)}%))';
  }
}

/// DT Package purchase details
class DtPackageDetails {
  final String packageId;
  final String name;
  final int dtAmount;
  final int bonusDt;
  final int priceKrw;
  final bool isPopular;

  const DtPackageDetails({
    required this.packageId,
    required this.name,
    required this.dtAmount,
    required this.bonusDt,
    required this.priceKrw,
    this.isPopular = false,
  });

  int get totalDt => dtAmount + bonusDt;

  /// Price per DT (including bonus)
  double get pricePerDt => priceKrw / totalDt;

  /// Discount percentage compared to base rate
  double get discountPercent {
    final basePrice = totalDt * WalletService.dtToKrwRate;
    return ((basePrice - priceKrw) / basePrice * 100).clamp(0, 100);
  }

  String get formattedPrice {
    return '₩${priceKrw.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  String get bonusText {
    if (bonusDt <= 0) return '';
    return '+$bonusDt 보너스';
  }
}
