import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/channel.dart';

void main() {
  group('Channel', () {
    Map<String, dynamic> _createChannelJson({
      String id = 'channel-1',
      String artistId = 'artist-1',
      String name = '테스트 채널',
      String? description,
      String? avatarUrl,
      bool? isActive,
      int? themeColorIndex,
      int? subscriberCount,
      int? unreadCount,
      String? lastMessagePreview,
      String? lastMessageAt,
    }) {
      return {
        'id': id,
        'artist_id': artistId,
        'name': name,
        if (description != null) 'description': description,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (isActive != null) 'is_active': isActive,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-15T12:00:00.000Z',
        if (themeColorIndex != null) 'theme_color_index': themeColorIndex,
        if (subscriberCount != null) 'subscriber_count': subscriberCount,
        if (unreadCount != null) 'unread_count': unreadCount,
        if (lastMessagePreview != null)
          'last_message_preview': lastMessagePreview,
        if (lastMessageAt != null) 'last_message_at': lastMessageAt,
      };
    }

    group('fromJson / toJson', () {
      test('round-trips core fields correctly', () {
        final json = _createChannelJson(
          description: '설명',
          avatarUrl: 'https://example.com/avatar.jpg',
          isActive: true,
          themeColorIndex: 3,
        );
        final channel = Channel.fromJson(json);
        final restored = Channel.fromJson(channel.toJson());

        expect(restored.id, equals('channel-1'));
        expect(restored.artistId, equals('artist-1'));
        expect(restored.name, equals('테스트 채널'));
        expect(restored.description, equals('설명'));
        expect(restored.avatarUrl, equals('https://example.com/avatar.jpg'));
        expect(restored.isActive, isTrue);
        expect(restored.themeColorIndex, equals(3));
      });

      test('handles null optional fields', () {
        final json = _createChannelJson();
        final channel = Channel.fromJson(json);

        expect(channel.description, isNull);
        expect(channel.avatarUrl, isNull);
        expect(channel.subscriberCount, isNull);
        expect(channel.unreadCount, isNull);
        expect(channel.lastMessagePreview, isNull);
        expect(channel.lastMessageAt, isNull);
      });

      test('defaults isActive to true and themeColorIndex to 0', () {
        final json = _createChannelJson();
        final channel = Channel.fromJson(json);

        expect(channel.isActive, isTrue);
        expect(channel.themeColorIndex, equals(0));
      });
    });

    group('toJson', () {
      test('excludes joined data fields', () {
        final json = _createChannelJson(
          subscriberCount: 100,
          unreadCount: 5,
          lastMessagePreview: 'Hello',
          lastMessageAt: '2024-01-15T12:00:00.000Z',
        );
        final channel = Channel.fromJson(json);
        final output = channel.toJson();

        expect(output.containsKey('subscriber_count'), isFalse);
        expect(output.containsKey('unread_count'), isFalse);
        expect(output.containsKey('last_message_preview'), isFalse);
        expect(output.containsKey('last_message_at'), isFalse);
      });
    });

    group('copyWith', () {
      test('preserves unchanged values', () {
        final channel = Channel.fromJson(
          _createChannelJson(description: '원래 설명'),
        );
        final copy = channel.copyWith(name: '변경된 이름');

        expect(copy.name, equals('변경된 이름'));
        expect(copy.description, equals('원래 설명'));
        expect(copy.id, equals(channel.id));
      });
    });
  });

  group('Subscription', () {
    Map<String, dynamic> _createSubscriptionJson({
      String id = 'sub-1',
      String userId = 'user-1',
      String channelId = 'channel-1',
      String tier = 'STANDARD',
      String? startedAt,
      String? expiresAt,
      bool? isActive,
      bool? autoRenew,
    }) {
      return {
        'id': id,
        'user_id': userId,
        'channel_id': channelId,
        'tier': tier,
        'started_at':
            startedAt ?? DateTime.now().toIso8601String(),
        if (expiresAt != null) 'expires_at': expiresAt,
        if (isActive != null) 'is_active': isActive,
        if (autoRenew != null) 'auto_renew': autoRenew,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-15T00:00:00.000Z',
      };
    }

    group('fromJson / toJson', () {
      test('round-trips all fields correctly', () {
        final json = _createSubscriptionJson(
          tier: 'VIP',
          expiresAt: '2025-01-01T00:00:00.000Z',
          isActive: true,
          autoRenew: false,
        );
        final sub = Subscription.fromJson(json);
        final restored = Subscription.fromJson(sub.toJson());

        expect(restored.id, equals('sub-1'));
        expect(restored.userId, equals('user-1'));
        expect(restored.channelId, equals('channel-1'));
        expect(restored.tier, equals('VIP'));
        expect(restored.expiresAt, isNotNull);
        expect(restored.isActive, isTrue);
        expect(restored.autoRenew, isFalse);
      });

      test('defaults tier to STANDARD when absent', () {
        final json = _createSubscriptionJson();
        json.remove('tier');
        final sub = Subscription.fromJson(json);
        expect(sub.tier, equals('STANDARD'));
      });
    });

    group('daysSubscribed', () {
      test('returns positive days for past start date', () {
        final pastDate =
            DateTime.now().subtract(const Duration(days: 30));
        final sub = Subscription.fromJson(
          _createSubscriptionJson(startedAt: pastDate.toIso8601String()),
        );
        expect(sub.daysSubscribed, greaterThanOrEqualTo(29));
        expect(sub.daysSubscribed, lessThanOrEqualTo(31));
      });
    });

    group('formattedDuration', () {
      test('returns 오늘 시작 for today', () {
        final sub = Subscription.fromJson(
          _createSubscriptionJson(
            startedAt: DateTime.now().toIso8601String(),
          ),
        );
        expect(sub.formattedDuration, equals('오늘 시작'));
      });

      test('returns N일째 for days < 30', () {
        final pastDate =
            DateTime.now().subtract(const Duration(days: 15));
        final sub = Subscription.fromJson(
          _createSubscriptionJson(startedAt: pastDate.toIso8601String()),
        );
        expect(sub.formattedDuration, contains('일째'));
      });

      test('returns N개월째 for 30-364 days', () {
        final pastDate =
            DateTime.now().subtract(const Duration(days: 90));
        final sub = Subscription.fromJson(
          _createSubscriptionJson(startedAt: pastDate.toIso8601String()),
        );
        expect(sub.formattedDuration, contains('개월째'));
      });

      test('returns N년째 for 365+ days', () {
        final pastDate =
            DateTime.now().subtract(const Duration(days: 400));
        final sub = Subscription.fromJson(
          _createSubscriptionJson(startedAt: pastDate.toIso8601String()),
        );
        expect(sub.formattedDuration, contains('년째'));
      });
    });
  });

  group('SubscriptionPricing', () {
    test('formattedPrice returns formatted KRW string', () {
      const pricing = SubscriptionPricing(monthlyPriceKrw: 4900);
      expect(pricing.formattedPrice, equals('4,900원'));
    });

    test('fromJson defaults correctly', () {
      final pricing = SubscriptionPricing.fromJson({});
      expect(pricing.monthlyPriceKrw, equals(4900));
      expect(pricing.currency, equals('KRW'));
      expect(pricing.billingCycle, equals('monthly'));
      expect(pricing.trialDays, equals(0));
      expect(pricing.autoRenewal, isTrue);
    });
  });
}
