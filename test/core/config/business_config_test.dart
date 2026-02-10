import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/core/config/business_config.dart';

void main() {
  group('BusinessConfig', () {
    group('getTokensForTier', () {
      test('returns 3 for BASIC tier', () {
        expect(BusinessConfig.getTokensForTier('BASIC'), equals(3));
      });

      test('returns 4 for STANDARD tier', () {
        expect(BusinessConfig.getTokensForTier('STANDARD'), equals(4));
      });

      test('returns 5 for VIP tier', () {
        expect(BusinessConfig.getTokensForTier('VIP'), equals(5));
      });

      test('handles case-insensitive input', () {
        expect(BusinessConfig.getTokensForTier('vip'), equals(5));
        expect(BusinessConfig.getTokensForTier('Vip'), equals(5));
        expect(BusinessConfig.getTokensForTier('standard'), equals(4));
      });

      test('returns default 3 for unknown tier', () {
        expect(BusinessConfig.getTokensForTier('PREMIUM'), equals(3));
        expect(BusinessConfig.getTokensForTier(''), equals(3));
      });
    });

    group('getCharacterLimit', () {
      test('returns 50 for day 0', () {
        expect(BusinessConfig.getCharacterLimit(0), equals(50));
      });

      test('returns 50 for day 49', () {
        expect(BusinessConfig.getCharacterLimit(49), equals(50));
      });

      test('returns 50 for day 50', () {
        expect(BusinessConfig.getCharacterLimit(50), equals(50));
      });

      test('returns 77 for day 77', () {
        expect(BusinessConfig.getCharacterLimit(77), equals(77));
      });

      test('returns 100 for day 100', () {
        expect(BusinessConfig.getCharacterLimit(100), equals(100));
      });

      test('returns 150 for day 150', () {
        expect(BusinessConfig.getCharacterLimit(150), equals(150));
      });

      test('returns 200 for day 200', () {
        expect(BusinessConfig.getCharacterLimit(200), equals(200));
      });

      test('returns 300 for day 300', () {
        expect(BusinessConfig.getCharacterLimit(300), equals(300));
      });

      test('returns 300 for day 999', () {
        expect(BusinessConfig.getCharacterLimit(999), equals(300));
      });
    });

    group('static constants', () {
      test('creatorPayoutPercent equals 80.0', () {
        expect(BusinessConfig.creatorPayoutPercent, equals(80.0));
      });

      test('platformCommissionPercent plus creatorPayoutPercent equals 100',
          () {
        expect(
          BusinessConfig.platformCommissionPercent +
              BusinessConfig.creatorPayoutPercent,
          equals(100.0),
        );
      });

      test('chargeAmounts is sorted ascending', () {
        for (int i = 1; i < BusinessConfig.chargeAmounts.length; i++) {
          expect(
            BusinessConfig.chargeAmounts[i],
            greaterThan(BusinessConfig.chargeAmounts[i - 1]),
          );
        }
      });
    });
  });
}
