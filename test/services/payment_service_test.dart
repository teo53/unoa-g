import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/services/payment_service.dart';

void main() {
  // ---------------------------------------------------------------------------
  // PaymentResult
  // ---------------------------------------------------------------------------
  group('PaymentResult', () {
    test('default isPending is false', () {
      const result = PaymentResult(success: true);
      expect(result.isPending, isFalse);
    });

    test('success result has no error', () {
      const result = PaymentResult(success: true, paymentId: 'pay_1');
      expect(result.success, isTrue);
      expect(result.paymentId, 'pay_1');
      expect(result.errorMessage, isNull);
      expect(result.isPending, isFalse);
    });

    test('failure result carries error message', () {
      const result = PaymentResult(
        success: false,
        errorMessage: '결제 실패',
      );
      expect(result.success, isFalse);
      expect(result.errorMessage, '결제 실패');
      expect(result.isPending, isFalse);
    });

    test('pending result has success=false and isPending=true', () {
      const result = PaymentResult(
        success: false,
        isPending: true,
        paymentId: 'order_123',
      );
      expect(result.success, isFalse);
      expect(result.isPending, isTrue);
      expect(result.paymentId, 'order_123');
      expect(result.errorMessage, isNull);
    });

    test('success=true with isPending=true is representable', () {
      // Edge case: should not happen in practice, but model allows it
      const result = PaymentResult(success: true, isPending: true);
      expect(result.success, isTrue);
      expect(result.isPending, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // PaymentRequest
  // ---------------------------------------------------------------------------
  group('PaymentRequest', () {
    test('constructs with required fields', () {
      const req = PaymentRequest(
        merchantUid: 'FUND_c1_123',
        name: '캠페인 - 골드 티어',
        amount: 50000,
        payMethod: 'card',
      );
      expect(req.merchantUid, 'FUND_c1_123');
      expect(req.name, '캠페인 - 골드 티어');
      expect(req.amount, 50000);
      expect(req.payMethod, 'card');
      expect(req.buyerName, isNull);
      expect(req.buyerEmail, isNull);
    });

    test('constructs with optional buyer info', () {
      const req = PaymentRequest(
        merchantUid: 'order_1',
        name: 'DT 100',
        amount: 10000,
        payMethod: 'bank_transfer',
        buyerName: '홍길동',
        buyerEmail: 'test@example.com',
      );
      expect(req.buyerName, '홍길동');
      expect(req.buyerEmail, 'test@example.com');
    });
  });

  // ---------------------------------------------------------------------------
  // DemoPaymentService
  // ---------------------------------------------------------------------------
  group('DemoPaymentService', () {
    late DemoPaymentService service;

    setUp(() {
      service = DemoPaymentService();
    });

    test('always returns success', () async {
      final result = await service.requestPayment(
        const PaymentRequest(
          merchantUid: 'test_1',
          name: 'Test',
          amount: 1000,
          payMethod: 'card',
        ),
      );
      expect(result.success, isTrue);
      expect(result.isPending, isFalse);
      expect(result.paymentId, isNotNull);
      expect(result.paymentId, startsWith('demo_payment_'));
      expect(result.errorMessage, isNull);
    });

    test('generates unique payment IDs across calls', () async {
      const req = PaymentRequest(
        merchantUid: 'test_uid',
        name: 'Test',
        amount: 1000,
        payMethod: 'card',
      );
      final r1 = await service.requestPayment(req);
      // Small delay to ensure different timestamp
      await Future.delayed(const Duration(milliseconds: 10));
      final r2 = await service.requestPayment(req);
      expect(r1.paymentId, isNot(equals(r2.paymentId)));
    });

    test('does not return isPending (demo = instant success)', () async {
      final result = await service.requestPayment(
        const PaymentRequest(
          merchantUid: 'test_2',
          name: 'Test',
          amount: 5000,
          payMethod: 'virtual_account',
        ),
      );
      expect(result.isPending, isFalse);
      expect(result.success, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // PortOnePaymentService — fail-closed checks
  // ---------------------------------------------------------------------------
  group('PortOnePaymentService — fail-closed', () {
    // Note: PortOnePaymentService reads compile-time constants (AppConfig).
    // In the default test environment:
    //   - AppConfig.portOneStoreId == '' (empty)
    //   - AppConfig.enableDtPurchase == false
    //   - kIsWeb == false (test runner is not web)
    // Therefore, the first fail-closed check (empty store ID) fires.

    late PortOnePaymentService service;

    setUp(() {
      service = PortOnePaymentService();
    });

    test('rejects when PORTONE_STORE_ID is empty', () async {
      final result = await service.requestPayment(
        const PaymentRequest(
          merchantUid: 'test_1',
          name: 'Test',
          amount: 10000,
          payMethod: 'card',
        ),
      );

      // Should fail-closed: store ID not configured
      expect(result.success, isFalse);
      expect(result.isPending, isFalse);
      expect(result.errorMessage, contains('설정'));
    });

    test('fail-closed result has no paymentId', () async {
      final result = await service.requestPayment(
        const PaymentRequest(
          merchantUid: 'test_2',
          name: 'Test',
          amount: 5000,
          payMethod: 'card',
        ),
      );

      expect(result.paymentId, isNull);
    });

    test('fail-closed does not set isPending', () async {
      final result = await service.requestPayment(
        const PaymentRequest(
          merchantUid: 'test_3',
          name: 'Test',
          amount: 1000,
          payMethod: 'bank_transfer',
        ),
      );

      // Fail-closed means explicit rejection, not a pending state
      expect(result.isPending, isFalse);
      expect(result.success, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // isPending contract validation
  // ---------------------------------------------------------------------------
  group('isPending contract', () {
    test('checkout-initiated result (pending) should not be treated as success',
        () {
      // This test documents the expected behavior:
      // When PortOne returns isPending=true, callers MUST NOT grant value.
      const pending = PaymentResult(
        success: false,
        isPending: true,
        paymentId: 'order_xyz',
      );

      // The correct check in FundingCheckoutScreen:
      // if (!result.success && !result.isPending) → reject
      // This allows pending payments to proceed to server verification.
      final shouldReject = !pending.success && !pending.isPending;
      expect(shouldReject, isFalse,
          reason: 'Pending payment should NOT be rejected');
    });

    test('explicit failure should be rejected', () {
      const failure = PaymentResult(
        success: false,
        isPending: false,
        errorMessage: '결제 실패',
      );

      final shouldReject = !failure.success && !failure.isPending;
      expect(shouldReject, isTrue,
          reason: 'Explicit failure should be rejected');
    });

    test('successful payment should not be rejected', () {
      const success = PaymentResult(success: true, paymentId: 'pay_ok');

      final shouldReject = !success.success && !success.isPending;
      expect(shouldReject, isFalse,
          reason: 'Successful payment should not be rejected');
    });

    test('backward compatibility: existing code checking only .success works',
        () {
      // When isPending defaults to false, existing code that only checks
      // .success will correctly reject failed payments.
      const oldStyleFailure = PaymentResult(success: false);
      expect(oldStyleFailure.isPending, isFalse);
      expect(oldStyleFailure.success, isFalse);
      // Old code: if (!result.success) → this still rejects correctly
    });
  });
}
