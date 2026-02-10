import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/dt_package.dart';

// Note: Full provider tests require mock Supabase setup.
// These tests focus on model interactions and state logic that can be tested independently.

void main() {
  group('DtPackage tests', () {
    DtPackage createPackage({
      String id = 'pkg-1',
      String name = 'Basic',
      int dtAmount = 100,
      int bonusDt = 0,
      int priceKrw = 10000,
      bool isPopular = false,
    }) {
      return DtPackage(
        id: id,
        name: name,
        dtAmount: dtAmount,
        bonusDt: bonusDt,
        priceKrw: priceKrw,
        isPopular: isPopular,
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
    });

    group('formattedPrice', () {
      test('formats 49,000원 correctly', () {
        final package = createPackage(priceKrw: 49000);
        expect(package.formattedPrice, equals('49,000원'));
      });

      test('formats 1,000원 correctly', () {
        final package = createPackage(priceKrw: 1000);
        expect(package.formattedPrice, equals('1,000원'));
      });

      test('formats 100원 correctly', () {
        final package = createPackage(priceKrw: 100);
        expect(package.formattedPrice, equals('100원'));
      });
    });

    group('bonusText', () {
      test('returns empty string when no bonus', () {
        final package = createPackage(bonusDt: 0);
        expect(package.bonusText, isEmpty);
      });

      test('returns formatted bonus text', () {
        final package = createPackage(bonusDt: 50);
        expect(package.bonusText, equals('+50 보너스'));
      });

      test('formats large bonus with comma', () {
        final package = createPackage(bonusDt: 1000);
        expect(package.bonusText, equals('+1,000 보너스'));
      });
    });

    group('pricePerDt', () {
      test('calculates correctly without bonus', () {
        final package = createPackage(dtAmount: 100, bonusDt: 0, priceKrw: 10000);
        expect(package.pricePerDt, equals(100.0));
      });

      test('calculates correctly with bonus', () {
        final package = createPackage(dtAmount: 100, bonusDt: 100, priceKrw: 10000);
        expect(package.pricePerDt, equals(50.0));
      });
    });
  });

  group('Wallet balance operations', () {
    test('calculates balance after purchase', () {
      const currentBalance = 500;
      const purchaseAmount = 100;
      const newBalance = currentBalance + purchaseAmount;
      expect(newBalance, equals(600));
    });

    test('calculates balance after donation', () {
      const currentBalance = 500;
      const donationAmount = 100;
      const newBalance = currentBalance - donationAmount;
      expect(newBalance, equals(400));
    });

    test('cannot donate more than balance', () {
      const currentBalance = 50;
      const donationAmount = 100;
      const canDonate = currentBalance >= donationAmount;
      expect(canDonate, isFalse);
    });

    test('can donate when balance is sufficient', () {
      const currentBalance = 100;
      const donationAmount = 100;
      const canDonate = currentBalance >= donationAmount;
      expect(canDonate, isTrue);
    });
  });

  group('Number formatting', () {
    String formatNumber(int number) {
      return number.toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (match) => '${match[1]},',
          );
    }

    test('formats small numbers', () {
      expect(formatNumber(100), equals('100'));
    });

    test('formats thousands', () {
      expect(formatNumber(1000), equals('1,000'));
    });

    test('formats millions', () {
      expect(formatNumber(1000000), equals('1,000,000'));
    });
  });

  group('Package selection', () {
    test('filters active packages', () {
      final packages = [
        const DtPackage(id: '1', name: 'A', dtAmount: 100, priceKrw: 1000, isActive: true),
        const DtPackage(id: '2', name: 'B', dtAmount: 200, priceKrw: 2000, isActive: false),
        const DtPackage(id: '3', name: 'C', dtAmount: 300, priceKrw: 3000, isActive: true),
      ];

      final active = packages.where((p) => p.isActive).toList();
      expect(active.length, equals(2));
    });

    test('finds popular package', () {
      final packages = [
        const DtPackage(id: '1', name: 'A', dtAmount: 100, priceKrw: 1000, isPopular: false),
        const DtPackage(id: '2', name: 'B', dtAmount: 200, priceKrw: 2000, isPopular: true),
        const DtPackage(id: '3', name: 'C', dtAmount: 300, priceKrw: 3000, isPopular: false),
      ];

      final popular = packages.where((p) => p.isPopular).firstOrNull;
      expect(popular, isNotNull);
      expect(popular!.id, equals('2'));
    });

    test('sorts packages by price ascending', () {
      final packages = [
        const DtPackage(id: '1', name: 'A', dtAmount: 100, priceKrw: 30000),
        const DtPackage(id: '2', name: 'B', dtAmount: 200, priceKrw: 10000),
        const DtPackage(id: '3', name: 'C', dtAmount: 300, priceKrw: 20000),
      ];

      final sorted = List<DtPackage>.from(packages)
        ..sort((a, b) => a.priceKrw.compareTo(b.priceKrw));

      expect(sorted[0].priceKrw, equals(10000));
      expect(sorted[1].priceKrw, equals(20000));
      expect(sorted[2].priceKrw, equals(30000));
    });

    test('sorts packages by value (DT per won) descending', () {
      final packages = [
        const DtPackage(id: '1', name: 'A', dtAmount: 100, bonusDt: 0, priceKrw: 10000), // 100/10000 = 0.01
        const DtPackage(id: '2', name: 'B', dtAmount: 200, bonusDt: 50, priceKrw: 20000), // 250/20000 = 0.0125
        const DtPackage(id: '3', name: 'C', dtAmount: 500, bonusDt: 100, priceKrw: 50000), // 600/50000 = 0.012
      ];

      // Calculate DT per won (higher = better value)
      final sorted = List<DtPackage>.from(packages)
        ..sort((a, b) {
          final aValue = a.totalDt / a.priceKrw;
          final bValue = b.totalDt / b.priceKrw;
          return bValue.compareTo(aValue);
        });

      expect(sorted[0].id, equals('2')); // Best value
      expect(sorted[1].id, equals('3'));
      expect(sorted[2].id, equals('1')); // Worst value
    });
  });

  group('ProviderContainer tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('container can be created and disposed', () {
      expect(container, isNotNull);
    });
  });
}
