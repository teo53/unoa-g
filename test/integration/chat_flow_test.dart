import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/reply_quota.dart';
import 'package:uno_a_flutter/data/services/chat_service.dart';

/// Integration tests for the chat flow
///
/// Tests the complete chat experience including:
/// 1. Reply quota management
/// 2. Character limit progression
/// 3. Message validation (text, donation)
/// 4. Spam detection
/// 5. Message formatting
void main() {
  late ChatService chatService;

  setUp(() {
    chatService = ChatService();
  });

  // Helper to create a ReplyQuota with sensible defaults
  ReplyQuota createQuota({
    int tokensAvailable = 3,
    int tokensUsed = 0,
    bool fallbackAvailable = false,
  }) {
    final now = DateTime.now();
    return ReplyQuota(
      id: 'quota-test',
      userId: 'user-test',
      channelId: 'channel-test',
      tokensAvailable: tokensAvailable,
      tokensUsed: tokensUsed,
      fallbackAvailable: fallbackAvailable,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('Chat Flow — Reply Quota', () {
    test('fan should be able to send message within quota', () {
      final quota = createQuota(tokensAvailable: 3, tokensUsed: 0);

      final result = chatService.validateMessage(
        content: 'Hello!',
        characterLimit: 150,
        quota: quota,
        isSubscriptionActive: true,
      );

      // null means validation passed
      expect(result, isNull);
      expect(chatService.canSendReply(quota), true);
    });

    test('fan should not be able to send message when quota exhausted', () {
      final quota = createQuota(tokensAvailable: 0, tokensUsed: 3);

      final result = chatService.validateMessage(
        content: 'Hello!',
        characterLimit: 150,
        quota: quota,
        isSubscriptionActive: true,
      );

      expect(result, isNotNull);
      expect(result!.success, false);
      expect(result.errorCode, 'QUOTA_EXCEEDED');
      expect(chatService.canSendReply(quota), false);
    });

    test('quota with fallback available should allow sending', () {
      final quota = createQuota(
        tokensAvailable: 0,
        tokensUsed: 3,
        fallbackAvailable: true,
      );

      expect(quota.canReply, true);
      expect(quota.isFallbackOnly, true);
      expect(quota.totalAvailable, 1);

      final result = chatService.validateMessage(
        content: 'Using fallback!',
        characterLimit: 150,
        quota: quota,
        isSubscriptionActive: true,
      );

      expect(result, isNull);
    });

    test('null quota should prevent sending', () {
      expect(chatService.canSendReply(null), false);

      final result = chatService.validateMessage(
        content: 'Hello!',
        characterLimit: 150,
        quota: null,
        isSubscriptionActive: true,
      );

      expect(result, isNotNull);
      expect(result!.errorCode, 'QUOTA_EXCEEDED');
    });

    test('afterReply should decrement tokens correctly', () {
      final quota = createQuota(tokensAvailable: 3, tokensUsed: 0);
      final after = quota.afterReply();

      expect(after.tokensAvailable, 2);
      expect(after.tokensUsed, 1);
      expect(after.lastReplyAt, isNotNull);
    });

    test('afterReply on fallback should consume fallback', () {
      final quota = createQuota(
        tokensAvailable: 0,
        tokensUsed: 3,
        fallbackAvailable: true,
      );
      final after = quota.afterReply();

      expect(after.tokensAvailable, 0);
      expect(after.fallbackAvailable, false);
      expect(after.fallbackUsedAt, isNotNull);
    });

    test('afterReply on exhausted quota returns unchanged', () {
      final quota = createQuota(tokensAvailable: 0, tokensUsed: 3);
      final after = quota.afterReply();

      expect(after.tokensAvailable, 0);
      expect(after.tokensUsed, 3);
    });

    test('empty quota factory creates zero-token quota', () {
      final empty = ReplyQuota.empty('user-1', 'channel-1');

      expect(empty.tokensAvailable, 0);
      expect(empty.tokensUsed, 0);
      expect(empty.canReply, false);
      expect(empty.userId, 'user-1');
      expect(empty.channelId, 'channel-1');
    });
  });

  group('Chat Flow — Character Limits', () {
    test('character limit should increase with subscription age', () {
      // Day 1-49: 50 chars
      expect(chatService.getCharacterLimit(1), 50);
      expect(chatService.getCharacterLimit(49), 50);

      // Day 50-76: still 50 chars (per progression rules)
      expect(chatService.getCharacterLimit(50), 50);

      // Day 77-99: 77 chars
      expect(chatService.getCharacterLimit(77), 77);
      expect(chatService.getCharacterLimit(99), 77);

      // Day 100-149: 100 chars
      expect(chatService.getCharacterLimit(100), 100);
      expect(chatService.getCharacterLimit(149), 100);

      // Day 150-199: 150 chars
      expect(chatService.getCharacterLimit(150), 150);

      // Day 200-299: 200 chars
      expect(chatService.getCharacterLimit(200), 200);

      // Day 300+: 300 chars (max)
      expect(chatService.getCharacterLimit(300), 300);
      expect(chatService.getCharacterLimit(365), 300);
      expect(chatService.getCharacterLimit(1000), 300);
    });

    test('message exceeding character limit should be rejected', () {
      final quota = createQuota(tokensAvailable: 3);
      final longMessage = 'A' * 51; // 51 chars, limit is 50

      final result = chatService.validateMessage(
        content: longMessage,
        characterLimit: 50,
        quota: quota,
        isSubscriptionActive: true,
      );

      expect(result, isNotNull);
      expect(result!.errorCode, 'CHARACTER_LIMIT');
    });

    test('message at exact character limit should pass', () {
      final quota = createQuota(tokensAvailable: 3);
      final exactMessage = 'A' * 50; // exactly 50 chars

      final result = chatService.validateMessage(
        content: exactMessage,
        characterLimit: 50,
        quota: quota,
        isSubscriptionActive: true,
      );

      expect(result, isNull);
    });

    test('empty message should pass character validation', () {
      final quota = createQuota(tokensAvailable: 3);

      final result = chatService.validateMessage(
        content: '',
        characterLimit: 50,
        quota: quota,
        isSubscriptionActive: true,
      );

      // Empty message passes character limit (UI should handle min length)
      expect(result, isNull);
    });

    test('CharacterLimits.defaultLimits base is 50', () {
      expect(CharacterLimits.defaultLimits.baseLimit, 50);
      expect(CharacterLimits.defaultLimits.getLimitForDays(0), 50);
    });

    test('CharacterLimitTier.getTierForDays returns correct tier', () {
      final tier1 = CharacterLimitTier.getTierForDays(1);
      expect(tier1.limit, 50);

      final tier7 = CharacterLimitTier.getTierForDays(7);
      expect(tier7.limit, 150);

      final tier30 = CharacterLimitTier.getTierForDays(30);
      expect(tier30.limit, 200);
    });
  });

  group('Chat Flow — Subscription Validation', () {
    test('expired subscription should block replies', () {
      final quota = createQuota(tokensAvailable: 3);

      final result = chatService.validateMessage(
        content: 'Hello!',
        characterLimit: 150,
        quota: quota,
        isSubscriptionActive: false,
      );

      expect(result, isNotNull);
      expect(result!.errorCode, 'SUBSCRIPTION_EXPIRED');
    });

    test('active subscription with valid quota should pass', () {
      final quota = createQuota(tokensAvailable: 1);

      final result = chatService.validateMessage(
        content: 'Hello!',
        characterLimit: 150,
        quota: quota,
        isSubscriptionActive: true,
      );

      expect(result, isNull);
    });
  });

  group('Chat Flow — Donation Messages', () {
    test('donation message should bypass quota', () {
      // Donation messages use validateDonationMessage, not validateMessage
      // No quota check needed

      final result = chatService.validateDonationMessage(
        content: 'Thank you!',
        maxLength: 100,
      );

      expect(result, isNull);
    });

    test('donation message exceeding length should be rejected', () {
      final longMessage = 'A' * 101;

      final result = chatService.validateDonationMessage(
        content: longMessage,
        maxLength: 100,
      );

      expect(result, isNotNull);
      expect(result!.errorCode, 'CHARACTER_LIMIT');
    });

    test('donation message at exact max length should pass', () {
      final exactMessage = 'A' * 100;

      final result = chatService.validateDonationMessage(
        content: exactMessage,
        maxLength: 100,
      );

      expect(result, isNull);
    });
  });

  group('Spam Detection', () {
    test('normal message should not be spam', () {
      final score = chatService.calculateSpamScore('안녕하세요! 오늘 공연 정말 좋았어요.');
      expect(score, lessThan(70));
      expect(chatService.isSpam('안녕하세요! 오늘 공연 정말 좋았어요.'), false);
    });

    test('repeated characters should increase spam score', () {
      final score = chatService.calculateSpamScore('aaaaaaa really long repeated chars');
      expect(score, greaterThanOrEqualTo(30));
    });

    test('all caps message should increase spam score', () {
      final score = chatService.calculateSpamScore('THIS IS ALL CAPS MESSAGE');
      expect(score, greaterThanOrEqualTo(20));
    });

    test('multiple URLs should increase spam score', () {
      final score = chatService.calculateSpamScore(
        'Check out https://example1.com and https://example2.com and https://example3.com',
      );
      expect(score, greaterThanOrEqualTo(25));
    });

    test('combined spam signals should exceed threshold', () {
      // Repeated chars (30) + ALL CAPS (20) = 50+
      const message = 'AAAAAAA THIS IS SPAM';
      final score = chatService.calculateSpamScore(message);
      expect(score, greaterThanOrEqualTo(50));
    });

    test('short all caps is not spam (length <= 5)', () {
      final score = chatService.calculateSpamScore('HELLO');
      // All caps check requires length > 5
      expect(score, lessThan(20));
    });

    test('spam score is clamped to 0-100', () {
      // Even with many spam signals, score should not exceed 100
      const message = 'AAAAAAA https://a.com https://b.com https://c.com';
      final score = chatService.calculateSpamScore(message);
      expect(score, lessThanOrEqualTo(100));
      expect(score, greaterThanOrEqualTo(0));
    });
  });

  group('Message Formatting', () {
    test('leading/trailing whitespace should be trimmed', () {
      final result = chatService.formatMessageContent('  Hello world  ');
      expect(result, 'Hello world');
    });

    test('multiple newlines should be collapsed to double newline', () {
      final result = chatService.formatMessageContent('Hello\n\n\n\n\nworld');
      expect(result, 'Hello\n\nworld');
    });

    test('multiple spaces should be collapsed to single space', () {
      final result = chatService.formatMessageContent('Hello    world');
      expect(result, 'Hello world');
    });

    test('single newline should be preserved', () {
      final result = chatService.formatMessageContent('Hello\nworld');
      expect(result, 'Hello\nworld');
    });

    test('double newline should be preserved', () {
      final result = chatService.formatMessageContent('Hello\n\nworld');
      expect(result, 'Hello\n\nworld');
    });

    test('empty string should remain empty', () {
      final result = chatService.formatMessageContent('');
      expect(result, '');
    });

    test('whitespace-only string should become empty', () {
      final result = chatService.formatMessageContent('   ');
      expect(result, '');
    });
  });

  group('ChatSendResult Factories', () {
    test('success result has message ID', () {
      final result = ChatSendResult.success('msg-123');

      expect(result.success, true);
      expect(result.messageId, 'msg-123');
      expect(result.errorCode, isNull);
    });

    test('error result has error details', () {
      final result = ChatSendResult.error('TEST', 'Test error');

      expect(result.success, false);
      expect(result.errorCode, 'TEST');
      expect(result.errorMessage, 'Test error');
      expect(result.messageId, isNull);
    });

    test('common error factories produce distinct codes', () {
      final quota = ChatSendResult.quotaExceeded();
      final charLimit = ChatSendResult.characterLimitExceeded(100);
      final expired = ChatSendResult.subscriptionExpired();
      final network = ChatSendResult.networkError();
      final unauth = ChatSendResult.unauthorized();

      final codes = {
        quota.errorCode,
        charLimit.errorCode,
        expired.errorCode,
        network.errorCode,
        unauth.errorCode,
      };

      expect(codes.length, 5);
    });

    test('characterLimitExceeded includes limit in message', () {
      final result = ChatSendResult.characterLimitExceeded(200);
      expect(result.errorMessage, contains('200'));
    });
  });

  group('ReplyQuota — JSON Serialization', () {
    test('round-trip fromJson/toJson preserves all fields', () {
      final now = DateTime.now();
      final original = ReplyQuota(
        id: 'quota-1',
        userId: 'user-1',
        channelId: 'channel-1',
        tokensAvailable: 2,
        tokensUsed: 1,
        lastBroadcastId: 'broadcast-1',
        lastBroadcastAt: now,
        lastReplyAt: now,
        fallbackAvailable: true,
        fallbackUsedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = ReplyQuota.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.channelId, original.channelId);
      expect(restored.tokensAvailable, original.tokensAvailable);
      expect(restored.tokensUsed, original.tokensUsed);
      expect(restored.lastBroadcastId, original.lastBroadcastId);
      expect(restored.fallbackAvailable, original.fallbackAvailable);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'quota-1',
        'user_id': 'user-1',
        'channel_id': 'channel-1',
        'tokens_available': 3,
        'tokens_used': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final quota = ReplyQuota.fromJson(json);

      expect(quota.lastBroadcastId, isNull);
      expect(quota.lastBroadcastAt, isNull);
      expect(quota.lastReplyAt, isNull);
      expect(quota.fallbackAvailable, false);
      expect(quota.fallbackUsedAt, isNull);
    });

    test('fromJson defaults tokensAvailable to 0 when missing', () {
      final json = {
        'id': 'quota-1',
        'user_id': 'user-1',
        'channel_id': 'channel-1',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final quota = ReplyQuota.fromJson(json);
      expect(quota.tokensAvailable, 0);
      expect(quota.tokensUsed, 0);
    });
  });

  group('ReplyQuota — copyWith', () {
    test('copyWith preserves unchanged fields', () {
      final original = createQuota(tokensAvailable: 3, tokensUsed: 1);
      final modified = original.copyWith(tokensAvailable: 2);

      expect(modified.tokensAvailable, 2);
      expect(modified.tokensUsed, 1); // unchanged
      expect(modified.userId, original.userId); // unchanged
      expect(modified.channelId, original.channelId); // unchanged
    });

    test('copyWith can update multiple fields', () {
      final original = createQuota();
      final modified = original.copyWith(
        tokensAvailable: 0,
        tokensUsed: 3,
        fallbackAvailable: true,
      );

      expect(modified.tokensAvailable, 0);
      expect(modified.tokensUsed, 3);
      expect(modified.fallbackAvailable, true);
    });
  });

  group('Validation Priority Order', () {
    test('subscription check happens before quota check', () {
      // Even with valid quota, expired subscription should block
      final quota = createQuota(tokensAvailable: 3);

      final result = chatService.validateMessage(
        content: 'Hello!',
        characterLimit: 150,
        quota: quota,
        isSubscriptionActive: false,
      );

      expect(result!.errorCode, 'SUBSCRIPTION_EXPIRED');
    });

    test('quota check happens before character limit check', () {
      // With exhausted quota, should get QUOTA_EXCEEDED not CHARACTER_LIMIT
      final quota = createQuota(tokensAvailable: 0);
      final longMessage = 'A' * 200;

      final result = chatService.validateMessage(
        content: longMessage,
        characterLimit: 50,
        quota: quota,
        isSubscriptionActive: true,
      );

      expect(result!.errorCode, 'QUOTA_EXCEEDED');
    });
  });
}
