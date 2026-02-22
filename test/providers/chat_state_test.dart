// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/broadcast_message.dart';
import 'package:uno_a_flutter/data/models/channel.dart';
import 'package:uno_a_flutter/data/models/reply_quota.dart';
import 'package:uno_a_flutter/providers/chat_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Build a minimal [ReplyQuota] for test purposes.
ReplyQuota _makeQuota({
  String id = 'quota-1',
  String userId = 'user-1',
  String channelId = 'channel-1',
  int tokensAvailable = 3,
  int tokensUsed = 0,
  bool fallbackAvailable = false,
}) {
  final now = DateTime.now();
  return ReplyQuota(
    id: id,
    userId: userId,
    channelId: channelId,
    tokensAvailable: tokensAvailable,
    tokensUsed: tokensUsed,
    fallbackAvailable: fallbackAvailable,
    createdAt: now,
    updatedAt: now,
  );
}

/// Build a minimal [Subscription] with configurable daysSubscribed.
/// [startedAt] is computed by subtracting [daysSubscribed] days from now.
Subscription _makeSubscription({
  String id = 'sub-1',
  String userId = 'user-1',
  String channelId = 'channel-1',
  String tier = 'STANDARD',
  int daysSubscribed = 0,
}) {
  final now = DateTime.now();
  return Subscription(
    id: id,
    userId: userId,
    channelId: channelId,
    tier: tier,
    startedAt: now.subtract(Duration(days: daysSubscribed)),
    isActive: true,
    createdAt: now.subtract(Duration(days: daysSubscribed)),
    updatedAt: now,
  );
}

