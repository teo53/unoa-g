/// Business Logic Configuration
///
/// Centralized configuration for business rules, limits, and constants.
/// These values define the core business logic of the UNO A platform.
library;

/// Purchase platform for pricing differentiation.
enum PurchasePlatform { web, android, ios }

class BusinessConfig {
  BusinessConfig._();

  // ============================================================
  // Subscription Tiers
  // ============================================================

  /// Available subscription tier names
  static const List<String> subscriptionTiers = ['BASIC', 'STANDARD', 'VIP'];

  /// Tier display names (Korean)
  static const Map<String, String> tierDisplayNames = {
    'BASIC': '베이직',
    'STANDARD': '스탠다드',
    'VIP': 'VIP',
  };

  /// Tier prices (monthly, in KRW)
  static const Map<String, int> tierPricesKrw = {
    'BASIC': 4900,
    'STANDARD': 9900,
    'VIP': 19900,
  };

  /// Tier prices by purchase platform (VAT 포함).
  ///
  /// - web: 최저가 (PG 수수료 수준)
  /// - android/ios: 인앱결제 수수료를 반영한 표시가
  ///
  /// NOTE: 실제 과금/정산은 구매 시점의 결제 레코드 기준이며,
  /// 여기 값은 "표시" 및 "결제 요청 검증"의 단일 소스입니다.
  static const Map<PurchasePlatform, Map<String, int>> tierPricesByPlatform = {
    PurchasePlatform.web: {'BASIC': 4900, 'STANDARD': 9900, 'VIP': 19900},
    PurchasePlatform.android: {'BASIC': 5900, 'STANDARD': 11900, 'VIP': 22900},
    PurchasePlatform.ios: {'BASIC': 6900, 'STANDARD': 13900, 'VIP': 27900},
  };

  /// Subscription product IDs for in-app purchase (monthly auto-renewable).
  ///
  /// Maps tier name to store product ID.
  /// Must match App Store Connect / Google Play Console product IDs
  /// and SUBSCRIPTION_PRODUCT_MAP in iap-verify Edge Function.
  static const Map<String, String> subscriptionSkuByTier = {
    'BASIC': 'com.unoa.sub.basic.monthly',
    'STANDARD': 'com.unoa.sub.standard.monthly',
    'VIP': 'com.unoa.sub.vip.monthly',
  };

  /// Reverse mapping: store product ID to tier name.
  static final Map<String, String> tierBySubscriptionSku = {
    for (final entry in subscriptionSkuByTier.entries) entry.value: entry.key,
  };

  /// All subscription product IDs for store queries.
  static Set<String> get allSubscriptionSkus =>
      subscriptionSkuByTier.values.toSet();

  /// DT packages with platform-specific prices.
  ///
  /// IMPORTANT: `id` must match `dt_packages.id` and Edge Function validation.
  static const List<Map<String, dynamic>> dtPackagesByPlatform = [
    {
      'id': 'dt_10',
      'dt': 10,
      'bonus': 0,
      'web': 1000,
      'android': 1200,
      'ios': 1400
    },
    {
      'id': 'dt_50',
      'dt': 50,
      'bonus': 0,
      'web': 5000,
      'android': 5900,
      'ios': 6900
    },
    {
      'id': 'dt_100',
      'dt': 100,
      'bonus': 5,
      'web': 10000,
      'android': 11900,
      'ios': 13900
    },
    {
      'id': 'dt_500',
      'dt': 500,
      'bonus': 50,
      'web': 50000,
      'android': 59000,
      'ios': 69000
    },
    {
      'id': 'dt_1000',
      'dt': 1000,
      'bonus': 150,
      'web': 100000,
      'android': 119000,
      'ios': 139000
    },
    {
      'id': 'dt_5000',
      'dt': 5000,
      'bonus': 1000,
      'web': 500000,
      'android': 590000,
      'ios': 690000
    },
  ];

  static String _platformKey(PurchasePlatform platform) {
    switch (platform) {
      case PurchasePlatform.ios:
        return 'ios';
      case PurchasePlatform.android:
        return 'android';
      case PurchasePlatform.web:
        return 'web';
    }
  }

