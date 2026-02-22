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

  /// Check if running in beta mode
  static bool get isBeta => environment == 'beta';

  // ============================================================
  // Supabase Configuration
  // ============================================================

  /// Supabase project URL (must be provided via --dart-define for non-dev builds)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://placeholder.supabase.co',
  );

  /// Supabase anonymous key (must be provided via --dart-define for non-dev builds)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Development-only fallback credentials.
  // Provide real values via --dart-define=SUPABASE_URL=... at build time.
  // NEVER commit real credentials here — use CI/CD secrets.
  static const String _devFallbackUrl = 'https://REPLACE-ME-dev.supabase.co';
  static const String _devFallbackKey = 'dev-key-not-set--run-with-dart-define';

  /// Effective Supabase URL — uses dev fallback only in development mode.
  static String get effectiveSupabaseUrl {
    if (supabaseUrl != 'https://placeholder.supabase.co' &&
        supabaseUrl.isNotEmpty) {
      return supabaseUrl;
    }
    // Only use fallback if it contains a real URL (not the placeholder)
    if (isDevelopment && !_devFallbackUrl.contains('REPLACE-ME')) {
      return _devFallbackUrl;
    }
    if (isDevelopment) {
      assert(() {
        debugLog(
            '\u26a0\ufe0f SUPABASE_URL not set. Run with: --dart-define=SUPABASE_URL=...');
        return true;
      }());
    }
    return supabaseUrl; // will be placeholder → validate() catches this
  }

  /// Effective Supabase anon key — uses dev fallback only in development mode.
  static String get effectiveSupabaseAnonKey {
    if (supabaseAnonKey.isNotEmpty) return supabaseAnonKey;
    // Only use fallback if it looks like a real JWT (starts with 'eyJ')
    if (isDevelopment && _devFallbackKey.startsWith('eyJ')) {
      return _devFallbackKey;
    }
    if (isDevelopment) {
      assert(() {
        debugLog(
            '\u26a0\ufe0f SUPABASE_ANON_KEY not set. Run with: --dart-define=SUPABASE_ANON_KEY=...');
        return true;
      }());
    }
    return supabaseAnonKey; // will be empty → validate() catches this
  }

  // ============================================================
  // Firebase Configuration
  // ============================================================

  /// Firebase project ID
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );

  /// Sentry DSN for error monitoring
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  // ============================================================
  // Feature Flags
  // ============================================================

  /// Enable demo mode (allows app usage without real authentication)
  /// 프로덕션에서는 반드시 ENABLE_DEMO=false로 빌드해야 합니다.
  static bool get enableDemoMode =>
      isDevelopment ||
      isBeta ||
      const bool.fromEnvironment('ENABLE_DEMO', defaultValue: false);

  /// Enable analytics tracking
  static bool get enableAnalytics =>
      isProduction ||
      const bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: false);

  /// Enable crash reporting
  static bool get enableCrashReporting =>
      isProduction ||
      isBeta ||
      isStaging ||
      const bool.fromEnvironment('ENABLE_CRASH_REPORTING', defaultValue: false);

  /// Enable verbose logging
  static bool get enableVerboseLogging =>
      isDevelopment ||
      const bool.fromEnvironment('VERBOSE_LOGGING', defaultValue: false);

  // ============================================================
  // Payment Configuration
  // ============================================================

  /// PortOne Store ID for payment processing
  static const String portOneStoreId = String.fromEnvironment(
    'PORTONE_STORE_ID',
    defaultValue: '',
  );

  /// Enable DT purchase flow (checkout/confirm/webhook gate alignment)
  static const bool enableDtPurchase = bool.fromEnvironment(
    'ENABLE_DT_PURCHASE',
    defaultValue: false,
  );

  /// PortOne Channel Key for payment processing
  static const String portOneChannelKey = String.fromEnvironment(
    'PORTONE_CHANNEL_KEY',
    defaultValue: '',
  );

  /// Enable In-App Purchase (iOS/Android only, web uses PortOne)
  static const bool enableIap = bool.fromEnvironment(
    'ENABLE_IAP',
    defaultValue: false,
  );

  // ============================================================
  // Storage Configuration
  // ============================================================

  /// Use signed URLs for private storage buckets
  /// Set to true when user-content bucket is switched to private
  static const bool usePrivateStorageBucket = bool.fromEnvironment(
    'USE_PRIVATE_STORAGE',
    defaultValue: false,
  );

  // ============================================================
  // Legal URLs
  // ============================================================

  /// Public privacy policy URL (required for store submission)
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: '',
  );

  /// Public terms of service URL (required for store submission)
  static const String termsOfServiceUrl = String.fromEnvironment(
    'TERMS_URL',
    defaultValue: '',
  );

  /// Effective privacy policy URL with fallback for development.
  static String get effectivePrivacyPolicyUrl => privacyPolicyUrl.isNotEmpty
      ? privacyPolicyUrl
      : 'https://unoa.app/privacy';

  /// Effective terms of service URL with fallback for development.
  static String get effectiveTermsOfServiceUrl => termsOfServiceUrl.isNotEmpty
      ? termsOfServiceUrl
      : 'https://unoa.app/terms';

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
        'DT Purchase Enabled: $enableDtPurchase\n'
        'Analytics: $enableAnalytics\n'
        'Supabase URL: $effectiveSupabaseUrl\n'
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

  // ============================================================
  // Runtime Validation
  // ============================================================

  /// Validate critical configuration at startup.
  /// Throws [StateError] if production/staging configuration is incomplete.
  static void validate() {
    final errors = <String>[];

    if (isProduction || isStaging || isBeta) {
      if (supabaseUrl == 'https://placeholder.supabase.co' ||
          supabaseUrl == 'https://your-project.supabase.co' ||
          supabaseUrl.isEmpty) {
        errors.add('SUPABASE_URL is not configured');
      }
      if (supabaseAnonKey.isEmpty) {
        errors.add('SUPABASE_ANON_KEY is not configured');
      }
    }

    if (isProduction) {
      if (sentryDsn.isEmpty) {
        errors.add('SENTRY_DSN is not configured for production');
      }
      if (enableDemoMode) {
        errors.add(
            'ENABLE_DEMO should be false in production (set --dart-define=ENABLE_DEMO=false)');
      }
      if (privacyPolicyUrl.isEmpty) {
        errors.add('PRIVACY_POLICY_URL is not configured for production '
            '(set --dart-define=PRIVACY_POLICY_URL=https://...)');
      }
      if (termsOfServiceUrl.isEmpty) {
        errors.add('TERMS_URL is not configured for production '
            '(set --dart-define=TERMS_URL=https://...)');
      }

      // P1-2 FIX: Validate payment configuration in production
      if (enableDtPurchase) {
        if (portOneStoreId.isEmpty) {
          errors
              .add('PORTONE_STORE_ID is required when ENABLE_DT_PURCHASE=true '
                  '(set --dart-define=PORTONE_STORE_ID=...)');
        }
        if (portOneChannelKey.isEmpty) {
          errors.add(
              'PORTONE_CHANNEL_KEY is required when ENABLE_DT_PURCHASE=true '
              '(set --dart-define=PORTONE_CHANNEL_KEY=...)');
        }
      }
      if (enableIap) {
        // IAP keys live server-side, so we just log a notice
        debugLog(
            'ℹ️ ENABLE_IAP=true — ensure IAP_VERIFY_ENABLED + Apple/Google keys are set on Supabase Edge Functions');
      }
    }

    if (errors.isNotEmpty) {
      throw StateError(
        'AppConfig validation failed for $environment:\n'
        '${errors.map((e) => '  - $e').join('\n')}\n\n'
        'Please provide all required --dart-define flags.',
      );
    }

    debugLog('AppConfig validation passed for $environment');
  }
}
