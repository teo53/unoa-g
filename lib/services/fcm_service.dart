import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/supabase/supabase_client.dart';

/// FCM Service for Push Notifications
///
/// Prerequisites:
/// 1. Add google-services.json to android/app/
/// 2. Add GoogleService-Info.plist to ios/Runner/
/// 3. Enable Firebase Cloud Messaging in Firebase Console
///
/// This service handles:
/// - FCM token management
/// - Push notification handling (foreground/background)
/// - Token refresh and server sync

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  String? _token;
  bool _initialized = false;

  /// Current FCM token
  String? get token => _token;
  bool get isInitialized => _initialized;

  /// Initialize FCM service
  ///
  /// Call this in main.dart after Firebase.initializeApp()
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        debugPrint('[FCM] Web platform - FCM not supported yet');
        return;
      }

      // Note: Requires firebase_messaging package and Firebase setup
      // This is a template that will work once Firebase is configured
      //
      // import 'package:firebase_messaging/firebase_messaging.dart';
      //
      // final messaging = FirebaseMessaging.instance;
      //
      // // Request permission (iOS)
      // final settings = await messaging.requestPermission(
      //   alert: true,
      //   announcement: false,
      //   badge: true,
      //   carPlay: false,
      //   criticalAlert: false,
      //   provisional: false,
      //   sound: true,
      // );
      //
      // if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      //   debugPrint('[FCM] Permission granted');
      // } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      //   debugPrint('[FCM] Provisional permission granted');
      // } else {
      //   debugPrint('[FCM] Permission denied');
      //   return;
      // }
      //
      // // Get token
      // _token = await messaging.getToken();
      // debugPrint('[FCM] Token: $_token');
      //
      // // Save token to server
      // if (_token != null) {
      //   await saveTokenToServer(_token!);
      // }
      //
      // // Listen for token refresh
      // messaging.onTokenRefresh.listen((newToken) {
      //   _token = newToken;
      //   saveTokenToServer(newToken);
      // });
      //
      // // Setup message handlers
      // setupMessageHandlers();

      _initialized = true;
      debugPrint('[FCM] Service initialized (template mode)');
    } catch (e) {
      debugPrint('[FCM] Initialization error: $e');
    }
  }

  /// Save FCM token to Supabase
  Future<void> saveTokenToServer(String token) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        assert(() { debugPrint('[FCM] No authenticated user, skipping token save'); return true; }());
        return;
      }

      // Upsert token to user_push_tokens table
      await SupabaseConfig.client.from('user_push_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': _getPlatform(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, token');

      assert(() { debugPrint('[FCM] Token saved to server'); return true; }());
    } catch (e) {
      assert(() { debugPrint('[FCM] Error saving token: ${e.runtimeType}'); return true; }());
    }
  }

  /// Remove FCM token from server (on logout)
  Future<void> removeTokenFromServer() async {
    try {
      if (_token == null) return;

      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      await SupabaseConfig.client
          .from('user_push_tokens')
          .delete()
          .eq('user_id', user.id)
          .eq('token', _token!);

      assert(() { debugPrint('[FCM] Token removed from server'); return true; }());
    } catch (e) {
      assert(() { debugPrint('[FCM] Error removing token: ${e.runtimeType}'); return true; }());
    }
  }

  /// Setup message handlers for foreground and background
  void setupMessageHandlers() {
    // Note: Requires firebase_messaging package
    //
    // // Foreground messages
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   debugPrint('[FCM] Foreground message: ${message.notification?.title}');
    //   _handleMessage(message);
    // });
    //
    // // Background/Terminated messages
    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //   debugPrint('[FCM] Message opened app: ${message.notification?.title}');
    //   _handleMessageTap(message);
    // });
    //
    // // Check if app was opened from notification
    // FirebaseMessaging.instance.getInitialMessage().then((message) {
    //   if (message != null) {
    //     debugPrint('[FCM] Initial message: ${message.notification?.title}');
    //     _handleMessageTap(message);
    //   }
    // });

    debugPrint('[FCM] Message handlers setup (template mode)');
  }

  /// Subscribe to a topic (e.g., channel notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      // await FirebaseMessaging.instance.subscribeToTopic(topic);
      debugPrint('[FCM] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[FCM] Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      // await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      debugPrint('[FCM] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('[FCM] Error unsubscribing from topic: $e');
    }
  }

  /// Subscribe to channel notifications
  Future<void> subscribeToChannel(String channelId) async {
    await subscribeToTopic('channel_$channelId');
  }

  /// Unsubscribe from channel notifications
  Future<void> unsubscribeFromChannel(String channelId) async {
    await unsubscribeFromTopic('channel_$channelId');
  }

  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  // /// Handle incoming message (show local notification)
  // void _handleMessage(RemoteMessage message) {
  //   // Show local notification using flutter_local_notifications
  //   // LocalNotificationService().show(
  //   //   title: message.notification?.title ?? 'New Message',
  //   //   body: message.notification?.body ?? '',
  //   //   payload: message.data.toString(),
  //   // );
  // }
  //
  // /// Handle message tap (navigate to relevant screen)
  // void _handleMessageTap(RemoteMessage message) {
  //   final data = message.data;
  //   final type = data['type'];
  //   final channelId = data['channel_id'];
  //
  //   // Navigate based on notification type
  //   switch (type) {
  //     case 'new_broadcast':
  //       // Navigate to chat thread
  //       break;
  //     case 'donation_reply':
  //       // Navigate to chat thread with message
  //       break;
  //     default:
  //       // Navigate to home
  //       break;
  //   }
  // }
}

/// Background message handler (must be top-level function)
///
/// Add this to main.dart:
/// ```dart
/// @pragma('vm:entry-point')
/// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
///   await Firebase.initializeApp();
///   debugPrint('[FCM] Background message: ${message.notification?.title}');
/// }
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
///   runApp(MyApp());
/// }
/// ```
