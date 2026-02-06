/// Application Environment Configuration
///
/// Centralized configuration for environment-specific settings.
/// Values can be overridden at build time using --dart-define flags.
///
/// Usage:
/// ```bash
/// flutter run --dart-define=ENV=production --dart-define=SUPABASE_URL=https://xxx.supabase.co
/// ```
class AppConfig {
  AppConfig._();

  // ============================================================
  // Environment Settings
  // ============================================================

  /// Current environment: 'development', 'staging', or 'production'
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  /// Check if running in development mode
  static bool get isDevelopment => environment == 'development';

  /// Check if running in staging mode
  static bool get isStaging => environment == 'staging';

  /// Check if running in production mode
  static bool get isProduction => environment == 'production';

  // ============================================================
  // Supabase Configuration
  // ============================================================

  /// Supabase project URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );

  /// Supabase anonymous key for client-side access
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // ============================================================
  // Firebase Configuration
  // ============================================================

  /// Firebase project ID
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'unoa-app-demo',
  );

  // ============================================================
  // Feature Flags
  // ============================================================

  /// Enable demo mode (allows app usage without real authentication)
  static bool get enableDemoMode =>
      isDevelopment ||
      const bool.fromEnvironment('ENABLE_DEMO', defaultValue: true);

  /// Enable analytics tracking
  static bool get enableAnalytics =>
      isProduction ||
      const bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: false);

  /// Enable crash reporting
  static bool get enableCrashReporting =>
      isProduction ||
      const bool.fromEnvironment('ENABLE_CRASH_REPORTING', defaultValue: false);

  /// Enable verbose logging
  static bool get enableVerboseLogging =>
      isDevelopment ||
      const bool.fromEnvironment('VERBOSE_LOGGING', defaultValue: false);

  // ============================================================
  // API Configuration
  // ============================================================

  /// API request timeout in seconds
  static const int apiTimeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT',
    defaultValue: 30,
  );

  /// Maximum retry attempts for failed API calls
  static const int maxRetryAttempts = int.fromEnvironment(
    'MAX_RETRY_ATTEMPTS',
    defaultValue: 3,
  );

  // ============================================================
  // App Info
  // ============================================================

  /// Application name
  static const String appName = 'UNO A';

  /// Current app version (should match pubspec.yaml)
  static const String appVersion = '1.0.0';

  /// Build number
  static const String buildNumber = String.fromEnvironment(
    'BUILD_NUMBER',
    defaultValue: '1',
  );

  // ============================================================
  // Debug Helpers
  // ============================================================

  /// Print current configuration (for debugging)
  /// Uses debugPrint which is appropriate for development
  static void printConfig() {
    if (!enableVerboseLogging) return;

    // ignore: avoid_print
    debugLog('=== AppConfig ===\n'
        'Environment: $environment\n'
        'Demo Mode: $enableDemoMode\n'
        'Analytics: $enableAnalytics\n'
        'Supabase URL: $supabaseUrl\n'
        'Firebase Project: $firebaseProjectId\n'
        '=================');
  }

  /// Debug log helper (only prints in development)
  static void debugLog(String message) {
    if (isDevelopment || enableVerboseLogging) {
      // Using assert to only run in debug mode
      assert(() {
        // ignore: avoid_print
        print(message);
        return true;
      }());
    }
  }
}
