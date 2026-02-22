import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/services/payment_service.dart';

void main() {
  // ---------------------------------------------------------------------------
  // PaymentResult factory constructors
  // ---------------------------------------------------------------------------
  group('PaymentResult', () {
    group('.confirmed factory', () {
      test('has success=true and isPending=false', () {
        const result = PaymentResult.confirmed('pay_1');
        expect(result.success, isTrue);
        expect(result.isPending, isFalse);
        expect(result.isConfirmed, isTrue);
        expect(result.isRejected, isFalse);
      });

      test('carries paymentId', () {
        const result = PaymentResult.confirmed('pay_abc');
        expect(result.paymentId, 'pay_abc');
        expect(result.errorMessage, isNull);
      });
    });

    group('.pending factory', () {
      test('has success=false and isPending=true', () {
        const result = PaymentResult.pending('order_123');
        expect(result.success, isFalse);
        expect(result.isPending, isTrue);
        expect(result.isConfirmed, isFalse);
        expect(result.isRejected, isFalse);
      });

      test('carries paymentId', () {
        const result = PaymentResult.pending('FUND_c1_123');
        expect(result.paymentId, 'FUND_c1_123');
        expect(result.errorMessage, isNull);
      });
    });

    group('.rejected factory', () {
      test('has success=false and isPending=false', () {
        const result = PaymentResult.rejected('결제 실패');
        expect(result.success, isFalse);
        expect(result.isPending, isFalse);
        expect(result.isConfirmed, isFalse);
        expect(result.isRejected, isTrue);
      });

      test('carries errorMessage', () {
        const result = PaymentResult.rejected('설정 오류');
        expect(result.errorMessage, '설정 오류');
        expect(result.paymentId, isNull);
      });
    });

    group('convenience getters', () {
      test('isConfirmed is true only for confirmed', () {
        expect(const PaymentResult.confirmed('p1').isConfirmed, isTrue);
        expect(const PaymentResult.pending('p2').isConfirmed, isFalse);
        expect(const PaymentResult.rejected('err').isConfirmed, isFalse);
      });

      test('isRejected is true only for rejected', () {
        expect(const PaymentResult.rejected('err').isRejected, isTrue);
        expect(const PaymentResult.confirmed('p1').isRejected, isFalse);
        expect(const PaymentResult.pending('p2').isRejected, isFalse);
      });
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

    test('always returns confirmed', () async {
      final result = await service.requestPayment(
        const PaymentRequest(
          merchantUid: 'test_1',
          name: 'Test',
          amount: 1000,
          payMethod: 'card',
        ),
      );
      expect(result.isConfirmed, isTrue);
      expect(result.isPending, isFalse);
      expect(result.isRejected, isFalse);
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

    test('does not return pending (demo = instant confirmation)', () async {
      final result = await service.requestPayment(
        const PaymentRequest(
          merchantUid: 'test_2',
          name: 'Test',
          amount: 5000,
          payMethod: 'virtual_account',
        ),
      );
      expect(result.isPending, isFalse);
      expect(result.isConfirmed, isTrue);
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
      expect(result.isRejected, isTrue);
      expect(result.success, isFalse);
      expect(result.isPending, isFalse);
      expect(result.errorMessage, contains('설정'));
    });

    test('rejected result has no paymentId', () async {
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

    test('rejected result is not pending', () async {
      final result = await service.requestPayment(
        const PaymentRequest(
          merchantUid: 'test_3',
          name: 'Test',
          amount: 1000,
          payMethod: 'bank_transfer',
        ),
      );

      expect(result.isPending, isFalse);
      expect(result.isRejected, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // isRejected contract validation (matches FundingCheckoutScreen usage)
  // ---------------------------------------------------------------------------
  group('isRejected contract', () {
    test('pending payment is NOT treated as rejected', () {
      const pending = PaymentResult.pending('order_xyz');
      expect(pending.isRejected, isFalse,
          reason: 'Pending payment should NOT be rejected');
    });

    test('rejected payment IS rejected', () {
      const failure = PaymentResult.rejected('결제 실패');
      expect(failure.isRejected, isTrue,
          reason: 'Explicit failure should be rejected');
    });

    test('confirmed payment is NOT rejected', () {
      const success = PaymentResult.confirmed('pay_ok');
      expect(success.isRejected, isFalse,
          reason: 'Confirmed payment should not be rejected');
    });
  });
}
