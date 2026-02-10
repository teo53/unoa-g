import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/private_card.dart';

void main() {
  group('PrivateCardTemplate', () {
    group('fromJson / toJson', () {
      test('round-trips all fields correctly', () {
        final json = {
          'id': 'template-1',
          'name': '핑크 하트',
          'category': 'hearts',
          'thumbnail_url': 'https://example.com/thumb.jpg',
          'full_image_url': 'https://example.com/full.jpg',
          'is_premium': true,
          'sort_order': 5,
        };
        final template = PrivateCardTemplate.fromJson(json);
        final output = template.toJson();

        expect(template.id, equals('template-1'));
        expect(template.name, equals('핑크 하트'));
        expect(template.category, equals('hearts'));
        expect(template.isPremium, isTrue);
        expect(template.sortOrder, equals(5));
        expect(output['id'], equals('template-1'));
      });

      test('defaults isPremium to false and category to general', () {
        final json = {
          'id': 't-1',
          'name': 'Basic',
          'thumbnail_url': 'url',
          'full_image_url': 'url',
        };
        final template = PrivateCardTemplate.fromJson(json);
        expect(template.isPremium, isFalse);
        expect(template.category, equals('general'));
        expect(template.sortOrder, equals(0));
      });
    });
  });

  group('PrivateCard', () {
    Map<String, dynamic> createCardJson({
      String id = 'card-1',
      String channelId = 'ch-1',
      String artistId = 'artist-1',
      String? templateContent,
      String cardTemplateId = 'template-1',
      String? status,
      List<String>? mediaUrls,
      List<String>? recipientIds,
    }) {
      return {
        'id': id,
        'channel_id': channelId,
        'artist_id': artistId,
        if (templateContent != null) 'template_content': templateContent,
        'card_template_id': cardTemplateId,
        if (status != null) 'status': status,
        if (mediaUrls != null) 'media_urls': mediaUrls,
        if (recipientIds != null) 'recipient_ids': recipientIds,
        'created_at': '2024-01-15T10:00:00.000Z',
      };
    }

    group('fromJson / toJson', () {
      test('round-trips all fields correctly', () {
        final json = createCardJson(
          templateContent: '안녕 {fanName}님!',
          status: 'sent',
          mediaUrls: ['url1', 'url2'],
          recipientIds: ['fan-1', 'fan-2'],
        );
        final card = PrivateCard.fromJson(json);
        final restored = PrivateCard.fromJson(card.toJson());

        expect(restored.id, equals('card-1'));
        expect(restored.channelId, equals('ch-1'));
        expect(restored.templateContent, equals('안녕 {fanName}님!'));
        expect(restored.status, equals(PrivateCardStatus.sent));
        expect(restored.mediaUrls, equals(['url1', 'url2']));
        expect(restored.recipientIds, equals(['fan-1', 'fan-2']));
      });

      test('defaults status to draft for unknown value', () {
        final json = createCardJson(status: 'unknown_status');
        final card = PrivateCard.fromJson(json);
        expect(card.status, equals(PrivateCardStatus.draft));
      });

      test('handles empty mediaUrls and recipientIds', () {
        final json = createCardJson();
        final card = PrivateCard.fromJson(json);
        expect(card.mediaUrls, isEmpty);
        expect(card.recipientIds, isEmpty);
      });
    });

    group('getPersonalizedContent', () {
      test('replaces {fanName} placeholder', () {
        final card = PrivateCard.fromJson(
          createCardJson(templateContent: '안녕 {fanName}님!'),
        );
        final result = card.getPersonalizedContent(fanName: '하늘덕후');
        expect(result, equals('안녕 하늘덕후님!'));
      });

      test('replaces {subscribeDays} placeholder', () {
        final card = PrivateCard.fromJson(
          createCardJson(
            templateContent: '구독 {subscribeDays}일 감사합니다!',
          ),
        );
        final result = card.getPersonalizedContent(
          fanName: 'Fan',
          subscribeDays: 100,
        );
        expect(result, equals('구독 100일 감사합니다!'));
      });

      test('replaces {tier} placeholder', () {
        final card = PrivateCard.fromJson(
          createCardJson(templateContent: '{tier} 구독자님 감사합니다!'),
        );
        final result = card.getPersonalizedContent(
          fanName: 'Fan',
          tier: 'VIP',
        );
        expect(result, equals('VIP 구독자님 감사합니다!'));
      });

      test('returns empty string when templateContent is null', () {
        final card = PrivateCard.fromJson(createCardJson());
        final result = card.getPersonalizedContent(fanName: 'Fan');
        expect(result, equals(''));
      });
    });

    group('copyWith', () {
      test('preserves unchanged values', () {
        final card = PrivateCard.fromJson(
          createCardJson(
            templateContent: '원래 내용',
            status: 'draft',
          ),
        );
        final copy = card.copyWith(status: PrivateCardStatus.sent);

        expect(copy.status, equals(PrivateCardStatus.sent));
        expect(copy.templateContent, equals('원래 내용'));
        expect(copy.id, equals(card.id));
      });
    });
  });
}
