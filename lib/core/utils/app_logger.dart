import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../monitoring/sentry_service.dart';

/// Centralized application logger.
///
/// Respects [kDebugMode] and [AppConfig.enableVerboseLogging].
/// - [debug] / [info]: console-only in debug or verbose mode
/// - [warning]: console in debug + Sentry in release
/// - [error]: always Sentry + console in debug
class AppLogger {
  AppLogger._();

  static void debug(String message, {String? tag}) {
    if (kDebugMode || AppConfig.enableVerboseLogging) {
      debugPrint('[${tag ?? 'DEBUG'}] $message');
    }
  }

  static void info(String message, {String? tag}) {
    if (kDebugMode || AppConfig.enableVerboseLogging) {
      debugPrint('[${tag ?? 'INFO'}] $message');
    }
  }

  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[WARN${tag != null ? '/$tag' : ''}] $message');
    }
    if (!kDebugMode) {
      SentryService.captureMessage(
        '${tag != null ? '[$tag] ' : ''}$message',
      );
    }
  }

  static void error(
    dynamic error, {
    StackTrace? stackTrace,
    String? tag,
    String? message,
    Map<String, dynamic>? extras,
  }) {
    if (kDebugMode) {
      debugPrint('[ERROR${tag != null ? '/$tag' : ''}] $error');
      if (message != null) debugPrint('  message: $message');
      if (stackTrace != null) debugPrint('$stackTrace');
    }
    SentryService.captureException(
      error,
      stackTrace: stackTrace,
      message: message ?? tag,
      extras: extras,
    );
  }
}
