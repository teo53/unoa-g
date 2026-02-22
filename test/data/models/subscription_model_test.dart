// Supplementary tests for [Subscription] and [Channel] models.
//
// channel_test.dart already covers the basic fromJson/toJson round-trip and
// the broad formattedDuration buckets.  This file fills the gaps:
//
// - fromJson / toJson round-trip (independent, self-contained coverage)
// - daysSubscribed with fixed past dates
// - formattedDuration exact boundary values:
//     0 days  → '오늘 시작'
//     1 day   → '1일째'    (missing from channel_test.dart)
//     2 days  → '2일째'
//     29 days → '29일째'   (last day < 30)
//     30 days → '1개월째'  (first day >= 30)
//     31 days → '1개월째'
//     59 days → '1개월째'  (59 // 30 == 1)
//     60 days → '2개월째'
//     364 days → '12개월째' (last day < 365)
//     365 days → '1년째'   (first day >= 365)
//     730 days → '2년째'
// - Channel fromJson / toJson round-trip (independent coverage)

import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/channel.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _subscriptionJson({
  String id = 'sub-1',
  String userId = 'user-1',
  String channelId = 'channel-1',
  String tier = 'STANDARD',
  required String startedAt,
  String? expiresAt,
  bool isActive = true,
  bool autoRenew = true,
}) {
  return {
    'id': id,
    'user_id': userId,
    'channel_id': channelId,
    'tier': tier,
    'started_at': startedAt,
    if (expiresAt != null) 'expires_at': expiresAt,
    'is_active': isActive,
    'auto_renew': autoRenew,
    'created_at': '2024-01-01T00:00:00.000Z',
    'updated_at': '2024-01-15T00:00:00.000Z',
  };
}

/// Creates a Subscription whose startedAt is exactly [daysAgo] days before now.
Subscription _subDaysAgo(int daysAgo) {
  final startedAt = DateTime.now().subtract(Duration(days: daysAgo));
  return Subscription.fromJson(
    _subscriptionJson(startedAt: startedAt.toIso8601String()),
  );
}

