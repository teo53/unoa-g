import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/core/config/app_config.dart';
import 'package:uno_a_flutter/core/config/business_config.dart';

void main() {
  group('AppConfig', () {
    test('default environment is development', () {
      expect(AppConfig.environment, equals('development'));
    });

    test('isDevelopment returns true by default', () {
      expect(AppConfig.isDevelopment, isTrue);
    });

    test('isProduction returns false by default', () {
      expect(AppConfig.isProduction, isFalse);
    });

    test('isBeta returns false by default', () {
      expect(AppConfig.isBeta, isFalse);
    });

    test('enableDemoMode is true in development', () {
      // In development, demo mode is always enabled
      expect(AppConfig.enableDemoMode, isTrue);
    });

    test('enableAnalytics is false in development', () {
      expect(AppConfig.enableAnalytics, isFalse);
    });

    test('appName is UNO A', () {
      expect(AppConfig.appName, equals('UNO A'));
    });

    test('appVersion matches semver format', () {
      expect(
        AppConfig.appVersion,
        matches(RegExp(r'^\d+\.\d+\.\d+$')),
      );
    });

    test('validate does not throw in development', () {
      // Development environment has relaxed validation
      expect(() => AppConfig.validate(), returnsNormally);
    });
  });

  group('BusinessConfig consistency', () {
    test('all subscription tiers have prices', () {
      for (final tier in BusinessConfig.subscriptionTiers) {
        expect(
          BusinessConfig.tierPricesKrw.containsKey(tier),
          isTrue,
          reason: 'Tier $tier should have a price',
        );
      }
    });

    test('all subscription tiers have display names', () {
      for (final tier in BusinessConfig.subscriptionTiers) {
        expect(
          BusinessConfig.tierDisplayNames.containsKey(tier),
          isTrue,
          reason: 'Tier $tier should have a display name',
        );
      }
    });

    test('all subscription tiers have benefits', () {
      for (final tier in BusinessConfig.subscriptionTiers) {
        expect(
          BusinessConfig.tierBenefits.containsKey(tier),
          isTrue,
          reason: 'Tier $tier should have benefits',
        );
      }
    });

    test('default reply tokens is positive', () {
      expect(BusinessConfig.defaultReplyTokens, greaterThan(0));
    });

    test('character limit increases with subscription age', () {
      final limit30 = BusinessConfig.getCharacterLimit(30);
      final limit100 = BusinessConfig.getCharacterLimit(100);
      final limit300 = BusinessConfig.getCharacterLimit(300);

      expect(limit100, greaterThanOrEqualTo(limit30));
      expect(limit300, greaterThanOrEqualTo(limit100));
    });
  });
}
