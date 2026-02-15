import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/services/wallet_service.dart';

/// Integration tests for the payment flow
///
/// Tests the complete flow from:
/// 1. Selecting a DT package
/// 2. Wallet validation (donation limits, refund eligibility)
/// 3. Atomic transaction logic (distribution, refund calculation)
/// 4. Idempotency & edge cases
void main() {
  late WalletService walletService;

  setUp(() {
    walletService = WalletService();
  });

  group('Payment Flow — DT Purchase Validation', () {
    test('complete purchase flow should compute correct distribution', () {
      // User purchases 100 DT package (₩10,000)
      // Platform takes 20%, creator gets 80%

      final distribution =
          walletService.calculateDonationDistribution(100);

      expect(distribution.totalDt, 100);
      expect(distribution.creatorShareDt, 80);
      expect(distribution.platformShareDt, 20);
      expect(distribution.creatorShareKrw, 80 * WalletService.dtUnitPriceKrw);
      expect(distribution.platformShareKrw, 20 * WalletService.dtUnitPriceKrw);
    });

    test('large donation distribution should not lose DT to rounding', () {
      // For 999 DT: creator floor(999*0.8) = 799, platform 999-799 = 200
      final distribution =
          walletService.calculateDonationDistribution(999);

      expect(distribution.creatorShareDt + distribution.platformShareDt,
          distribution.totalDt);
      expect(distribution.creatorShareDt, 799);
      expect(distribution.platformShareDt, 200);
    });

    test('minimum donation (100 DT) distribution is correct', () {
      final distribution =
          walletService.calculateDonationDistribution(WalletService.minimumDonationDt);

      expect(distribution.totalDt, 100);
      expect(distribution.creatorShareDt, 80);
      expect(distribution.platformShareDt, 20);
    });

    test('DT to KRW conversion should use unit price', () {
      expect(walletService.dtToKrw(100), 100 * WalletService.dtUnitPriceKrw);
      expect(walletService.dtToKrw(0), 0);
      expect(walletService.dtToKrw(1), WalletService.dtUnitPriceKrw);
    });

    test('KRW to DT conversion should truncate (floor division)', () {
      expect(walletService.krwToDt(10000), 10000 ~/ WalletService.dtUnitPriceKrw);
      expect(walletService.krwToDt(0), 0);
      // Fractional remainder should be discarded
      expect(walletService.krwToDt(150), 150 ~/ WalletService.dtUnitPriceKrw);
    });
  });

  group('Payment Flow — Donation Validation', () {
    test('valid donation within balance should pass', () {
      final result = walletService.validateDonation(
        amountDt: 500,
        currentBalance: 1000,
      );

      // null means validation passed
      expect(result, isNull);
    });

    test('donation equal to balance should pass', () {
      final result = walletService.validateDonation(
        amountDt: 1000,
        currentBalance: 1000,
      );

      expect(result, isNull);
    });

    test('donation exceeding balance should fail with INSUFFICIENT_BALANCE', () {
      final result = walletService.validateDonation(
        amountDt: 1001,
        currentBalance: 1000,
      );

      expect(result, isNotNull);
      expect(result!.success, false);
      expect(result.errorCode, 'INSUFFICIENT_BALANCE');
    });

    test('donation below minimum should fail with MINIMUM_AMOUNT', () {
      final result = walletService.validateDonation(
        amountDt: WalletService.minimumDonationDt - 1,
        currentBalance: 10000,
      );

      expect(result, isNotNull);
      expect(result!.success, false);
      expect(result.errorCode, 'MINIMUM_AMOUNT');
    });

    test('donation above maximum should fail with MAXIMUM_AMOUNT', () {
      final result = walletService.validateDonation(
        amountDt: WalletService.maximumDonationDt + 1,
        currentBalance: WalletService.maximumDonationDt + 100,
      );

      expect(result, isNotNull);
      expect(result!.success, false);
      expect(result.errorCode, 'MAXIMUM_AMOUNT');
    });

    test('donation at exact minimum boundary should pass', () {
      final result = walletService.validateDonation(
        amountDt: WalletService.minimumDonationDt,
        currentBalance: WalletService.minimumDonationDt,
      );

      expect(result, isNull);
    });

    test('donation at exact maximum boundary should pass', () {
      final result = walletService.validateDonation(
        amountDt: WalletService.maximumDonationDt,
        currentBalance: WalletService.maximumDonationDt,
      );

      expect(result, isNull);
    });
  });

  group('Refund Validation', () {
    test('refund within 7 days with no usage should pass', () {
      final result = walletService.validateRefund(
        purchaseDate: DateTime.now().subtract(const Duration(days: 3)),
        purchasedDt: 100,
        usedDt: 0,
      );

      expect(result, isNull);
    });

    test('refund after 7 days should fail with REFUND_EXPIRED', () {
      final result = walletService.validateRefund(
        purchaseDate: DateTime.now().subtract(const Duration(days: 8)),
        purchasedDt: 100,
        usedDt: 0,
      );

      expect(result, isNotNull);
      expect(result!.success, false);
      expect(result.errorCode, 'REFUND_EXPIRED');
    });

    test('refund with used DT should fail with REFUND_NOT_ALLOWED', () {
      final result = walletService.validateRefund(
        purchaseDate: DateTime.now().subtract(const Duration(days: 1)),
        purchasedDt: 100,
        usedDt: 50,
      );

      expect(result, isNotNull);
      expect(result!.success, false);
      expect(result.errorCode, 'REFUND_NOT_ALLOWED');
    });

    test('refund on exactly day 7 should pass', () {
      final result = walletService.validateRefund(
        purchaseDate: DateTime.now().subtract(const Duration(days: 7)),
        purchasedDt: 100,
        usedDt: 0,
      );

      expect(result, isNull);
    });

    test('refund on day 0 (same day) should pass', () {
      final result = walletService.validateRefund(
        purchaseDate: DateTime.now(),
        purchasedDt: 500,
        usedDt: 0,
      );

      expect(result, isNull);
    });
  });

  group('Refund Amount Calculation', () {
    test('full refund when no DT used', () {
      final amount = walletService.calculateRefundAmount(
        purchasedDt: 100,
        bonusDt: 5,
        usedDt: 0,
      );

      // Only purchased DT is refundable, not bonus
      expect(amount, 100);
    });

    test('partial refund is not applicable (usedDt > 0 means no refund)', () {
      // Even though calculation returns partial, validateRefund blocks it
      final amount = walletService.calculateRefundAmount(
        purchasedDt: 100,
        bonusDt: 5,
        usedDt: 30,
      );

      expect(amount, 70); // 100 - 30
    });

    test('bonus DT is never refundable', () {
      final amount = walletService.calculateRefundAmount(
        purchasedDt: 100,
        bonusDt: 50,
        usedDt: 0,
      );

      // Bonus not included in refund
      expect(amount, 100);
    });

    test('fully used DT returns zero refund', () {
      final amount = walletService.calculateRefundAmount(
        purchasedDt: 100,
        bonusDt: 5,
        usedDt: 100,
      );

      expect(amount, 0);
    });

    test('used more than purchased returns zero (not negative)', () {
      final amount = walletService.calculateRefundAmount(
        purchasedDt: 100,
        bonusDt: 50,
        usedDt: 120,
      );

      expect(amount, 0);
    });
  });

  group('WalletResult Factories', () {
    test('success result has correct properties', () {
      final result = WalletResult.success(
        newBalance: 500,
        transactionId: 'tx-123',
      );

      expect(result.success, true);
      expect(result.newBalance, 500);
      expect(result.transactionId, 'tx-123');
      expect(result.errorCode, isNull);
      expect(result.errorMessage, isNull);
    });

    test('error result has correct properties', () {
      final result = WalletResult.error('TEST_ERROR', 'Test message');

      expect(result.success, false);
      expect(result.errorCode, 'TEST_ERROR');
      expect(result.errorMessage, 'Test message');
      expect(result.newBalance, isNull);
    });

    test('common error factories produce distinct codes', () {
      final insufficient = WalletResult.insufficientBalance();
      final invalid = WalletResult.invalidAmount();
      final unauthorized = WalletResult.unauthorized();
      final refundNotAllowed = WalletResult.refundNotAllowed();
      final refundExpired = WalletResult.refundExpired();

      final codes = {
        insufficient.errorCode,
        invalid.errorCode,
        unauthorized.errorCode,
        refundNotAllowed.errorCode,
        refundExpired.errorCode,
      };

      // All error codes must be unique
      expect(codes.length, 5);

      // All should be failures
      expect(insufficient.success, false);
      expect(invalid.success, false);
      expect(unauthorized.success, false);
      expect(refundNotAllowed.success, false);
      expect(refundExpired.success, false);
    });
  });

  group('DT Formatting', () {
    test('formatDt formats with comma separator', () {
      expect(walletService.formatDt(1000), '1,000 DT');
      expect(walletService.formatDt(0), '0 DT');
      expect(walletService.formatDt(999999), '999,999 DT');
    });

    test('formatKrw formats with won symbol and comma', () {
      expect(walletService.formatKrw(10000), '₩10,000');
      expect(walletService.formatKrw(0), '₩0');
      expect(walletService.formatKrw(1000000), '₩1,000,000');
    });
  });

  group('DtPackageDetails', () {
    test('totalDt includes bonus', () {
      const pkg = DtPackageDetails(
        packageId: 'dt_100',
        name: '100 DT',
        dtAmount: 100,
        bonusDt: 5,
        priceKrw: 10000,
      );

      expect(pkg.totalDt, 105);
    });

    test('pricePerDt accounts for bonus', () {
      const pkg = DtPackageDetails(
        packageId: 'dt_100',
        name: '100 DT',
        dtAmount: 100,
        bonusDt: 0,
        priceKrw: 10000,
      );

      expect(pkg.pricePerDt, 100.0);
    });

    test('formattedPrice uses won symbol with commas', () {
      const pkg = DtPackageDetails(
        packageId: 'dt_1000',
        name: '1,000 DT',
        dtAmount: 1000,
        bonusDt: 150,
        priceKrw: 100000,
      );

      expect(pkg.formattedPrice, '₩100,000');
    });

    test('bonusText is empty when no bonus', () {
      const pkg = DtPackageDetails(
        packageId: 'dt_10',
        name: '10 DT',
        dtAmount: 10,
        bonusDt: 0,
        priceKrw: 1000,
      );

      expect(pkg.bonusText, '');
    });

    test('bonusText shows bonus when present', () {
      const pkg = DtPackageDetails(
        packageId: 'dt_500',
        name: '500 DT',
        dtAmount: 500,
        bonusDt: 50,
        priceKrw: 50000,
      );

      expect(pkg.bonusText, '+50 보너스');
    });

    test('discountPercent is correct for bulk packages', () {
      const pkg = DtPackageDetails(
        packageId: 'dt_5000',
        name: '5,000 DT',
        dtAmount: 5000,
        bonusDt: 1000,
        priceKrw: 500000,
      );

      // Base price = 6000 * 100 = 600,000 KRW
      // Discount = (600000 - 500000) / 600000 * 100 ≈ 16.67%
      final basePrice = pkg.totalDt * WalletService.dtUnitPriceKrw;
      final expectedDiscount = (basePrice - pkg.priceKrw) / basePrice * 100;
      expect(pkg.discountPercent, closeTo(expectedDiscount, 0.01));
      expect(pkg.discountPercent, greaterThan(0));
    });
  });
}
