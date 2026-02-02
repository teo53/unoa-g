import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/channel.dart';

void main() {
  group('Channel', () {
    final now = DateTime(2024, 1, 15, 12, 0, 0);

    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'id': 'channel-1',
          'artist_id': 'artist-1',
          'name': '아이유',
          'description': '아이유의 프라이빗 메시지',
          'avatar_url': 'https://example.com/avatar.jpg',
          'is_active': true,
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-15T12:00:00.000',
          'subscriber_count': 1000,
          'unread_count': 5,
          'last_message_preview': 'Hello fans!',
          'last_message_at': '2024-01-15T11:00:00.000',
        };

        final channel = Channel.fromJson(json);

        expect(channel.id, equals('channel-1'));
        expect(channel.artistId, equals('artist-1'));
        expect(channel.name, equals('아이유'));
        expect(channel.description, equals('아이유의 프라이빗 메시지'));
        expect(channel.avatarUrl, equals('https://example.com/avatar.jpg'));
        expect(channel.isActive, isTrue);
        expect(channel.subscriberCount, equals(1000));
        expect(channel.unreadCount, equals(5));
        expect(channel.lastMessagePreview, equals('Hello fans!'));
        expect(channel.lastMessageAt, isNotNull);
      });

      test('handles missing optional fields', () {
        final json = {
          'id': 'channel-1',
          'artist_id': 'artist-1',
          'name': 'Test Channel',
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-15T12:00:00.000',
        };

        final channel = Channel.fromJson(json);

        expect(channel.description, isNull);
        expect(channel.avatarUrl, isNull);
        expect(channel.isActive, isTrue); // Default
        expect(channel.subscriberCount, isNull);
        expect(channel.unreadCount, isNull);
        expect(channel.lastMessagePreview, isNull);
        expect(channel.lastMessageAt, isNull);
      });

      test('handles is_active false', () {
        final json = {
          'id': 'channel-1',
          'artist_id': 'artist-1',
          'name': 'Inactive Channel',
          'is_active': false,
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-15T12:00:00.000',
        };

        final channel = Channel.fromJson(json);

        expect(channel.isActive, isFalse);
      });
    });

    group('toJson', () {
      test('produces correct output', () {
        final channel = Channel(
          id: 'channel-1',
          artistId: 'artist-1',
          name: '아이유',
          description: 'Test description',
          avatarUrl: 'https://example.com/avatar.jpg',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        final json = channel.toJson();

        expect(json['id'], equals('channel-1'));
        expect(json['artist_id'], equals('artist-1'));
        expect(json['name'], equals('아이유'));
        expect(json['description'], equals('Test description'));
        expect(json['avatar_url'], equals('https://example.com/avatar.jpg'));
        expect(json['is_active'], isTrue);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = Channel(
          id: 'channel-1',
          artistId: 'artist-1',
          name: 'Original',
          createdAt: now,
          updatedAt: now,
        );

        final copy = original.copyWith(
          name: 'Updated',
          description: 'New description',
        );

        expect(copy.name, equals('Updated'));
        expect(copy.description, equals('New description'));
        expect(copy.id, equals(original.id));
        expect(copy.artistId, equals(original.artistId));
      });
    });

    group('default values', () {
      test('isActive defaults to true', () {
        final channel = Channel(
          id: 'channel-1',
          artistId: 'artist-1',
          name: 'Test',
          createdAt: now,
          updatedAt: now,
        );

        expect(channel.isActive, isTrue);
      });
    });
  });

  group('Subscription', () {
    group('daysSubscribed', () {
      test('returns correct days for past subscription', () {
        final startDate = DateTime.now().subtract(const Duration(days: 100));
        final subscription = Subscription(
          id: 'sub-1',
          userId: 'user-1',
          channelId: 'channel-1',
          tier: 'STANDARD',
          startedAt: startDate,
          createdAt: startDate,
          updatedAt: DateTime.now(),
        );

        // Should be approximately 100 days (may vary slightly due to test timing)
        expect(subscription.daysSubscribed, greaterThanOrEqualTo(99));
        expect(subscription.daysSubscribed, lessThanOrEqualTo(101));
      });

      test('returns 0 for subscription started today', () {
        final now = DateTime.now();
        final subscription = Subscription(
          id: 'sub-1',
          userId: 'user-1',
          channelId: 'channel-1',
          tier: 'STANDARD',
          startedAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.daysSubscribed, equals(0));
      });
    });

    group('formattedDuration', () {
      test('returns "오늘 시작" for day 0', () {
        final now = DateTime.now();
        final subscription = Subscription(
          id: 'sub-1',
          userId: 'user-1',
          channelId: 'channel-1',
          tier: 'STANDARD',
          startedAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.formattedDuration, equals('오늘 시작'));
      });

      test('returns "1일째" for day 1', () {
        final startDate = DateTime.now().subtract(const Duration(days: 1));
        final subscription = Subscription(
          id: 'sub-1',
          userId: 'user-1',
          channelId: 'channel-1',
          tier: 'STANDARD',
          startedAt: startDate,
          createdAt: startDate,
          updatedAt: DateTime.now(),
        );

        expect(subscription.formattedDuration, equals('1일째'));
      });

      test('returns "N일째" for days 2-29', () {
        final startDate = DateTime.now().subtract(const Duration(days: 15));
        final subscription = Subscription(
          id: 'sub-1',
          userId: 'user-1',
          channelId: 'channel-1',
          tier: 'STANDARD',
          startedAt: startDate,
          createdAt: startDate,
          updatedAt: DateTime.now(),
        );

        expect(subscription.formattedDuration, equals('15일째'));
      });

      test('returns "N개월째" for 30+ days', () {
        final startDate = DateTime.now().subtract(const Duration(days: 60));
        final subscription = Subscription(
          id: 'sub-1',
          userId: 'user-1',
          channelId: 'channel-1',
          tier: 'STANDARD',
          startedAt: startDate,
          createdAt: startDate,
          updatedAt: DateTime.now(),
        );

        expect(subscription.formattedDuration, equals('2개월째'));
      });

      test('returns "N년째" for 365+ days', () {
        final startDate = DateTime.now().subtract(const Duration(days: 400));
        final subscription = Subscription(
          id: 'sub-1',
          userId: 'user-1',
          channelId: 'channel-1',
          tier: 'STANDARD',
          startedAt: startDate,
          createdAt: startDate,
          updatedAt: DateTime.now(),
        );

        expect(subscription.formattedDuration, equals('1년째'));
      });
    });

    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'id': 'sub-1',
          'user_id': 'user-1',
          'channel_id': 'channel-1',
          'tier': 'VIP',
          'started_at': '2024-01-01T00:00:00.000',
          'expires_at': '2024-02-01T00:00:00.000',
          'is_active': true,
          'auto_renew': false,
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-15T00:00:00.000',
        };

        final subscription = Subscription.fromJson(json);

        expect(subscription.id, equals('sub-1'));
        expect(subscription.userId, equals('user-1'));
        expect(subscription.channelId, equals('channel-1'));
        expect(subscription.tier, equals('VIP'));
        expect(subscription.expiresAt, isNotNull);
        expect(subscription.isActive, isTrue);
        expect(subscription.autoRenew, isFalse);
      });

      test('handles missing optional fields', () {
        final json = {
          'id': 'sub-1',
          'user_id': 'user-1',
          'channel_id': 'channel-1',
          'started_at': '2024-01-01T00:00:00.000',
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-01T00:00:00.000',
        };

        final subscription = Subscription.fromJson(json);

        expect(subscription.tier, equals('STANDARD')); // Default
        expect(subscription.expiresAt, isNull);
        expect(subscription.isActive, isTrue); // Default
        expect(subscription.autoRenew, isTrue); // Default
      });
    });

    group('toJson', () {
      test('produces correct output', () {
        final now = DateTime(2024, 1, 15);
        final subscription = Subscription(
          id: 'sub-1',
          userId: 'user-1',
          channelId: 'channel-1',
          tier: 'VIP',
          startedAt: now,
          isActive: true,
          autoRenew: true,
          createdAt: now,
          updatedAt: now,
        );

        final json = subscription.toJson();

        expect(json['id'], equals('sub-1'));
        expect(json['user_id'], equals('user-1'));
        expect(json['channel_id'], equals('channel-1'));
        expect(json['tier'], equals('VIP'));
        expect(json['is_active'], isTrue);
        expect(json['auto_renew'], isTrue);
      });
    });

    group('default values', () {
      test('isActive defaults to true', () {
        final now = DateTime.now();
        final subscription = Subscription(
          id: 'sub-1',
          userId: 'user-1',
          channelId: 'channel-1',
          tier: 'STANDARD',
          startedAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.isActive, isTrue);
      });

      test('autoRenew defaults to true', () {
        final now = DateTime.now();
        final subscription = Subscription(
          id: 'sub-1',
          userId: 'user-1',
          channelId: 'channel-1',
          tier: 'STANDARD',
          startedAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.autoRenew, isTrue);
      });
    });
  });

  group('SubscriptionPricing', () {
    group('formattedPrice', () {
      test('formats default price correctly', () {
        expect(
          SubscriptionPricing.defaultPricing.formattedPrice,
          equals('4,900원'),
        );
      });

      test('formats small price without comma', () {
        const pricing = SubscriptionPricing(monthlyPriceKrw: 900);
        expect(pricing.formattedPrice, equals('900원'));
      });

      test('formats large price with multiple commas', () {
        const pricing = SubscriptionPricing(monthlyPriceKrw: 1000000);
        expect(pricing.formattedPrice, equals('1,000,000원'));
      });
    });

    group('default values', () {
      test('currency defaults to KRW', () {
        const pricing = SubscriptionPricing(monthlyPriceKrw: 4900);
        expect(pricing.currency, equals('KRW'));
      });

      test('billingCycle defaults to monthly', () {
        const pricing = SubscriptionPricing(monthlyPriceKrw: 4900);
        expect(pricing.billingCycle, equals('monthly'));
      });

      test('trialDays defaults to 0', () {
        const pricing = SubscriptionPricing(monthlyPriceKrw: 4900);
        expect(pricing.trialDays, equals(0));
      });

      test('autoRenewal defaults to true', () {
        const pricing = SubscriptionPricing(monthlyPriceKrw: 4900);
        expect(pricing.autoRenewal, isTrue);
      });
    });

    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'monthly_price_krw': 9900,
          'currency': 'USD',
          'billing_cycle': 'yearly',
          'trial_days': 7,
          'auto_renewal': false,
        };

        final pricing = SubscriptionPricing.fromJson(json);

        expect(pricing.monthlyPriceKrw, equals(9900));
        expect(pricing.currency, equals('USD'));
        expect(pricing.billingCycle, equals('yearly'));
        expect(pricing.trialDays, equals(7));
        expect(pricing.autoRenewal, isFalse);
      });

      test('uses defaults for missing fields', () {
        final json = <String, dynamic>{};
        final pricing = SubscriptionPricing.fromJson(json);

        expect(pricing.monthlyPriceKrw, equals(4900));
        expect(pricing.currency, equals('KRW'));
        expect(pricing.billingCycle, equals('monthly'));
        expect(pricing.trialDays, equals(0));
        expect(pricing.autoRenewal, isTrue);
      });
    });

    group('defaultPricing', () {
      test('has correct default values', () {
        const pricing = SubscriptionPricing.defaultPricing;

        expect(pricing.monthlyPriceKrw, equals(4900));
        expect(pricing.currency, equals('KRW'));
        expect(pricing.billingCycle, equals('monthly'));
        expect(pricing.trialDays, equals(0));
        expect(pricing.autoRenewal, isTrue);
      });
    });
  });
}
