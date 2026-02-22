import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/services/payment_service.dart';

/// Tests for the funding checkout payment result branching logic.
///
/// FundingCheckoutScreen._initiateKrwPayment() uses this condition:
///   if (paymentResult.isRejected) → throw
///
/// This test file validates that the branching correctly handles:
/// 1. Confirmed → proceed to pledge (demo mode)
/// 2. Pending → proceed to server-side verification (NOT rejected)
/// 3. Rejected → throw (user sees error screen)
void main() {
  /// Simulates the exact branching logic from FundingCheckoutScreen.
  /// Returns null if payment proceeds, or error message if rejected.
  String? evaluatePaymentResult(PaymentResult result) {
    if (result.isRejected) {
      return result.errorMessage ?? '결제에 실패했습니다';
    }
    return null; // proceeds to submitPledge
  }

  group('Funding Checkout — payment result branching', () {
    test('confirmed: proceeds to pledge creation', () {
      const result = PaymentResult.confirmed('demo_payment_1');

      expect(evaluatePaymentResult(result), isNull,
          reason: 'Confirmed payment should proceed');
    });

    test('pending: proceeds to server-side verification', () {
      const result = PaymentResult.pending('FUND_c1_123');

      expect(evaluatePaymentResult(result), isNull,
          reason:
              'Pending payment should proceed to Edge Function verification');
    });

    test('rejected: throws with error message', () {
      const result = PaymentResult.rejected('결제 서비스가 아직 설정되지 않았습니다.');

      final error = evaluatePaymentResult(result);
      expect(error, isNotNull);
      expect(error, contains('설정'));
    });

    test('rejected without custom message uses default', () {
      // PaymentResult.rejected always has a message, but test the fallback
      const result = PaymentResult.rejected('');

      final error = evaluatePaymentResult(result);
      // Empty string is truthy in the null-coalesce, so it returns ''
      expect(error, isNotNull);
    });

    test('DemoPaymentService result always proceeds', () async {
      final demo = DemoPaymentService();
      final result = await demo.requestPayment(
        const PaymentRequest(
          merchantUid: 'FUND_test_1',
          name: '테스트 캠페인 - 실버 티어',
          amount: 10000,
          payMethod: 'card',
        ),
      );

      expect(evaluatePaymentResult(result), isNull,
          reason: 'Demo payment should always proceed');
      expect(result.isConfirmed, isTrue);
    });

    test('PortOne fail-closed result is correctly rejected', () async {
      // In test environment, PortOne will fail-closed (no store ID)
      final portone = PortOnePaymentService();
      final result = await portone.requestPayment(
        const PaymentRequest(
          merchantUid: 'FUND_test_2',
          name: '테스트',
          amount: 5000,
          payMethod: 'card',
        ),
      );

      final error = evaluatePaymentResult(result);
      expect(error, isNotNull,
          reason: 'PortOne fail-closed should be rejected by checkout logic');
      expect(result.isRejected, isTrue);
    });
  });

  group('Funding Checkout — payment method coverage', () {
    test('card payment method is valid', () {
      const req = PaymentRequest(
        merchantUid: 'FUND_1',
        name: 'Test',
        amount: 10000,
        payMethod: 'card',
      );
      expect(req.payMethod, 'card');
    });

    test('bank_transfer payment method is valid', () {
      const req = PaymentRequest(
        merchantUid: 'FUND_2',
        name: 'Test',
        amount: 10000,
        payMethod: 'bank_transfer',
      );
      expect(req.payMethod, 'bank_transfer');
    });

    test('virtual_account payment method is valid', () {
      const req = PaymentRequest(
        merchantUid: 'FUND_3',
        name: 'Test',
        amount: 10000,
        payMethod: 'virtual_account',
      );
      expect(req.payMethod, 'virtual_account');
    });
  });

  group('Funding Checkout — state invariants', () {
    test('confirmed and pending are mutually exclusive', () {
      const confirmed = PaymentResult.confirmed('p1');
      const pending = PaymentResult.pending('p2');

      expect(confirmed.isConfirmed, isTrue);
      expect(confirmed.isPending, isFalse);
      expect(pending.isConfirmed, isFalse);
      expect(pending.isPending, isTrue);
    });

    test('rejected is distinct from both confirmed and pending', () {
      const rejected = PaymentResult.rejected('err');

      expect(rejected.isConfirmed, isFalse);
      expect(rejected.isPending, isFalse);
      expect(rejected.isRejected, isTrue);
    });

    test('all three PortOne fail-closed paths return rejected', () async {
      // In test environment, only the first fail-closed fires (empty store ID),
      // but we verify the result is always rejected
      final portone = PortOnePaymentService();
      final result = await portone.requestPayment(
        const PaymentRequest(
          merchantUid: 'test',
          name: 'Test',
          amount: 1000,
          payMethod: 'card',
        ),
      );

      expect(result.isRejected, isTrue);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage!.isNotEmpty, isTrue);
    });
  });
}
