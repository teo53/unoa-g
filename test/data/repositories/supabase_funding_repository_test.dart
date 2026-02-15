import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/repositories/supabase_funding_repository.dart';

void main() {
  group('SupabaseFundingRepository prelaunch signup', () {
    test('authenticated signup uses campaign_id,user_id conflict key', () {
      final conflictKey = SupabaseFundingRepository.prelaunchSignupConflictKeyFor(
        userId: 'user-1',
        email: 'fan@example.com',
      );

      expect(conflictKey, equals('campaign_id,user_id'));
    });

    test('anonymous signup uses campaign_id,email conflict key', () {
      final conflictKey = SupabaseFundingRepository.prelaunchSignupConflictKeyFor(
        userId: null,
        email: 'fan@example.com',
      );

      expect(conflictKey, equals('campaign_id,email'));
    });

    test('includes email in payload when provided', () {
      final payload = SupabaseFundingRepository.buildPrelaunchSignupPayload(
        campaignId: 'campaign-1',
        userId: 'user-1',
        email: 'fan@example.com',
      );

      expect(payload['campaign_id'], equals('campaign-1'));
      expect(payload['user_id'], equals('user-1'));
      expect(payload['email'], equals('fan@example.com'));
      expect(payload['notify_on_launch'], isTrue);
    });

    test('duplicate signup scenario keeps same idempotent identity keys', () {
      final firstPayload = SupabaseFundingRepository.buildPrelaunchSignupPayload(
        campaignId: 'campaign-1',
        userId: 'user-1',
        email: 'fan@example.com',
      );
      final secondPayload = SupabaseFundingRepository.buildPrelaunchSignupPayload(
        campaignId: 'campaign-1',
        userId: 'user-1',
        email: 'fan@example.com',
      );
      final conflictKey = SupabaseFundingRepository.prelaunchSignupConflictKeyFor(
        userId: 'user-1',
        email: 'fan@example.com',
      );

      expect(conflictKey, equals('campaign_id,user_id'));
      expect(secondPayload['campaign_id'], equals(firstPayload['campaign_id']));
      expect(secondPayload['user_id'], equals(firstPayload['user_id']));
    });
  });
}
