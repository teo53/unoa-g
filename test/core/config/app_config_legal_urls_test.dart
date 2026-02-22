import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/core/config/app_config.dart';

void main() {
  group('AppConfig legal URL getters', () {
    test('effectivePrivacyPolicyUrl returns fallback when env var is empty',
        () {
      // In test environment, PRIVACY_POLICY_URL is not set via --dart-define
      // so privacyPolicyUrl will be '' (empty default).
      // effectivePrivacyPolicyUrl should return the fallback.
      final url = AppConfig.effectivePrivacyPolicyUrl;
      expect(url, isNotEmpty, reason: 'Effective URL should never be empty');
      expect(url, contains('privacy'),
          reason: 'Privacy URL should contain "privacy"');
      expect(url, startsWith('https://'), reason: 'URL must use HTTPS');
    });

    test('effectiveTermsOfServiceUrl returns fallback when env var is empty',
        () {
      final url = AppConfig.effectiveTermsOfServiceUrl;
      expect(url, isNotEmpty, reason: 'Effective URL should never be empty');
      expect(url, contains('terms'),
          reason: 'Terms URL should contain "terms"');
      expect(url, startsWith('https://'), reason: 'URL must use HTTPS');
    });

    test('effective URLs use HTTPS scheme', () {
      expect(AppConfig.effectivePrivacyPolicyUrl, startsWith('https://'));
      expect(AppConfig.effectiveTermsOfServiceUrl, startsWith('https://'));
    });

    test('environment defaults to development in test', () {
      expect(AppConfig.environment, equals('development'));
      expect(AppConfig.isDevelopment, isTrue);
    });
  });
}
