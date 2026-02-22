import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/config/app_config.dart';
import '../core/utils/app_logger.dart';

/// Payment outcome from payment provider.
///
/// Invariants (enforced by factory constructors):
///   - [isConfirmed] implies [isPending] == false
///   - [isPending]   implies [isConfirmed] == false
///   - [isRejected]  implies both are false
///
/// Call sites MUST use the named factories:
///   PaymentResult.confirmed(paymentId)
///   PaymentResult.pending(paymentId)
///   PaymentResult.rejected(message)
class PaymentResult {
  /// True only when the server has confirmed the payment was collected.
  final bool success;

  /// True when the PG checkout was initiated but the payment is not yet
  /// server-confirmed (e.g., PortOne redirect flow).  UI must NOT treat
  /// this as "paid" — start a confirmation watcher instead.
  final bool isPending;

  final String? paymentId;
  final String? errorMessage;

  const PaymentResult._({
    required this.success,
    required this.isPending,
    this.paymentId,
    this.errorMessage,
  });

  /// Server-confirmed payment (webhook or confirm endpoint succeeded).
  const factory PaymentResult.confirmed(String paymentId) = _Confirmed;

  /// Checkout initiated, awaiting server confirmation.
  const factory PaymentResult.pending(String paymentId) = _Pending;

  /// Payment rejected or failed.
  const factory PaymentResult.rejected(String message) = _Rejected;

  bool get isConfirmed => success && !isPending;
  bool get isRejected => !success && !isPending;
}

class _Confirmed extends PaymentResult {
  const _Confirmed(String paymentId)
      : super._(success: true, isPending: false, paymentId: paymentId);
}

class _Pending extends PaymentResult {
  const _Pending(String paymentId)
      : super._(success: false, isPending: true, paymentId: paymentId);
}

class _Rejected extends PaymentResult {
  const _Rejected(String message)
      : super._(
          success: false,
          isPending: false,
          errorMessage: message,
        );
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

/// Demo mode payment service - simulates confirmed payment
class DemoPaymentService implements IPaymentService {
  @override
  Future<PaymentResult> requestPayment(PaymentRequest request) async {
    // Simulate payment processing delay
    await Future.delayed(const Duration(milliseconds: 500));
    return PaymentResult.confirmed(
      'demo_payment_${DateTime.now().millisecondsSinceEpoch}',
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
/// Returns [PaymentResult.pending] on successful checkout initiation,
/// NEVER [PaymentResult.confirmed].  Confirmation requires server
/// verification via webhook / payment-confirm Edge Function.
class PortOnePaymentService implements IPaymentService {
  @override
  Future<PaymentResult> requestPayment(PaymentRequest request) async {
    // FAIL-CLOSED 1: Store ID not configured
    if (AppConfig.portOneStoreId.isEmpty) {
      AppLogger.error('PortOne rejected: PORTONE_STORE_ID not configured',
          tag: 'Payment');
      return const PaymentResult.rejected(
        '결제 서비스가 아직 설정되지 않았습니다.',
      );
    }

    // FAIL-CLOSED 2: Web only (mobile must use IAP)
    if (!kIsWeb) {
      AppLogger.error('PortOne rejected: not web platform', tag: 'Payment');
      return const PaymentResult.rejected(
        '웹에서만 결제가 가능합니다.',
      );
    }

    // FAIL-CLOSED 3: DT purchase disabled
    if (!AppConfig.enableDtPurchase) {
      return const PaymentResult.rejected(
        '현재 결제가 비활성화되어 있습니다.',
      );
    }

    // Server-side checkout flow:
    // The checkout is initiated server-side via payment-checkout Edge Function,
    // and the webhook handles completion notification.
    // P0 FIX: Return PENDING, not confirmed.  The PG checkout has been
    // initiated, but no money has been collected yet.  The caller must
    // poll or subscribe for server-side confirmation.
    AppLogger.info(
        'PortOne checkout initiated: ${request.merchantUid}, '
        'amount: ${request.amount}',
        tag: 'Payment');

    return PaymentResult.pending(request.merchantUid);
  }
}
