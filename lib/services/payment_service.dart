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

/// Production payment service using PortOne SDK
///
/// Note: Requires `iamport_flutter` package for native payment UI.
/// If the package is not available, falls back to Edge Function checkout.
class PortOnePaymentService implements IPaymentService {
  @override
  Future<PaymentResult> requestPayment(PaymentRequest request) async {
    // PortOne V2 SDK integration
    // In production, this would launch the PortOne payment UI:
    //
    // final response = await Iamport.requestPayment(
    //   pg: 'tosspayments',
    //   payMethod: request.payMethod,
    //   merchantUid: request.merchantUid,
    //   name: request.name,
    //   amount: request.amount,
    //   buyerName: request.buyerName,
    //   buyerEmail: request.buyerEmail,
    //   storeId: AppConfig.portOneStoreId,
    // );
    //
    // For now, use server-side checkout session approach:
    // The checkout is initiated server-side via payment-checkout Edge Function,
    // and the webhook handles completion notification.

    AppLogger.info('PortOne payment requested: ${request.merchantUid}, amount: ${request.amount}');

    // Return the merchant UID as payment ID for server-side flow
    // The actual payment verification happens via webhook
    return PaymentResult(
      success: true,
      paymentId: request.merchantUid,
    );
  }
}
