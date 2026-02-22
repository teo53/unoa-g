import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/services/payment_service.dart';

/// Tests for the funding checkout payment result branching logic.
///
/// FundingCheckoutScreen._initiateKrwPayment() uses this condition:
///   if (!paymentResult.success && !paymentResult.isPending) → throw
///
/// This test file validates that the branching correctly handles:
/// 1. Success → proceed to pledge
/// 2. Pending → proceed to server-side verification (NOT rejected)
/// 3. Failure → throw (user sees error screen)
void main() {
  /// Simulates the exact branching logic from FundingCheckoutScreen.
  /// Returns null if payment proceeds, or error message if rejected.
  String? evaluatePaymentResult(PaymentResult result) {
    if (!result.success && !result.isPending) {
      return result.errorMessage ?? '결제에 실패했습니다';
    }
    return null; // proceeds to submitPledge
  }

  group('Funding Checkout — payment result branching', () {
    test('success: proceeds to pledge creation', () {
      const result = PaymentResult(
        success: true,
        paymentId: 'demo_payment_1',
      );

      expect(evaluatePaymentResult(result), isNull,
          reason: 'Successful payment should proceed');
    });

    test('pending: proceeds to server-side verification', () {
      const result = PaymentResult(
        success: false,
        isPending: true,
        paymentId: 'FUND_c1_123',
      );

      expect(evaluatePaymentResult(result), isNull,
          reason: 'Pending payment should proceed to Edge Function verification');
    });

    test('failure: throws with error message', () {
      const result = PaymentResult(
        success: false,
        isPending: false,
        errorMessage: '결제 서비스가 아직 설정되지 않았습니다.',
      );

      final error = evaluatePaymentResult(result);
      expect(error, isNotNull);
      expect(error, contains('설정'));
    });

    test('failure without message: uses default error', () {
      const result = PaymentResult(
        success: false,
        isPending: false,
      );

      final error = evaluatePaymentResult(result);
      expect(error, '결제에 실패했습니다');
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
      expect(result.isPending, isFalse);
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

  group('Funding Checkout — edge cases', () {
    test('isPending with errorMessage still proceeds', () {
      // Unlikely but possible: isPending with a warning message
      const result = PaymentResult(
        success: false,
        isPending: true,
        errorMessage: '처리 중입니다',
      );

      expect(evaluatePaymentResult(result), isNull,
          reason: 'isPending should take precedence over errorMessage');
    });

    test('all three PortOne fail-closed paths return consistent shape', () async {
      // In test environment, only the first fail-closed fires (empty store ID),
      // but we verify the result shape is consistent
      final portone = PortOnePaymentService();
      final result = await portone.requestPayment(
        const PaymentRequest(
          merchantUid: 'test',
          name: 'Test',
          amount: 1000,
          payMethod: 'card',
        ),
      );

      // All fail-closed results must have this shape:
      expect(result.success, isFalse);
      expect(result.isPending, isFalse);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage!.isNotEmpty, isTrue);
    });
  });
}
