/// Application-wide constants
/// Centralizes magic numbers and configuration values for maintainability
library;

/// API and Pagination constants
class ApiConstants {
  ApiConstants._();

  /// Default page size for message pagination
  static const int chatMessagePageSize = 50;

  /// Default page size for list views
  static const int defaultPageSize = 20;

  /// API request timeout duration
  static const Duration apiTimeout = Duration(seconds: 30);

  /// Maximum retry attempts for pagination
  static const int maxPaginationRetries = 3;

  /// Scroll threshold to trigger pagination (pixels from end)
  static const double scrollPaginationThreshold = 100.0;
}

/// Pricing constants (in KRW)
class PricingConstants {
  PricingConstants._();

  /// Default monthly subscription price
  static const int defaultMonthlyPriceKrw = 4900;

  /// VIP tier monthly price
  static const int vipMonthlyPriceKrw = 9900;

  /// Minimum DT purchase amount
  static const int minDtPurchaseKrw = 1000;

  /// DT to KRW exchange rate (1 DT = X KRW)
  static const int dtToKrwRate = 100;
}

/// Chat and messaging constants
class ChatConstants {
  ChatConstants._();

  /// Default character limit for replies (base subscription)
  static const int defaultCharacterLimit = 50;

  /// Extended character limit (7+ days subscribed)
  static const int extendedCharacterLimit = 100;

  /// Maximum character limit (14+ days subscribed)
  static const int maxCharacterLimit = 150;

  /// Donation message maximum length
  static const int donationMessageMaxLength = 100;

  /// Days subscribed threshold for extended limit
  static const int extendedLimitDaysThreshold = 7;

  /// Days subscribed threshold for max limit
  static const int maxLimitDaysThreshold = 14;

  /// Default reply tokens per broadcast
  static const int defaultReplyTokens = 3;

  /// Bonus tokens for 7+ days subscribers
  static const int bonusTokens7Days = 1;

  /// Bonus tokens for 14+ days subscribers
  static const int bonusTokens14Days = 2;
}

/// UI animation and timing constants
class UiConstants {
  UiConstants._();

  /// Default animation duration
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  /// Scroll debounce duration
  static const Duration scrollDebounceDuration = Duration(milliseconds: 100);

  /// Typing indicator timeout
  static const Duration typingIndicatorTimeout = Duration(seconds: 3);

  /// Avatar size in chat header
  static const double chatHeaderAvatarSize = 32.0;

  /// Avatar size in message bubble
  static const double messageBubbleAvatarSize = 36.0;
}

/// Subscription tier names
class SubscriptionTiers {
  SubscriptionTiers._();

  static const String basic = 'BASIC';
  static const String standard = 'STANDARD';
  static const String vip = 'VIP';

  /// Get tier multiplier for token calculation
  static double getMultiplier(String tier) {
    switch (tier.toUpperCase()) {
      case vip:
        return 1.5;
      case standard:
        return 1.2;
      case basic:
      default:
        return 1.0;
    }
  }
}

/// Delivery scope values for messages
class DeliveryScopes {
  DeliveryScopes._();

  static const String broadcast = 'broadcast';
  static const String directReply = 'direct_reply';
  static const String donationMessage = 'donation_message';
  static const String donationReply = 'donation_reply';
}

/// User roles
class UserRoles {
  UserRoles._();

  static const String fan = 'fan';
  static const String creator = 'creator';
  static const String admin = 'admin';
  static const String moderator = 'moderator';
}
