import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/broadcast_message.dart';

void main() {
  group('DeliveryScope', () {
    test('has all expected values', () {
      expect(DeliveryScope.values, hasLength(4));
      expect(DeliveryScope.values, contains(DeliveryScope.broadcast));
      expect(DeliveryScope.values, contains(DeliveryScope.directReply));
      expect(DeliveryScope.values, contains(DeliveryScope.donationMessage));
      expect(DeliveryScope.values, contains(DeliveryScope.donationReply));
    });
  });

  group('BroadcastMessageType', () {
    test('has all expected values', () {
      expect(BroadcastMessageType.values, hasLength(4));
      expect(BroadcastMessageType.values, contains(BroadcastMessageType.text));
      expect(BroadcastMessageType.values, contains(BroadcastMessageType.image));
      expect(BroadcastMessageType.values, contains(BroadcastMessageType.emoji));
      expect(BroadcastMessageType.values, contains(BroadcastMessageType.voice));
    });
  });

  group('BroadcastMessage', () {
    final now = DateTime(2024, 1, 15, 12, 0, 0);

    group('computed properties', () {
      test('isFromArtist returns true for artist sender', () {
        final message = BroadcastMessage(
          id: 'msg-1',
          channelId: 'channel-1',
          senderId: 'artist-1',
          senderType: 'artist',
          deliveryScope: DeliveryScope.broadcast,
          createdAt: now,
        );

        expect(message.isFromArtist, isTrue);
        expect(message.isFromFan, isFalse);
      });

      test('isFromFan returns true for fan sender', () {
        final message = BroadcastMessage(
          id: 'msg-1',
          channelId: 'channel-1',
          senderId: 'user-1',
          senderType: 'fan',
          deliveryScope: DeliveryScope.directReply,
          createdAt: now,
        );

        expect(message.isFromFan, isTrue);
        expect(message.isFromArtist, isFalse);
      });

      test('isBroadcast returns true for broadcast scope', () {
        final message = BroadcastMessage(
          id: 'msg-1',
          channelId: 'channel-1',
          senderId: 'artist-1',
          senderType: 'artist',
          deliveryScope: DeliveryScope.broadcast,
          createdAt: now,
        );

        expect(message.isBroadcast, isTrue);
        expect(message.isDonation, isFalse);
      });

      test('isDonation returns true for donation message', () {
        final message = BroadcastMessage(
          id: 'msg-1',
          channelId: 'channel-1',
          senderId: 'user-1',
          senderType: 'fan',
          deliveryScope: DeliveryScope.donationMessage,
          donationAmount: 1000,
          createdAt: now,
        );

        expect(message.isDonation, isTrue);
        expect(message.isBroadcast, isFalse);
      });

      test('isDonation returns true for donation reply', () {
        final message = BroadcastMessage(
          id: 'msg-1',
          channelId: 'channel-1',
          senderId: 'artist-1',
          senderType: 'artist',
          deliveryScope: DeliveryScope.donationReply,
          createdAt: now,
        );

        expect(message.isDonation, isTrue);
      });
    });

    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'id': 'msg-1',
          'channel_id': 'channel-1',
          'sender_id': 'artist-1',
          'sender_type': 'artist',
          'delivery_scope': 'broadcast',
          'reply_to_message_id': null,
          'target_user_id': null,
          'content': 'Hello fans!',
          'message_type': 'text',
          'media_url': null,
          'media_metadata': null,
          'donation_id': null,
          'donation_amount': null,
          'is_highlighted': false,
          'highlighted_at': null,
          'created_at': '2024-01-15T12:00:00.000',
          'updated_at': '2024-01-15T12:00:00.000',
          'deleted_at': null,
          'is_read': true,
          'read_at': '2024-01-15T12:30:00.000',
          'sender_name': 'Test Artist',
          'sender_avatar_url': 'https://example.com/avatar.jpg',
          'sender_tier': 'VIP',
          'sender_days_subscribed': 100,
        };

        final message = BroadcastMessage.fromJson(json);

        expect(message.id, equals('msg-1'));
        expect(message.channelId, equals('channel-1'));
        expect(message.senderId, equals('artist-1'));
        expect(message.senderType, equals('artist'));
        expect(message.deliveryScope, equals(DeliveryScope.broadcast));
        expect(message.content, equals('Hello fans!'));
        expect(message.messageType, equals(BroadcastMessageType.text));
        expect(message.isRead, isTrue);
        expect(message.senderName, equals('Test Artist'));
        expect(message.senderTier, equals('VIP'));
        expect(message.senderDaysSubscribed, equals(100));
      });

      test('parses delivery_scope direct_reply', () {
        final json = _createMinimalJson(deliveryScope: 'direct_reply');
        final message = BroadcastMessage.fromJson(json);
        expect(message.deliveryScope, equals(DeliveryScope.directReply));
      });

      test('parses delivery_scope donation_message', () {
        final json = _createMinimalJson(deliveryScope: 'donation_message');
        final message = BroadcastMessage.fromJson(json);
        expect(message.deliveryScope, equals(DeliveryScope.donationMessage));
      });

      test('parses delivery_scope donation_reply', () {
        final json = _createMinimalJson(deliveryScope: 'donation_reply');
        final message = BroadcastMessage.fromJson(json);
        expect(message.deliveryScope, equals(DeliveryScope.donationReply));
      });

      test('defaults unknown delivery_scope to broadcast', () {
        final json = _createMinimalJson(deliveryScope: 'unknown_scope');
        final message = BroadcastMessage.fromJson(json);
        expect(message.deliveryScope, equals(DeliveryScope.broadcast));
      });

      test('parses message_type image', () {
        final json = _createMinimalJson(messageType: 'image');
        final message = BroadcastMessage.fromJson(json);
        expect(message.messageType, equals(BroadcastMessageType.image));
      });

      test('parses message_type emoji', () {
        final json = _createMinimalJson(messageType: 'emoji');
        final message = BroadcastMessage.fromJson(json);
        expect(message.messageType, equals(BroadcastMessageType.emoji));
      });

      test('parses message_type voice', () {
        final json = _createMinimalJson(messageType: 'voice');
        final message = BroadcastMessage.fromJson(json);
        expect(message.messageType, equals(BroadcastMessageType.voice));
      });

      test('defaults unknown message_type to text', () {
        final json = _createMinimalJson(messageType: 'unknown_type');
        final message = BroadcastMessage.fromJson(json);
        expect(message.messageType, equals(BroadcastMessageType.text));
      });

      test('handles null message_type', () {
        final json = _createMinimalJson();
        json.remove('message_type');
        final message = BroadcastMessage.fromJson(json);
        expect(message.messageType, equals(BroadcastMessageType.text));
      });

      test('parses datetime fields correctly', () {
        final json = {
          ..._createMinimalJson(),
          'highlighted_at': '2024-01-15T10:00:00.000',
          'updated_at': '2024-01-15T11:00:00.000',
          'deleted_at': '2024-01-15T14:00:00.000',
          'read_at': '2024-01-15T12:30:00.000',
        };

        final message = BroadcastMessage.fromJson(json);

        expect(message.highlightedAt, isNotNull);
        expect(message.updatedAt, isNotNull);
        expect(message.deletedAt, isNotNull);
        expect(message.readAt, isNotNull);
      });

      test('handles null datetime fields', () {
        final json = _createMinimalJson();
        final message = BroadcastMessage.fromJson(json);

        expect(message.highlightedAt, isNull);
        expect(message.updatedAt, isNull);
        expect(message.deletedAt, isNull);
        expect(message.readAt, isNull);
      });

      test('parses donation fields', () {
        final json = {
          ..._createMinimalJson(deliveryScope: 'donation_message'),
          'donation_id': 'donation-123',
          'donation_amount': 5000,
        };

        final message = BroadcastMessage.fromJson(json);

        expect(message.donationId, equals('donation-123'));
        expect(message.donationAmount, equals(5000));
      });
    });

    group('toJson', () {
      test('produces correct output', () {
        final message = BroadcastMessage(
          id: 'msg-1',
          channelId: 'channel-1',
          senderId: 'artist-1',
          senderType: 'artist',
          deliveryScope: DeliveryScope.broadcast,
          content: 'Hello!',
          messageType: BroadcastMessageType.text,
          isHighlighted: true,
          createdAt: now,
        );

        final json = message.toJson();

        expect(json['id'], equals('msg-1'));
        expect(json['channel_id'], equals('channel-1'));
        expect(json['sender_id'], equals('artist-1'));
        expect(json['sender_type'], equals('artist'));
        expect(json['delivery_scope'], equals('broadcast'));
        expect(json['content'], equals('Hello!'));
        expect(json['message_type'], equals('text'));
        expect(json['is_highlighted'], isTrue);
      });

      test('converts all delivery scopes correctly', () {
        for (final scope in DeliveryScope.values) {
          final message = BroadcastMessage(
            id: 'msg-1',
            channelId: 'channel-1',
            senderId: 'sender-1',
            senderType: 'artist',
            deliveryScope: scope,
            createdAt: now,
          );

          final json = message.toJson();
          final expectedString = switch (scope) {
            DeliveryScope.broadcast => 'broadcast',
            DeliveryScope.directReply => 'direct_reply',
            DeliveryScope.donationMessage => 'donation_message',
            DeliveryScope.donationReply => 'donation_reply',
          };

          expect(json['delivery_scope'], equals(expectedString));
        }
      });

      test('converts all message types correctly', () {
        for (final type in BroadcastMessageType.values) {
          final message = BroadcastMessage(
            id: 'msg-1',
            channelId: 'channel-1',
            senderId: 'sender-1',
            senderType: 'artist',
            deliveryScope: DeliveryScope.broadcast,
            messageType: type,
            createdAt: now,
          );

          final json = message.toJson();
          final expectedString = switch (type) {
            BroadcastMessageType.text => 'text',
            BroadcastMessageType.image => 'image',
            BroadcastMessageType.emoji => 'emoji',
            BroadcastMessageType.voice => 'voice',
          };

          expect(json['message_type'], equals(expectedString));
        }
      });
    });

    group('roundtrip serialization', () {
      test('preserves all data through toJson and fromJson', () {
        final original = BroadcastMessage(
          id: 'msg-1',
          channelId: 'channel-1',
          senderId: 'artist-1',
          senderType: 'artist',
          deliveryScope: DeliveryScope.donationMessage,
          content: 'Test message',
          messageType: BroadcastMessageType.image,
          mediaUrl: 'https://example.com/image.jpg',
          donationId: 'donation-1',
          donationAmount: 1000,
          isHighlighted: true,
          highlightedAt: now,
          createdAt: now,
          updatedAt: now,
        );

        final json = original.toJson();
        final restored = BroadcastMessage.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.channelId, equals(original.channelId));
        expect(restored.senderId, equals(original.senderId));
        expect(restored.senderType, equals(original.senderType));
        expect(restored.deliveryScope, equals(original.deliveryScope));
        expect(restored.content, equals(original.content));
        expect(restored.messageType, equals(original.messageType));
        expect(restored.mediaUrl, equals(original.mediaUrl));
        expect(restored.donationId, equals(original.donationId));
        expect(restored.donationAmount, equals(original.donationAmount));
        expect(restored.isHighlighted, equals(original.isHighlighted));
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = BroadcastMessage(
          id: 'msg-1',
          channelId: 'channel-1',
          senderId: 'artist-1',
          senderType: 'artist',
          deliveryScope: DeliveryScope.broadcast,
          content: 'Original',
          createdAt: now,
        );

        final copy = original.copyWith(
          content: 'Updated',
          isHighlighted: true,
        );

        expect(copy.content, equals('Updated'));
        expect(copy.isHighlighted, isTrue);
        expect(copy.id, equals(original.id));
        expect(copy.channelId, equals(original.channelId));
      });

      test('preserves all fields when no arguments', () {
        final original = BroadcastMessage(
          id: 'msg-1',
          channelId: 'channel-1',
          senderId: 'artist-1',
          senderType: 'artist',
          deliveryScope: DeliveryScope.broadcast,
          content: 'Test',
          createdAt: now,
        );

        final copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.channelId, equals(original.channelId));
        expect(copy.content, equals(original.content));
        expect(copy.deliveryScope, equals(original.deliveryScope));
      });
    });

    group('default values', () {
      test('messageType defaults to text', () {
        final message = BroadcastMessage(
          id: 'msg-1',
          channelId: 'channel-1',
          senderId: 'artist-1',
          senderType: 'artist',
          deliveryScope: DeliveryScope.broadcast,
          createdAt: now,
        );

        expect(message.messageType, equals(BroadcastMessageType.text));
      });

      test('isHighlighted defaults to false', () {
        final message = BroadcastMessage(
          id: 'msg-1',
          channelId: 'channel-1',
          senderId: 'artist-1',
          senderType: 'artist',
          deliveryScope: DeliveryScope.broadcast,
          createdAt: now,
        );

        expect(message.isHighlighted, isFalse);
      });
    });
  });
}

Map<String, dynamic> _createMinimalJson({
  String deliveryScope = 'broadcast',
  String? messageType,
}) {
  return {
    'id': 'msg-1',
    'channel_id': 'channel-1',
    'sender_id': 'sender-1',
    'sender_type': 'artist',
    'delivery_scope': deliveryScope,
    if (messageType != null) 'message_type': messageType,
    'created_at': '2024-01-15T12:00:00.000',
  };
}
