import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/reply_quota.dart';

void main() {
  group('ReplyQuota', () {
    final now = DateTime.now();

    ReplyQuota createQuota({
      int tokensAvailable = 3,
      int tokensUsed = 0,
      bool fallbackAvailable = false,
    }) {
      return ReplyQuota(
        id: 'quota-1',
        userId: 'user-1',
        channelId: 'channel-1',
        tokensAvailable: tokensAvailable,
        tokensUsed: tokensUsed,
        fallbackAvailable: fallbackAvailable,
        createdAt: now,
        updatedAt: now,
      );
    }

    group('canReply', () {
      test('returns true when tokens available', () {
        final quota = createQuota(tokensAvailable: 3, fallbackAvailable: false);
        expect(quota.canReply, isTrue);
      });

      test('returns true when only fallback available', () {
        final quota = createQuota(tokensAvailable: 0, fallbackAvailable: true);
        expect(quota.canReply, isTrue);
      });

      test('returns true when both tokens and fallback available', () {
        final quota = createQuota(tokensAvailable: 2, fallbackAvailable: true);
        expect(quota.canReply, isTrue);
      });

      test('returns false when no tokens and no fallback', () {
        final quota = createQuota(tokensAvailable: 0, fallbackAvailable: false);
        expect(quota.canReply, isFalse);
      });
    });

    group('totalAvailable', () {
      test('returns tokens only when no fallback', () {
        final quota = createQuota(tokensAvailable: 3, fallbackAvailable: false);
        expect(quota.totalAvailable, equals(3));
      });

      test('includes fallback in count', () {
        final quota = createQuota(tokensAvailable: 2, fallbackAvailable: true);
        expect(quota.totalAvailable, equals(3));
      });

      test('returns 1 when only fallback available', () {
        final quota = createQuota(tokensAvailable: 0, fallbackAvailable: true);
        expect(quota.totalAvailable, equals(1));
      });
    });

    group('isFallbackOnly', () {
      test('returns true when no tokens but fallback available', () {
        final quota = createQuota(tokensAvailable: 0, fallbackAvailable: true);
        expect(quota.isFallbackOnly, isTrue);
      });

      test('returns false when tokens available', () {
        final quota = createQuota(tokensAvailable: 1, fallbackAvailable: true);
        expect(quota.isFallbackOnly, isFalse);
      });

      test('returns false when no fallback', () {
        final quota = createQuota(tokensAvailable: 0, fallbackAvailable: false);
        expect(quota.isFallbackOnly, isFalse);
      });
    });

    group('afterReply', () {
      test('decrements token when tokens available', () {
        final quota = createQuota(
            tokensAvailable: 3, tokensUsed: 0, fallbackAvailable: true);
        final afterReply = quota.afterReply();

        expect(afterReply.tokensAvailable, equals(2));
        expect(afterReply.tokensUsed, equals(1));
        expect(afterReply.fallbackAvailable, isTrue); // Unchanged
        expect(afterReply.lastReplyAt, isNotNull);
      });

      test('uses fallback when no tokens available', () {
        final quota = createQuota(tokensAvailable: 0, fallbackAvailable: true);
        final afterReply = quota.afterReply();

        expect(afterReply.tokensAvailable, equals(0));
        expect(afterReply.fallbackAvailable, isFalse);
        expect(afterReply.fallbackUsedAt, isNotNull);
        expect(afterReply.lastReplyAt, isNotNull);
      });

      test('returns same quota when no tokens and no fallback', () {
        final quota = createQuota(tokensAvailable: 0, fallbackAvailable: false);
        final afterReply = quota.afterReply();

        expect(afterReply.tokensAvailable, equals(0));
        expect(afterReply.fallbackAvailable, isFalse);
        // Should be the same object (no change)
        expect(afterReply.id, equals(quota.id));
      });
    });

    group('fromJson / toJson', () {
      test('round-trips correctly', () {
        final original = ReplyQuota(
          id: 'quota-123',
          userId: 'user-456',
          channelId: 'channel-789',
          tokensAvailable: 2,
          tokensUsed: 1,
          lastBroadcastId: 'broadcast-1',
          lastBroadcastAt: now,
          lastReplyAt: now,
          fallbackAvailable: true,
          fallbackUsedAt: null,
          createdAt: now,
          updatedAt: now,
        );

        final json = original.toJson();
        final restored = ReplyQuota.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.userId, equals(original.userId));
        expect(restored.channelId, equals(original.channelId));
        expect(restored.tokensAvailable, equals(original.tokensAvailable));
        expect(restored.tokensUsed, equals(original.tokensUsed));
        expect(restored.lastBroadcastId, equals(original.lastBroadcastId));
        expect(restored.fallbackAvailable, equals(original.fallbackAvailable));
      });

      test('handles null optional fields', () {
        final json = {
          'id': 'quota-1',
          'user_id': 'user-1',
          'channel_id': 'channel-1',
          'tokens_available': 3,
          'tokens_used': 0,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        final quota = ReplyQuota.fromJson(json);

        expect(quota.lastBroadcastId, isNull);
        expect(quota.lastBroadcastAt, isNull);
        expect(quota.lastReplyAt, isNull);
        expect(quota.fallbackAvailable, isFalse);
        expect(quota.fallbackUsedAt, isNull);
      });
    });

    group('copyWith', () {
      test('preserves unchanged values', () {
        final quota = createQuota(tokensAvailable: 3);
        final copied = quota.copyWith(tokensAvailable: 2);

        expect(copied.tokensAvailable, equals(2));
        expect(copied.id, equals(quota.id));
        expect(copied.userId, equals(quota.userId));
        expect(copied.channelId, equals(quota.channelId));
      });
    });

    group('empty factory', () {
      test('creates quota with zero tokens', () {
        final empty = ReplyQuota.empty('user-1', 'channel-1');

        expect(empty.id, isEmpty);
        expect(empty.userId, equals('user-1'));
        expect(empty.channelId, equals('channel-1'));
        expect(empty.tokensAvailable, equals(0));
        expect(empty.tokensUsed, equals(0));
        expect(empty.canReply, isFalse);
      });
    });
  });

  group('CharacterLimits', () {
    group('getLimitForDays', () {
      test('returns base limit for day 0', () {
        final limit = CharacterLimits.defaultLimits.getLimitForDays(0);
        expect(limit, equals(50));
      });

      test('returns 50 for day 1', () {
        final limit = CharacterLimits.defaultLimits.getLimitForDays(1);
        expect(limit, equals(50));
      });

      test('returns 50 for day 49', () {
        final limit = CharacterLimits.defaultLimits.getLimitForDays(49);
        expect(limit, equals(50));
      });

      test('returns 50 for day 50', () {
        final limit = CharacterLimits.defaultLimits.getLimitForDays(50);
        expect(limit, equals(50));
      });

      test('returns 77 for day 77', () {
        final limit = CharacterLimits.defaultLimits.getLimitForDays(77);
        expect(limit, equals(77));
      });

      test('returns 77 for day 99', () {
        final limit = CharacterLimits.defaultLimits.getLimitForDays(99);
        expect(limit, equals(77));
      });

      test('returns 100 for day 100', () {
        final limit = CharacterLimits.defaultLimits.getLimitForDays(100);
        expect(limit, equals(100));
      });

      test('returns 150 for day 150', () {
        final limit = CharacterLimits.defaultLimits.getLimitForDays(150);
        expect(limit, equals(150));
      });

      test('returns 200 for day 200', () {
        final limit = CharacterLimits.defaultLimits.getLimitForDays(200);
        expect(limit, equals(200));
      });

      test('returns 300 for day 300', () {
        final limit = CharacterLimits.defaultLimits.getLimitForDays(300);
        expect(limit, equals(300));
      });

      test('returns 300 for day 365+', () {
        final limit = CharacterLimits.defaultLimits.getLimitForDays(500);
        expect(limit, equals(300));
      });
    });

    group('fromJson', () {
      test('parses custom limits correctly', () {
        final json = {
          'base_limit': 30,
          'progression': [
            {'min_days': 10, 'max_chars': 50},
            {'min_days': 30, 'max_chars': 100},
          ],
        };

        final limits = CharacterLimits.fromJson(json);

        expect(limits.baseLimit, equals(30));
        expect(limits.progression.length, equals(2));
        expect(limits.getLimitForDays(5), equals(30));
        expect(limits.getLimitForDays(15), equals(50));
        expect(limits.getLimitForDays(50), equals(100));
      });
    });
  });

  group('ReplyQuota.getCharacterLimitForDays', () {
    test('uses default limits', () {
      expect(ReplyQuota.getCharacterLimitForDays(30), equals(50));
      expect(ReplyQuota.getCharacterLimitForDays(100), equals(100));
      expect(ReplyQuota.getCharacterLimitForDays(300), equals(300));
    });
  });
}
