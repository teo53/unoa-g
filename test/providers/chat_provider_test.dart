import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/broadcast_message.dart';
import 'package:uno_a_flutter/data/models/reply_quota.dart';

// Note: Full provider tests require mock Supabase setup.
// These tests focus on model interactions and state logic that can be tested independently.

void main() {
  group('ChatState logic', () {
    // Helper to create test messages
    BroadcastMessage createMessage({
      required String id,
      String senderType = 'artist',
      DeliveryScope deliveryScope = DeliveryScope.broadcast,
      BroadcastMessageType messageType = BroadcastMessageType.text,
      String? content,
      DateTime? createdAt,
    }) {
      return BroadcastMessage(
        id: id,
        channelId: 'channel-1',
        senderId: 'sender-1',
        senderType: senderType,
        deliveryScope: deliveryScope,
        messageType: messageType,
        content: content ?? 'Test message',
        createdAt: createdAt ?? DateTime.now(),
      );
    }

    // Helper to create test quota
    ReplyQuota createQuota({
      int tokensAvailable = 3,
      bool fallbackAvailable = false,
    }) {
      final now = DateTime.now();
      return ReplyQuota(
        id: 'quota-1',
        userId: 'user-1',
        channelId: 'channel-1',
        tokensAvailable: tokensAvailable,
        tokensUsed: 0,
        fallbackAvailable: fallbackAvailable,
        createdAt: now,
        updatedAt: now,
      );
    }

    group('Reply capability', () {
      test('can reply when quota has tokens', () {
        final quota = createQuota(tokensAvailable: 3);
        expect(quota.canReply, isTrue);
      });

      test('can reply when quota has fallback', () {
        final quota = createQuota(tokensAvailable: 0, fallbackAvailable: true);
        expect(quota.canReply, isTrue);
      });

      test('cannot reply when no tokens and no fallback', () {
        final quota = createQuota(tokensAvailable: 0, fallbackAvailable: false);
        expect(quota.canReply, isFalse);
      });
    });

    group('Message filtering', () {
      test('filters artist messages correctly', () {
        final messages = [
          createMessage(id: '1', senderType: 'artist'),
          createMessage(id: '2', senderType: 'fan'),
          createMessage(id: '3', senderType: 'artist'),
        ];

        final artistMessages = messages.where((m) => m.isFromArtist).toList();
        expect(artistMessages.length, equals(2));
      });

      test('filters broadcast messages correctly', () {
        final messages = [
          createMessage(id: '1', deliveryScope: DeliveryScope.broadcast),
          createMessage(id: '2', deliveryScope: DeliveryScope.directReply),
          createMessage(id: '3', deliveryScope: DeliveryScope.donationMessage),
        ];

        final broadcasts = messages.where((m) => m.isBroadcast).toList();
        expect(broadcasts.length, equals(1));
      });

      test('filters donation messages correctly', () {
        final messages = [
          createMessage(id: '1', deliveryScope: DeliveryScope.broadcast),
          createMessage(id: '2', deliveryScope: DeliveryScope.donationMessage),
          createMessage(id: '3', deliveryScope: DeliveryScope.donationReply),
        ];

        final donations = messages.where((m) => m.isDonation).toList();
        expect(donations.length, equals(2));
      });
    });

    group('Message sorting', () {
      test('sorts messages by createdAt descending (newest first)', () {
        final now = DateTime.now();
        final messages = [
          createMessage(id: '1', createdAt: now.subtract(const Duration(hours: 2))),
          createMessage(id: '2', createdAt: now),
          createMessage(id: '3', createdAt: now.subtract(const Duration(hours: 1))),
        ];

        final sorted = List<BroadcastMessage>.from(messages)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        expect(sorted[0].id, equals('2')); // Newest
        expect(sorted[1].id, equals('3'));
        expect(sorted[2].id, equals('1')); // Oldest
      });

      test('sorts messages by createdAt ascending (oldest first)', () {
        final now = DateTime.now();
        final messages = [
          createMessage(id: '1', createdAt: now.subtract(const Duration(hours: 2))),
          createMessage(id: '2', createdAt: now),
          createMessage(id: '3', createdAt: now.subtract(const Duration(hours: 1))),
        ];

        final sorted = List<BroadcastMessage>.from(messages)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        expect(sorted[0].id, equals('1')); // Oldest
        expect(sorted[1].id, equals('3'));
        expect(sorted[2].id, equals('2')); // Newest
      });
    });

    group('Message type handling', () {
      test('correctly identifies image messages', () {
        final message = createMessage(
          id: '1',
          messageType: BroadcastMessageType.image,
        );
        expect(message.messageType, equals(BroadcastMessageType.image));
      });

      test('correctly identifies video messages', () {
        final message = createMessage(
          id: '1',
          messageType: BroadcastMessageType.video,
        );
        expect(message.messageType, equals(BroadcastMessageType.video));
      });

      test('correctly identifies voice messages', () {
        final message = createMessage(
          id: '1',
          messageType: BroadcastMessageType.voice,
        );
        expect(message.messageType, equals(BroadcastMessageType.voice));
      });
    });

    group('Character limit calculation', () {
      test('returns base limit for new subscribers', () {
        final limit = ReplyQuota.getCharacterLimitForDays(1);
        expect(limit, equals(50));
      });

      test('returns increased limit for long-term subscribers', () {
        final limit100 = ReplyQuota.getCharacterLimitForDays(100);
        final limit200 = ReplyQuota.getCharacterLimitForDays(200);
        final limit300 = ReplyQuota.getCharacterLimitForDays(300);

        expect(limit100, equals(100));
        expect(limit200, equals(200));
        expect(limit300, equals(300));
      });
    });

    group('Quota management', () {
      test('afterReply decrements tokens correctly', () {
        final quota = createQuota(tokensAvailable: 3);
        final afterFirst = quota.afterReply();
        final afterSecond = afterFirst.afterReply();
        final afterThird = afterSecond.afterReply();

        expect(afterFirst.tokensAvailable, equals(2));
        expect(afterSecond.tokensAvailable, equals(1));
        expect(afterThird.tokensAvailable, equals(0));
      });

      test('uses fallback after tokens exhausted', () {
        final quota = createQuota(tokensAvailable: 0, fallbackAvailable: true);
        final afterFallback = quota.afterReply();

        expect(afterFallback.tokensAvailable, equals(0));
        expect(afterFallback.fallbackAvailable, isFalse);
        expect(afterFallback.fallbackUsedAt, isNotNull);
      });
    });

    group('Message list operations', () {
      test('adds new message to beginning of list', () {
        final existing = [
          createMessage(id: '1'),
          createMessage(id: '2'),
        ];

        final newMessage = createMessage(id: '3');
        final updated = [newMessage, ...existing];

        expect(updated.length, equals(3));
        expect(updated.first.id, equals('3'));
      });

      test('deduplicates messages by id', () {
        final messages = [
          createMessage(id: '1', content: 'First'),
          createMessage(id: '2'),
          createMessage(id: '1', content: 'Duplicate'),
        ];

        final seen = <String>{};
        final deduplicated = messages.where((m) {
          if (seen.contains(m.id)) return false;
          seen.add(m.id);
          return true;
        }).toList();

        expect(deduplicated.length, equals(2));
        expect(deduplicated.first.content, equals('First'));
      });
    });
  });

  group('ProviderContainer tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('container can be created and disposed', () {
      expect(container, isNotNull);
    });
  });
}
