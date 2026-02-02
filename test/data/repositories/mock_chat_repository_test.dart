import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/broadcast_message.dart';
import 'package:uno_a_flutter/data/repositories/mock_chat_repository.dart';

void main() {
  group('MockChatRepository', () {
    late MockChatRepository repository;

    setUp(() {
      repository = MockChatRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    group('getChannel', () {
      test('returns channel for valid channel ID', () async {
        final channel = await repository.getChannel('channel_1');

        expect(channel, isNotNull);
        expect(channel!.id, equals('channel_1'));
        expect(channel.name, equals('아이유'));
      });

      test('returns null for invalid channel ID', () async {
        final channel = await repository.getChannel('nonexistent');

        expect(channel, isNull);
      });
    });

    group('getSubscribedChannels', () {
      test('returns list of subscribed channels', () async {
        final channels = await repository.getSubscribedChannels();

        expect(channels, isNotEmpty);
        expect(channels.length, equals(2));
        expect(channels.any((c) => c.id == 'channel_1'), isTrue);
        expect(channels.any((c) => c.id == 'channel_2'), isTrue);
      });
    });

    group('getMessages', () {
      test('returns messages for valid channel', () async {
        final messages = await repository.getMessages('channel_1');

        expect(messages, isNotEmpty);
        expect(messages.every((m) => m.channelId == 'channel_1'), isTrue);
      });

      test('returns empty list for invalid channel', () async {
        final messages = await repository.getMessages('nonexistent');

        expect(messages, isEmpty);
      });

      test('respects limit parameter', () async {
        final messages = await repository.getMessages('channel_1', limit: 1);

        expect(messages.length, lessThanOrEqualTo(1));
      });
    });

    group('watchMessages', () {
      test('emits messages for channel', () async {
        final stream = repository.watchMessages('channel_1');
        final messages = await stream.first;

        expect(messages, isNotEmpty);
        expect(messages.every((m) => m.channelId == 'channel_1'), isTrue);
      });

      test('emits empty list for invalid channel', () async {
        final stream = repository.watchMessages('nonexistent');
        final messages = await stream.first;

        expect(messages, isEmpty);
      });
    });

    group('getQuota', () {
      test('returns quota for subscribed channel', () async {
        final quota = await repository.getQuota('channel_1');

        expect(quota, isNotNull);
        expect(quota!.channelId, equals('channel_1'));
        expect(quota.tokensAvailable, greaterThanOrEqualTo(0));
      });

      test('returns null for invalid channel', () async {
        final quota = await repository.getQuota('nonexistent');

        expect(quota, isNull);
      });
    });

    group('watchQuota', () {
      test('emits quota for channel', () async {
        final stream = repository.watchQuota('channel_1');
        final quota = await stream.first;

        expect(quota, isNotNull);
        expect(quota!.channelId, equals('channel_1'));
      });
    });

    group('getSubscription', () {
      test('returns subscription for subscribed channel', () async {
        final subscription = await repository.getSubscription('channel_1');

        expect(subscription, isNotNull);
        expect(subscription!.channelId, equals('channel_1'));
        expect(subscription.isActive, isTrue);
      });

      test('returns null for unsubscribed channel', () async {
        final subscription = await repository.getSubscription('nonexistent');

        expect(subscription, isNull);
      });
    });

    group('getDaysSubscribed', () {
      test('returns positive days for active subscription', () async {
        final days = await repository.getDaysSubscribed('channel_1');

        expect(days, greaterThan(0));
      });

      test('returns 0 for unsubscribed channel', () async {
        final days = await repository.getDaysSubscribed('nonexistent');

        expect(days, equals(0));
      });
    });

    group('getCharacterLimit', () {
      test('returns character limit based on subscription age', () async {
        // channel_1 has 85 days subscription, should get 77 char limit
        final limit = await repository.getCharacterLimit('channel_1');

        expect(limit, equals(77));
      });

      test('returns base limit for new subscription', () async {
        // channel_2 has 30 days subscription, should get 50 char limit
        final limit = await repository.getCharacterLimit('channel_2');

        expect(limit, equals(50));
      });

      test('returns base limit for unsubscribed channel', () async {
        final limit = await repository.getCharacterLimit('nonexistent');

        expect(limit, equals(50));
      });
    });

    group('sendReply', () {
      test('creates message and decrements quota', () async {
        final quotaBefore = await repository.getQuota('channel_1');
        final tokensBefore = quotaBefore!.tokensAvailable;

        final message = await repository.sendReply('channel_1', '안녕하세요!');

        expect(message, isNotNull);
        expect(message.content, equals('안녕하세요!'));
        expect(message.senderType, equals('fan'));
        expect(message.deliveryScope, equals(DeliveryScope.directReply));

        final quotaAfter = await repository.getQuota('channel_1');
        expect(quotaAfter!.tokensAvailable, equals(tokensBefore - 1));
      });

      test('throws when no tokens available', () async {
        // channel_2 has 0 tokens
        expect(
          () => repository.sendReply('channel_2', '메시지'),
          throwsException,
        );
      });

      test('throws when message exceeds character limit', () async {
        // channel_1 has 77 char limit
        final longMessage = 'a' * 100;

        expect(
          () => repository.sendReply('channel_1', longMessage),
          throwsException,
        );
      });

      test('notifies message stream after sending', () async {
        final stream = repository.watchMessages('channel_1');
        final initialMessages = await stream.first;
        final initialCount = initialMessages.length;

        await repository.sendReply('channel_1', 'New message');

        // Get next emission
        final updatedMessages = await stream.first;
        expect(updatedMessages.length, equals(initialCount + 1));
      });
    });

    group('sendDonationMessage', () {
      test('creates donation message', () async {
        final message = await repository.sendDonationMessage(
          'channel_1',
          '후원합니다!',
          100,
          'donation_id_123',
        );

        expect(message, isNotNull);
        expect(message.content, equals('후원합니다!'));
        expect(message.deliveryScope, equals(DeliveryScope.donationMessage));
        expect(message.donationAmount, equals(100));
        expect(message.donationId, equals('donation_id_123'));
      });

      test('allows message without tokens (donation bypasses quota)', () async {
        // channel_2 has 0 tokens but donation should still work
        final message = await repository.sendDonationMessage(
          'channel_2',
          '응원해요!',
          500,
          'donation_id_456',
        );

        expect(message, isNotNull);
        expect(message.donationAmount, equals(500));
      });

      test('throws when message exceeds 100 character limit', () async {
        final longMessage = 'a' * 101;

        expect(
          () => repository.sendDonationMessage(
            'channel_1',
            longMessage,
            100,
            'donation_id',
          ),
          throwsException,
        );
      });

      test('allows message up to 100 characters', () async {
        final exactMessage = 'a' * 100;

        final message = await repository.sendDonationMessage(
          'channel_1',
          exactMessage,
          100,
          'donation_id',
        );

        expect(message.content, hasLength(100));
      });
    });
  });

  group('MockArtistInboxRepository', () {
    late MockArtistInboxRepository repository;

    setUp(() {
      repository = MockArtistInboxRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    group('getFanMessages', () {
      test('returns all fan messages by default', () async {
        final messages = await repository.getFanMessages('channel_1');

        expect(messages, isNotEmpty);
        expect(messages.every((m) => m.senderType == 'fan'), isTrue);
      });

      test('filters by donation type', () async {
        final messages = await repository.getFanMessages(
          'channel_1',
          filterType: 'donation',
        );

        expect(
          messages.every((m) => m.deliveryScope == DeliveryScope.donationMessage),
          isTrue,
        );
      });

      test('filters by regular type', () async {
        final messages = await repository.getFanMessages(
          'channel_1',
          filterType: 'regular',
        );

        expect(
          messages.every((m) => m.deliveryScope == DeliveryScope.directReply),
          isTrue,
        );
      });

      test('filters by highlighted', () async {
        final messages = await repository.getFanMessages(
          'channel_1',
          filterType: 'highlighted',
        );

        expect(messages.every((m) => m.isHighlighted), isTrue);
      });

      test('respects limit and offset', () async {
        final allMessages = await repository.getFanMessages('channel_1');
        final limitedMessages = await repository.getFanMessages(
          'channel_1',
          limit: 1,
          offset: 1,
        );

        expect(limitedMessages.length, equals(1));
        if (allMessages.length > 1) {
          expect(limitedMessages.first.id, equals(allMessages[1].id));
        }
      });
    });

    group('watchFanMessages', () {
      test('emits fan messages for channel', () async {
        final stream = repository.watchFanMessages('channel_1');
        final messages = await stream.first;

        expect(messages, isNotEmpty);
        expect(messages.every((m) => m.senderType == 'fan'), isTrue);
      });
    });

    group('sendBroadcast', () {
      test('creates broadcast message', () async {
        final message = await repository.sendBroadcast(
          'channel_1',
          '오늘도 좋은 하루 보내세요!',
        );

        expect(message, isNotNull);
        expect(message.content, equals('오늘도 좋은 하루 보내세요!'));
        expect(message.senderType, equals('artist'));
        expect(message.deliveryScope, equals(DeliveryScope.broadcast));
        expect(message.messageType, equals(BroadcastMessageType.text));
      });

      test('supports image message type', () async {
        final message = await repository.sendBroadcast(
          'channel_1',
          '새 사진!',
          messageType: BroadcastMessageType.image,
          mediaUrl: 'https://example.com/image.jpg',
        );

        expect(message.messageType, equals(BroadcastMessageType.image));
        expect(message.mediaUrl, equals('https://example.com/image.jpg'));
      });
    });

    group('replyToDonation', () {
      test('creates donation reply to valid donation message', () async {
        final message = await repository.replyToDonation(
          'channel_1',
          'fan_msg_2', // This is the donation message in mock data
          '감사합니다!',
        );

        expect(message, isNotNull);
        expect(message.deliveryScope, equals(DeliveryScope.donationReply));
        expect(message.replyToMessageId, equals('fan_msg_2'));
        expect(message.content, equals('감사합니다!'));
      });

      test('throws for non-donation message', () async {
        expect(
          () => repository.replyToDonation(
            'channel_1',
            'fan_msg_1', // This is a regular reply, not a donation
            '답장',
          ),
          throwsException,
        );
      });

      test('throws for nonexistent message', () async {
        expect(
          () => repository.replyToDonation(
            'channel_1',
            'nonexistent_msg',
            '답장',
          ),
          throwsException,
        );
      });
    });

    group('toggleHighlight', () {
      test('toggles highlight status', () async {
        // Get initial state
        var messages = await repository.getFanMessages('channel_1');
        final message = messages.firstWhere((m) => m.id == 'fan_msg_1');
        final initialHighlight = message.isHighlighted;

        // Toggle
        await repository.toggleHighlight('fan_msg_1');

        // Check new state
        messages = await repository.getFanMessages('channel_1');
        final updatedMessage = messages.firstWhere((m) => m.id == 'fan_msg_1');
        expect(updatedMessage.isHighlighted, equals(!initialHighlight));
      });
    });

    group('getInboxStats', () {
      test('returns inbox statistics', () async {
        final stats = await repository.getInboxStats('channel_1');

        expect(stats, isNotNull);
        expect(stats.totalMessages, greaterThanOrEqualTo(0));
        expect(stats.subscriberCount, greaterThan(0));
      });

      test('counts donation messages correctly', () async {
        final allMessages = await repository.getFanMessages('channel_1');
        final donationCount = allMessages
            .where((m) => m.deliveryScope == DeliveryScope.donationMessage)
            .length;

        final stats = await repository.getInboxStats('channel_1');

        expect(stats.donationMessages, equals(donationCount));
      });

      test('counts highlighted messages correctly', () async {
        final allMessages = await repository.getFanMessages('channel_1');
        final highlightedCount = allMessages.where((m) => m.isHighlighted).length;

        final stats = await repository.getInboxStats('channel_1');

        expect(stats.highlightedMessages, equals(highlightedCount));
      });
    });
  });

  group('InboxStats', () {
    test('stores all statistics', () {
      const stats = InboxStats(
        totalMessages: 100,
        unreadMessages: 25,
        donationMessages: 10,
        highlightedMessages: 5,
        subscriberCount: 1000,
      );

      expect(stats.totalMessages, equals(100));
      expect(stats.unreadMessages, equals(25));
      expect(stats.donationMessages, equals(10));
      expect(stats.highlightedMessages, equals(5));
      expect(stats.subscriberCount, equals(1000));
    });
  });
}
