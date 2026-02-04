import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/dt_package.dart';

void main() {
  group('DtPackage', () {
    DtPackage createPackage({
      String id = 'pkg-1',
      String name = '기본 패키지',
      int dtAmount = 100,
      int bonusDt = 0,
      int priceKrw = 10000,
      bool isPopular = false,
      bool isActive = true,
    }) {
      return DtPackage(
        id: id,
        name: name,
        dtAmount: dtAmount,
        bonusDt: bonusDt,
        priceKrw: priceKrw,
        isPopular: isPopular,
        isActive: isActive,
      );
    }

    group('totalDt', () {
      test('returns dtAmount when no bonus', () {
        final package = createPackage(dtAmount: 100, bonusDt: 0);
        expect(package.totalDt, equals(100));
      });

      test('includes bonus in total', () {
        final package = createPackage(dtAmount: 100, bonusDt: 20);
        expect(package.totalDt, equals(120));
      });

      test('handles large amounts', () {
        final package = createPackage(dtAmount: 10000, bonusDt: 2000);
        expect(package.totalDt, equals(12000));
      });
    });

    group('formattedPrice', () {
      test('formats with comma separators and 원 suffix', () {
        final package = createPackage(priceKrw: 49000);
        expect(package.formattedPrice, equals('49,000원'));
      });

      test('formats small amounts', () {
        final package = createPackage(priceKrw: 100);
        expect(package.formattedPrice, equals('100원'));
      });

      test('formats large amounts', () {
        final package = createPackage(priceKrw: 1000000);
        expect(package.formattedPrice, equals('1,000,000원'));
      });

      test('handles zero', () {
        final package = createPackage(priceKrw: 0);
        expect(package.formattedPrice, equals('0원'));
      });
    });

    group('formattedDt', () {
      test('includes total DT with suffix', () {
        final package = createPackage(dtAmount: 500, bonusDt: 50);
        expect(package.formattedDt, equals('550 DT'));
      });

      test('formats with comma separators', () {
        final package = createPackage(dtAmount: 10000, bonusDt: 2000);
        expect(package.formattedDt, equals('12,000 DT'));
      });
    });

    group('bonusText', () {
      test('returns empty string when no bonus', () {
        final package = createPackage(bonusDt: 0);
        expect(package.bonusText, isEmpty);
      });

      test('formats bonus with + prefix and 보너스 suffix', () {
        final package = createPackage(bonusDt: 50);
        expect(package.bonusText, equals('+50 보너스'));
      });

      test('formats large bonus with comma', () {
        final package = createPackage(bonusDt: 2000);
        expect(package.bonusText, equals('+2,000 보너스'));
      });
    });

    group('pricePerDt', () {
      test('calculates price per DT correctly', () {
        final package = createPackage(dtAmount: 100, bonusDt: 0, priceKrw: 10000);
        expect(package.pricePerDt, equals(100.0));
      });

      test('accounts for bonus in calculation', () {
        final package = createPackage(dtAmount: 100, bonusDt: 25, priceKrw: 10000);
        // 10000 / 125 = 80
        expect(package.pricePerDt, equals(80.0));
      });
    });

    group('formattedPricePerDt', () {
      test('formats with suffix', () {
        final package = createPackage(dtAmount: 100, bonusDt: 0, priceKrw: 10000);
        expect(package.formattedPricePerDt, equals('100원/DT'));
      });

      test('rounds to integer', () {
        final package = createPackage(dtAmount: 100, bonusDt: 20, priceKrw: 10000);
        // 10000 / 120 = 83.33...
        expect(package.formattedPricePerDt, equals('83원/DT'));
      });
    });

    group('fromJson / toJson', () {
      test('round-trips all fields correctly', () {
        final original = createPackage(
          id: 'pkg-123',
          name: '프리미엄 패키지',
          dtAmount: 1000,
          bonusDt: 200,
          priceKrw: 99000,
          isPopular: true,
          isActive: true,
        );

        final json = original.toJson();
        final restored = DtPackage.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.name, equals(original.name));
        expect(restored.dtAmount, equals(original.dtAmount));
        expect(restored.bonusDt, equals(original.bonusDt));
        expect(restored.priceKrw, equals(original.priceKrw));
        expect(restored.isPopular, equals(original.isPopular));
        expect(restored.isActive, equals(original.isActive));
      });

      test('handles missing optional fields with defaults', () {
        final json = {
          'id': 'pkg-1',
          'name': 'Basic',
          'dt_amount': 100,
          'price_krw': 10000,
        };

        final package = DtPackage.fromJson(json);

        expect(package.bonusDt, equals(0));
        expect(package.isPopular, isFalse);
        expect(package.isActive, isTrue);
      });
    });

    group('copyWith', () {
      test('preserves unchanged values', () {
        final original = createPackage(
          id: 'pkg-1',
          name: 'Original',
          dtAmount: 100,
        );

        final copied = original.copyWith(name: 'Updated');

        expect(copied.name, equals('Updated'));
        expect(copied.id, equals(original.id));
        expect(copied.dtAmount, equals(original.dtAmount));
      });

      test('can update all fields', () {
        final original = createPackage();
        final copied = original.copyWith(
          id: 'new-id',
          name: 'New Name',
          dtAmount: 500,
          bonusDt: 100,
          priceKrw: 50000,
          isPopular: true,
          isActive: false,
        );

        expect(copied.id, equals('new-id'));
        expect(copied.name, equals('New Name'));
        expect(copied.dtAmount, equals(500));
        expect(copied.bonusDt, equals(100));
        expect(copied.priceKrw, equals(50000));
        expect(copied.isPopular, isTrue);
        expect(copied.isActive, isFalse);
      });
    });

    group('equality', () {
      test('packages with same id are equal', () {
        final package1 = createPackage(id: 'pkg-1', name: 'Name 1');
        final package2 = createPackage(id: 'pkg-1', name: 'Name 2');

        expect(package1, equals(package2));
      });

      test('packages with different ids are not equal', () {
        final package1 = createPackage(id: 'pkg-1');
        final package2 = createPackage(id: 'pkg-2');

        expect(package1, isNot(equals(package2)));
      });
    });

    group('hashCode', () {
      test('same id produces same hashCode', () {
        final package1 = createPackage(id: 'pkg-1');
        final package2 = createPackage(id: 'pkg-1');

        expect(package1.hashCode, equals(package2.hashCode));
      });
    });

    group('toString', () {
      test('includes key fields', () {
        final package = createPackage(
          id: 'pkg-123',
          name: 'Test Package',
          dtAmount: 100,
          bonusDt: 20,
          priceKrw: 10000,
        );

        final str = package.toString();

        expect(str, contains('pkg-123'));
        expect(str, contains('Test Package'));
        expect(str, contains('100'));
        expect(str, contains('20'));
        expect(str, contains('10000'));
      });
    });
  });
}
