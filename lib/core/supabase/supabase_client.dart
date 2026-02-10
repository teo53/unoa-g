import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration and client initialization
class SupabaseConfig {
  // These should be provided via environment variables or --dart-define
  // flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  /// Initialize Supabase client
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: kDebugMode,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 10,
      ),
      storageOptions: const StorageClientOptions(
        retryAttempts: 3,
      ),
    );

    if (kDebugMode) {
      debugPrint('[SupabaseConfig] Initialized with URL: $supabaseUrl');
    }
  }

  /// Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Get current user
  static User? get currentUser => client.auth.currentUser;

  /// Get current session
  static Session? get currentSession => client.auth.currentSession;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get auth state stream
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}

/// Extension methods for SupabaseClient
extension SupabaseClientExtension on SupabaseClient {
  /// Get the current user's ID or throw
  String get currentUserId {
    final user = auth.currentUser;
    if (user == null) {
      throw StateError('User is not authenticated');
    }
    return user.id;
  }

  /// Check if current user has a specific role
  Future<bool> hasRole(String role) async {
    final userId = auth.currentUser?.id;
    if (userId == null) return false;

    final response =
        await from('user_profiles').select('role').eq('id', userId).single();

    return response['role'] == role;
  }

  /// Check if current user is admin
  Future<bool> get isAdmin => hasRole('admin');

  /// Check if current user is creator
  Future<bool> get isCreator => hasRole('creator');
}

/// Convenience getter for Supabase client
SupabaseClient get supabase => SupabaseConfig.client;
