import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';
import '../core/supabase/supabase_auth_service.dart';
import '../core/config/demo_config.dart';
import '../data/models/user.dart';

// Re-export unified user models for backward compatibility
export '../data/models/user.dart' show UserAuthProfile, UserDisplayProfile, UserBase;

/// Sentinel for updateDemoProfile to distinguish "not provided" from "null"
const Object _demoSentinel = Object();

/// @deprecated Use [UserAuthProfile] from data/models/user.dart instead
/// Kept as typedef for backward compatibility
typedef UserProfile = UserAuthProfile;

/// Authentication state
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  final UserProfile profile;

  const AuthAuthenticated({
    required this.user,
    required this.profile,
  });
}

class AuthUnauthenticated extends AuthState {
  final String? message;

  const AuthUnauthenticated([this.message]);
}

class AuthError extends AuthState {
  final String message;
  final Object? error;

  const AuthError(this.message, [this.error]);
}

/// Demo mode authenticated state (no real user)
class AuthDemoMode extends AuthState {
  final UserProfile demoProfile;

  const AuthDemoMode({required this.demoProfile});
}

/// Auth notifier for managing authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseAuthService _authService;
  final SupabaseClient _client;
  StreamSubscription? _authSubscription;

  AuthNotifier(this._authService, this._client) : super(const AuthInitial()) {
    _initialize();
  }

  void _initialize() {
    // Listen to auth state changes
    _authSubscription = _client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final event = data.event;

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.userUpdated) {
        if (session?.user != null) {
          await _loadUserProfile(session!.user);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        state = const AuthUnauthenticated();
      }
    });

    // Check initial session
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    state = const AuthLoading();

    try {
      final session = _client.auth.currentSession;
      if (session?.user != null) {
        await _loadUserProfile(session!.user);
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      state = AuthError('Failed to check session', e);
    }
  }

  Future<void> _loadUserProfile(User user) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        // Profile doesn't exist yet (shouldn't happen due to trigger)
        state = AuthAuthenticated(
          user: user,
          profile: UserProfile(
            id: user.id,
            role: 'fan',
            displayName: user.userMetadata?['display_name'] as String? ??
                user.email?.split('@').first,
            avatarUrl: user.userMetadata?['avatar_url'] as String?,
            createdAt: DateTime.now(),
          ),
        );
      } else {
        final profile = UserProfile.fromJson(response);

        if (profile.isBanned) {
          await signOut();
          state = const AuthUnauthenticated('계정이 정지되었습니다.');
          return;
        }

        state = AuthAuthenticated(user: user, profile: profile);
      }
    } catch (e) {
      state = AuthError('Failed to load profile', e);
    }
  }

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
    DateTime? dateOfBirth,
  }) async {
    state = const AuthLoading();

    try {
      await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
        dateOfBirth: dateOfBirth,
      );
      // Auth state listener will handle the rest
    } catch (e) {
      state = AuthError('회원가입에 실패했습니다.', e);
    }
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();

    try {
      await _authService.signIn(email: email, password: password);
      // Auth state listener will handle the rest
    } catch (e) {
      state = AuthError('로그인에 실패했습니다. 이메일과 비밀번호를 확인해주세요.', e);
    }
  }

  /// Sign in with Kakao
  Future<void> signInWithKakao() async {
    state = const AuthLoading();

    try {
      await _authService.signInWithKakao();
    } catch (e) {
      state = AuthError('카카오 로그인에 실패했습니다.', e);
    }
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    state = const AuthLoading();

    try {
      await _authService.signInWithApple();
    } catch (e) {
      state = AuthError('Apple 로그인에 실패했습니다.', e);
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = const AuthLoading();

    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      state = AuthError('Google 로그인에 실패했습니다.', e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthError('로그아웃에 실패했습니다.', e);
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    try {
      // Update auth user metadata
      if (displayName != null || avatarUrl != null) {
        await _authService.updateProfile(
          displayName: displayName,
          avatarUrl: avatarUrl,
        );
      }

      // Update profile in database
      await _client.from('user_profiles').update({
        if (displayName != null) 'display_name': displayName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (bio != null) 'bio': bio,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentState.user.id);

      // Reload profile
      await _loadUserProfile(currentState.user);
    } catch (e) {
      state = AuthError('프로필 업데이트에 실패했습니다.', e);
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      throw Exception('비밀번호 재설정 이메일 발송에 실패했습니다.');
    }
  }

  /// Sign in with email (alias for signIn)
  Future<void> signInWithEmail(String email, String password) async {
    await signIn(email: email, password: password);
  }

  /// Sign up with email (alias for signUp)
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
    DateTime? dateOfBirth,
  }) async {
    await signUp(
      email: email,
      password: password,
      displayName: displayName,
      dateOfBirth: dateOfBirth,
    );
  }

  /// Record guardian consent for minors
  Future<void> recordGuardianConsent() async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    try {
      await _client.from('user_profiles').update({
        'guardian_consent_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentState.user.id);

      // Reload profile
      await _loadUserProfile(currentState.user);
    } catch (e) {
      throw Exception('법정대리인 동의 기록에 실패했습니다.');
    }
  }

  /// Enter demo mode without authentication
  /// [asCreator] - if true, enters as creator/artist demo account
  void enterDemoMode({bool asCreator = false}) {
    final demoProfile = asCreator
        ? UserProfile(
            id: DemoConfig.demoCreatorId,
            role: 'creator',
            displayName: DemoConfig.demoCreatorName,
            avatarUrl: DemoConfig.demoCreatorAvatarUrl,
            bio: DemoConfig.demoCreatorBio,
            createdAt: DateTime.now().subtract(
              Duration(days: DemoConfig.demoAccountCreatedDaysAgo),
            ),
          )
        : UserProfile(
            id: DemoConfig.demoFanId,
            role: 'fan',
            displayName: DemoConfig.demoFanName,
            avatarUrl: null,
            bio: DemoConfig.demoFanBio,
            createdAt: DateTime.now(),
          );
    state = AuthDemoMode(demoProfile: demoProfile);
  }

  /// Enter demo mode as fan
  void enterDemoModeAsFan() {
    enterDemoMode(asCreator: false);
  }

  /// Enter demo mode as creator
  void enterDemoModeAsCreator() {
    enterDemoMode(asCreator: true);
  }

  /// Exit demo mode
  void exitDemoMode() {
    state = const AuthUnauthenticated();
  }

  /// Update demo profile (for demo mode only)
  ///
  /// Social link fields use [Object?] with sentinel to distinguish
  /// "not provided" (keep existing) from "set to null" (clear the field).
  /// Pass `null` explicitly to clear a social link.
  /// Omit the parameter to keep the existing value.
  void updateDemoProfile({
    String? displayName,
    String? avatarUrl,
    String? bio,
    int? themeColorIndex,
    Object? instagramLink = _demoSentinel,
    Object? youtubeLink = _demoSentinel,
    Object? tiktokLink = _demoSentinel,
    Object? twitterLink = _demoSentinel,
  }) {
    final currentState = state;
    if (currentState is! AuthDemoMode) return;

    final updatedProfile = currentState.demoProfile.copyWith(
      displayName: displayName,
      avatarUrl: avatarUrl,
      bio: bio,
      themeColorIndex: themeColorIndex,
      instagramLink: instagramLink == _demoSentinel
          ? currentState.demoProfile.instagramLink
          : instagramLink,
      youtubeLink: youtubeLink == _demoSentinel
          ? currentState.demoProfile.youtubeLink
          : youtubeLink,
      tiktokLink: tiktokLink == _demoSentinel
          ? currentState.demoProfile.tiktokLink
          : tiktokLink,
      twitterLink: twitterLink == _demoSentinel
          ? currentState.demoProfile.twitterLink
          : twitterLink,
    );

    state = AuthDemoMode(demoProfile: updatedProfile);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseConfig.client;
});

/// Auth service provider
final authServiceProvider = Provider<SupabaseAuthService>((ref) {
  return SupabaseAuthService(ref.watch(supabaseClientProvider));
});

/// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(supabaseClientProvider),
  );
});

/// Current user provider (convenience)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return authState.user;
  }
  return null;
});

/// Current user profile provider (convenience) - includes demo mode
final currentProfileProvider = Provider<UserProfile?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return authState.profile;
  }
  if (authState is AuthDemoMode) {
    return authState.demoProfile;
  }
  return null;
});

/// Is authenticated provider (convenience) - includes demo mode
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthAuthenticated || authState is AuthDemoMode;
});

/// Is demo mode provider
final isDemoModeProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is AuthDemoMode;
});

/// Is creator provider (convenience)
final isCreatorProvider = Provider<bool>((ref) {
  final profile = ref.watch(currentProfileProvider);
  return profile?.isCreator ?? false;
});

/// Is admin provider (convenience)
final isAdminProvider = Provider<bool>((ref) {
  final profile = ref.watch(currentProfileProvider);
  return profile?.isAdmin ?? false;
});
