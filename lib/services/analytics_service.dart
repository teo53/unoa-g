import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../core/config/app_config.dart';
import '../core/utils/app_logger.dart';

/// Analytics Service for GA4 / Firebase Analytics
///
/// Prerequisites:
/// 1. Add google-services.json to android/app/
/// 2. Add GoogleService-Info.plist to ios/Runner/
/// 3. Enable Firebase Analytics in Firebase Console
///
/// This service handles:
/// - Screen view tracking
/// - Custom event logging
/// - User property management
/// - Business metrics (subscriptions, purchases, messages)

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  bool _initialized = false;
  FirebaseAnalytics? _analytics;

  bool get isInitialized => _initialized;

  /// Whether analytics collection is active (production only)
  bool get _isActive => _initialized && _analytics != null;

  /// Initialize Analytics service
  ///
  /// Call this in main.dart after Firebase.initializeApp()
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (AppConfig.enableAnalytics) {
        _analytics = FirebaseAnalytics.instance;
        await _analytics!.setAnalyticsCollectionEnabled(true);
        AppLogger.info('Service initialized (Firebase Analytics active)', tag: 'Analytics');
      } else {
        AppLogger.info('Service initialized (no-op: analytics disabled)', tag: 'Analytics');
      }

      _initialized = true;
    } catch (e) {
      _initialized = true;
      AppLogger.error(e, tag: 'Analytics', message: 'Initialization error — running in no-op mode');
    }
  }

  // ========================================
  // Screen Tracking
  // ========================================

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      if (_isActive) {
        await _analytics!.logScreenView(
          screenName: screenName,
          screenClass: screenClass,
        );
      }
      AppLogger.debug('Screen view: $screenName', tag: 'Analytics');
    } catch (e) {
      AppLogger.debug('Error logging screen view: $e', tag: 'Analytics');
    }
  }

  // ========================================
  // User Properties
  // ========================================

  /// Set user ID for analytics
  Future<void> setUserId(String? userId) async {
    try {
      if (_isActive) {
        await _analytics!.setUserId(id: userId);
      }
      AppLogger.debug('User ID set: ${userId ?? 'null'}', tag: 'Analytics');
    } catch (e) {
      AppLogger.debug('Error setting user ID: $e', tag: 'Analytics');
    }
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      if (_isActive) {
        await _analytics!.setUserProperty(name: name, value: value);
      }
      AppLogger.debug('User property: $name = $value', tag: 'Analytics');
    } catch (e) {
      AppLogger.debug('Error setting user property: $e', tag: 'Analytics');
    }
  }

  /// Set user subscription tier
  Future<void> setSubscriptionTier(String tier) async {
    await setUserProperty(name: 'subscription_tier', value: tier);
  }

  /// Set user account type (fan/artist)
  Future<void> setAccountType(String type) async {
    await setUserProperty(name: 'account_type', value: type);
  }

  // ========================================
  // Generic Event Logging
  // ========================================

  /// Log custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      if (_isActive) {
        await _analytics!.logEvent(
          name: name,
          parameters: parameters,
        );
      }
      AppLogger.debug('Event: $name, params: $parameters', tag: 'Analytics');
    } catch (e) {
      AppLogger.debug('Error logging event: $e', tag: 'Analytics');
    }
  }

  // ========================================
  // Authentication Events
  // ========================================

  /// Log user sign up
  Future<void> logSignUp({required String method}) async {
    await logEvent(
      name: 'sign_up',
      parameters: {'method': method},
    );
  }

  /// Log user login
  Future<void> logLogin({required String method}) async {
    await logEvent(
      name: 'login',
      parameters: {'method': method},
    );
  }

  /// Log user logout
  Future<void> logLogout() async {
    await logEvent(name: 'logout');
    await setUserId(null);
  }

  // ========================================
  // Subscription Events
  // ========================================

  /// Log subscription start
  Future<void> logSubscription({
    required String channelId,
    required String artistName,
    required String tier,
    required double amount,
  }) async {
    await logEvent(
      name: 'subscribe',
      parameters: {
        'channel_id': channelId,
        'artist_name': artistName,
        'tier': tier,
        'value': amount,
        'currency': 'KRW',
      },
    );
  }

  /// Log subscription cancellation
  Future<void> logUnsubscribe({
    required String channelId,
    required String artistName,
    required String tier,
    int? subscriptionDays,
  }) async {
    await logEvent(
      name: 'unsubscribe',
      parameters: {
        'channel_id': channelId,
        'artist_name': artistName,
        'tier': tier,
        if (subscriptionDays != null) 'subscription_days': subscriptionDays,
      },
    );
  }

  /// Log subscription tier upgrade
  Future<void> logTierUpgrade({
    required String channelId,
    required String fromTier,
    required String toTier,
    required double amount,
  }) async {
    await logEvent(
      name: 'tier_upgrade',
      parameters: {
        'channel_id': channelId,
        'from_tier': fromTier,
        'to_tier': toTier,
        'value': amount,
        'currency': 'KRW',
      },
    );
  }

  // ========================================
  // DT (Digital Token) Events
  // ========================================

  /// Log DT purchase
  Future<void> logDtPurchase({
    required String packageId,
    required int dtAmount,
    required int bonusDt,
    required double priceKrw,
  }) async {
    await logEvent(
      name: 'dt_purchase',
      parameters: {
        'package_id': packageId,
        'dt_amount': dtAmount,
        'bonus_dt': bonusDt,
        'total_dt': dtAmount + bonusDt,
        'value': priceKrw,
        'currency': 'KRW',
      },
    );

    // Also log as purchase event for GA4 ecommerce
    if (_isActive) {
      try {
        await _analytics!.logPurchase(
          currency: 'KRW',
          value: priceKrw,
          items: [
            AnalyticsEventItem(
              itemId: packageId,
              itemName: 'DT Package',
              quantity: dtAmount + bonusDt,
            ),
          ],
        );
      } catch (e) {
        AppLogger.debug('Error logging purchase event: $e', tag: 'Analytics');
      }
    }
  }

  /// Log DT donation
  Future<void> logDtDonation({
    required String channelId,
    required String artistName,
    required int dtAmount,
  }) async {
    await logEvent(
      name: 'dt_donation',
      parameters: {
        'channel_id': channelId,
        'artist_name': artistName,
        'dt_amount': dtAmount,
      },
    );
  }

  // ========================================
  // Messaging Events
  // ========================================

  /// Log message sent
  Future<void> logMessageSent({
    required String type,
    String? channelId,
    int? characterCount,
  }) async {
    await logEvent(
      name: 'message_sent',
      parameters: {
        'message_type': type,
        if (channelId != null) 'channel_id': channelId,
        if (characterCount != null) 'character_count': characterCount,
      },
    );
  }

  /// Log broadcast message (artist)
  Future<void> logBroadcastSent({
    required String channelId,
    required String messageType,
    int? subscriberCount,
  }) async {
    await logEvent(
      name: 'broadcast_sent',
      parameters: {
        'channel_id': channelId,
        'message_type': messageType,
        if (subscriberCount != null) 'subscriber_count': subscriberCount,
      },
    );
  }

  /// Log reply sent (fan)
  Future<void> logReplySent({
    required String channelId,
    required int characterCount,
    required bool usedToken,
    required bool usedFallback,
  }) async {
    await logEvent(
      name: 'reply_sent',
      parameters: {
        'channel_id': channelId,
        'character_count': characterCount,
        'used_token': usedToken,
        'used_fallback': usedFallback,
      },
    );
  }

  /// Log media upload
  Future<void> logMediaUpload({
    required String mediaType,
    int? fileSizeBytes,
    int? durationSeconds,
  }) async {
    await logEvent(
      name: 'media_upload',
      parameters: {
        'media_type': mediaType,
        if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
      },
    );
  }

  // ========================================
  // Engagement Events
  // ========================================

  /// Log artist profile view
  Future<void> logArtistProfileView({
    required String artistId,
    required String artistName,
  }) async {
    await logEvent(
      name: 'artist_profile_view',
      parameters: {
        'artist_id': artistId,
        'artist_name': artistName,
      },
    );
  }

  /// Log chat opened
  Future<void> logChatOpened({
    required String channelId,
    required String artistName,
  }) async {
    await logEvent(
      name: 'chat_opened',
      parameters: {
        'channel_id': channelId,
        'artist_name': artistName,
      },
    );
  }

  /// Log notification opened
  Future<void> logNotificationOpened({
    required String notificationType,
    String? channelId,
  }) async {
    await logEvent(
      name: 'notification_opened',
      parameters: {
        'notification_type': notificationType,
        if (channelId != null) 'channel_id': channelId,
      },
    );
  }

  /// Log search performed
  Future<void> logSearch({
    required String searchTerm,
    int? resultCount,
  }) async {
    if (_isActive) {
      try {
        await _analytics!.logSearch(searchTerm: searchTerm);
      } catch (_) {}
    }
    await logEvent(
      name: 'search',
      parameters: {
        'search_term': searchTerm,
        if (resultCount != null) 'result_count': resultCount,
      },
    );
  }

  /// Log share action
  Future<void> logShare({
    required String contentType,
    required String itemId,
    String? method,
  }) async {
    if (_isActive) {
      try {
        await _analytics!.logShare(
          contentType: contentType,
          itemId: itemId,
          method: method ?? 'unknown',
        );
      } catch (_) {}
    }
    await logEvent(
      name: 'share',
      parameters: {
        'content_type': contentType,
        'item_id': itemId,
        if (method != null) 'method': method,
      },
    );
  }

  // ========================================
  // Error Tracking
  // ========================================

  /// Log error event
  Future<void> logError({
    required String errorCode,
    required String errorMessage,
    String? screenName,
  }) async {
    await logEvent(
      name: 'app_error',
      parameters: {
        'error_code': errorCode,
        'error_message': errorMessage.length > 100
            ? errorMessage.substring(0, 100)
            : errorMessage,
        if (screenName != null) 'screen_name': screenName,
      },
    );
  }

  // ========================================
  // App Lifecycle Events
  // ========================================

  /// Log app open
  Future<void> logAppOpen() async {
    if (_isActive) {
      try {
        await _analytics!.logAppOpen();
      } catch (_) {}
    }
    AppLogger.debug('App open logged', tag: 'Analytics');
  }

  /// Log tutorial begin
  Future<void> logTutorialBegin() async {
    if (_isActive) {
      try {
        await _analytics!.logTutorialBegin();
      } catch (_) {}
    }
    await logEvent(name: 'tutorial_begin');
  }

  /// Log tutorial complete
  Future<void> logTutorialComplete() async {
    if (_isActive) {
      try {
        await _analytics!.logTutorialComplete();
      } catch (_) {}
    }
    await logEvent(name: 'tutorial_complete');
  }

  // ========================================
  // Debug Mode
  // ========================================

  /// Enable debug mode (for DebugView in Firebase Console)
  Future<void> setDebugMode(bool enabled) async {
    try {
      // Debug mode is typically set via adb for Android:
      // adb shell setprop debug.firebase.analytics.app <package_name>
      // or via scheme for iOS:
      // -FIRDebugEnabled
      AppLogger.debug('Debug mode: $enabled', tag: 'Analytics');
    } catch (e) {
      AppLogger.debug('Error setting debug mode: $e', tag: 'Analytics');
    }
  }

  /// Reset analytics data (for testing)
  Future<void> resetAnalyticsData() async {
    try {
      if (_isActive) {
        await _analytics!.resetAnalyticsData();
      }
      AppLogger.debug('Analytics data reset', tag: 'Analytics');
    } catch (e) {
      AppLogger.debug('Error resetting analytics data: $e', tag: 'Analytics');
    }
  }
}

