import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/services/iap_service.dart';

void main() {
  group('IapService product ID mappings', () {
    test('DT product IDs follow com.unoa.dt.* convention', () {
      for (final id in IapService.productIdMap.values) {
        expect(id, startsWith('com.unoa.dt.'),
            reason: 'DT product ID "$id" must start with com.unoa.dt.');
      }
    });

    test('Subscription product IDs follow com.unoa.sub.* convention', () {
      for (final id in IapService.subscriptionProductIdMap.values) {
        expect(id, startsWith('com.unoa.sub.'),
            reason:
                'Subscription product ID "$id" must start with com.unoa.sub.');
      }
    });

    test('No overlap between DT and subscription product IDs', () {
      final dtIds = IapService.productIdMap.values.toSet();
      final subIds = IapService.subscriptionProductIdMap.values.toSet();
      final overlap = dtIds.intersection(subIds);
      expect(overlap, isEmpty,
          reason: 'DT and subscription product IDs must not overlap: $overlap');
    });

    test('allProductIds contains both DT and subscription product IDs', () {
      final allIds = IapService.allProductIds;
      for (final dtId in IapService.productIdMap.values) {
        expect(allIds.contains(dtId), isTrue,
            reason: 'allProductIds missing DT product: $dtId');
      }
      for (final subId in IapService.subscriptionProductIdMap.values) {
        expect(allIds.contains(subId), isTrue,
            reason: 'allProductIds missing subscription product: $subId');
      }
    });

    test('isSubscriptionProduct returns true only for subscription IDs', () {
      for (final subId in IapService.subscriptionProductIdMap.values) {
        expect(IapService.isSubscriptionProduct(subId), isTrue,
            reason: '$subId should be identified as subscription');
      }
      for (final dtId in IapService.productIdMap.values) {
        expect(IapService.isSubscriptionProduct(dtId), isFalse,
            reason: '$dtId should NOT be identified as subscription');
      }
    });

    test('getPackageId returns correct internal ID for DT products', () {
      for (final entry in IapService.productIdMap.entries) {
        expect(IapService.getPackageId(entry.value), equals(entry.key));
      }
    });

    test('getPackageId returns null for subscription products', () {
      for (final subId in IapService.subscriptionProductIdMap.values) {
        expect(IapService.getPackageId(subId), isNull,
            reason:
                'Subscription product $subId should not be in DT reverse map');
      }
    });

    test('subscriptionProductIdMap matches all standard tiers', () {
      expect(IapService.subscriptionProductIdMap.containsKey('BASIC'), isTrue);
      expect(
          IapService.subscriptionProductIdMap.containsKey('STANDARD'), isTrue);
      expect(IapService.subscriptionProductIdMap.containsKey('VIP'), isTrue);
    });
  });
}
