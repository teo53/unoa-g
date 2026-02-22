import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/services/wallet_service.dart';

void main() {
  late WalletService service;

  setUp(() {
    service = WalletService();
  });

  // ---------------------------------------------------------------------------
  // WalletResult factories
  // ---------------------------------------------------------------------------
  group('WalletResult', () {
    group('.success factory', () {
      test('isSuccess is true', () {
        final result = WalletResult.success();
        expect(result.success, isTrue);
      });

      test('errorCode and errorMessage are null', () {
        final result = WalletResult.success();
        expect(result.errorCode, isNull);
        expect(result.errorMessage, isNull);
      });

      test('carries optional newBalance', () {
        final result = WalletResult.success(newBalance: 5000);
        expect(result.newBalance, equals(5000));
      });

      test('carries optional transactionId', () {
        final result = WalletResult.success(transactionId: 'txn-abc');
        expect(result.transactionId, equals('txn-abc'));
      });

      test('newBalance and transactionId default to null', () {
        final result = WalletResult.success();
        expect(result.newBalance, isNull);
        expect(result.transactionId, isNull);
      });
    });

    group('.error factory', () {
      test('isSuccess is false', () {
        final result = WalletResult.error('ERR', 'message');
        expect(result.success, isFalse);
      });

      test('stores errorCode and errorMessage', () {
        final result = WalletResult.error('MY_CODE', 'My message');
        expect(result.errorCode, equals('MY_CODE'));
        expect(result.errorMessage, equals('My message'));
      });
    });

    group('.insufficientBalance factory', () {
      test('isSuccess is false', () {
        expect(WalletResult.insufficientBalance().success, isFalse);
      });

      test('errorCode is INSUFFICIENT_BALANCE', () {
        expect(
          WalletResult.insufficientBalance().errorCode,
          equals('INSUFFICIENT_BALANCE'),
        );
      });

      test('errorMessage is non-empty', () {
        expect(
          WalletResult.insufficientBalance().errorMessage,
          isNotEmpty,
        );
      });
    });

    group('.invalidAmount factory', () {
      test('isSuccess is false', () {
        expect(WalletResult.invalidAmount().success, isFalse);
      });

      test('errorCode is INVALID_AMOUNT', () {
        expect(
          WalletResult.invalidAmount().errorCode,
          equals('INVALID_AMOUNT'),
        );
      });
    });

    group('.unauthorized factory', () {
      test('isSuccess is false', () {
        expect(WalletResult.unauthorized().success, isFalse);
      });

      test('errorCode is UNAUTHORIZED', () {
        expect(WalletResult.unauthorized().errorCode, equals('UNAUTHORIZED'));
      });
    });

    group('.refundNotAllowed factory', () {
      test('isSuccess is false', () {
        expect(WalletResult.refundNotAllowed().success, isFalse);
      });

      test('errorCode is REFUND_NOT_ALLOWED', () {
        expect(
          WalletResult.refundNotAllowed().errorCode,
          equals('REFUND_NOT_ALLOWED'),
        );
      });
    });

    group('.refundExpired factory', () {
      test('isSuccess is false', () {
        expect(WalletResult.refundExpired().success, isFalse);
      });

      test('errorCode is REFUND_EXPIRED', () {
        expect(
          WalletResult.refundExpired().errorCode,
          equals('REFUND_EXPIRED'),
        );
      });
    });
  });

  // ---------------------------------------------------------------------------
  // WalletService.validateDonation
  // ---------------------------------------------------------------------------
  group('WalletService.validateDonation', () {
    test('returns error when amountDt is below minimum (99 DT)', () {
      final result = service.validateDonation(
        amountDt: 99,
        currentBalance: 10000,
      );
      expect(result, isNotNull);
      expect(result!.success, isFalse);
      expect(result.errorCode, equals('MINIMUM_AMOUNT'));
    });

    test('returns error when amountDt is exactly 0', () {
      final result = service.validateDonation(
        amountDt: 0,
        currentBalance: 10000,
      );
      expect(result, isNotNull);
      expect(result!.errorCode, equals('MINIMUM_AMOUNT'));
    });

    test('returns error when amountDt is exactly minimum minus 1 (99)', () {
      final result = service.validateDonation(
        amountDt: 99,
        currentBalance: 10000,
      );
      expect(result!.errorCode, equals('MINIMUM_AMOUNT'));
    });

    test('returns null when amountDt equals minimum (100 DT)', () {
      final result = service.validateDonation(
        amountDt: 100,
        currentBalance: 10000,
      );
      expect(result, isNull);
    });

    test('returns error when amountDt exceeds maximum (1,000,001 DT)', () {
      final result = service.validateDonation(
        amountDt: 1000001,
        currentBalance: 2000000,
      );
      expect(result, isNotNull);
      expect(result!.errorCode, equals('MAXIMUM_AMOUNT'));
    });

    test('returns null when amountDt equals maximum (1,000,000 DT)', () {
      final result = service.validateDonation(
        amountDt: 1000000,
        currentBalance: 1000000,
      );
      expect(result, isNull);
    });

    test('returns insufficientBalance when balance is less than amount', () {
      final result = service.validateDonation(
        amountDt: 500,
        currentBalance: 499,
      );
      expect(result, isNotNull);
      expect(result!.errorCode, equals('INSUFFICIENT_BALANCE'));
    });

    test('returns null when balance equals amount exactly', () {
      final result = service.validateDonation(
        amountDt: 500,
        currentBalance: 500,
      );
      expect(result, isNull);
    });

    test('returns null when balance exceeds amount (valid donation)', () {
      final result = service.validateDonation(
        amountDt: 300,
        currentBalance: 1000,
      );
      expect(result, isNull);
    });

    test('minimum check takes priority over balance check', () {
      // amountDt=50 is below minimum regardless of balance
      final result = service.validateDonation(
        amountDt: 50,
        currentBalance: 0,
      );
      expect(result!.errorCode, equals('MINIMUM_AMOUNT'));
    });
  });

  // ---------------------------------------------------------------------------
  // WalletService.calculateDonationDistribution
  // ---------------------------------------------------------------------------
  group('WalletService.calculateDonationDistribution', () {
    test('creator + platform shares always equal total', () {
      for (final amount in [1, 100, 333, 1000, 9999]) {
        final dist = service.calculateDonationDistribution(amount);
        expect(
          dist.creatorShareDt + dist.platformShareDt,
          equals(dist.totalDt),
          reason: 'Failed for amount=$amount',
        );
      }
    });

    test('boundary: 1 DT — creator gets 0, platform gets 1', () {
      final dist = service.calculateDonationDistribution(1);
      expect(dist.totalDt, equals(1));
      expect(dist.creatorShareDt, equals(0)); // floor(1 * 0.80) = 0
      expect(dist.platformShareDt, equals(1));
    });

    test('minimum donation: 100 DT — 80/20 split', () {
      final dist = service.calculateDonationDistribution(100);
      expect(dist.creatorShareDt, equals(80));
      expect(dist.platformShareDt, equals(20));
    });

    test('1000 DT — creator 800, platform 200', () {
      final dist = service.calculateDonationDistribution(1000);
      expect(dist.creatorShareDt, equals(800));
      expect(dist.platformShareDt, equals(200));
    });

    test('krw fields are DT amount * 100', () {
      final dist = service.calculateDonationDistribution(100);
      expect(dist.creatorShareKrw, equals(80 * 100));
      expect(dist.platformShareKrw, equals(20 * 100));
    });

    test('odd amount (333 DT) floors creator share correctly', () {
      // 333 * 0.80 = 266.4 → floor → 266
      final dist = service.calculateDonationDistribution(333);
      expect(dist.creatorShareDt, equals(266));
      expect(dist.platformShareDt, equals(67)); // 333 - 266
      expect(dist.creatorShareDt + dist.platformShareDt, equals(333));
    });

    test('totalDt field matches input amount', () {
      final dist = service.calculateDonationDistribution(500);
      expect(dist.totalDt, equals(500));
    });
  });

  // ---------------------------------------------------------------------------
  // WalletService.dtToKrw / krwToDt
  // ---------------------------------------------------------------------------
  group('WalletService.dtToKrw', () {
    test('0 DT converts to 0 KRW', () {
      expect(service.dtToKrw(0), equals(0));
    });

    test('1 DT converts to 100 KRW', () {
      expect(service.dtToKrw(1), equals(100));
    });

    test('100 DT converts to 10,000 KRW', () {
      expect(service.dtToKrw(100), equals(10000));
    });

    test('10,000 DT converts to 1,000,000 KRW', () {
      expect(service.dtToKrw(10000), equals(1000000));
    });
  });

  group('WalletService.krwToDt', () {
    test('0 KRW converts to 0 DT', () {
      expect(service.krwToDt(0), equals(0));
    });

    test('100 KRW converts to 1 DT', () {
      expect(service.krwToDt(100), equals(1));
    });

    test('150 KRW truncates to 1 DT (integer division)', () {
      expect(service.krwToDt(150), equals(1));
    });

    test('99 KRW truncates to 0 DT', () {
      expect(service.krwToDt(99), equals(0));
    });

    test('10,000 KRW converts to 100 DT', () {
      expect(service.krwToDt(10000), equals(100));
    });

    test('dtToKrw and krwToDt are inverse for multiples of unit price', () {
      const dt = 500;
      expect(service.krwToDt(service.dtToKrw(dt)), equals(dt));
    });
  });

  // ---------------------------------------------------------------------------
  // WalletService.formatDt / formatKrw
  // ---------------------------------------------------------------------------
  group('WalletService.formatDt', () {
    test('formats small number without commas', () {
      expect(service.formatDt(100), equals('100 DT'));
    });

    test('formats 1,000 with comma', () {
      expect(service.formatDt(1000), equals('1,000 DT'));
    });

    test('formats 1,000,000 with commas', () {
      expect(service.formatDt(1000000), equals('1,000,000 DT'));
    });

    test('formats 0 correctly', () {
      expect(service.formatDt(0), equals('0 DT'));
    });

    test('formats large number with multiple commas', () {
      expect(service.formatDt(1234567), equals('1,234,567 DT'));
    });
  });

  group('WalletService.formatKrw', () {
    test('formats small number with won prefix', () {
      expect(service.formatKrw(100), equals('₩100'));
    });

    test('formats 1,000 with comma and won prefix', () {
      expect(service.formatKrw(1000), equals('₩1,000'));
    });

    test('formats 1,000,000 with commas and won prefix', () {
      expect(service.formatKrw(1000000), equals('₩1,000,000'));
    });

    test('formats 0 correctly', () {
      expect(service.formatKrw(0), equals('₩0'));
    });

    test('formats 49,000 correctly', () {
      expect(service.formatKrw(49000), equals('₩49,000'));
    });
  });

  // ---------------------------------------------------------------------------
  // WalletService.validateRefund
  // ---------------------------------------------------------------------------
  group('WalletService.validateRefund', () {
    test('returns null when purchase was today and no DT used', () {
      final result = service.validateRefund(
        purchaseDate: DateTime.now(),
        purchasedDt: 1000,
        usedDt: 0,
      );
      expect(result, isNull);
    });

    test('returns null when purchase was 7 days ago (boundary, inclusive)', () {
      // inDays = 7 is NOT > 7, so should still be allowed
      final purchaseDate = DateTime.now().subtract(const Duration(days: 7));
      final result = service.validateRefund(
        purchaseDate: purchaseDate,
        purchasedDt: 1000,
        usedDt: 0,
      );
      expect(result, isNull);
    });

    test('returns refundExpired when purchase was 8 days ago', () {
      final purchaseDate = DateTime.now().subtract(const Duration(days: 8));
      final result = service.validateRefund(
        purchaseDate: purchaseDate,
        purchasedDt: 1000,
        usedDt: 0,
      );
      expect(result, isNotNull);
      expect(result!.errorCode, equals('REFUND_EXPIRED'));
    });

    test('returns refundExpired for purchases far in the past', () {
      final purchaseDate = DateTime.now().subtract(const Duration(days: 365));
      final result = service.validateRefund(
        purchaseDate: purchaseDate,
        purchasedDt: 1000,
        usedDt: 0,
      );
      expect(result!.errorCode, equals('REFUND_EXPIRED'));
    });

    test('returns refundNotAllowed when usedDt > 0 within period', () {
      final result = service.validateRefund(
        purchaseDate: DateTime.now().subtract(const Duration(days: 1)),
        purchasedDt: 1000,
        usedDt: 1,
      );
      expect(result, isNotNull);
      expect(result!.errorCode, equals('REFUND_NOT_ALLOWED'));
    });

    test('returns refundNotAllowed when all DT has been used', () {
      final result = service.validateRefund(
        purchaseDate: DateTime.now(),
        purchasedDt: 1000,
        usedDt: 1000,
      );
      expect(result!.errorCode, equals('REFUND_NOT_ALLOWED'));
    });

    test('expiry check runs before used-DT check', () {
      // Both expired AND used — expiry should win because it's checked first
      final purchaseDate = DateTime.now().subtract(const Duration(days: 30));
      final result = service.validateRefund(
        purchaseDate: purchaseDate,
        purchasedDt: 1000,
        usedDt: 500,
      );
      expect(result!.errorCode, equals('REFUND_EXPIRED'));
    });
  });

  // ---------------------------------------------------------------------------
  // WalletService.calculateRefundAmount
  // ---------------------------------------------------------------------------
  group('WalletService.calculateRefundAmount', () {
    test('full refund when nothing used and no bonus', () {
      final amount = service.calculateRefundAmount(
        purchasedDt: 1000,
        bonusDt: 0,
        usedDt: 0,
      );
      expect(amount, equals(1000));
    });

    test('bonus DT is not refundable', () {
      final amount = service.calculateRefundAmount(
        purchasedDt: 1000,
        bonusDt: 200,
        usedDt: 0,
      );
      // Only purchasedDt is refundable
      expect(amount, equals(1000));
    });

    test('partial refund when some DT used', () {
      final amount = service.calculateRefundAmount(
        purchasedDt: 1000,
        bonusDt: 0,
        usedDt: 300,
      );
      expect(amount, equals(700));
    });

    test('returns 0 when usedDt equals purchasedDt', () {
      final amount = service.calculateRefundAmount(
        purchasedDt: 1000,
        bonusDt: 0,
        usedDt: 1000,
      );
      expect(amount, equals(0));
    });

    test('returns 0 when usedDt exceeds purchasedDt (clamped)', () {
      final amount = service.calculateRefundAmount(
        purchasedDt: 1000,
        bonusDt: 200,
        usedDt: 1100,
      );
      // 1000 - 1100 = -100, clamped to 0
      expect(amount, equals(0));
    });

    test('returns 0 when all purchased and bonus was used', () {
      final amount = service.calculateRefundAmount(
        purchasedDt: 500,
        bonusDt: 100,
        usedDt: 600,
      );
      expect(amount, equals(0));
    });
  });

  // ---------------------------------------------------------------------------
  // DtPackageDetails computed properties
  // ---------------------------------------------------------------------------
  group('DtPackageDetails', () {
    DtPackageDetails makePackage({
      String packageId = 'pkg-1',
      String name = '기본 패키지',
      int dtAmount = 100,
      int bonusDt = 0,
      int priceKrw = 10000,
      bool isPopular = false,
    }) {
      return DtPackageDetails(
        packageId: packageId,
        name: name,
        dtAmount: dtAmount,
        bonusDt: bonusDt,
        priceKrw: priceKrw,
        isPopular: isPopular,
      );
    }

    group('totalDt', () {
      test('returns dtAmount when no bonus', () {
        final pkg = makePackage(dtAmount: 100, bonusDt: 0);
        expect(pkg.totalDt, equals(100));
      });

      test('sums dtAmount and bonusDt', () {
        final pkg = makePackage(dtAmount: 100, bonusDt: 25);
        expect(pkg.totalDt, equals(125));
      });

      test('handles large amounts', () {
        final pkg = makePackage(dtAmount: 10000, bonusDt: 2000);
        expect(pkg.totalDt, equals(12000));
      });
    });

    group('pricePerDt', () {
      test('calculates correctly without bonus', () {
        final pkg = makePackage(dtAmount: 100, bonusDt: 0, priceKrw: 10000);
        // 10000 / 100 = 100.0
        expect(pkg.pricePerDt, equals(100.0));
      });

      test('accounts for bonus DT in denominator', () {
        final pkg = makePackage(dtAmount: 100, bonusDt: 25, priceKrw: 10000);
        // 10000 / 125 = 80.0
        expect(pkg.pricePerDt, equals(80.0));
      });
    });

    group('discountPercent', () {
      test('returns 0 when price equals base rate', () {
        // dtAmount=100, bonus=0 → totalDt=100, basePrice=100*100=10000
        final pkg = makePackage(dtAmount: 100, bonusDt: 0, priceKrw: 10000);
        expect(pkg.discountPercent, equals(0.0));
      });

      test('calculates discount when bonus DT is given', () {
        // dtAmount=100, bonus=25 → totalDt=125, basePrice=125*100=12500
        // discount = (12500 - 10000) / 12500 * 100 = 20%
        final pkg = makePackage(dtAmount: 100, bonusDt: 25, priceKrw: 10000);
        expect(pkg.discountPercent, closeTo(20.0, 0.01));
      });

      test('clamps to 0 when package price exceeds base rate', () {
        // priceKrw higher than base — no negative discount
        final pkg = makePackage(dtAmount: 100, bonusDt: 0, priceKrw: 15000);
        expect(pkg.discountPercent, equals(0.0));
      });

      test('clamps to 100 at maximum discount', () {
        // If price is 0, discount would be 100%
        final pkg = makePackage(dtAmount: 100, bonusDt: 0, priceKrw: 0);
        expect(pkg.discountPercent, equals(100.0));
      });
    });

    group('formattedPrice', () {
      test('formats with won prefix', () {
        final pkg = makePackage(priceKrw: 9900);
        expect(pkg.formattedPrice, equals('₩9,900'));
      });

      test('formats small amount without commas', () {
        final pkg = makePackage(priceKrw: 100);
        expect(pkg.formattedPrice, equals('₩100'));
      });

      test('formats million-range amounts with commas', () {
        final pkg = makePackage(priceKrw: 1000000);
        expect(pkg.formattedPrice, equals('₩1,000,000'));
      });

      test('formats 0 correctly', () {
        final pkg = makePackage(priceKrw: 0);
        expect(pkg.formattedPrice, equals('₩0'));
      });
    });

    group('bonusText', () {
      test('returns empty string when bonusDt is 0', () {
        final pkg = makePackage(bonusDt: 0);
        expect(pkg.bonusText, isEmpty);
      });

      test('returns empty string when bonusDt is negative', () {
        final pkg = makePackage(bonusDt: -1);
        expect(pkg.bonusText, isEmpty);
      });

      test('formats bonus with + prefix and 보너스 suffix', () {
        final pkg = makePackage(bonusDt: 50);
        expect(pkg.bonusText, equals('+50 보너스'));
      });

      test('formats large bonus amount', () {
        final pkg = makePackage(bonusDt: 2000);
        expect(pkg.bonusText, equals('+2000 보너스'));
      });
    });

    group('isPopular flag', () {
      test('defaults to false', () {
        const pkg = DtPackageDetails(
          packageId: 'p',
          name: 'n',
          dtAmount: 100,
          bonusDt: 0,
          priceKrw: 10000,
        );
        expect(pkg.isPopular, isFalse);
      });

      test('can be set to true', () {
        final pkg = makePackage(isPopular: true);
        expect(pkg.isPopular, isTrue);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // DonationDistribution.toString
  // ---------------------------------------------------------------------------
  group('DonationDistribution.toString', () {
    test('contains total DT', () {
      final dist = service.calculateDonationDistribution(1000);
      expect(dist.toString(), contains('1000'));
    });

    test('contains creator share DT', () {
      final dist = service.calculateDonationDistribution(1000);
      // creatorShareDt = 800
      expect(dist.toString(), contains('800'));
    });

    test('contains platform share DT', () {
      final dist = service.calculateDonationDistribution(1000);
      // platformShareDt = 200
      expect(dist.toString(), contains('200'));
    });

    test('contains percentage indicators', () {
      final dist = service.calculateDonationDistribution(1000);
      expect(dist.toString(), contains('%'));
    });

    test('full format matches expected pattern for 100 DT', () {
      final dist = service.calculateDonationDistribution(100);
      final str = dist.toString();
      // Should be: DonationDistribution(total: 100 DT, creator: 80 DT (80%), platform: 20 DT (20%))
      expect(str, contains('total:'));
      expect(str, contains('creator:'));
      expect(str, contains('platform:'));
      expect(str, contains('80'));
      expect(str, contains('20'));
    });

    test('1 DT boundary — 0% creator, 100% platform', () {
      final dist = service.calculateDonationDistribution(1);
      final str = dist.toString();
      expect(str, contains('0'));
      // Platform gets 100%
      expect(str, contains('100'));
    });
  });

  // ---------------------------------------------------------------------------
  // WalletService constants
  // ---------------------------------------------------------------------------
  group('WalletService constants', () {
    test('creatorShareRate is 0.80', () {
      expect(WalletService.creatorShareRate, equals(0.80));
    });

    test('platformShareRate is 0.20', () {
      expect(WalletService.platformShareRate, equals(0.20));
    });

    test('creatorShareRate + platformShareRate = 1.0', () {
      expect(
        WalletService.creatorShareRate + WalletService.platformShareRate,
        closeTo(1.0, 0.0001),
      );
    });

    test('dtUnitPriceKrw is 100', () {
      expect(WalletService.dtUnitPriceKrw, equals(100));
    });

    test('minimumDonationDt is 100', () {
      expect(WalletService.minimumDonationDt, equals(100));
    });

    test('maximumDonationDt is 1,000,000', () {
      expect(WalletService.maximumDonationDt, equals(1000000));
    });

    test('refundPeriodDays is 7', () {
      expect(WalletService.refundPeriodDays, equals(7));
    });
  });
}
