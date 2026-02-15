import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/core/config/business_config.dart';

void main() {
  group('Settlement Business Logic', () {
    group('commission calculation', () {
      test('20% platform fee on 100,000 KRW', () {
        const grossKrw = 100000;
        final platformFee = (grossKrw * BusinessConfig.platformCommissionPercent / 100).round();
        expect(platformFee, 20000);
      });

      test('creator receives 80% of gross', () {
        const grossKrw = 100000;
        final creatorShare = (grossKrw * BusinessConfig.creatorPayoutPercent / 100).round();
        expect(creatorShare, 80000);
      });

      test('platform fee + creator share equals gross', () {
        const grossKrw = 123456;
        final platformFee = (grossKrw * BusinessConfig.platformCommissionPercent / 100).round();
        final creatorShare = (grossKrw * BusinessConfig.creatorPayoutPercent / 100).round();
        expect(platformFee + creatorShare, grossKrw);
      });
    });

    group('withholding tax', () {
      test('3.3% default withholding on 80,000 KRW net', () {
        const netBeforeTax = 80000;
        const withholdingRate = 0.033;
        final tax = (netBeforeTax * withholdingRate).round();
        expect(tax, 2640);
      });

      test('net payout after tax', () {
        const grossKrw = 100000;
        final creatorShare = (grossKrw * BusinessConfig.creatorPayoutPercent / 100).round();
        const withholdingRate = 0.033;
        final tax = (creatorShare * withholdingRate).round();
        final netPayout = creatorShare - tax;
        expect(netPayout, 80000 - 2640);
        expect(netPayout, 77360);
      });
    });

    group('DT to KRW conversion', () {
      test('base unit price is 100 KRW per DT', () {
        expect(BusinessConfig.dtBaseUnitPriceKrw, 100);
      });

      test('1000 DT = 100,000 KRW at base rate', () {
        const dtAmount = 1000;
        final krw = dtAmount * BusinessConfig.dtBaseUnitPriceKrw;
        expect(krw, 100000);
      });
    });

    group('charge amounts', () {
      test('charge amounts are sorted ascending', () {
        for (int i = 1; i < BusinessConfig.chargeAmounts.length; i++) {
          expect(
            BusinessConfig.chargeAmounts[i],
            greaterThan(BusinessConfig.chargeAmounts[i - 1]),
          );
        }
      });

      test('all charge amounts are within limits', () {
        for (final amount in BusinessConfig.chargeAmounts) {
          expect(amount, greaterThanOrEqualTo(BusinessConfig.minChargeDt));
          expect(amount, lessThanOrEqualTo(BusinessConfig.maxChargeDt));
        }
      });
    });

    group('donation limits', () {
      test('min donation is 100 DT', () {
        expect(BusinessConfig.minDonationDt, 100);
      });
      test('max donation is 1,000,000 DT', () {
        expect(BusinessConfig.maxDonationDt, 1000000);
      });
      test('quick donation amounts are within limits', () {
        for (final amount in BusinessConfig.quickDonationAmounts) {
          expect(amount, greaterThanOrEqualTo(BusinessConfig.minDonationDt));
          expect(amount, lessThanOrEqualTo(BusinessConfig.maxDonationDt));
        }
      });
    });
  });
}
