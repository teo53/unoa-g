import 'package:flutter/foundation.dart';

/// Centralized error handling and logging service
///
/// Provides consistent error handling across the app with
/// environment-aware logging (verbose in debug, minimal in release).
class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();

  // Error handlers for different contexts
  final List<ErrorHandler> _handlers = [];

  /// Register a custom error handler (e.g., Crashlytics, Sentry)
  void addHandler(ErrorHandler handler) {
    _handlers.add(handler);
  }

  /// Remove a registered error handler
  void removeHandler(ErrorHandler handler) {
    _handlers.remove(handler);
  }

  /// Log an error with optional stack trace
  void logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    ErrorSeverity severity = ErrorSeverity.error,
    Map<String, dynamic>? extras,
  }) {
    final message = _formatErrorMessage(error, context);

    // Debug logging
    if (kDebugMode) {
      _logToConsole(message, severity, stackTrace);
    }

    // Notify registered handlers
    for (final handler in _handlers) {
      handler.handle(
        error,
        stackTrace: stackTrace,
        context: context,
        severity: severity,
        extras: extras,
      );
    }
  }

  /// Log a warning message
  void logWarning(String message, {String? context}) {
    logError(
      message,
      context: context,
      severity: ErrorSeverity.warning,
    );
  }

  /// Log an info message
  void logInfo(String message, {String? context}) {
    if (kDebugMode) {
      debugPrint('[INFO${context != null ? '/$context' : ''}] $message');
    }
  }

  /// Log a debug message (only in debug mode)
  void logDebug(String message, {String? context}) {
    if (kDebugMode) {
      debugPrint('[DEBUG${context != null ? '/$context' : ''}] $message');
    }
  }

  String _formatErrorMessage(dynamic error, String? context) {
    final buffer = StringBuffer();
    if (context != null) {
      buffer.write('[$context] ');
    }
    buffer.write(error.toString());
    return buffer.toString();
  }

  void _logToConsole(
    String message,
    ErrorSeverity severity,
    StackTrace? stackTrace,
  ) {
    final severityLabel = severity.name.toUpperCase();
    debugPrint('[$severityLabel] $message');
    if (stackTrace != null && severity.index >= ErrorSeverity.error.index) {
      debugPrint(stackTrace.toString());
    }
  }
}

/// Error severity levels
enum ErrorSeverity {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Interface for error handlers (Crashlytics, Sentry, etc.)
abstract class ErrorHandler {
  void handle(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    ErrorSeverity severity,
    Map<String, dynamic>? extras,
  });
}

/// Console error handler for development
class ConsoleErrorHandler implements ErrorHandler {
  @override
  void handle(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    ErrorSeverity severity = ErrorSeverity.error,
    Map<String, dynamic>? extras,
  }) {
    if (kDebugMode) {
      debugPrint('=== Error Report ===');
      debugPrint('Severity: ${severity.name}');
      if (context != null) debugPrint('Context: $context');
      debugPrint('Error: $error');
      if (extras != null && extras.isNotEmpty) {
        debugPrint('Extras: $extras');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace:');
        debugPrint(stackTrace.toString());
      }
      debugPrint('===================');
    }
  }
}

/// Extension for easier error handling in async operations
extension ErrorHandling<T> on Future<T> {
  /// Handle errors with automatic logging
  Future<T> handleError({
    String? context,
    T Function(dynamic error)? fallback,
  }) async {
    try {
      return await this;
    } catch (e, stackTrace) {
      ErrorService().logError(
        e,
        stackTrace: stackTrace,
        context: context,
      );
      if (fallback != null) {
        return fallback(e);
      }
      rethrow;
    }
  }

  /// Handle errors silently (log but don't throw)
  Future<T?> handleErrorSilently({String? context}) async {
    try {
      return await this;
    } catch (e, stackTrace) {
      ErrorService().logError(
        e,
        stackTrace: stackTrace,
        context: context,
        severity: ErrorSeverity.warning,
      );
      return null;
    }
  }
}

/// Global error service instance for convenience
final errorService = ErrorService();