/// Analytics event names as constants for consistency
class AnalyticsEvents {
  AnalyticsEvents._();

  // Authentication
  static const signUp = 'sign_up';
  static const login = 'login';
  static const logout = 'logout';

  // Subscriptions
  static const subscribe = 'subscribe';
  static const unsubscribe = 'unsubscribe';
  static const tierUpgrade = 'tier_upgrade';

  // DT
  static const dtPurchase = 'dt_purchase';
  static const dtDonation = 'dt_donation';

  // Messaging
  static const messageSent = 'message_sent';
  static const broadcastSent = 'broadcast_sent';
  static const replySent = 'reply_sent';
  static const mediaUpload = 'media_upload';

  // Engagement
  static const artistProfileView = 'artist_profile_view';
  static const chatOpened = 'chat_opened';
  static const notificationOpened = 'notification_opened';
  static const search = 'search';
  static const share = 'share';

  // Errors
  static const appError = 'app_error';

  // Lifecycle
  static const appOpen = 'app_open';
  static const tutorialBegin = 'tutorial_begin';
  static const tutorialComplete = 'tutorial_complete';
}

/// User properties as constants
class AnalyticsUserProperties {
  AnalyticsUserProperties._();

  static const subscriptionTier = 'subscription_tier';
  static const accountType = 'account_type';
  static const subscriptionCount = 'subscription_count';
  static const totalDtBalance = 'total_dt_balance';
}
