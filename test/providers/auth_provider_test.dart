import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/providers/auth_provider.dart';
import 'package:uno_a_flutter/core/config/demo_config.dart';

void main() {
  group('AuthState', () {
    test('AuthInitial is created', () {
      const state = AuthInitial();
      expect(state, isA<AuthState>());
    });

    test('AuthLoading is created', () {
      const state = AuthLoading();
      expect(state, isA<AuthState>());
    });

    test('AuthUnauthenticated with optional message', () {
      const state1 = AuthUnauthenticated();
      expect(state1.message, isNull);

      const state2 = AuthUnauthenticated('Session expired');
      expect(state2.message, 'Session expired');
    });

    test('AuthError holds message and optional error', () {
      const state1 = AuthError('Something failed');
      expect(state1.message, 'Something failed');
      expect(state1.error, isNull);

      final error = Exception('test');
      final state2 = AuthError('Failed', error);
      expect(state2.message, 'Failed');
      expect(state2.error, error);
    });

    test('AuthDemoMode holds demo profile', () {
      final profile = UserAuthProfile(
        id: DemoConfig.demoFanId,
        role: 'fan',
        displayName: DemoConfig.demoFanName,
        createdAt: DateTime.now(),
      );
      final state = AuthDemoMode(demoProfile: profile);
      expect(state.demoProfile.id, DemoConfig.demoFanId);
      expect(state.demoProfile.role, 'fan');
      expect(state.demoProfile.displayName, DemoConfig.demoFanName);
    });
  });

  group('UserAuthProfile', () {
    test('fan profile', () {
      final profile = UserAuthProfile(
        id: 'test-id',
        role: 'fan',
        displayName: 'TestUser',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(profile.isFan, true);
      expect(profile.isCreator, false);
      expect(profile.isAdmin, false);
    });

    test('creator profile', () {
      final profile = UserAuthProfile(
        id: 'test-id',
        role: 'creator',
        displayName: 'Creator',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(profile.isFan, false);
      expect(profile.isCreator, true);
      expect(profile.isAdmin, false);
    });

    test('admin profile', () {
      final profile = UserAuthProfile(
        id: 'test-id',
        role: 'admin',
        displayName: 'Admin',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(profile.isFan, false);
      expect(profile.isCreator, false);
      expect(profile.isAdmin, true);
    });

    test('demo fan profile uses DemoConfig', () {
      final profile = UserAuthProfile(
        id: DemoConfig.demoFanId,
        role: 'fan',
        displayName: DemoConfig.demoFanName,
        bio: DemoConfig.demoFanBio,
        createdAt: DateTime.now(),
      );
      expect(profile.id, 'demo_user_001');
      expect(profile.displayName, '데모 팬');
      expect(profile.bio, DemoConfig.demoFanBio);
    });

    test('demo creator profile uses DemoConfig', () {
      final profile = UserAuthProfile(
        id: DemoConfig.demoCreatorId,
        role: 'creator',
        displayName: DemoConfig.demoCreatorName,
        avatarUrl: DemoConfig.demoCreatorAvatarUrl,
        bio: DemoConfig.demoCreatorBio,
        createdAt: DateTime.now(),
      );
      expect(profile.id, 'demo_creator_001');
      expect(profile.displayName, '하늘달 (데모)');
      expect(profile.isCreator, true);
    });
  });

  group('DemoConfig integration', () {
    test('demoChannelId exists', () {
      expect(DemoConfig.demoChannelId, isNotEmpty);
    });

    test('demoCreatorId exists', () {
      expect(DemoConfig.demoCreatorId, isNotEmpty);
    });

    test('demoFanId exists', () {
      expect(DemoConfig.demoFanId, isNotEmpty);
    });

    test('initialDtBalance is positive', () {
      expect(DemoConfig.initialDtBalance, greaterThan(0));
    });

    test('avatarUrl generates valid URL', () {
      final url = DemoConfig.avatarUrl('test');
      expect(url, contains('picsum.photos'));
      expect(url, contains('test'));
    });
  });
}