  /// Get tier price for a specific platform.
  /// Falls back to `tierPricesKrw` to keep backward compatibility.
  static int getTierPrice(String tier, PurchasePlatform platform) {
    final key = tier.toUpperCase();
    return tierPricesByPlatform[platform]?[key] ?? tierPricesKrw[key] ?? 0;
  }

  /// Get DT package price for a specific platform.
  static int getDtPackagePrice(String packageId, PurchasePlatform platform) {
    final platformKey = _platformKey(platform);
    final pkg = dtPackagesByPlatform
        .cast<Map<String, Object?>>()
        .where((p) => (p['id'] as String?) == packageId)
        .toList(growable: false);

    if (pkg.isEmpty) return 0;
    final map = pkg.first;
    final value = map[platformKey];
    if (value is int) return value;
    final webValue = map['web'];
    return webValue is int ? webValue : 0;
  }

  /// Tier benefits descriptions
  static const Map<String, List<String>> tierBenefits = {
    'BASIC': [
      '아티스트 메시지 수신',
      '기본 이모티콘 사용',
    ],
    'STANDARD': [
      '아티스트 메시지 수신',
      '모든 이모티콘 사용',
      '답글 토큰 +1',
      '프로필 배지',
    ],
    'VIP': [
      '모든 STANDARD 혜택',
      '답글 토큰 +2',
      '독점 콘텐츠 접근',
      'VIP 전용 배지',
      '우선 응답 기회',
    ],
  };

  // ============================================================
  // Reply Token System
  // ============================================================

  /// Default reply tokens per broadcast
  static const int defaultReplyTokens = 3;

  /// Additional tokens for STANDARD tier
  static const int standardTierBonusTokens = 1;

  /// Additional tokens for VIP tier
  static const int vipTierBonusTokens = 2;

  /// Get total tokens for tier
  static int getTokensForTier(String tier) {
    switch (tier.toUpperCase()) {
      case 'VIP':
        return defaultReplyTokens + vipTierBonusTokens;
      case 'STANDARD':
        return defaultReplyTokens + standardTierBonusTokens;
      default:
        return defaultReplyTokens;
    }
  }

  // ============================================================
  // Character Limits by Subscription Age
  // ============================================================

  /// Character limits based on subscription duration (days)
  /// Key: minimum days subscribed, Value: max characters allowed
  static const Map<int, int> characterLimitsByDays = {
    0: 50, // 0-49 days
    50: 50, // 50-76 days
    77: 77, // 77-99 days
    100: 100, // 100-149 days
    150: 150, // 150-199 days
    200: 200, // 200-299 days
    300: 300, // 300+ days
  };

  /// Get character limit for subscription age
  static int getCharacterLimit(int daysSubscribed) {
    int limit = 50; // Default minimum
    for (final entry in characterLimitsByDays.entries) {
      if (daysSubscribed >= entry.key) {
        limit = entry.value;
      }
    }
    return limit;
  }

  /// Maximum possible character limit
  static const int maxCharacterLimit = 300;

  /// Minimum character limit
  static const int minCharacterLimit = 50;

  // ============================================================
  // DT (Digital Token) Currency
  // ============================================================

  /// DT 기본 단가 참고값 (패키지별 고정 가격 적용, 환율 개념 아님)
  /// 정산 시에는 실제 결제 금액(price_krw) 기준으로 처리
  /// 이 값은 UI 표시용 참고값으로만 사용
  static const int dtBaseUnitPriceKrw = 100;

  /// Minimum DT charge amount
  static const int minChargeDt = 1000;

  /// Maximum DT charge amount
  static const int maxChargeDt = 1000000;

  /// Available charge amounts (in DT)
  static const List<int> chargeAmounts = [
    1000,
    3000,
    5000,
    10000,
    30000,
    50000,
    100000,
  ];

  // ============================================================
  // DT Refund & Expiry Policy
  // ============================================================

