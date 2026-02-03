import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// Authentication service for Supabase
class SupabaseAuthService {
  final SupabaseClient _client;

  SupabaseAuthService([SupabaseClient? client])
      : _client = client ?? SupabaseConfig.client;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
    DateTime? dateOfBirth,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (displayName != null) 'display_name': displayName,
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
      },
    );

    if (response.user == null) {
      throw AuthException('Sign up failed');
    }

    return response;
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw AuthException('Sign in failed');
    }

    return response;
  }

  /// Sign in with OAuth provider
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    final response = await _client.auth.signInWithOAuth(
      provider,
      redirectTo: kIsWeb ? null : 'com.unoa.app://callback',
    );

    return response;
  }

  /// Sign in with Kakao
  Future<bool> signInWithKakao() async {
    return signInWithOAuth(OAuthProvider.kakao);
  }

  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    return signInWithOAuth(OAuthProvider.apple);
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    return signInWithOAuth(OAuthProvider.google);
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? null : 'com.unoa.app://reset-password',
    );
  }

  /// Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Update user profile
  Future<UserResponse> updateProfile({
    String? email,
    String? displayName,
    String? avatarUrl,
  }) async {
    return await _client.auth.updateUser(
      UserAttributes(
        email: email,
        data: {
          if (displayName != null) 'display_name': displayName,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        },
      ),
    );
  }

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Get current session
  Session? get currentSession => _client.auth.currentSession;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Auth state stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Refresh session
  Future<AuthResponse> refreshSession() async {
    return await _client.auth.refreshSession();
  }

  /// Verify OTP (for phone auth if needed)
  Future<AuthResponse> verifyOTP({
    required String phone,
    required String token,
  }) async {
    return await _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  /// Resend OTP
  Future<ResendResponse> resendOTP({
    required String phone,
  }) async {
    return await _client.auth.resend(
      phone: phone,
      type: OtpType.sms,
    );
  }
}

/// Auth exception wrapper
class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, [this.code]);

  @override
  String toString() => 'AuthException: $message${code != null ? ' ($code)' : ''}';
}
