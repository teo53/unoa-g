import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/reply_quota.dart';

void main() {
  group('ReplyQuota', () {
    late ReplyQuota quota;
    final now = DateTime(2024, 1, 15, 12, 0, 0);

    setUp(() {
      quota = ReplyQuota(
        id: 'quota-1',
        userId: 'user-1',
        channelId: 'channel-1',
        tokensAvailable: 3,
        tokensUsed: 0,
        lastBroadcastId: 'broadcast-1',
        lastBroadcastAt: now,
        createdAt: now,
        updatedAt: now,
      );
    });

    group('canReply', () {
      test('returns true when tokens are available', () {
        expect(quota.canReply, isTrue);
      });

      test('returns true when fallback is available and no tokens', () {
        final fallbackQuota = quota.copyWith(
          tokensAvailable: 0,
          fallbackAvailable: true,
        );
        expect(fallbackQuota.canReply, isTrue);
      });

      test('returns false when no tokens and no fallback', () {
        final emptyQuota = quota.copyWith(
          tokensAvailable: 0,
          fallbackAvailable: false,
        );
        expect(emptyQuota.canReply, isFalse);
      });
    });

    group('totalAvailable', () {
      test('returns tokens when no fallback', () {
        expect(quota.totalAvailable, equals(3));
      });

      test('includes fallback token in total', () {
        final withFallback = quota.copyWith(fallbackAvailable: true);
        expect(withFallback.totalAvailable, equals(4));
      });

      test('returns 1 when only fallback available', () {
        final onlyFallback = quota.copyWith(
          tokensAvailable: 0,
          fallbackAvailable: true,
        );
        expect(onlyFallback.totalAvailable, equals(1));
      });
    });

    group('isFallbackOnly', () {
      test('returns false when tokens are available', () {
        expect(quota.isFallbackOnly, isFalse);
      });

      test('returns true when no tokens but fallback available', () {
        final fallbackOnly = quota.copyWith(
          tokensAvailable: 0,
          fallbackAvailable: true,
        );
        expect(fallbackOnly.isFallbackOnly, isTrue);
      });

      test('returns false when no tokens and no fallback', () {
        final empty = quota.copyWith(
          tokensAvailable: 0,
          fallbackAvailable: false,
        );
        expect(empty.isFallbackOnly, isFalse);
      });
    });

    group('afterReply', () {
      test('decrements token when tokens available', () {
        final after = quota.afterReply();
        expect(after.tokensAvailable, equals(2));
        expect(after.tokensUsed, equals(1));
        expect(after.lastReplyAt, isNotNull);
      });

      test('uses fallback when no tokens available', () {
        final noTokens = quota.copyWith(
          tokensAvailable: 0,
          fallbackAvailable: true,
        );
        final after = noTokens.afterReply();

        expect(after.tokensAvailable, equals(0));
        expect(after.fallbackAvailable, isFalse);
        expect(after.fallbackUsedAt, isNotNull);
        expect(after.lastReplyAt, isNotNull);
      });

      test('returns unchanged when no tokens and no fallback', () {
        final empty = quota.copyWith(
          tokensAvailable: 0,
          fallbackAvailable: false,
        );
        final after = empty.afterReply();

        expect(after.tokensAvailable, equals(0));
        expect(after.tokensUsed, equals(0));
      });

      test('prefers regular tokens over fallback', () {
        final withBoth = quota.copyWith(
          tokensAvailable: 1,
          fallbackAvailable: true,
        );
        final after = withBoth.afterReply();

        expect(after.tokensAvailable, equals(0));
        expect(after.fallbackAvailable, isTrue); // Fallback untouched
      });
    });

    group('empty factory', () {
      test('creates quota with zero tokens', () {
        final empty = ReplyQuota.empty('user-123', 'channel-456');

        expect(empty.userId, equals('user-123'));
        expect(empty.channelId, equals('channel-456'));
        expect(empty.tokensAvailable, equals(0));
        expect(empty.tokensUsed, equals(0));
        expect(empty.canReply, isFalse);
      });
    });

    group('JSON serialization', () {
      test('fromJson parses all fields correctly', () {
        final json = {
          'id': 'quota-1',
          'user_id': 'user-1',
          'channel_id': 'channel-1',
          'tokens_available': 2,
          'tokens_used': 1,
          'last_broadcast_id': 'broadcast-1',
          'last_broadcast_at': '2024-01-15T12:00:00.000',
          'last_reply_at': '2024-01-15T13:00:00.000',
          'fallback_available': true,
          'fallback_used_at': null,
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-15T12:00:00.000',
        };

        final parsed = ReplyQuota.fromJson(json);

        expect(parsed.id, equals('quota-1'));
        expect(parsed.userId, equals('user-1'));
        expect(parsed.channelId, equals('channel-1'));
        expect(parsed.tokensAvailable, equals(2));
        expect(parsed.tokensUsed, equals(1));
        expect(parsed.lastBroadcastId, equals('broadcast-1'));
        expect(parsed.fallbackAvailable, isTrue);
        expect(parsed.lastBroadcastAt, isNotNull);
        expect(parsed.lastReplyAt, isNotNull);
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'id': 'quota-1',
          'user_id': 'user-1',
          'channel_id': 'channel-1',
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-01T00:00:00.000',
        };

        final parsed = ReplyQuota.fromJson(json);

        expect(parsed.tokensAvailable, equals(0));
        expect(parsed.tokensUsed, equals(0));
        expect(parsed.fallbackAvailable, isFalse);
        expect(parsed.lastBroadcastId, isNull);
      });

      test('toJson produces correct output', () {
        final json = quota.toJson();

        expect(json['id'], equals('quota-1'));
        expect(json['user_id'], equals('user-1'));
        expect(json['channel_id'], equals('channel-1'));
        expect(json['tokens_available'], equals(3));
        expect(json['tokens_used'], equals(0));
        expect(json['fallback_available'], isFalse);
      });

      test('roundtrip serialization preserves data', () {
        final json = quota.toJson();
        final restored = ReplyQuota.fromJson(json);

        expect(restored.id, equals(quota.id));
        expect(restored.userId, equals(quota.userId));
        expect(restored.channelId, equals(quota.channelId));
        expect(restored.tokensAvailable, equals(quota.tokensAvailable));
        expect(restored.tokensUsed, equals(quota.tokensUsed));
        expect(restored.fallbackAvailable, equals(quota.fallbackAvailable));
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final copy = quota.copyWith(
          tokensAvailable: 1,
          tokensUsed: 2,
        );

        expect(copy.tokensAvailable, equals(1));
        expect(copy.tokensUsed, equals(2));
        expect(copy.id, equals(quota.id)); // Unchanged
        expect(copy.userId, equals(quota.userId)); // Unchanged
      });

      test('preserves all fields when no arguments', () {
        final copy = quota.copyWith();

        expect(copy.id, equals(quota.id));
        expect(copy.userId, equals(quota.userId));
        expect(copy.channelId, equals(quota.channelId));
        expect(copy.tokensAvailable, equals(quota.tokensAvailable));
      });
    });
  });

  group('CharacterLimits', () {
    group('getLimitForDays with default limits', () {
      const limits = CharacterLimits.defaultLimits;

      test('returns base limit for day 0', () {
        expect(limits.getLimitForDays(0), equals(50));
      });

      test('returns 50 for day 1', () {
        expect(limits.getLimitForDays(1), equals(50));
      });

      test('returns 50 for day 49', () {
        expect(limits.getLimitForDays(49), equals(50));
      });

      test('returns 50 for day 50', () {
        expect(limits.getLimitForDays(50), equals(50));
      });

      test('returns 50 for day 76 (boundary before 77)', () {
        expect(limits.getLimitForDays(76), equals(50));
      });

      test('returns 77 for day 77', () {
        expect(limits.getLimitForDays(77), equals(77));
      });

      test('returns 77 for day 99', () {
        expect(limits.getLimitForDays(99), equals(77));
      });

      test('returns 100 for day 100', () {
        expect(limits.getLimitForDays(100), equals(100));
      });

      test('returns 100 for day 149', () {
        expect(limits.getLimitForDays(149), equals(100));
      });

      test('returns 150 for day 150', () {
        expect(limits.getLimitForDays(150), equals(150));
      });

      test('returns 150 for day 199', () {
        expect(limits.getLimitForDays(199), equals(150));
      });

      test('returns 200 for day 200', () {
        expect(limits.getLimitForDays(200), equals(200));
      });

      test('returns 200 for day 299', () {
        expect(limits.getLimitForDays(299), equals(200));
      });

      test('returns 300 for day 300', () {
        expect(limits.getLimitForDays(300), equals(300));
      });

      test('returns 300 for day 365', () {
        expect(limits.getLimitForDays(365), equals(300));
      });

      test('returns 300 for day 1000 (max cap)', () {
        expect(limits.getLimitForDays(1000), equals(300));
      });
    });

    group('CharacterLimitRule', () {
      test('fromJson parses correctly', () {
        final json = {'min_days': 100, 'max_chars': 100};
        final rule = CharacterLimitRule.fromJson(json);

        expect(rule.minDays, equals(100));
        expect(rule.maxChars, equals(100));
      });
    });

    group('CharacterLimits fromJson', () {
      test('parses custom limits', () {
        final json = {
          'base_limit': 30,
          'progression': [
            {'min_days': 10, 'max_chars': 50},
            {'min_days': 30, 'max_chars': 100},
          ],
        };

        final limits = CharacterLimits.fromJson(json);

        expect(limits.baseLimit, equals(30));
        expect(limits.getLimitForDays(0), equals(30));
        expect(limits.getLimitForDays(10), equals(50));
        expect(limits.getLimitForDays(30), equals(100));
      });

      test('handles missing progression', () {
        final json = {'base_limit': 50};
        final limits = CharacterLimits.fromJson(json);

        expect(limits.baseLimit, equals(50));
        expect(limits.progression, isEmpty);
      });

      test('uses default base limit when missing', () {
        final json = <String, dynamic>{};
        final limits = CharacterLimits.fromJson(json);

        expect(limits.baseLimit, equals(50));
      });
    });
  });
}