  /// Refund window (days after purchase) for unused DT
  static const int dtRefundWindowDays = 7;

  /// DT expiry period (years from purchase/grant)
  static const int dtExpiryYears = 5;

  // ============================================================
  // Donation System
  // ============================================================

  /// Minimum donation amount (DT)
  static const int minDonationDt = 100;

  /// Maximum donation amount (DT)
  static const int maxDonationDt = 1000000;

  /// Quick donation amounts (DT)
  static const List<int> quickDonationAmounts = [
    100,
    500,
    1000,
    5000,
    10000,
  ];

  /// Platform commission rate (percentage)
  static const double platformCommissionPercent = 20.0;

  /// Creator payout rate (percentage)
  static double get creatorPayoutPercent => 100.0 - platformCommissionPercent;

  // ============================================================
  // Content Limits
  // ============================================================

  /// Maximum broadcast message length
  static const int maxBroadcastLength = 2000;

  /// Maximum bio length
  static const int maxBioLength = 200;

  /// Maximum display name length
  static const int maxDisplayNameLength = 20;

  /// Minimum display name length
  static const int minDisplayNameLength = 2;

  /// Maximum media attachments per message
  static const int maxMediaAttachments = 10;

  // ============================================================
  // Funding Campaigns
  // ============================================================

  /// Minimum funding goal (KRW)
  static const int minFundingGoalKrw = 100000;

  /// Maximum funding goal (KRW)
  static const int maxFundingGoalKrw = 100000000;

  /// Maximum campaign duration (days)
  static const int maxCampaignDurationDays = 90;

  /// Minimum campaign duration (days)
  static const int minCampaignDurationDays = 7;

  // ============================================================
  // User Verification
  // ============================================================

  /// Age for minor status (under this age requires guardian consent)
  static const int minorAgeThreshold = 14;

  /// Age for restricted content access
  static const int adultAgeThreshold = 19;

  // ============================================================
  // Rate Limits
  // ============================================================

  /// Maximum messages per hour (fan)
  static const int maxMessagesPerHour = 60;

  /// Maximum broadcasts per day (creator)
  static const int maxBroadcastsPerDay = 50;

  /// Cooldown between messages (seconds)
  static const int messageCooldownSeconds = 5;

  // ============================================================
  // Private Card System
  // ============================================================

  /// Maximum characters for private card message
  static const int privateCardMaxChars = 500;

  /// Maximum media size for private card (MB)
  static const int privateCardMaxMediaSizeMb = 50;

  /// Allowed media types for private card attachments
  static const List<String> privateCardMediaTypes = [
    'png',
    'jpg',
    'jpeg',
    'gif',
    'mp4',
    'mov',
    'm4a',
    'mp3',
  ];

  /// Maximum media attachments per private card
  static const int privateCardMaxMediaCount = 5;

  // ============================================================
  // Cache Durations
  // ============================================================

  /// Profile cache duration (minutes)
  static const int profileCacheMinutes = 5;

  /// Message list cache duration (seconds)
  static const int messageListCacheSeconds = 30;

  /// Artist list cache duration (minutes)
  static const int artistListCacheMinutes = 10;

  // ============================================================
  // Poll/VS System
  // ============================================================

  /// Maximum polls a creator can send per KST day
  static const int maxPollsPerDay = 5;

  /// Default poll duration (hours)
  static const int defaultPollDurationHours = 24;

  /// Maximum poll options
  static const int maxPollOptions = 4;

  // ============================================================
  // Celebrations System
  // ============================================================

  /// Subscription milestone days that trigger celebration events
  static const List<int> milestoneDays = [50, 100, 365];

  /// Days before a celebration event expires
  static const int celebrationExpiryDays = 7;

  // ============================================================
  // Consent System
  // ============================================================

  /// Current consent document version.
  ///
  /// Increment this when terms/privacy policy changes require re-consent.
  /// Maps to `user_consents.version` (VARCHAR(20) NOT NULL, migration 018).
  static const String currentConsentVersion = 'v1.0.0';
}
