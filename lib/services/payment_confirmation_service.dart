import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/app_logger.dart';

/// Outcome of a payment confirmation attempt.
enum ConfirmationOutcome {
  /// Server confirmed the payment was successfully collected.
  confirmed,

  /// Server explicitly rejected the payment (invalid, mismatched, etc.).
  rejected,

  /// Confirmation polling timed out — payment may still settle later
  /// (webhook or reconcile will handle it).
  timeout,
}

/// Result of awaiting payment confirmation.
class ConfirmationResult {
  final ConfirmationOutcome outcome;
  final String? message;

  const ConfirmationResult({
    required this.outcome,
    this.message,
  });
}

/// Lightweight service for polling payment confirmation status.
///
/// Two confirmation strategies supported:
///   1. [awaitFundingConfirmation] — calls funding-pledge Edge Function
///      which verifies payment with PortOne API synchronously.
///   2. [awaitDtPurchaseConfirmation] — polls dt_purchases table for
///      status change from 'checkout' to 'paid'/'failed'.
///
/// Usage:
/// ```dart
/// final service = PaymentConfirmationService(supabaseClient);
/// final result = await service.awaitDtPurchaseConfirmation(
///   orderId: 'FUND_xxx_123',
///   timeout: Duration(seconds: 120),
/// );
/// ```
class PaymentConfirmationService {
  final SupabaseClient _client;

  PaymentConfirmationService(this._client);

  /// Poll dt_purchases table for server-confirmed payment status.
  ///
  /// The payment-webhook or payment-confirm Edge Function updates
  /// dt_purchases.status to 'paid' or 'failed'.  This method polls
  /// until that happens or [timeout] is reached.
  Future<ConfirmationResult> awaitDtPurchaseConfirmation({
    required String orderId,
    Duration timeout = const Duration(seconds: 120),
    Duration pollInterval = const Duration(seconds: 3),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      try {
        final response = await _client
            .from('dt_purchases')
            .select('status')
            .eq('order_id', orderId)
            .maybeSingle();

        if (response == null) {
          // Row not yet created — still initializing
          await Future.delayed(pollInterval);
          continue;
        }

        final status = response['status'] as String?;

        if (status == 'paid') {
          return const ConfirmationResult(
            outcome: ConfirmationOutcome.confirmed,
            message: '결제가 완료되었습니다.',
          );
        }

        if (status == 'failed' || status == 'cancelled') {
          return ConfirmationResult(
            outcome: ConfirmationOutcome.rejected,
            message: '결제가 실패했습니다. (status: $status)',
          );
        }

        // Still pending (checkout / processing) — keep polling
      } catch (e) {
        AppLogger.warning(
          'Payment confirmation poll error: $e',
          tag: 'PaymentConfirm',
        );
      }

      await Future.delayed(pollInterval);
    }

    return const ConfirmationResult(
      outcome: ConfirmationOutcome.timeout,
      message: '결제 확인 시간이 초과되었습니다. 잠시 후 지갑에서 확인해주세요.',
    );
  }

  /// Funding confirmation is synchronous via Edge Function.
  ///
  /// The funding-pledge Edge Function verifies payment with PortOne API
  /// and creates the pledge atomically.  A successful [submitPledge] call
  /// returning a non-null pledge_id IS the confirmation.
  ///
  /// This method wraps that check for consistency with the confirmation
  /// service pattern.
  ConfirmationResult interpretFundingPledgeResult(
      Map<String, dynamic> pledgeResult) {
    if (pledgeResult['pledge_id'] != null) {
      return const ConfirmationResult(
        outcome: ConfirmationOutcome.confirmed,
        message: '후원이 완료되었습니다!',
      );
    }

    return ConfirmationResult(
      outcome: ConfirmationOutcome.rejected,
      message: pledgeResult['error']?.toString() ?? '후원에 실패했습니다',
    );
  }
}
