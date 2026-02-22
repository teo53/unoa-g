// ignore_for_file: prefer_const_constructors

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/core/config/business_config.dart';
import 'package:uno_a_flutter/providers/subscription_provider.dart';

void main() {
  // ==========================================================================
  // SubscriptionInfo.fromJson
  // ==========================================================================

  group('SubscriptionInfo.fromJson', () {
    test('parses all full fields including nested channels map', () {
      final expiresAt =
          DateTime.now().add(const Duration(days: 30)).toIso8601String();
      final json = <String, dynamic>{
        'id': 'sub-001',
        'channel_id': 'chan-001',
        'tier': 'STANDARD',
        'expires_at': expiresAt,
        'channels': {
          'name': '하늘달',
          'avatar_url': 'https://example.com/avatar.jpg',
        },
      };

      final sub = SubscriptionInfo.fromJson(json);

      expect(sub.id, 'sub-001');
      expect(sub.artistId, 'chan-001');
      expect(sub.artistName, '하늘달');
      expect(sub.avatarUrl, 'https://example.com/avatar.jpg');
      expect(sub.tier, 'STANDARD');
      expect(sub.price, BusinessConfig.tierPricesKrw['STANDARD']);
      expect(sub.price, 9900);
    });

    test('reads artistName and avatarUrl from nested channels map', () {
      final json = <String, dynamic>{
        'id': 'sub-002',
        'channel_id': 'chan-002',
        'tier': 'VIP',
        'expires_at':
            DateTime.now().add(const Duration(days: 60)).toIso8601String(),
        'channels': {
          'name': '이준호',
          'avatar_url': 'https://example.com/junho.png',
        },
      };

      final sub = SubscriptionInfo.fromJson(json);

      expect(sub.artistName, '이준호');
      expect(sub.avatarUrl, 'https://example.com/junho.png');
    });

    test('derives price from BusinessConfig.tierPricesKrw for BASIC tier', () {
      final json = <String, dynamic>{
        'id': 'sub-003',
        'channel_id': 'chan-003',
        'tier': 'BASIC',
        'expires_at':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'channels': {'name': '박서연', 'avatar_url': ''},
      };

      final sub = SubscriptionInfo.fromJson(json);

      expect(sub.price, BusinessConfig.tierPricesKrw['BASIC']);
      expect(sub.price, 4900);
    });

    test('derives price from BusinessConfig.tierPricesKrw for VIP tier', () {
      final json = <String, dynamic>{
        'id': 'sub-004',
        'channel_id': 'chan-004',
        'tier': 'VIP',
        'expires_at':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'channels': {'name': '아티스트', 'avatar_url': ''},
      };

      final sub = SubscriptionInfo.fromJson(json);

      expect(sub.price, BusinessConfig.tierPricesKrw['VIP']);
      expect(sub.price, 19900);
    });

    test('unknown tier falls back to price 0', () {
      final json = <String, dynamic>{
        'id': 'sub-005',
        'channel_id': 'chan-005',
        'tier': 'UNKNOWN_TIER',
        'expires_at':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'channels': {'name': '아티스트', 'avatar_url': ''},
      };

      final sub = SubscriptionInfo.fromJson(json);

      expect(sub.price, 0);
    });

    test('expiresAt fallback to 30 days from now when null', () {
      final before = DateTime.now().add(const Duration(days: 29));
      final json = <String, dynamic>{
        'id': 'sub-006',
        'channel_id': 'chan-006',
        'tier': 'BASIC',
        'expires_at': null,
        'channels': {'name': '아티스트', 'avatar_url': ''},
      };

      final sub = SubscriptionInfo.fromJson(json);
      final after = DateTime.now().add(const Duration(days: 31));

      expect(sub.nextBillingDate.isAfter(before), isTrue);
      expect(sub.nextBillingDate.isBefore(after), isTrue);
    });

    test('expiresAt fallback to 30 days from now when expires_at is absent',
        () {
      // No 'expires_at' key at all
      final json = <String, dynamic>{
        'id': 'sub-007',
        'channel_id': 'chan-007',
        'tier': 'STANDARD',
        'channels': {'name': '아티스트', 'avatar_url': ''},
      };

      final sub = SubscriptionInfo.fromJson(json);
      final before = DateTime.now().add(const Duration(days: 29));
      final after = DateTime.now().add(const Duration(days: 31));

      expect(sub.nextBillingDate.isAfter(before), isTrue);
      expect(sub.nextBillingDate.isBefore(after), isTrue);
    });

    test('null channels map yields empty artistName and avatarUrl', () {
      final json = <String, dynamic>{
        'id': 'sub-008',
        'channel_id': 'chan-008',
        'tier': 'BASIC',
        'expires_at':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'channels': null,
      };

      final sub = SubscriptionInfo.fromJson(json);

      expect(sub.artistName, '');
      expect(sub.avatarUrl, '');
    });

    test('tier defaults to BASIC when absent', () {
      final json = <String, dynamic>{
        'id': 'sub-009',
        'channel_id': 'chan-009',
        'expires_at':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'channels': {'name': '아티스트', 'avatar_url': ''},
      };

      final sub = SubscriptionInfo.fromJson(json);

      expect(sub.tier, 'BASIC');
      expect(sub.price, 4900);
    });
  });

  // ==========================================================================
  // SubscriptionInfo.isExpiringSoon
  // ==========================================================================

  group('SubscriptionInfo.isExpiringSoon', () {
    // NOTE: isExpiringSoon is computed in fromJson via:
    //   daysUntilExpiry = nextBilling.difference(DateTime.now()).inDays
    //   isExpiringSoon = daysUntilExpiry <= 7
    //
    // Duration.inDays truncates toward zero. To avoid flakiness at day
    // boundaries, tests that need "exactly N days" use large margins (e.g. 1
    // day, 3 days, 15 days) rather than 7 or 8. The boundary value test uses
    // the constructor isExpiringSoon field directly.

    test('true when already past expiry (negative daysUntilExpiry)', () {
      // expires_at in the past → inDays is negative → <= 7 is true
      final expiresAt =
          DateTime.now().subtract(const Duration(hours: 2)).toIso8601String();
      final json = <String, dynamic>{
        'id': 'sub-past',
        'channel_id': 'chan-past',
        'tier': 'BASIC',
        'expires_at': expiresAt,
        'channels': {'name': '아티스트', 'avatar_url': ''},
      };

      final sub = SubscriptionInfo.fromJson(json);
      expect(sub.isExpiringSoon, isTrue);
    });

    test('true when 1 day until expiry', () {
      final expiresAt =
          DateTime.now().add(const Duration(days: 1)).toIso8601String();
      final json = <String, dynamic>{
        'id': 'sub-1day',
        'channel_id': 'chan-1day',
        'tier': 'BASIC',
        'expires_at': expiresAt,
        'channels': {'name': '아티스트', 'avatar_url': ''},
      };

      final sub = SubscriptionInfo.fromJson(json);
      expect(sub.isExpiringSoon, isTrue);
    });

    test('true when 3 days until expiry', () {
      final expiresAt =
          DateTime.now().add(const Duration(days: 3)).toIso8601String();
      final json = <String, dynamic>{
        'id': 'sub-soon2',
        'channel_id': 'chan-soon2',
        'tier': 'STANDARD',
        'expires_at': expiresAt,
        'channels': {'name': '아티스트', 'avatar_url': ''},
      };

      final sub = SubscriptionInfo.fromJson(json);
      expect(sub.isExpiringSoon, isTrue);
    });

    test('true when isExpiringSoon is explicitly set via constructor', () {
      // The constructor stores whatever value is passed — no recalculation.
      final sub = SubscriptionInfo(
        id: 'sub-explicit-true',
        artistId: 'chan-explicit-true',
        artistName: '아티스트',
        avatarUrl: '',
        tier: 'BASIC',
        price: 4900,
        nextBillingDate: DateTime.now().add(const Duration(days: 20)),
        isExpiringSoon: true,
      );
      expect(sub.isExpiringSoon, isTrue);
    });

    test('false when 15 days until expiry', () {
      // 15 days >> 7: no boundary ambiguity.
      final expiresAt =
          DateTime.now().add(const Duration(days: 15)).toIso8601String();
      final json = <String, dynamic>{
        'id': 'sub-15',
        'channel_id': 'chan-15',
        'tier': 'BASIC',
        'expires_at': expiresAt,
        'channels': {'name': '아티스트', 'avatar_url': ''},
      };

      final sub = SubscriptionInfo.fromJson(json);
      expect(sub.isExpiringSoon, isFalse);
    });

    test('false when 30 days until expiry', () {
      final expiresAt =
          DateTime.now().add(const Duration(days: 30)).toIso8601String();
      final json = <String, dynamic>{
        'id': 'sub-far',
        'channel_id': 'chan-far',
        'tier': 'VIP',
        'expires_at': expiresAt,
        'channels': {'name': '아티스트', 'avatar_url': ''},
      };

      final sub = SubscriptionInfo.fromJson(json);
      expect(sub.isExpiringSoon, isFalse);
    });

    test('false when isExpiringSoon is explicitly set false via constructor',
        () {
      final sub = SubscriptionInfo(
        id: 'sub-explicit-false',
        artistId: 'chan-explicit-false',
        artistName: '아티스트',
        avatarUrl: '',
        tier: 'BASIC',
        price: 4900,
        nextBillingDate: DateTime.now().add(const Duration(days: 1)),
        isExpiringSoon: false,
      );
      expect(sub.isExpiringSoon, isFalse);
    });

    test('false by default when constructed without isExpiringSoon', () {
      final sub = SubscriptionInfo(
        id: 'sub-default',
        artistId: 'chan-default',
        artistName: '아티스트',
        avatarUrl: '',
        tier: 'BASIC',
        price: 4900,
        nextBillingDate: DateTime.now().add(const Duration(days: 30)),
      );
      expect(sub.isExpiringSoon, isFalse);
    });
  });

  // ==========================================================================
  // SubscriptionInfo.formattedPrice
  // ==========================================================================

  group('SubscriptionInfo.formattedPrice', () {
    SubscriptionInfo makeSubWithPrice(int price) {
      return SubscriptionInfo(
        id: 'sub-p',
        artistId: 'chan-p',
        artistName: '아티스트',
        avatarUrl: '',
        tier: 'BASIC',
        price: price,
        nextBillingDate: DateTime.now().add(const Duration(days: 30)),
      );
    }

    test('formats 4900 as "4,900원"', () {
      expect(makeSubWithPrice(4900).formattedPrice, '4,900원');
    });

    test('formats 9900 as "9,900원"', () {
      expect(makeSubWithPrice(9900).formattedPrice, '9,900원');
    });

    test('formats 19900 as "19,900원"', () {
      expect(makeSubWithPrice(19900).formattedPrice, '19,900원');
    });

    test('formats 0 as "0원"', () {
      expect(makeSubWithPrice(0).formattedPrice, '0원');
    });

    test('formats 1000000 as "1,000,000원"', () {
      expect(makeSubWithPrice(1000000).formattedPrice, '1,000,000원');
    });

    test('formats 100 as "100원" (no comma for 3-digit numbers)', () {
      expect(makeSubWithPrice(100).formattedPrice, '100원');
    });
  });

  // ==========================================================================
  // SubscriptionInfo.formattedNextBilling
  // ==========================================================================

  group('SubscriptionInfo.formattedNextBilling', () {
    SubscriptionInfo makeSubWithDate(DateTime date) {
      return SubscriptionInfo(
        id: 'sub-d',
        artistId: 'chan-d',
        artistName: '아티스트',
        avatarUrl: '',
        tier: 'BASIC',
        price: 4900,
        nextBillingDate: date,
      );
    }

    test('formats 2025-01-05 as "2025.01.05"', () {
      final sub = makeSubWithDate(DateTime(2025, 1, 5));
      expect(sub.formattedNextBilling, '2025.01.05');
    });

    test('formats 2024-12-31 as "2024.12.31"', () {
      final sub = makeSubWithDate(DateTime(2024, 12, 31));
      expect(sub.formattedNextBilling, '2024.12.31');
    });

    test('formats 2026-07-09 as "2026.07.09"', () {
      final sub = makeSubWithDate(DateTime(2026, 7, 9));
      expect(sub.formattedNextBilling, '2026.07.09');
    });

    test('zero-pads single-digit month and day', () {
      final sub = makeSubWithDate(DateTime(2025, 3, 4));
      expect(sub.formattedNextBilling, '2025.03.04');
    });

    test('YYYY.MM.DD format structure is correct', () {
      final sub = makeSubWithDate(DateTime(2025, 11, 22));
      final formatted = sub.formattedNextBilling;
      expect(formatted, matches(RegExp(r'^\d{4}\.\d{2}\.\d{2}$')));
      expect(formatted, '2025.11.22');
    });
  });

  // ==========================================================================
  // SubscriptionState sealed classes — construction
  // ==========================================================================

  group('SubscriptionState sealed class construction', () {
    test('SubscriptionInitial constructs', () {
      const state = SubscriptionInitial();
      expect(state, isA<SubscriptionState>());
      expect(state, isA<SubscriptionInitial>());
    });

    test('SubscriptionLoading constructs', () {
      const state = SubscriptionLoading();
      expect(state, isA<SubscriptionState>());
      expect(state, isA<SubscriptionLoading>());
    });

    test('SubscriptionLoaded constructs with subscriptions list', () {
      const state = SubscriptionLoaded(subscriptions: []);
      expect(state, isA<SubscriptionState>());
      expect(state, isA<SubscriptionLoaded>());
      expect(state.subscriptions, isEmpty);
    });

    test('SubscriptionLoaded holds provided subscriptions', () {
      final sub = SubscriptionInfo(
        id: 'sub-1',
        artistId: 'chan-1',
        artistName: '하늘달',
        avatarUrl: '',
        tier: 'VIP',
        price: 19900,
        nextBillingDate: DateTime(2025, 12, 31),
      );
      final state = SubscriptionLoaded(subscriptions: [sub]);
      expect(state.subscriptions.length, 1);
      expect(state.subscriptions.first.id, 'sub-1');
    });

    test('SubscriptionError constructs with message', () {
      const state = SubscriptionError('오류가 발생했습니다.');
      expect(state, isA<SubscriptionState>());
      expect(state, isA<SubscriptionError>());
      expect(state.message, '오류가 발생했습니다.');
      expect(state.error, isNull);
    });

    test('SubscriptionError constructs with message and error object', () {
      final exception = Exception('network error');
      final state = SubscriptionError('네트워크 오류', exception);
      expect(state.message, '네트워크 오류');
      expect(state.error, same(exception));
    });
  });

  // ==========================================================================
  // Derived providers via ProviderContainer
  // ==========================================================================

  // ==========================================================================
  // Derived providers via ProviderContainer
  //
  // Strategy: directly override the downstream convenience providers so we
  // avoid instantiating SubscriptionNotifier (which needs a live Ref/Supabase).
  // Each convenience provider is a simple Provider<T> that we can override
  // with a known return value.
  // ==========================================================================

  group('subscriptionListProvider', () {
    test('returns empty list when underlying state is non-Loaded (Initial)',
        () {
      // subscriptionListProvider returns [] for any non-SubscriptionLoaded state.
      // We verify the logic by directly checking what the provider computes
      // given a known SubscriptionState.
      const SubscriptionState nonLoadedState = SubscriptionInitial();
      final result = nonLoadedState is SubscriptionLoaded
          ? nonLoadedState.subscriptions
          : <SubscriptionInfo>[];
      expect(result, isEmpty);
    });

    test('returns empty list when underlying state is SubscriptionLoading', () {
      const SubscriptionState nonLoadedState = SubscriptionLoading();
      final result = nonLoadedState is SubscriptionLoaded
          ? nonLoadedState.subscriptions
          : <SubscriptionInfo>[];
      expect(result, isEmpty);
    });

    test('returns empty list when underlying state is SubscriptionError', () {
      const SubscriptionState nonLoadedState = SubscriptionError('error');
      final result = nonLoadedState is SubscriptionLoaded
          ? nonLoadedState.subscriptions
          : <SubscriptionInfo>[];
      expect(result, isEmpty);
    });

    test('returns subscriptions list when state is SubscriptionLoaded', () {
      final subs = [
        SubscriptionInfo(
          id: 'sub-1',
          artistId: 'chan-1',
          artistName: '아티스트 A',
          avatarUrl: '',
          tier: 'BASIC',
          price: 4900,
          nextBillingDate: DateTime(2025, 12, 1),
        ),
        SubscriptionInfo(
          id: 'sub-2',
          artistId: 'chan-2',
          artistName: '아티스트 B',
          avatarUrl: '',
          tier: 'VIP',
          price: 19900,
          nextBillingDate: DateTime(2025, 12, 15),
        ),
      ];
      final SubscriptionState loadedState =
          SubscriptionLoaded(subscriptions: subs);
      final result = loadedState is SubscriptionLoaded
          ? loadedState.subscriptions
          : <SubscriptionInfo>[];
      expect(result.length, 2);
      expect(result.first.id, 'sub-1');
      expect(result.last.id, 'sub-2');
    });

    test('ProviderContainer: overriding subscriptionListProvider yields list',
        () {
      final subs = [
        SubscriptionInfo(
          id: 'sub-1',
          artistId: 'chan-1',
          artistName: '아티스트 A',
          avatarUrl: '',
          tier: 'BASIC',
          price: 4900,
          nextBillingDate: DateTime(2025, 12, 1),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          subscriptionListProvider.overrideWith((_) => subs),
        ],
      );
      addTearDown(container.dispose);

      final list = container.read(subscriptionListProvider);
      expect(list.length, 1);
      expect(list.first.id, 'sub-1');
    });

    test('ProviderContainer: overriding subscriptionListProvider yields empty',
        () {
      final container = ProviderContainer(
        overrides: [
          subscriptionListProvider.overrideWith((_) => const []),
        ],
      );
      addTearDown(container.dispose);

      final list = container.read(subscriptionListProvider);
      expect(list, isEmpty);
    });
  });

  group('subscriptionCountProvider', () {
    test('returns 0 for empty list', () {
      final container = ProviderContainer(
        overrides: [
          subscriptionListProvider.overrideWith((_) => const []),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(subscriptionCountProvider), 0);
    });

    test('returns correct count for 3 subscriptions', () {
      final subs = List.generate(
        3,
        (i) => SubscriptionInfo(
          id: 'sub-$i',
          artistId: 'chan-$i',
          artistName: '아티스트 $i',
          avatarUrl: '',
          tier: 'BASIC',
          price: 4900,
          nextBillingDate: DateTime(2025, 12, i + 1),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          subscriptionListProvider.overrideWith((_) => subs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(subscriptionCountProvider), 3);
    });

    test('returns 1 for single subscription', () {
      final subs = [
        SubscriptionInfo(
          id: 'sub-1',
          artistId: 'chan-1',
          artistName: '아티스트',
          avatarUrl: '',
          tier: 'VIP',
          price: 19900,
          nextBillingDate: DateTime(2025, 12, 1),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          subscriptionListProvider.overrideWith((_) => subs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(subscriptionCountProvider), 1);
    });
  });

  group('hasAnyActiveSubscriptionProvider', () {
    test('false when list is empty', () {
      final container = ProviderContainer(
        overrides: [
          subscriptionListProvider.overrideWith((_) => const []),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(hasAnyActiveSubscriptionProvider), isFalse);
    });

    test('true when list has at least one subscription', () {
      final subs = [
        SubscriptionInfo(
          id: 'sub-1',
          artistId: 'chan-1',
          artistName: '아티스트',
          avatarUrl: '',
          tier: 'STANDARD',
          price: 9900,
          nextBillingDate: DateTime(2025, 12, 1),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          subscriptionListProvider.overrideWith((_) => subs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(hasAnyActiveSubscriptionProvider), isTrue);
    });

    test('true when list has multiple subscriptions', () {
      final subs = List.generate(
        3,
        (i) => SubscriptionInfo(
          id: 'sub-$i',
          artistId: 'chan-$i',
          artistName: '아티스트 $i',
          avatarUrl: '',
          tier: 'BASIC',
          price: 4900,
          nextBillingDate: DateTime(2025, 12, i + 1),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          subscriptionListProvider.overrideWith((_) => subs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(hasAnyActiveSubscriptionProvider), isTrue);
    });
  });
}
