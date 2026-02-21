import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/config/app_config.dart';
import '../core/utils/app_logger.dart';

/// Payment result from payment provider
class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    this.paymentId,
    this.errorMessage,
  });
}

/// Payment request parameters
class PaymentRequest {
  final String merchantUid;
  final String name;
  final int amount;
  final String payMethod; // card, bank_transfer, virtual_account
  final String? buyerName;
  final String? buyerEmail;

  const PaymentRequest({
    required this.merchantUid,
    required this.name,
    required this.amount,
    required this.payMethod,
    this.buyerName,
    this.buyerEmail,
  });
}

/// Abstract payment service interface
abstract class IPaymentService {
  Future<PaymentResult> requestPayment(PaymentRequest request);
}

/// Demo mode payment service - simulates payment success
class DemoPaymentService implements IPaymentService {
  @override
  Future<PaymentResult> requestPayment(PaymentRequest request) async {
    // Simulate payment processing delay
    await Future.delayed(const Duration(milliseconds: 500));
    return PaymentResult(
      success: true,
      paymentId: 'demo_payment_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}

/// Production payment service using PortOne SDK (WEB ONLY)
///
/// P0-2: Fail-closed — rejects payments when:
///   1. PORTONE_STORE_ID is not configured
///   2. Platform is not web (mobile must use IAP)
///   3. DT purchase is disabled via feature flag
///
/// Server-side checkout flow:
///   payment-checkout Edge Function → TossPayments checkout URL → redirect
///   Payment completion → payment-webhook → payment-confirm dual verification
class PortOnePaymentService implements IPaymentService {
  @override
  Future<PaymentResult> requestPayment(PaymentRequest request) async {
    // FAIL-CLOSED 1: Store ID not configured
    if (AppConfig.portOneStoreId.isEmpty) {
      AppLogger.error('PortOne rejected: PORTONE_STORE_ID not configured',
          tag: 'Payment');
      return const PaymentResult(
        success: false,
        errorMessage: '결제 서비스가 아직 설정되지 않았습니다.',
      );
    }

    // FAIL-CLOSED 2: Web only (mobile must use IAP)
    if (!kIsWeb) {
      AppLogger.error('PortOne rejected: not web platform', tag: 'Payment');
      return const PaymentResult(
        success: false,
        errorMessage: '웹에서만 결제가 가능합니다.',
      );
    }

    // FAIL-CLOSED 3: DT purchase disabled
    if (!AppConfig.enableDtPurchase) {
      return const PaymentResult(
        success: false,
        errorMessage: '현재 결제가 비활성화되어 있습니다.',
      );
    }

    // Server-side checkout flow:
    // The checkout is initiated server-side via payment-checkout Edge Function,
    // and the webhook handles completion notification.
    AppLogger.info(
        'PortOne checkout: ${request.merchantUid}, amount: ${request.amount}',
        tag: 'Payment');

    return PaymentResult(
      success: true,
      paymentId: request.merchantUid,
    );
  }
}
