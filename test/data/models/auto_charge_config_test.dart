import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/auto_charge_config.dart';

void main() {
  group('AutoChargeConfig', () {
    final now = DateTime(2025, 6, 15, 10, 0, 0);

    final sampleJson = {
      'id': 'config_1',
      'user_id': 'user_1',
      'is_enabled': true,
      'threshold_dt': 200,
      'charge_amount_dt': 2000,
      'charge_package_id': 'pkg_1',
      'billing_key_id': 'billing_1',
      'max_monthly_charges': 10,
      'charges_this_month': 3,
      'last_charged_at': now.toIso8601String(),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    test('fromJson creates correct instance', () {
      final config = AutoChargeConfig.fromJson(sampleJson);

      expect(config.id, 'config_1');
      expect(config.userId, 'user_1');
      expect(config.isEnabled, true);
      expect(config.thresholdDt, 200);
      expect(config.chargeAmountDt, 2000);
      expect(config.chargePackageId, 'pkg_1');
      expect(config.billingKeyId, 'billing_1');
      expect(config.maxMonthlyCharges, 10);
      expect(config.chargesThisMonth, 3);
      expect(config.lastChargedAt, now);
    });

    test('toJson produces correct map', () {
      final config = AutoChargeConfig.fromJson(sampleJson);
      final json = config.toJson();

      expect(json['id'], 'config_1');
      expect(json['user_id'], 'user_1');
      expect(json['is_enabled'], true);
      expect(json['threshold_dt'], 200);
      expect(json['charge_amount_dt'], 2000);
    });

    test('round-trip fromJson → toJson', () {
      final config = AutoChargeConfig.fromJson(sampleJson);
      final json = config.toJson();
      final config2 = AutoChargeConfig.fromJson(json);

      expect(config2.id, config.id);
      expect(config2.isEnabled, config.isEnabled);
      expect(config2.thresholdDt, config.thresholdDt);
      expect(config2.chargeAmountDt, config.chargeAmountDt);
    });

    test('computed properties work correctly', () {
      final config = AutoChargeConfig.fromJson(sampleJson);

      expect(config.hasBillingKey, true);
      expect(config.canChargeThisMonth, true);
      expect(config.remainingCharges, 7);
    });

    test('canChargeThisMonth returns false when maxed', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json['charges_this_month'] = 10;
      final config = AutoChargeConfig.fromJson(json);

      expect(config.canChargeThisMonth, false);
      expect(config.remainingCharges, 0);
    });

    test('fromJson handles null optional fields', () {
      final minJson = {
        'id': 'config_2',
        'user_id': 'user_2',
        'created_at': now.toIso8601String(),
      };
      final config = AutoChargeConfig.fromJson(minJson);

      expect(config.isEnabled, false);
      expect(config.thresholdDt, 100);
      expect(config.chargeAmountDt, 1000);
      expect(config.billingKeyId, null);
      expect(config.hasBillingKey, false);
    });

    test('copyWith creates modified copy', () {
      final config = AutoChargeConfig.fromJson(sampleJson);
      final updated = config.copyWith(
        isEnabled: false,
        thresholdDt: 500,
      );

      expect(updated.isEnabled, false);
      expect(updated.thresholdDt, 500);
      expect(updated.chargeAmountDt, config.chargeAmountDt);
      expect(updated.id, config.id);
    });

    test('equality based on id', () {
      final config1 = AutoChargeConfig.fromJson(sampleJson);
      final config2 = AutoChargeConfig.fromJson(sampleJson);
      expect(config1, equals(config2));
    });
  });
}
