import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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
  // Sentry 초기화를 위해 runZonedGuarded 사용
  await runZonedGuarded(() async {
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

    // Initialize Sentry for error monitoring
    await SentryService.initialize();

    // Initialize Supabase
    await SupabaseConfig.initialize();

    // Initialize Firebase (for FCM & Analytics)
    // Note: Uncomment when Firebase is configured with google-services.json / GoogleService-Info.plist
    // await Firebase.initializeApp();
    // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize FCM (push notifications) - only when crash reporting is enabled
    if (AppConfig.enableCrashReporting) {
      await FcmService().initialize();
    }

    // Initialize Analytics (GA4) - only when analytics is enabled
    if (AppConfig.enableAnalytics) {
      await AnalyticsService().initialize();
      await AnalyticsService().logAppOpen();
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
      // Sentry 위젯 래핑 (네비게이션 추적 등)
      SentryWidget(
        child: const ProviderScope(
          child: UnoAApp(),
        ),
      ),
    );
  }, (error, stackTrace) {
    // Zone 에러 캡처
    SentryService.captureException(error, stackTrace: stackTrace);
    if (kDebugMode) {
      debugPrint('[ZoneError] $error');
      debugPrint('[StackTrace] $stackTrace');
    }
  });
}
