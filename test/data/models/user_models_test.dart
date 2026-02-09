import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/user.dart';

void main() {
  group('UserAuthProfile', () {
    Map<String, dynamic> _createAuthProfileJson({
      String id = 'user-1',
      String? role,
      String? displayName = '테스트유저',
      String? avatarUrl,
      String? bio,
      String? dateOfBirth,
      bool? isBanned,
      String? locale,
      String? instagramLink,
      String? youtubeLink,
      String? tiktokLink,
      String? twitterLink,
    }) {
      return {
        'id': id,
        if (role != null) 'role': role,
        'display_name': displayName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (bio != null) 'bio': bio,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
        if (isBanned != null) 'is_banned': isBanned,
        if (locale != null) 'locale': locale,
        'created_at': '2024-01-01T00:00:00.000Z',
        if (instagramLink != null) 'instagram_link': instagramLink,
        if (youtubeLink != null) 'youtube_link': youtubeLink,
        if (tiktokLink != null) 'tiktok_link': tiktokLink,
        if (twitterLink != null) 'twitter_link': twitterLink,
      };
    }

    group('fromJson / toJson', () {
      test('round-trips all fields correctly', () {
        final json = _createAuthProfileJson(
          role: 'creator',
          bio: '안녕하세요',
          instagramLink: 'https://instagram.com/test',
        );
        final profile = UserAuthProfile.fromJson(json);
        final restored = UserAuthProfile.fromJson(profile.toJson());

        expect(restored.id, equals('user-1'));
        expect(restored.role, equals('creator'));
        expect(restored.displayName, equals('테스트유저'));
        expect(restored.bio, equals('안녕하세요'));
        expect(restored.instagramLink, equals('https://instagram.com/test'));
      });

      test('defaults role to fan when absent', () {
        final json = _createAuthProfileJson();
        final profile = UserAuthProfile.fromJson(json);
        expect(profile.role, equals('fan'));
      });

      test('defaults isBanned to false and locale to ko-KR', () {
        final json = _createAuthProfileJson();
        final profile = UserAuthProfile.fromJson(json);
        expect(profile.isBanned, isFalse);
        expect(profile.locale, equals('ko-KR'));
      });
    });

    group('role helpers', () {
      test('isFan returns true for fan role', () {
        final profile = UserAuthProfile.fromJson(
          _createAuthProfileJson(role: 'fan'),
        );
        expect(profile.isFan, isTrue);
        expect(profile.isCreator, isFalse);
      });

      test('isCreator returns true for creator role', () {
        final profile = UserAuthProfile.fromJson(
          _createAuthProfileJson(role: 'creator'),
        );
        expect(profile.isCreator, isTrue);
        expect(profile.isFan, isFalse);
      });

      test('isCreatorManager returns true for creator_manager role', () {
        final profile = UserAuthProfile.fromJson(
          _createAuthProfileJson(role: 'creator_manager'),
        );
        expect(profile.isCreatorManager, isTrue);
      });

      test('isAdmin returns true for admin role', () {
        final profile = UserAuthProfile.fromJson(
          _createAuthProfileJson(role: 'admin'),
        );
        expect(profile.isAdmin, isTrue);
      });
    });

    group('age verification', () {
      test('age calculates correctly from dateOfBirth', () {
        final yearsAgo =
            DateTime.now().subtract(const Duration(days: 365 * 20));
        final profile = UserAuthProfile.fromJson(
          _createAuthProfileJson(
            dateOfBirth: yearsAgo.toIso8601String(),
          ),
        );
        expect(profile.age, greaterThanOrEqualTo(19));
        expect(profile.age, lessThanOrEqualTo(21));
      });

      test('isMinorUnder14 returns true for young user', () {
        final yearsAgo =
            DateTime.now().subtract(const Duration(days: 365 * 10));
        final profile = UserAuthProfile.fromJson(
          _createAuthProfileJson(
            dateOfBirth: yearsAgo.toIso8601String(),
          ),
        );
        expect(profile.isMinorUnder14, isTrue);
      });

      test('isMinorUnder14 returns false when dateOfBirth is null', () {
        final profile = UserAuthProfile.fromJson(
          _createAuthProfileJson(),
        );
        expect(profile.age, isNull);
        expect(profile.isMinorUnder14, isFalse);
      });
    });

    group('copyWith sentinel', () {
      test('preserves unchanged values', () {
        final profile = UserAuthProfile.fromJson(
          _createAuthProfileJson(
            instagramLink: 'https://instagram.com/test',
          ),
        );
        final copy = profile.copyWith(displayName: '새이름');

        expect(copy.displayName, equals('새이름'));
        expect(copy.instagramLink, equals('https://instagram.com/test'));
      });

      test('can set instagramLink to null using sentinel', () {
        final profile = UserAuthProfile.fromJson(
          _createAuthProfileJson(
            instagramLink: 'https://instagram.com/test',
          ),
        );
        final copy = profile.copyWith(instagramLink: null);

        expect(copy.instagramLink, isNull);
      });
    });
  });

  group('UserDisplayProfile', () {
    Map<String, dynamic> _createDisplayProfileJson({
      String id = 'user-1',
      String name = '테스트유저',
      String? englishName,
      String username = 'testuser',
      String? avatarUrl,
      String tier = 'STANDARD',
      int subscriptionCount = 2,
      int dtBalance = 5000,
    }) {
      return {
        'id': id,
        'display_name': name,
        if (englishName != null) 'english_name': englishName,
        'username': username,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'tier': tier,
        'subscription_count': subscriptionCount,
        'dt_balance': dtBalance,
      };
    }

    group('fromJson / toJson', () {
      test('round-trips all fields correctly', () {
        final json = _createDisplayProfileJson(
          englishName: 'TestUser',
          dtBalance: 10000,
        );
        final profile = UserDisplayProfile.fromJson(json);
        final restored = UserDisplayProfile.fromJson(profile.toJson());

        expect(restored.id, equals('user-1'));
        expect(restored.name, equals('테스트유저'));
        expect(restored.englishName, equals('TestUser'));
        expect(restored.dtBalance, equals(10000));
      });
    });

    group('displayName', () {
      test('includes English name in parentheses when available', () {
        final profile = UserDisplayProfile.fromJson(
          _createDisplayProfileJson(englishName: 'TestUser'),
        );
        expect(profile.displayName, equals('테스트유저 (TestUser)'));
      });

      test('returns name only when no English name', () {
        final profile = UserDisplayProfile.fromJson(
          _createDisplayProfileJson(),
        );
        expect(profile.displayName, equals('테스트유저'));
      });
    });

    group('tierBadge', () {
      test('returns diamond VIP badge', () {
        final profile = UserDisplayProfile.fromJson(
          _createDisplayProfileJson(tier: 'VIP'),
        );
        expect(profile.tierBadge, equals('💎 VIP'));
      });

      test('returns star STANDARD badge', () {
        final profile = UserDisplayProfile.fromJson(
          _createDisplayProfileJson(tier: 'STANDARD'),
        );
        expect(profile.tierBadge, equals('⭐ STANDARD'));
      });
    });

    group('formattedBalance', () {
      test('returns correct DT format', () {
        final profile = UserDisplayProfile.fromJson(
          _createDisplayProfileJson(dtBalance: 15000),
        );
        expect(profile.formattedBalance, equals('15000 DT'));
      });
    });

    group('copyWith', () {
      test('preserves unchanged values', () {
        final profile = UserDisplayProfile.fromJson(
          _createDisplayProfileJson(dtBalance: 5000),
        );
        final copy = profile.copyWith(tier: 'VIP');

        expect(copy.tier, equals('VIP'));
        expect(copy.dtBalance, equals(5000));
        expect(copy.name, equals('테스트유저'));
      });
    });
  });
}
