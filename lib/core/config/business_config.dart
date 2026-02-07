/// Business Logic Configuration
///
/// Centralized configuration for business rules, limits, and constants.
/// These values define the core business logic of the UNO A platform.
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

  /// DT per KRW exchange rate (1 KRW = X DT)
  static const int dtPerKrw = 1;

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
    'png', 'jpg', 'jpeg', 'gif', 'mp4', 'mov', 'm4a', 'mp3',
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
}
