import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/config/app_config.dart';
import 'core/supabase/supabase_client.dart';
import 'core/monitoring/sentry_service.dart';
import 'services/fcm_service.dart';
import 'services/analytics_service.dart';
import 'app.dart';

// Note: Uncomment when Firebase is configured
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

/// Background message handler for FCM (must be top-level function)
///
/// Uncomment when Firebase is configured:
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   debugPrint('[FCM] Background message: ${message.notification?.title}');
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Validate configuration before any initialization
  AppConfig.validate();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize Sentry for error monitoring (safe — skips if no DSN)
  try {
    await SentryService.initialize();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Main] Sentry init failed (non-fatal): $e');
    }
  }

  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Main] Supabase init failed (non-fatal): $e');
    }
  }

  // Initialize Firebase (for FCM & Analytics)
  // Note: Uncomment when Firebase is configured with google-services.json / GoogleService-Info.plist
  // await Firebase.initializeApp();
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize FCM (push notifications) - only when crash reporting is enabled
  if (AppConfig.enableCrashReporting) {
    try {
      await FcmService().initialize();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Main] FCM init failed (non-fatal): $e');
      }
    }
  }

  // Initialize Analytics (GA4) - only when analytics is enabled
  if (AppConfig.enableAnalytics) {
    try {
      await AnalyticsService().initialize();
      await AnalyticsService().logAppOpen();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Main] Analytics init failed (non-fatal): $e');
      }
    }
  }

  // Flutter 에러 핸들러 설정
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    SentryService.captureException(
      details.exception,
      stackTrace: details.stack,
      message: details.context?.toString(),
      extras: {
        'library': details.library ?? 'unknown',
        'silent': details.silent,
      },
    );
  };

  // 플랫폼 에러 핸들러 설정
  PlatformDispatcher.instance.onError = (error, stack) {
    SentryService.captureException(error, stackTrace: stack);
    return true;
  };

  runApp(
    const ProviderScope(
      child: UnoAApp(),
    ),
  );
}
