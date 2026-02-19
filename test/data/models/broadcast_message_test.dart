import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/broadcast_message.dart';

void main() {
  group('DeliveryScope', () {
    test('parses broadcast correctly', () {
      final json = _createMessageJson(deliveryScope: 'broadcast');
      final message = BroadcastMessage.fromJson(json);
      expect(message.deliveryScope, equals(DeliveryScope.broadcast));
    });

    test('parses direct_reply correctly', () {
      final json = _createMessageJson(deliveryScope: 'direct_reply');
      final message = BroadcastMessage.fromJson(json);
      expect(message.deliveryScope, equals(DeliveryScope.directReply));
    });

    test('parses donation_message correctly', () {
      final json = _createMessageJson(deliveryScope: 'donation_message');
      final message = BroadcastMessage.fromJson(json);
      expect(message.deliveryScope, equals(DeliveryScope.donationMessage));
    });

    test('parses donation_reply correctly', () {
      final json = _createMessageJson(deliveryScope: 'donation_reply');
      final message = BroadcastMessage.fromJson(json);
      expect(message.deliveryScope, equals(DeliveryScope.donationReply));
    });

    test('defaults to broadcast for unknown value', () {
      final json = _createMessageJson(deliveryScope: 'unknown');
      final message = BroadcastMessage.fromJson(json);
      expect(message.deliveryScope, equals(DeliveryScope.broadcast));
    });
  });

  group('BroadcastMessageType', () {
    test('parses text correctly', () {
      final json = _createMessageJson(messageType: 'text');
      final message = BroadcastMessage.fromJson(json);
      expect(message.messageType, equals(BroadcastMessageType.text));
    });

    test('parses image correctly', () {
      final json = _createMessageJson(messageType: 'image');
      final message = BroadcastMessage.fromJson(json);
      expect(message.messageType, equals(BroadcastMessageType.image));
    });

    test('parses video correctly', () {
      final json = _createMessageJson(messageType: 'video');
      final message = BroadcastMessage.fromJson(json);
      expect(message.messageType, equals(BroadcastMessageType.video));
    });

    test('parses emoji correctly', () {
      final json = _createMessageJson(messageType: 'emoji');
      final message = BroadcastMessage.fromJson(json);
      expect(message.messageType, equals(BroadcastMessageType.emoji));
    });

    test('parses voice correctly', () {
      final json = _createMessageJson(messageType: 'voice');
      final message = BroadcastMessage.fromJson(json);
      expect(message.messageType, equals(BroadcastMessageType.voice));
    });

    test('defaults to text for unknown value', () {
      final json = _createMessageJson(messageType: 'unknown');
      final message = BroadcastMessage.fromJson(json);
      expect(message.messageType, equals(BroadcastMessageType.text));
    });

    test('defaults to text for null value', () {
      final json = _createMessageJson();
      json.remove('message_type');
      final message = BroadcastMessage.fromJson(json);
      expect(message.messageType, equals(BroadcastMessageType.text));
    });
  });

  group('BroadcastMessage computed properties', () {
    test('isFromArtist returns true for artist sender', () {
      final json = _createMessageJson(senderType: 'artist');
      final message = BroadcastMessage.fromJson(json);
      expect(message.isFromArtist, isTrue);
      expect(message.isFromFan, isFalse);
    });

    test('isFromFan returns true for fan sender', () {
      final json = _createMessageJson(senderType: 'fan');
      final message = BroadcastMessage.fromJson(json);
      expect(message.isFromFan, isTrue);
      expect(message.isFromArtist, isFalse);
    });

    test('isBroadcast returns true for broadcast delivery', () {
      final json = _createMessageJson(deliveryScope: 'broadcast');
      final message = BroadcastMessage.fromJson(json);
      expect(message.isBroadcast, isTrue);
    });

    test('isDonation returns true for donation_message', () {
      final json = _createMessageJson(deliveryScope: 'donation_message');
      final message = BroadcastMessage.fromJson(json);
      expect(message.isDonation, isTrue);
    });

    test('isDonation returns true for donation_reply', () {
      final json = _createMessageJson(deliveryScope: 'donation_reply');
      final message = BroadcastMessage.fromJson(json);
      expect(message.isDonation, isTrue);
    });

    test('isDonation returns false for broadcast', () {
      final json = _createMessageJson(deliveryScope: 'broadcast');
      final message = BroadcastMessage.fromJson(json);
      expect(message.isDonation, isFalse);
    });
  });

  group('BroadcastMessage fromJson / toJson', () {
    test('round-trips all fields correctly', () {
      final now = DateTime.now();
      final original = BroadcastMessage(
        id: 'msg-123',
        channelId: 'channel-456',
        senderId: 'sender-789',
        senderType: 'artist',
        deliveryScope: DeliveryScope.broadcast,
        replyToMessageId: 'reply-to-1',
        targetUserId: 'target-1',
        content: 'Hello fans!',
        messageType: BroadcastMessageType.text,
        mediaUrl: null,
        mediaMetadata: null,
        donationId: null,
        donationAmount: null,
        isHighlighted: true,
        highlightedAt: now,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
      );

      final json = original.toJson();
      final restored = BroadcastMessage.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.channelId, equals(original.channelId));
      expect(restored.senderId, equals(original.senderId));
      expect(restored.senderType, equals(original.senderType));
      expect(restored.deliveryScope, equals(original.deliveryScope));
      expect(restored.replyToMessageId, equals(original.replyToMessageId));
      expect(restored.targetUserId, equals(original.targetUserId));
      expect(restored.content, equals(original.content));
      expect(restored.messageType, equals(original.messageType));
      expect(restored.isHighlighted, equals(original.isHighlighted));
    });

    test('handles media message correctly', () {
      final json = _createMessageJson(
        messageType: 'image',
        mediaUrl: 'https://example.com/image.jpg',
        mediaMetadata: {
          'width': 800,
          'height': 600,
          'format': 'webp',
        },
      );

      final message = BroadcastMessage.fromJson(json);

      expect(message.messageType, equals(BroadcastMessageType.image));
      expect(message.mediaUrl, equals('https://example.com/image.jpg'));
      expect(message.mediaMetadata?['width'], equals(800));
      expect(message.mediaMetadata?['height'], equals(600));
    });

    test('handles donation message correctly', () {
      final json = _createMessageJson(
        deliveryScope: 'donation_message',
        donationId: 'donation-123',
        donationAmount: 500,
      );

      final message = BroadcastMessage.fromJson(json);

      expect(message.isDonation, isTrue);
      expect(message.donationId, equals('donation-123'));
      expect(message.donationAmount, equals(500));
    });

    test('handles null optional fields', () {
      final json = {
        'id': 'msg-1',
        'channel_id': 'channel-1',
        'sender_id': 'sender-1',
        'sender_type': 'artist',
        'delivery_scope': 'broadcast',
        'created_at': DateTime.now().toIso8601String(),
      };

      final message = BroadcastMessage.fromJson(json);

      expect(message.replyToMessageId, isNull);
      expect(message.targetUserId, isNull);
      expect(message.content, isNull);
      expect(message.mediaUrl, isNull);
      expect(message.mediaMetadata, isNull);
      expect(message.donationId, isNull);
      expect(message.donationAmount, isNull);
      expect(message.isHighlighted, isFalse);
      expect(message.highlightedAt, isNull);
      expect(message.updatedAt, isNull);
      expect(message.deletedAt, isNull);
    });

    test('handles read status fields', () {
      final json = _createMessageJson();
      json['is_read'] = true;
      json['read_at'] = DateTime.now().toIso8601String();

      final message = BroadcastMessage.fromJson(json);

      expect(message.isRead, isTrue);
      expect(message.readAt, isNotNull);
    });

    test('handles sender info fields', () {
      final json = _createMessageJson();
      json['sender_name'] = '아티스트 이름';
      json['sender_avatar_url'] = 'https://example.com/avatar.jpg';
      json['sender_tier'] = 'VIP';
      json['sender_days_subscribed'] = 100;

      final message = BroadcastMessage.fromJson(json);

      expect(message.senderName, equals('아티스트 이름'));
      expect(message.senderAvatarUrl, equals('https://example.com/avatar.jpg'));
      expect(message.senderTier, equals('VIP'));
      expect(message.senderDaysSubscribed, equals(100));
    });
  });

  group('Welcome delivery scope', () {
    test('parses welcome correctly', () {
      final json = _createMessageJson(deliveryScope: 'welcome');
      final message = BroadcastMessage.fromJson(json);
      expect(message.deliveryScope, equals(DeliveryScope.welcome));
    });

    test('isWelcome returns true for welcome scope', () {
      final json = _createMessageJson(deliveryScope: 'welcome');
      final message = BroadcastMessage.fromJson(json);
      expect(message.isWelcome, isTrue);
    });

    test('isWelcome returns false for broadcast scope', () {
      final json = _createMessageJson(deliveryScope: 'broadcast');
      final message = BroadcastMessage.fromJson(json);
      expect(message.isWelcome, isFalse);
    });

    test('welcome toJson produces correct value', () {
      final message = BroadcastMessage(
        id: 'msg-1',
        channelId: 'channel-1',
        senderId: 'sender-1',
        senderType: 'artist',
        deliveryScope: DeliveryScope.welcome,
        createdAt: DateTime.now(),
      );
      final json = message.toJson();
      expect(json['delivery_scope'], equals('welcome'));
    });

    test('parses public_share correctly', () {
      final json = _createMessageJson(deliveryScope: 'public_share');
      final message = BroadcastMessage.fromJson(json);
      expect(message.deliveryScope, equals(DeliveryScope.publicShare));
    });

    test('parses private_card correctly', () {
      final json = _createMessageJson(deliveryScope: 'private_card');
      final message = BroadcastMessage.fromJson(json);
      expect(message.deliveryScope, equals(DeliveryScope.privateCard));
    });
  });

  group('Tier-gated content', () {
    test('isTierGated returns true when minTierRequired is set', () {
      final json = _createMessageJson();
      json['min_tier_required'] = 'VIP';
      final message = BroadcastMessage.fromJson(json);
      expect(message.isTierGated, isTrue);
      expect(message.minTierRequired, equals('VIP'));
    });

    test('isTierGated returns false when minTierRequired is null', () {
      final json = _createMessageJson();
      final message = BroadcastMessage.fromJson(json);
      expect(message.isTierGated, isFalse);
      expect(message.minTierRequired, isNull);
    });

    test('canViewWithTier returns true when user tier meets requirement', () {
      final json = _createMessageJson();
      json['min_tier_required'] = 'STANDARD';
      final message = BroadcastMessage.fromJson(json);

      expect(message.canViewWithTier('VIP'), isTrue);
      expect(message.canViewWithTier('STANDARD'), isTrue);
      expect(message.canViewWithTier('BASIC'), isFalse);
    });

    test('canViewWithTier returns true when no tier requirement', () {
      final json = _createMessageJson();
      final message = BroadcastMessage.fromJson(json);

      expect(message.canViewWithTier('BASIC'), isTrue);
      expect(message.canViewWithTier('VIP'), isTrue);
      expect(message.canViewWithTier(null), isTrue);
    });

    test('canViewWithTier denies null userTier (fail-closed security)', () {
      final json = _createMessageJson();
      json['min_tier_required'] = 'BASIC';
      final message = BroadcastMessage.fromJson(json);

      // SECURITY: null/unknown tier → denied (fail-closed)
      expect(message.canViewWithTier(null), isFalse);
    });

    test('canViewWithTier denies unknown tier values (fail-closed security)', () {
      // Unknown min_tier_required → deny all
      final json1 = _createMessageJson();
      json1['min_tier_required'] = 'INVALID_TIER';
      final msg1 = BroadcastMessage.fromJson(json1);
      expect(msg1.canViewWithTier('VIP'), isFalse);
      expect(msg1.canViewWithTier('BASIC'), isFalse);

      // Valid required tier, unknown user tier → deny
      final json2 = _createMessageJson();
      json2['min_tier_required'] = 'STANDARD';
      final msg2 = BroadcastMessage.fromJson(json2);
      expect(msg2.canViewWithTier('UNKNOWN'), isFalse);
      expect(msg2.canViewWithTier(''), isFalse);
    });

    test('canViewWithTier VIP requirement', () {
      final json = _createMessageJson();
      json['min_tier_required'] = 'VIP';
      final message = BroadcastMessage.fromJson(json);

      expect(message.canViewWithTier('VIP'), isTrue);
      expect(message.canViewWithTier('STANDARD'), isFalse);
      expect(message.canViewWithTier('BASIC'), isFalse);
    });

    test('minTierRequired round-trips via toJson/fromJson', () {
      final original = BroadcastMessage(
        id: 'msg-1',
        channelId: 'channel-1',
        senderId: 'sender-1',
        senderType: 'artist',
        deliveryScope: DeliveryScope.broadcast,
        createdAt: DateTime.now(),
        minTierRequired: 'STANDARD',
      );

      final json = original.toJson();
      expect(json['min_tier_required'], equals('STANDARD'));

      final restored = BroadcastMessage.fromJson(json);
      expect(restored.minTierRequired, equals('STANDARD'));
      expect(restored.isTierGated, isTrue);
    });

    test('copyWith updates minTierRequired', () {
      final original = BroadcastMessage(
        id: 'msg-1',
        channelId: 'channel-1',
        senderId: 'sender-1',
        senderType: 'artist',
        deliveryScope: DeliveryScope.broadcast,
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(minTierRequired: 'VIP');
      expect(updated.minTierRequired, equals('VIP'));
      expect(updated.isTierGated, isTrue);
      expect(original.minTierRequired, isNull);
    });
  });

  group('BroadcastMessage copyWith', () {
    test('preserves unchanged values', () {
      final original = BroadcastMessage(
        id: 'msg-1',
        channelId: 'channel-1',
        senderId: 'sender-1',
        senderType: 'artist',
        deliveryScope: DeliveryScope.broadcast,
        content: 'Original content',
        createdAt: DateTime.now(),
      );

      final copied = original.copyWith(content: 'New content');

      expect(copied.content, equals('New content'));
      expect(copied.id, equals(original.id));
      expect(copied.channelId, equals(original.channelId));
      expect(copied.senderId, equals(original.senderId));
      expect(copied.senderType, equals(original.senderType));
      expect(copied.deliveryScope, equals(original.deliveryScope));
    });

    test('can update multiple fields', () {
      final original = BroadcastMessage(
        id: 'msg-1',
        channelId: 'channel-1',
        senderId: 'sender-1',
        senderType: 'artist',
        deliveryScope: DeliveryScope.broadcast,
        content: 'Original',
        isHighlighted: false,
        createdAt: DateTime.now(),
      );

      final copied = original.copyWith(
        content: 'Updated',
        isHighlighted: true,
        highlightedAt: DateTime.now(),
      );

      expect(copied.content, equals('Updated'));
      expect(copied.isHighlighted, isTrue);
      expect(copied.highlightedAt, isNotNull);
    });
  });
}

/// Helper to create message JSON for testing
Map<String, dynamic> _createMessageJson({
  String? deliveryScope,
  String? messageType,
  String? senderType,
  String? mediaUrl,
  Map<String, dynamic>? mediaMetadata,
  String? donationId,
  int? donationAmount,
  String? minTierRequired,
}) {
  return {
    'id': 'msg-${DateTime.now().millisecondsSinceEpoch}',
    'channel_id': 'channel-1',
    'sender_id': 'sender-1',
    'sender_type': senderType ?? 'artist',
    'delivery_scope': deliveryScope ?? 'broadcast',
    if (messageType != null) 'message_type': messageType,
    'content': 'Test message',
    if (mediaUrl != null) 'media_url': mediaUrl,
    if (mediaMetadata != null) 'media_metadata': mediaMetadata,
    if (donationId != null) 'donation_id': donationId,
    if (donationAmount != null) 'donation_amount': donationAmount,
    if (minTierRequired != null) 'min_tier_required': minTierRequired,
    'created_at': DateTime.now().toIso8601String(),
  };
}
