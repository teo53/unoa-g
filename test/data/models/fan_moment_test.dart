import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/fan_moment.dart';

void main() {
  group('MomentSourceType', () {
    test('parses private_card correctly', () {
      final json = _createMomentJson(sourceType: 'private_card');
      final moment = FanMoment.fromJson(json);
      expect(moment.sourceType, equals(MomentSourceType.privateCard));
    });

    test('parses highlight correctly', () {
      final json = _createMomentJson(sourceType: 'highlight');
      final moment = FanMoment.fromJson(json);
      expect(moment.sourceType, equals(MomentSourceType.highlight));
    });

    test('parses media_message correctly', () {
      final json = _createMomentJson(sourceType: 'media_message');
      final moment = FanMoment.fromJson(json);
      expect(moment.sourceType, equals(MomentSourceType.mediaMessage));
    });

    test('parses donation_reply correctly', () {
      final json = _createMomentJson(sourceType: 'donation_reply');
      final moment = FanMoment.fromJson(json);
      expect(moment.sourceType, equals(MomentSourceType.donationReply));
    });

    test('parses welcome correctly', () {
      final json = _createMomentJson(sourceType: 'welcome');
      final moment = FanMoment.fromJson(json);
      expect(moment.sourceType, equals(MomentSourceType.welcome));
    });

    test('parses manual correctly', () {
      final json = _createMomentJson(sourceType: 'manual');
      final moment = FanMoment.fromJson(json);
      expect(moment.sourceType, equals(MomentSourceType.manual));
    });

    test('defaults to manual for unknown value', () {
      final json = _createMomentJson(sourceType: 'unknown');
      final moment = FanMoment.fromJson(json);
      expect(moment.sourceType, equals(MomentSourceType.manual));
    });
  });

  group('FanMoment computed properties', () {
    test('hasMedia returns true when mediaUrl is set', () {
      final json = _createMomentJson(mediaUrl: 'https://example.com/img.jpg');
      final moment = FanMoment.fromJson(json);
      expect(moment.hasMedia, isTrue);
    });

    test('hasMedia returns false when mediaUrl is null', () {
      final json = _createMomentJson();
      final moment = FanMoment.fromJson(json);
      expect(moment.hasMedia, isFalse);
    });

    test('isImage returns true for image media type', () {
      final json = _createMomentJson(
        mediaUrl: 'https://example.com/img.jpg',
        mediaType: 'image',
      );
      final moment = FanMoment.fromJson(json);
      expect(moment.isImage, isTrue);
      expect(moment.isVideo, isFalse);
    });

    test('isVideo returns true for video media type', () {
      final json = _createMomentJson(
        mediaUrl: 'https://example.com/video.mp4',
        mediaType: 'video',
      );
      final moment = FanMoment.fromJson(json);
      expect(moment.isVideo, isTrue);
      expect(moment.isImage, isFalse);
    });

    test('sourceLabel returns correct Korean label', () {
      expect(
        FanMoment.fromJson(_createMomentJson(sourceType: 'private_card'))
            .sourceLabel,
        equals('프라이빗 카드'),
      );
      expect(
        FanMoment.fromJson(_createMomentJson(sourceType: 'highlight'))
            .sourceLabel,
        equals('하이라이트'),
      );
      expect(
        FanMoment.fromJson(_createMomentJson(sourceType: 'manual')).sourceLabel,
        equals('저장한 메시지'),
      );
    });
  });

  group('FanMoment fromJson / toJson', () {
    test('round-trips all fields correctly', () {
      final now = DateTime.now();
      final original = FanMoment(
        id: 'moment-123',
        fanId: 'fan-456',
        channelId: 'channel-789',
        sourceType: MomentSourceType.privateCard,
        sourceMessageId: 'msg-001',
        sourceCardId: 'card-001',
        title: '프라이빗 카드',
        content: '특별한 메시지입니다',
        mediaUrl: 'https://example.com/image.jpg',
        mediaType: 'image',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        artistName: '하늘달',
        artistAvatarUrl: 'https://example.com/avatar.jpg',
        isFavorite: true,
        metadata: {'key': 'value'},
        createdAt: now,
        collectedAt: now,
      );

      final json = original.toJson();
      final restored = FanMoment.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.fanId, equals(original.fanId));
      expect(restored.channelId, equals(original.channelId));
      expect(restored.sourceType, equals(original.sourceType));
      expect(restored.sourceMessageId, equals(original.sourceMessageId));
      expect(restored.sourceCardId, equals(original.sourceCardId));
      expect(restored.title, equals(original.title));
      expect(restored.content, equals(original.content));
      expect(restored.mediaUrl, equals(original.mediaUrl));
      expect(restored.mediaType, equals(original.mediaType));
      expect(restored.thumbnailUrl, equals(original.thumbnailUrl));
      expect(restored.artistName, equals(original.artistName));
      expect(restored.artistAvatarUrl, equals(original.artistAvatarUrl));
      expect(restored.isFavorite, equals(original.isFavorite));
    });

    test('handles null optional fields', () {
      final json = {
        'id': 'moment-1',
        'fan_id': 'fan-1',
        'channel_id': 'channel-1',
        'source_type': 'manual',
        'created_at': DateTime.now().toIso8601String(),
      };

      final moment = FanMoment.fromJson(json);

      expect(moment.sourceMessageId, isNull);
      expect(moment.sourceCardId, isNull);
      expect(moment.title, isNull);
      expect(moment.content, isNull);
      expect(moment.mediaUrl, isNull);
      expect(moment.mediaType, isNull);
      expect(moment.thumbnailUrl, isNull);
      expect(moment.artistName, isNull);
      expect(moment.artistAvatarUrl, isNull);
      expect(moment.isFavorite, isFalse);
      expect(moment.metadata, isNull);
    });
  });

  group('FanMoment copyWith', () {
    test('preserves unchanged values', () {
      final original = FanMoment(
        id: 'moment-1',
        fanId: 'fan-1',
        channelId: 'channel-1',
        sourceType: MomentSourceType.highlight,
        content: 'Original',
        isFavorite: false,
        createdAt: DateTime.now(),
        collectedAt: DateTime.now(),
      );

      final copied = original.copyWith(isFavorite: true);

      expect(copied.isFavorite, isTrue);
      expect(copied.id, equals(original.id));
      expect(copied.content, equals(original.content));
      expect(copied.sourceType, equals(original.sourceType));
    });

    test('can update content and title', () {
      final original = FanMoment(
        id: 'moment-1',
        fanId: 'fan-1',
        channelId: 'channel-1',
        sourceType: MomentSourceType.manual,
        content: 'Old content',
        title: 'Old title',
        createdAt: DateTime.now(),
        collectedAt: DateTime.now(),
      );

      final copied = original.copyWith(
        content: 'New content',
        title: 'New title',
      );

      expect(copied.content, equals('New content'));
      expect(copied.title, equals('New title'));
      expect(copied.id, equals(original.id));
    });
  });

  group('FanMoment equality', () {
    test('equal by id', () {
      final a = FanMoment(
        id: 'same-id',
        fanId: 'fan-1',
        channelId: 'channel-1',
        sourceType: MomentSourceType.manual,
        createdAt: DateTime.now(),
        collectedAt: DateTime.now(),
      );
      final b = FanMoment(
        id: 'same-id',
        fanId: 'fan-2',
        channelId: 'channel-2',
        sourceType: MomentSourceType.highlight,
        createdAt: DateTime.now(),
        collectedAt: DateTime.now(),
      );
      expect(a, equals(b));
    });

    test('not equal by different id', () {
      final a = FanMoment(
        id: 'id-1',
        fanId: 'fan-1',
        channelId: 'channel-1',
        sourceType: MomentSourceType.manual,
        createdAt: DateTime.now(),
        collectedAt: DateTime.now(),
      );
      final b = FanMoment(
        id: 'id-2',
        fanId: 'fan-1',
        channelId: 'channel-1',
        sourceType: MomentSourceType.manual,
        createdAt: DateTime.now(),
        collectedAt: DateTime.now(),
      );
      expect(a, isNot(equals(b)));
    });
  });
}

/// Helper to create moment JSON for testing
Map<String, dynamic> _createMomentJson({
  String? sourceType,
  String? mediaUrl,
  String? mediaType,
}) {
  return {
    'id': 'moment-${DateTime.now().millisecondsSinceEpoch}',
    'fan_id': 'fan-1',
    'channel_id': 'channel-1',
    'source_type': sourceType ?? 'manual',
    'created_at': DateTime.now().toIso8601String(),
    'collected_at': DateTime.now().toIso8601String(),
    if (mediaUrl != null) 'media_url': mediaUrl,
    if (mediaType != null) 'media_type': mediaType,
  };
}