/// Build a minimal [BroadcastMessage].
BroadcastMessage _makeMessage({
  String id = 'msg-1',
  String channelId = 'channel-1',
  String senderId = 'artist-1',
  String senderType = 'artist',
  DeliveryScope deliveryScope = DeliveryScope.broadcast,
  String? content = 'Hello!',
  DateTime? createdAt,
}) {
  return BroadcastMessage(
    id: id,
    channelId: channelId,
    senderId: senderId,
    senderType: senderType,
    deliveryScope: deliveryScope,
    content: content,
    createdAt: createdAt ?? DateTime.now(),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ==========================================================================
  // ChatState — construction
  // ==========================================================================

  group('ChatState construction', () {
    test('constructor stores channelId and uses correct defaults', () {
      const state = ChatState(channelId: 'ch-1');

      expect(state.channelId, 'ch-1');
      expect(state.channel, isNull);
      expect(state.messages, isEmpty);
      expect(state.quota, isNull);
      expect(state.subscription, isNull);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.hasMoreMessages, isTrue);
      expect(state.onlineUsers, isEmpty);
      expect(state.typingUsers, isEmpty);
      expect(state.replyingToMessage, isNull);
    });

    test('stores all explicit values correctly', () {
      final quota = _makeQuota();
      final sub = _makeSubscription();
      final msg = _makeMessage();

      final state = ChatState(
        channelId: 'ch-42',
        quota: quota,
        subscription: sub,
        messages: [msg],
        isLoading: true,
        error: 'something failed',
        hasMoreMessages: false,
        onlineUsers: const {'user-1': true},
        typingUsers: const {'user-2'},
        replyingToMessage: msg,
      );

      expect(state.channelId, 'ch-42');
      expect(state.quota, same(quota));
      expect(state.subscription, same(sub));
      expect(state.messages, hasLength(1));
      expect(state.isLoading, isTrue);
      expect(state.error, 'something failed');
      expect(state.hasMoreMessages, isFalse);
      expect(state.onlineUsers, containsPair('user-1', true));
      expect(state.typingUsers, contains('user-2'));
      expect(state.replyingToMessage, same(msg));
    });
  });

  // ==========================================================================
  // ChatState.copyWith — field preservation
  // ==========================================================================

  group('ChatState.copyWith field preservation', () {
    test('channelId is always preserved (cannot be changed via copyWith)', () {
      const state = ChatState(channelId: 'ch-preserved');
      final copy = state.copyWith(isLoading: true);
      expect(copy.channelId, 'ch-preserved');
    });

    test('preserves all unchanged fields', () {
      final quota = _makeQuota();
      final sub = _makeSubscription();
      final messages = [_makeMessage(id: 'm1'), _makeMessage(id: 'm2')];

      final original = ChatState(
        channelId: 'ch-1',
        quota: quota,
        subscription: sub,
        messages: messages,
        hasMoreMessages: false,
        onlineUsers: const {'u1': true},
        typingUsers: const {'u2'},
      );

      final copy = original.copyWith(isLoading: true);

      expect(copy.quota, same(quota));
      expect(copy.subscription, same(sub));
      expect(copy.messages, same(messages));
      expect(copy.hasMoreMessages, isFalse);
      expect(copy.onlineUsers, containsPair('u1', true));
      expect(copy.typingUsers, contains('u2'));
      expect(copy.isLoading, isTrue);
    });

    test('error is replaced by copyWith (not preserved implicitly)', () {
      final withError = ChatState(channelId: 'ch-1', error: 'old error');
      final copy = withError.copyWith(isLoading: false);
      expect(copy.error, isNull);
    });

    test('error can be explicitly set to a new value via copyWith', () {
      const original = ChatState(channelId: 'ch-1');
      final copy = original.copyWith(error: 'network timeout');
      expect(copy.error, 'network timeout');
    });

    test('can update messages list', () {
      const original = ChatState(channelId: 'ch-1');
      final newMessages = [_makeMessage(id: 'new-msg')];
      final copy = original.copyWith(messages: newMessages);
      expect(copy.messages, hasLength(1));
      expect(copy.messages.first.id, 'new-msg');
    });

    test('can update quota', () {
      const original = ChatState(channelId: 'ch-1');
      final quota = _makeQuota(tokensAvailable: 1);
      final copy = original.copyWith(quota: quota);
      expect(copy.quota!.tokensAvailable, 1);
    });
  });

  // ==========================================================================
  // ChatState.copyWith — clearReplyingTo edge case
  // ==========================================================================

  group('ChatState.copyWith clearReplyingTo', () {
    test('clearReplyingTo:true sets replyingToMessage to null', () {
      final msg = _makeMessage(id: 'reply-target');
      final state = ChatState(
        channelId: 'ch-1',
        replyingToMessage: msg,
      );

      final cleared = state.copyWith(clearReplyingTo: true);
      expect(cleared.replyingToMessage, isNull);
    });

    test(
        'clearReplyingTo:true overrides any replyingToMessage passed to copyWith',
        () {
      final originalMsg = _makeMessage(id: 'original');
      final newMsg = _makeMessage(id: 'new-target');

      final state = ChatState(
        channelId: 'ch-1',
        replyingToMessage: originalMsg,
      );

      // Even if we pass a new message AND clearReplyingTo:true, the clear wins
      final copy = state.copyWith(
        replyingToMessage: newMsg,
        clearReplyingTo: true,
      );

      expect(copy.replyingToMessage, isNull);
    });

    test('clearReplyingTo defaults to false — replyingToMessage is preserved',
        () {
      final msg = _makeMessage(id: 'preserved');
      final state = ChatState(
        channelId: 'ch-1',
        replyingToMessage: msg,
      );

      // No clearReplyingTo → defaults to false → original message preserved
      final copy = state.copyWith(isLoading: true);
      expect(copy.replyingToMessage, same(msg));
    });

    test('clearReplyingTo:false keeps existing replyingToMessage', () {
      final msg = _makeMessage(id: 'kept');
      final state = ChatState(
        channelId: 'ch-1',
        replyingToMessage: msg,
      );

      final copy = state.copyWith(clearReplyingTo: false);
      expect(copy.replyingToMessage, same(msg));
    });

    test('can set new replyingToMessage when clearReplyingTo is false', () {
      const state = ChatState(channelId: 'ch-1');
      final msg = _makeMessage(id: 'new-reply');

      final copy = state.copyWith(replyingToMessage: msg);
      expect(copy.replyingToMessage!.id, 'new-reply');
    });

    test('clearReplyingTo:true on state with null replyingToMessage is no-op',
        () {
      const state = ChatState(channelId: 'ch-1');
      final copy = state.copyWith(clearReplyingTo: true);
      expect(copy.replyingToMessage, isNull);
    });
  });

  // ==========================================================================
  // ChatState.canReply
  // ==========================================================================

  group('ChatState.canReply', () {
    test('is false when quota is null', () {
      const state = ChatState(channelId: 'ch-1');
      expect(state.canReply, isFalse);
    });

    test('is true when quota has tokens available', () {
      final state = ChatState(
        channelId: 'ch-1',
        quota: _makeQuota(tokensAvailable: 3),
      );
      expect(state.canReply, isTrue);
    });

    test('is true when quota has fallbackAvailable', () {
      final state = ChatState(
        channelId: 'ch-1',
        quota: _makeQuota(tokensAvailable: 0, fallbackAvailable: true),
      );
      expect(state.canReply, isTrue);
    });

    test('is false when quota has 0 tokens and no fallback', () {
      final state = ChatState(
        channelId: 'ch-1',
        quota: _makeQuota(tokensAvailable: 0, fallbackAvailable: false),
      );
      expect(state.canReply, isFalse);
    });

    test('is true when quota has 1 token (boundary)', () {
      final state = ChatState(
        channelId: 'ch-1',
        quota: _makeQuota(tokensAvailable: 1),
      );
      expect(state.canReply, isTrue);
    });

    test('delegates to quota.canReply — stays consistent with quota changes',
        () {
      final quotaWithTokens = _makeQuota(tokensAvailable: 2);
      final stateWithTokens = ChatState(
        channelId: 'ch-1',
        quota: quotaWithTokens,
      );
      expect(stateWithTokens.canReply, equals(quotaWithTokens.canReply));

      final depleted = quotaWithTokens.afterReply().afterReply();
      final stateAfterReplies = stateWithTokens.copyWith(quota: depleted);
      expect(stateAfterReplies.canReply, equals(depleted.canReply));
    });
  });

  // ==========================================================================
  // ChatState.characterLimit
  // ==========================================================================

  group('ChatState.characterLimit', () {
    test('returns 50 when subscription is null', () {
      const state = ChatState(channelId: 'ch-1');
      expect(state.characterLimit, 50);
    });

    test('returns 50 for a brand-new subscriber (0 days)', () {
      final state = ChatState(
        channelId: 'ch-1',
        subscription: _makeSubscription(daysSubscribed: 0),
      );
      // baseLimit is 50; minDays:1 rule requires >= 1 day, so 0 days → base 50
      expect(state.characterLimit, 50);
    });

    test('returns 50 for subscriber at 1 day', () {
      final state = ChatState(
        channelId: 'ch-1',
        subscription: _makeSubscription(daysSubscribed: 1),
      );
      expect(state.characterLimit, 50);
    });

    test('returns 50 for subscriber at 49 days (below 50-day threshold)', () {
      final state = ChatState(
        channelId: 'ch-1',
        subscription: _makeSubscription(daysSubscribed: 49),
      );
      expect(state.characterLimit, 50);
    });

    test('returns 50 for subscriber at exactly 50 days', () {
      final state = ChatState(
        channelId: 'ch-1',
        subscription: _makeSubscription(daysSubscribed: 50),
      );
      expect(state.characterLimit, 50);
    });

    test('returns 77 for subscriber at exactly 77 days', () {
      final state = ChatState(
        channelId: 'ch-1',
        subscription: _makeSubscription(daysSubscribed: 77),
      );
      expect(state.characterLimit, 77);
    });

    test('returns 100 for subscriber at exactly 100 days', () {
      final state = ChatState(
        channelId: 'ch-1',
        subscription: _makeSubscription(daysSubscribed: 100),
      );
      expect(state.characterLimit, 100);
    });

    test('returns 150 for subscriber at exactly 150 days', () {
      final state = ChatState(
        channelId: 'ch-1',
        subscription: _makeSubscription(daysSubscribed: 150),
      );
      expect(state.characterLimit, 150);
    });

    test('returns 200 for subscriber at exactly 200 days', () {
      final state = ChatState(
        channelId: 'ch-1',
        subscription: _makeSubscription(daysSubscribed: 200),
      );
      expect(state.characterLimit, 200);
    });

    test('returns 300 for subscriber at exactly 300 days', () {
      final state = ChatState(
        channelId: 'ch-1',
        subscription: _makeSubscription(daysSubscribed: 300),
      );
      expect(state.characterLimit, 300);
    });

    test('returns 300 for subscriber at 365 days (capped at 300)', () {
      final state = ChatState(
        channelId: 'ch-1',
        subscription: _makeSubscription(daysSubscribed: 365),
      );
      expect(state.characterLimit, 300);
    });

    test('returns 300 for very long-term subscriber (1000 days)', () {
      final state = ChatState(
        channelId: 'ch-1',
        subscription: _makeSubscription(daysSubscribed: 1000),
      );
      expect(state.characterLimit, 300);
    });

    test('limit increases monotonically across threshold days', () {
      final thresholds = [0, 1, 50, 77, 100, 150, 200, 300, 365];
      int prev = 0;
      for (final days in thresholds) {
        final state = ChatState(
          channelId: 'ch-1',
          subscription: _makeSubscription(daysSubscribed: days),
        );
        expect(
          state.characterLimit,
          greaterThanOrEqualTo(prev),
          reason: 'limit at $days days should be >= limit at $prev days',
        );
        prev = state.characterLimit;
      }
    });
  });

  // ==========================================================================
  // ReplyQuota
  // ==========================================================================

  group('ReplyQuota.canReply', () {
    test('true when tokensAvailable > 0', () {
      final quota = _makeQuota(tokensAvailable: 1);
      expect(quota.canReply, isTrue);
    });

    test('true when tokensAvailable == 0 but fallbackAvailable is true', () {
      final quota = _makeQuota(tokensAvailable: 0, fallbackAvailable: true);
      expect(quota.canReply, isTrue);
    });

    test('false when tokensAvailable == 0 and fallbackAvailable is false', () {
      final quota = _makeQuota(tokensAvailable: 0, fallbackAvailable: false);
      expect(quota.canReply, isFalse);
    });

    test('true when tokensAvailable is 3 (default)', () {
      final quota = _makeQuota();
      expect(quota.canReply, isTrue);
    });
  });

  group('ReplyQuota.afterReply', () {
    test('decrements tokensAvailable by 1 when tokens remain', () {
      final quota = _makeQuota(tokensAvailable: 3);
      final after = quota.afterReply();
      expect(after.tokensAvailable, 2);
    });

    test('increments tokensUsed by 1 when tokens remain', () {
      final quota = _makeQuota(tokensAvailable: 3, tokensUsed: 0);
      final after = quota.afterReply();
      expect(after.tokensUsed, 1);
    });

    test('sets lastReplyAt when tokens are decremented', () {
      final quota = _makeQuota(tokensAvailable: 2);
      final before = DateTime.now();
      final after = quota.afterReply();
      expect(after.lastReplyAt, isNotNull);
      expect(
          after.lastReplyAt!.isAfter(before) ||
              after.lastReplyAt!.isAtSameMomentAs(before),
          isTrue);
    });

    test('three consecutive afterReply calls exhaust all 3 tokens', () {
      final quota = _makeQuota(tokensAvailable: 3);
      final after1 = quota.afterReply();
      final after2 = after1.afterReply();
      final after3 = after2.afterReply();

      expect(after1.tokensAvailable, 2);
      expect(after2.tokensAvailable, 1);
      expect(after3.tokensAvailable, 0);
      expect(after3.tokensUsed, 3);
    });

    test(
        'uses fallback when tokensAvailable is 0 and fallbackAvailable is true',
        () {
      final quota = _makeQuota(tokensAvailable: 0, fallbackAvailable: true);
      final after = quota.afterReply();

      expect(after.tokensAvailable, 0);
      expect(after.fallbackAvailable, isFalse);
      expect(after.fallbackUsedAt, isNotNull);
    });

    test('sets lastReplyAt when fallback is consumed', () {
      final quota = _makeQuota(tokensAvailable: 0, fallbackAvailable: true);
      final before = DateTime.now();
      final after = quota.afterReply();
      expect(after.lastReplyAt, isNotNull);
      expect(
          after.lastReplyAt!.isAfter(before) ||
              after.lastReplyAt!.isAtSameMomentAs(before),
          isTrue);
    });

    test('is a no-op when no tokens and no fallback', () {
      final quota = _makeQuota(tokensAvailable: 0, fallbackAvailable: false);
      final after = quota.afterReply();

      // Should return `this` unchanged
      expect(after.tokensAvailable, 0);
      expect(after.fallbackAvailable, isFalse);
      expect(after.tokensUsed, 0);
    });
  });

  group('ReplyQuota.empty factory', () {
    test('creates quota with zero tokens and no fallback', () {
      final quota = ReplyQuota.empty('user-x', 'channel-y');

      expect(quota.userId, 'user-x');
      expect(quota.channelId, 'channel-y');
      expect(quota.tokensAvailable, 0);
      expect(quota.tokensUsed, 0);
      expect(quota.fallbackAvailable, isFalse);
      expect(quota.canReply, isFalse);
    });

    test('id is empty string', () {
      final quota = ReplyQuota.empty('u', 'c');
      expect(quota.id, '');
    });

    test('createdAt and updatedAt are set to now', () {
      final before = DateTime.now();
      final quota = ReplyQuota.empty('u', 'c');
      final after = DateTime.now();

      expect(
          quota.createdAt.isAfter(before) ||
              quota.createdAt.isAtSameMomentAs(before),
          isTrue);
      expect(
          quota.createdAt.isBefore(after) ||
              quota.createdAt.isAtSameMomentAs(after),
          isTrue);
    });
  });

  // ==========================================================================
  // ReplyQuota.getCharacterLimitForDays — actual progression thresholds
  // ==========================================================================

  group('ReplyQuota.getCharacterLimitForDays', () {
    test('0 days → base limit of 50', () {
      expect(ReplyQuota.getCharacterLimitForDays(0), 50);
    });

    test('1 day → 50', () {
      expect(ReplyQuota.getCharacterLimitForDays(1), 50);
    });

    test('49 days → 50 (below 50-day threshold)', () {
      expect(ReplyQuota.getCharacterLimitForDays(49), 50);
    });

    test('50 days → 50 (same threshold, same cap)', () {
      expect(ReplyQuota.getCharacterLimitForDays(50), 50);
    });

    test('76 days → 50 (below 77-day threshold)', () {
      expect(ReplyQuota.getCharacterLimitForDays(76), 50);
    });

    test('77 days → 77', () {
      expect(ReplyQuota.getCharacterLimitForDays(77), 77);
    });

    test('99 days → 77 (below 100-day threshold)', () {
      expect(ReplyQuota.getCharacterLimitForDays(99), 77);
    });

    test('100 days → 100', () {
      expect(ReplyQuota.getCharacterLimitForDays(100), 100);
    });

    test('149 days → 100 (below 150-day threshold)', () {
      expect(ReplyQuota.getCharacterLimitForDays(149), 100);
    });

    test('150 days → 150', () {
      expect(ReplyQuota.getCharacterLimitForDays(150), 150);
    });

    test('199 days → 150 (below 200-day threshold)', () {
      expect(ReplyQuota.getCharacterLimitForDays(199), 150);
    });

    test('200 days → 200', () {
      expect(ReplyQuota.getCharacterLimitForDays(200), 200);
    });

    test('299 days → 200 (below 300-day threshold)', () {
      expect(ReplyQuota.getCharacterLimitForDays(299), 200);
    });

    test('300 days → 300', () {
      expect(ReplyQuota.getCharacterLimitForDays(300), 300);
    });

    test('365 days → 300 (capped, no higher tier)', () {
      expect(ReplyQuota.getCharacterLimitForDays(365), 300);
    });

    test('730 days → 300 (max is still 300)', () {
      expect(ReplyQuota.getCharacterLimitForDays(730), 300);
    });

    test('limits are non-decreasing across all thresholds', () {
      final days = [0, 1, 50, 77, 100, 150, 200, 300, 365, 730];
      int prev = ReplyQuota.getCharacterLimitForDays(0);
      for (final d in days.skip(1)) {
        final limit = ReplyQuota.getCharacterLimitForDays(d);
        expect(
          limit,
          greaterThanOrEqualTo(prev),
          reason:
              'Limit at $d days ($limit) should be >= limit at prev ($prev)',
        );
        prev = limit;
      }
    });
  });
}
