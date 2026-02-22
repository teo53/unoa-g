import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/core/config/business_config.dart';
import 'package:uno_a_flutter/services/iap_service.dart';

void main() {
  group('BusinessConfig subscription SKUs', () {
    test('all subscription tiers have SKUs', () {
      for (final tier in BusinessConfig.subscriptionTiers) {
        expect(BusinessConfig.subscriptionSkuByTier.containsKey(tier), isTrue,
            reason: 'Missing SKU for tier: $tier');
      }
    });

    test('reverse mapping is consistent with forward mapping', () {
      for (final entry in BusinessConfig.subscriptionSkuByTier.entries) {
        expect(BusinessConfig.tierBySubscriptionSku[entry.value],
            equals(entry.key),
            reason:
                'Reverse mapping for ${entry.value} should be ${entry.key}');
      }
    });

    test('SKU naming convention follows com.unoa.sub.*.monthly', () {
      for (final sku in BusinessConfig.subscriptionSkuByTier.values) {
        expect(sku, startsWith('com.unoa.sub.'),
            reason: 'SKU "$sku" must start with com.unoa.sub.');
        expect(sku, endsWith('.monthly'),
            reason: 'SKU "$sku" must end with .monthly');
      }
    });

    test('allSubscriptionSkus contains all tier SKUs', () {
      final allSkus = BusinessConfig.allSubscriptionSkus;
      expect(allSkus.length, BusinessConfig.subscriptionTiers.length);
      for (final sku in BusinessConfig.subscriptionSkuByTier.values) {
        expect(allSkus.contains(sku), isTrue,
            reason: 'allSubscriptionSkus missing: $sku');
      }
    });

    test('BusinessConfig SKUs match IapService subscriptionProductIdMap', () {
      for (final tier in BusinessConfig.subscriptionTiers) {
        final bizSku = BusinessConfig.subscriptionSkuByTier[tier];
        final iapSku = IapService.subscriptionProductIdMap[tier];
        expect(bizSku, equals(iapSku),
            reason: 'SKU mismatch for tier $tier: '
                'BusinessConfig=$bizSku, IapService=$iapSku');
      }
    });

    test('tier prices exist for all platforms', () {
      for (final platform in PurchasePlatform.values) {
        for (final tier in BusinessConfig.subscriptionTiers) {
          final price = BusinessConfig.getTierPrice(tier, platform);
          expect(price, greaterThan(0),
              reason: 'Price for $tier on $platform should be > 0');
        }
      }
    });

    test('iOS prices >= Android prices >= web prices', () {
      for (final tier in BusinessConfig.subscriptionTiers) {
        final web = BusinessConfig.getTierPrice(tier, PurchasePlatform.web);
        final android =
            BusinessConfig.getTierPrice(tier, PurchasePlatform.android);
        final ios = BusinessConfig.getTierPrice(tier, PurchasePlatform.ios);
        expect(ios, greaterThanOrEqualTo(android),
            reason: 'iOS price should be >= Android for $tier');
        expect(android, greaterThanOrEqualTo(web),
            reason: 'Android price should be >= web for $tier');
      }
    });
  });
}