Map<String, dynamic> _channelJson() => {
      'id': 'ch-1',
      'artist_id': 'artist-1',
      'name': '테스트 채널',
      'description': '채널 설명',
      'avatar_url': 'https://example.com/avatar.jpg',
      'is_active': true,
      'created_at': '2024-03-01T10:00:00.000Z',
      'updated_at': '2024-03-15T10:00:00.000Z',
      'theme_color_index': 2,
      'screenshot_warning_enabled': false,
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Subscription — fromJson / toJson round-trip
  // -------------------------------------------------------------------------

  group('Subscription fromJson / toJson round-trip', () {
    test('persists all scalar fields', () {
      final json = _subscriptionJson(
        id: 'sub-rt',
        userId: 'u-rt',
        channelId: 'ch-rt',
        tier: 'VIP',
        startedAt: '2023-06-15T08:00:00.000Z',
        expiresAt: '2024-06-15T08:00:00.000Z',
        isActive: true,
        autoRenew: false,
      );

      final original = Subscription.fromJson(json);
      final restored = Subscription.fromJson(original.toJson());

      expect(restored.id, equals('sub-rt'));
      expect(restored.userId, equals('u-rt'));
      expect(restored.channelId, equals('ch-rt'));
      expect(restored.tier, equals('VIP'));
      expect(restored.isActive, isTrue);
      expect(restored.autoRenew, isFalse);
      expect(restored.startedAt.toIso8601String(),
          equals(original.startedAt.toIso8601String()));
      expect(restored.expiresAt, isNotNull);
      expect(restored.expiresAt!.toIso8601String(),
          equals(original.expiresAt!.toIso8601String()));
    });

    test('null expiresAt survives round-trip', () {
      final json = _subscriptionJson(
        startedAt: '2024-01-01T00:00:00.000Z',
      );
      final sub = Subscription.fromJson(json);
      final restored = Subscription.fromJson(sub.toJson());

      expect(restored.expiresAt, isNull);
    });

    test('toJson contains all expected keys', () {
      final sub = Subscription.fromJson(
        _subscriptionJson(startedAt: '2024-01-01T00:00:00.000Z'),
      );
      final json = sub.toJson();

      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('user_id'), isTrue);
      expect(json.containsKey('channel_id'), isTrue);
      expect(json.containsKey('tier'), isTrue);
      expect(json.containsKey('started_at'), isTrue);
      expect(json.containsKey('expires_at'), isTrue);
      expect(json.containsKey('is_active'), isTrue);
      expect(json.containsKey('auto_renew'), isTrue);
      expect(json.containsKey('created_at'), isTrue);
      expect(json.containsKey('updated_at'), isTrue);
    });

    test('defaults tier to STANDARD when key is absent', () {
      final json = _subscriptionJson(startedAt: '2024-01-01T00:00:00.000Z');
      json.remove('tier');
      expect(Subscription.fromJson(json).tier, equals('STANDARD'));
    });

    test('defaults isActive to true when key is absent', () {
      final json = _subscriptionJson(startedAt: '2024-01-01T00:00:00.000Z');
      json.remove('is_active');
      expect(Subscription.fromJson(json).isActive, isTrue);
    });

    test('defaults autoRenew to true when key is absent', () {
      final json = _subscriptionJson(startedAt: '2024-01-01T00:00:00.000Z');
      json.remove('auto_renew');
      expect(Subscription.fromJson(json).autoRenew, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Subscription — daysSubscribed
  // -------------------------------------------------------------------------

  group('Subscription daysSubscribed', () {
    test('returns 0 when startedAt is now (same moment)', () {
      // Use a time very slightly in the past to avoid negative microsecond
      // difference but still within the same "inDays == 0" window.
      final now = DateTime.now().subtract(const Duration(seconds: 1));
      final sub = Subscription.fromJson(
        _subscriptionJson(startedAt: now.toIso8601String()),
      );
      expect(sub.daysSubscribed, equals(0));
    });

    test('returns 1 for 1 day ago', () {
      expect(_subDaysAgo(1).daysSubscribed, equals(1));
    });

    test('returns 30 for exactly 30 days ago', () {
      expect(_subDaysAgo(30).daysSubscribed, equals(30));
    });

    test('returns 365 for exactly 365 days ago', () {
      expect(_subDaysAgo(365).daysSubscribed, equals(365));
    });

    test('returns correct value for arbitrary past date', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 120));
      final sub = Subscription.fromJson(
        _subscriptionJson(startedAt: pastDate.toIso8601String()),
      );
      // Allow ±1 to handle sub-second timing jitter in tests.
      expect(sub.daysSubscribed, inInclusiveRange(119, 121));
    });
  });

  // -------------------------------------------------------------------------
  // Subscription — formattedDuration
  // -------------------------------------------------------------------------

  group('Subscription formattedDuration', () {
    test('0 days → 오늘 시작', () {
      final now = DateTime.now().subtract(const Duration(seconds: 1));
      final sub = Subscription.fromJson(
        _subscriptionJson(startedAt: now.toIso8601String()),
      );
      expect(sub.formattedDuration, equals('오늘 시작'));
    });

    test('1 day → 1일째', () {
      expect(_subDaysAgo(1).formattedDuration, equals('1일째'));
    });

    test('2 days → 2일째', () {
      expect(_subDaysAgo(2).formattedDuration, equals('2일째'));
    });

    test('15 days → 15일째', () {
      expect(_subDaysAgo(15).formattedDuration, equals('15일째'));
    });

    test('29 days → 29일째 (last day in <30 bucket)', () {
      expect(_subDaysAgo(29).formattedDuration, equals('29일째'));
    });

    test('30 days → 1개월째 (first day in months bucket)', () {
      expect(_subDaysAgo(30).formattedDuration, equals('1개월째'));
    });

    test('31 days → 1개월째', () {
      expect(_subDaysAgo(31).formattedDuration, equals('1개월째'));
    });

    test('59 days → 1개월째 (59 ~/ 30 == 1)', () {
      expect(_subDaysAgo(59).formattedDuration, equals('1개월째'));
    });

    test('60 days → 2개월째', () {
      expect(_subDaysAgo(60).formattedDuration, equals('2개월째'));
    });

    test('90 days → 3개월째', () {
      expect(_subDaysAgo(90).formattedDuration, equals('3개월째'));
    });

    test('364 days → 12개월째 (364 ~/ 30 == 12, still < 365)', () {
      expect(_subDaysAgo(364).formattedDuration, equals('12개월째'));
    });

    test('365 days → 1년째 (first day in years bucket)', () {
      expect(_subDaysAgo(365).formattedDuration, equals('1년째'));
    });

    test('400 days → 1년째 (400 ~/ 365 == 1)', () {
      expect(_subDaysAgo(400).formattedDuration, equals('1년째'));
    });

    test('730 days → 2년째', () {
      expect(_subDaysAgo(730).formattedDuration, equals('2년째'));
    });

    test('1095 days → 3년째', () {
      expect(_subDaysAgo(1095).formattedDuration, equals('3년째'));
    });

    test('format contains 일째 for 1-29 day range', () {
      for (final days in [1, 5, 10, 20, 28, 29]) {
        expect(
          _subDaysAgo(days).formattedDuration,
          contains('일째'),
          reason: 'Expected 일째 for $days days',
        );
      }
    });

    test('format contains 개월째 for 30-364 day range', () {
      for (final days in [30, 45, 60, 90, 180, 364]) {
        expect(
          _subDaysAgo(days).formattedDuration,
          contains('개월째'),
          reason: 'Expected 개월째 for $days days',
        );
      }
    });

    test('format contains 년째 for 365+ day range', () {
      for (final days in [365, 400, 730, 1000]) {
        expect(
          _subDaysAgo(days).formattedDuration,
          contains('년째'),
          reason: 'Expected 년째 for $days days',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // Channel — fromJson / toJson round-trip (independent coverage)
  // -------------------------------------------------------------------------

  group('Channel fromJson / toJson round-trip', () {
    test('persists all core fields', () {
      final json = _channelJson();
      final channel = Channel.fromJson(json);
      final restored = Channel.fromJson(channel.toJson());

      expect(restored.id, equals('ch-1'));
      expect(restored.artistId, equals('artist-1'));
      expect(restored.name, equals('테스트 채널'));
      expect(restored.description, equals('채널 설명'));
      expect(restored.avatarUrl, equals('https://example.com/avatar.jpg'));
      expect(restored.isActive, isTrue);
      expect(restored.themeColorIndex, equals(2));
      expect(restored.screenshotWarningEnabled, isFalse);
      expect(restored.createdAt.toIso8601String(),
          equals(channel.createdAt.toIso8601String()));
    });

    test('toJson omits joined data (subscriberCount, unreadCount, etc.)', () {
      final json = {
        ..._channelJson(),
        'subscriber_count': 500,
        'unread_count': 3,
        'last_message_preview': 'Hello',
        'last_message_at': '2024-04-01T00:00:00.000Z',
      };
      final channel = Channel.fromJson(json);
      final output = channel.toJson();

      expect(output.containsKey('subscriber_count'), isFalse);
      expect(output.containsKey('unread_count'), isFalse);
      expect(output.containsKey('last_message_preview'), isFalse);
      expect(output.containsKey('last_message_at'), isFalse);
    });

    test('defaults screenshotWarningEnabled to true when absent', () {
      final json = _channelJson()..remove('screenshot_warning_enabled');
      expect(Channel.fromJson(json).screenshotWarningEnabled, isTrue);
    });

    test('defaults themeColorIndex to 0 when absent', () {
      final json = _channelJson()..remove('theme_color_index');
      expect(Channel.fromJson(json).themeColorIndex, equals(0));
    });

    test('defaults isActive to true when absent', () {
      final json = _channelJson()..remove('is_active');
      expect(Channel.fromJson(json).isActive, isTrue);
    });

    test('null optional fields survive round-trip', () {
      final json = {
        'id': 'ch-2',
        'artist_id': 'artist-2',
        'name': '최소 채널',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };
      final channel = Channel.fromJson(json);
      expect(channel.description, isNull);
      expect(channel.avatarUrl, isNull);

      final restored = Channel.fromJson(channel.toJson());
      expect(restored.description, isNull);
      expect(restored.avatarUrl, isNull);
    });
  });
}
