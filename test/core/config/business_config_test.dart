import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/core/config/business_config.dart';

void main() {
  group('BusinessConfig', () {
    group('subscriptionTiers', () {
      test('has 3 tiers', () {
        expect(BusinessConfig.subscriptionTiers.length, 3);
      });
      test('contains BASIC, STANDARD, VIP', () {
        expect(BusinessConfig.subscriptionTiers, ['BASIC', 'STANDARD', 'VIP']);
      });
    });

    group('tierPricesKrw', () {
      test('BASIC is 4900', () {
        expect(BusinessConfig.tierPricesKrw['BASIC'], 4900);
      });
      test('STANDARD is 9900', () {
        expect(BusinessConfig.tierPricesKrw['STANDARD'], 9900);
      });
      test('VIP is 19900', () {
        expect(BusinessConfig.tierPricesKrw['VIP'], 19900);
      });
    });

    group('getTokensForTier', () {
      test('BASIC gets 3 tokens', () {
        expect(BusinessConfig.getTokensForTier('BASIC'), 3);
      });
      test('STANDARD gets 4 tokens', () {
        expect(BusinessConfig.getTokensForTier('STANDARD'), 4);
      });
      test('VIP gets 5 tokens', () {
        expect(BusinessConfig.getTokensForTier('VIP'), 5);
      });
      test('case insensitive', () {
        expect(BusinessConfig.getTokensForTier('vip'), 5);
        expect(BusinessConfig.getTokensForTier('Vip'), 5);
      });
      test('unknown tier gets default 3', () {
        expect(BusinessConfig.getTokensForTier('unknown'), 3);
      });
    });

    group('getCharacterLimit', () {
      test('0 days returns 50', () {
        expect(BusinessConfig.getCharacterLimit(0), 50);
      });
      test('49 days returns 50', () {
        expect(BusinessConfig.getCharacterLimit(49), 50);
      });
      test('50 days returns 50', () {
        expect(BusinessConfig.getCharacterLimit(50), 50);
      });
      test('76 days returns 50', () {
        expect(BusinessConfig.getCharacterLimit(76), 50);
      });
      test('77 days returns 77', () {
        expect(BusinessConfig.getCharacterLimit(77), 77);
      });
      test('99 days returns 77', () {
        expect(BusinessConfig.getCharacterLimit(99), 77);
      });
      test('100 days returns 100', () {
        expect(BusinessConfig.getCharacterLimit(100), 100);
      });
      test('149 days returns 100', () {
        expect(BusinessConfig.getCharacterLimit(149), 100);
      });
      test('150 days returns 150', () {
        expect(BusinessConfig.getCharacterLimit(150), 150);
      });
      test('200 days returns 200', () {
        expect(BusinessConfig.getCharacterLimit(200), 200);
      });
      test('300 days returns 300', () {
        expect(BusinessConfig.getCharacterLimit(300), 300);
      });
      test('1000 days returns 300', () {
        expect(BusinessConfig.getCharacterLimit(1000), 300);
      });
    });

    group('platformCommissionPercent', () {
      test('is 20%', () {
        expect(BusinessConfig.platformCommissionPercent, 20.0);
      });
      test('creator payout is 80%', () {
        expect(BusinessConfig.creatorPayoutPercent, 80.0);
      });
      test('commission + payout equals 100%', () {
        expect(
          BusinessConfig.platformCommissionPercent +
              BusinessConfig.creatorPayoutPercent,
          100.0,
        );
      });
    });

    group('funding campaign limits', () {
      test('min funding goal is 100,000 KRW', () {
        expect(BusinessConfig.minFundingGoalKrw, 100000);
      });
      test('max campaign duration is 90 days', () {
        expect(BusinessConfig.maxCampaignDurationDays, 90);
      });
      test('min campaign duration is 7 days', () {
        expect(BusinessConfig.minCampaignDurationDays, 7);
      });
    });

    group('rate limits', () {
      test('max messages per hour is 60', () {
        expect(BusinessConfig.maxMessagesPerHour, 60);
      });
      test('max broadcasts per day is 50', () {
        expect(BusinessConfig.maxBroadcastsPerDay, 50);
      });
    });

    group('milestone days', () {
      test('has 3 milestones', () {
        expect(BusinessConfig.milestoneDays.length, 3);
      });
      test('milestones are 50, 100, 365', () {
        expect(BusinessConfig.milestoneDays, [50, 100, 365]);
      });
    });

    group('chargeAmounts', () {
      test('is sorted ascending', () {
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
