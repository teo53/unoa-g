import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/sticker.dart';

void main() {
  group('Sticker fromJson / toJson', () {
    test('round-trips correctly', () {
      final now = DateTime.now();
      final original = Sticker(
        id: 'sticker-123',
        stickerSetId: 'set-456',
        name: '하트 스티커',
        imageUrl: 'https://example.com/sticker.png',
        animationUrl: 'https://example.com/sticker.gif',
        sortOrder: 3,
        createdAt: now,
      );

      final json = original.toJson();
      final restored = Sticker.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.stickerSetId, equals(original.stickerSetId));
      expect(restored.name, equals(original.name));
      expect(restored.imageUrl, equals(original.imageUrl));
      expect(restored.animationUrl, equals(original.animationUrl));
      expect(restored.sortOrder, equals(original.sortOrder));
    });

    test('isAnimated returns true when animationUrl is set', () {
      final sticker = Sticker(
        id: 'sticker-1',
        stickerSetId: 'set-1',
        name: 'Animated',
        imageUrl: 'https://example.com/sticker.png',
        animationUrl: 'https://example.com/sticker.gif',
        createdAt: DateTime.now(),
      );
      expect(sticker.isAnimated, isTrue);
    });

    test('isAnimated returns false when animationUrl is null', () {
      final sticker = Sticker(
        id: 'sticker-1',
        stickerSetId: 'set-1',
        name: 'Static',
        imageUrl: 'https://example.com/sticker.png',
        createdAt: DateTime.now(),
      );
      expect(sticker.isAnimated, isFalse);
    });
  });

  group('StickerSet fromJson / toJson', () {
    test('round-trips correctly', () {
      final now = DateTime.now();
      final original = StickerSet(
        id: 'set-123',
        channelId: 'channel-456',
        creatorId: 'creator-789',
        name: '기본 스티커 팩',
        description: '귀여운 스티커 모음',
        thumbnailUrl: 'https://example.com/thumb.png',
        priceDt: 200,
        isActive: true,
        sortOrder: 1,
        createdAt: now,
        isPurchased: true,
        stickers: [
          Sticker(
            id: 'sticker-1',
            stickerSetId: 'set-123',
            name: '하트',
            imageUrl: 'https://example.com/heart.png',
            createdAt: now,
          ),
        ],
      );

      final json = original.toJson();
      final restored = StickerSet.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.channelId, equals(original.channelId));
      expect(restored.creatorId, equals(original.creatorId));
      expect(restored.name, equals(original.name));
      expect(restored.description, equals(original.description));
      expect(restored.priceDt, equals(original.priceDt));
      expect(restored.isActive, equals(original.isActive));
      expect(restored.isPurchased, equals(original.isPurchased));
      expect(restored.stickers.length, equals(1));
      expect(restored.stickers.first.name, equals('하트'));
    });

    test('isFree returns true when price is 0', () {
      final set = StickerSet(
        id: 'set-1',
        channelId: 'channel-1',
        creatorId: 'creator-1',
        name: 'Free Pack',
        priceDt: 0,
        createdAt: DateTime.now(),
      );
      expect(set.isFree, isTrue);
    });

    test('isFree returns false when price is > 0', () {
      final set = StickerSet(
        id: 'set-1',
        channelId: 'channel-1',
        creatorId: 'creator-1',
        name: 'Paid Pack',
        priceDt: 100,
        createdAt: DateTime.now(),
      );
      expect(set.isFree, isFalse);
    });

    test('handles null optional fields', () {
      final json = {
        'id': 'set-1',
        'channel_id': 'channel-1',
        'creator_id': 'creator-1',
        'name': 'Test Pack',
        'created_at': DateTime.now().toIso8601String(),
      };

      final set = StickerSet.fromJson(json);

      expect(set.description, isNull);
      expect(set.thumbnailUrl, isNull);
      expect(set.priceDt, equals(100)); // default
      expect(set.isActive, isTrue); // default
      expect(set.isPurchased, isFalse); // default
      expect(set.stickers, isEmpty);
    });
  });

  group('StickerSet copyWith', () {
    test('updates specified fields', () {
      final original = StickerSet(
        id: 'set-1',
        channelId: 'channel-1',
        creatorId: 'creator-1',
        name: 'Original',
        priceDt: 100,
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(
        name: 'Updated',
        priceDt: 200,
        isPurchased: true,
      );

      expect(updated.name, equals('Updated'));
      expect(updated.priceDt, equals(200));
      expect(updated.isPurchased, isTrue);
      expect(updated.id, equals(original.id));
      expect(updated.channelId, equals(original.channelId));
    });
  });

  group('StickerPurchase fromJson / toJson', () {
    test('round-trips correctly', () {
      final now = DateTime.now();
      final original = StickerPurchase(
        id: 'purchase-1',
        buyerId: 'buyer-1',
        stickerSetId: 'set-1',
        priceDt: 300,
        purchasedAt: now,
      );

      final json = original.toJson();
      final restored = StickerPurchase.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.buyerId, equals(original.buyerId));
      expect(restored.stickerSetId, equals(original.stickerSetId));
      expect(restored.priceDt, equals(original.priceDt));
    });
  });
}
