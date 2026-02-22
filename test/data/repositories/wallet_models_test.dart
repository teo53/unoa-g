import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/repositories/supabase_wallet_repository.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  final baseCreatedAt = DateTime(2025, 1, 15, 12, 0, 0);
  final baseUpdatedAt = DateTime(2025, 1, 15, 13, 0, 0);

  Wallet makeWallet({
    String id = 'wallet-1',
    String userId = 'user-1',
    int balanceDt = 0,
    int lifetimePurchasedDt = 0,
    int lifetimeSpentDt = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wallet(
      id: id,
      userId: userId,
      balanceDt: balanceDt,
      lifetimePurchasedDt: lifetimePurchasedDt,
      lifetimeSpentDt: lifetimeSpentDt,
      createdAt: createdAt ?? baseCreatedAt,
      updatedAt: updatedAt ?? baseUpdatedAt,
    );
  }

  LedgerEntry makeLedgerEntry({
    String id = 'ledger-1',
    String idempotencyKey = 'key-1',
    String? fromWalletId = 'wallet-from',
    String? toWalletId,
    int amountDt = 100,
    String entryType = 'purchase',
    String? referenceType,
    String? referenceId,
    String? description,
    String status = 'completed',
    DateTime? createdAt,
  }) {
    return LedgerEntry(
      id: id,
      idempotencyKey: idempotencyKey,
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      amountDt: amountDt,
      entryType: entryType,
      referenceType: referenceType,
      referenceId: referenceId,
      description: description,
      status: status,
      createdAt: createdAt ?? baseCreatedAt,
    );
  }

  DtPackage makeDtPackage({
    String id = 'pkg-1',
    String name = '기본 패키지',
    int dtAmount = 1000,
    int bonusDt = 0,
    int priceKrw = 10000,
    bool isPopular = false,
    bool isActive = true,
  }) {
    return DtPackage(
      id: id,
      name: name,
      dtAmount: dtAmount,
      bonusDt: bonusDt,
      priceKrw: priceKrw,
      isPopular: isPopular,
      isActive: isActive,
    );
  }

  DtPurchase makeDtPurchase({
    String id = 'purchase-1',
    String userId = 'user-1',
    String packageId = 'pkg-1',
    int dtAmount = 1000,
    int bonusDt = 0,
    int priceKrw = 10000,
    String? paymentMethod,
    String? paymentProvider,
    String? paymentProviderTransactionId,
    String status = 'pending',
    int dtUsed = 0,
    DateTime? refundEligibleUntil,
    DateTime? createdAt,
    DateTime? paidAt,
    DateTime? refundedAt,
  }) {
    return DtPurchase(
      id: id,
      userId: userId,
      packageId: packageId,
      dtAmount: dtAmount,
      bonusDt: bonusDt,
      priceKrw: priceKrw,
      paymentMethod: paymentMethod,
      paymentProvider: paymentProvider,
      paymentProviderTransactionId: paymentProviderTransactionId,
      status: status,
      dtUsed: dtUsed,
      refundEligibleUntil: refundEligibleUntil,
      createdAt: createdAt ?? baseCreatedAt,
      paidAt: paidAt,
      refundedAt: refundedAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Wallet
  // ---------------------------------------------------------------------------

  group('Wallet', () {
    group('formattedBalance', () {
      test('formats zero as "0"', () {
        final wallet = makeWallet(balanceDt: 0);
        expect(wallet.formattedBalance, equals('0'));
      });

      test('formats three-digit number without comma', () {
        final wallet = makeWallet(balanceDt: 999);
        expect(wallet.formattedBalance, equals('999'));
      });

      test('formats 1234 with comma as "1,234"', () {
        final wallet = makeWallet(balanceDt: 1234);
        expect(wallet.formattedBalance, equals('1,234'));
      });

      test('formats 10000 as "10,000"', () {
        final wallet = makeWallet(balanceDt: 10000);
        expect(wallet.formattedBalance, equals('10,000'));
      });

      test('formats 1234567 as "1,234,567"', () {
        final wallet = makeWallet(balanceDt: 1234567);
        expect(wallet.formattedBalance, equals('1,234,567'));
      });
    });

    group('balanceKrw', () {
      test('returns 0 when balanceDt is 0', () {
        final wallet = makeWallet(balanceDt: 0);
        expect(wallet.balanceKrw, equals(0));
      });

      test('returns balanceDt * 100', () {
        final wallet = makeWallet(balanceDt: 1234);
        expect(wallet.balanceKrw, equals(123400));
      });

      test('large balance calculates correctly', () {
        final wallet = makeWallet(balanceDt: 15000);
        expect(wallet.balanceKrw, equals(1500000));
      });
    });

    group('formattedBalanceKrw', () {
      test('formats with 원 suffix', () {
        final wallet = makeWallet(balanceDt: 100);
        expect(wallet.formattedBalanceKrw, equals('10,000원'));
      });

      test('formats zero correctly', () {
        final wallet = makeWallet(balanceDt: 0);
        expect(wallet.formattedBalanceKrw, equals('0원'));
      });

      test('formats large amount with commas', () {
        final wallet = makeWallet(balanceDt: 15000);
        expect(wallet.formattedBalanceKrw, equals('1,500,000원'));
      });
    });

    group('fromJson round-trip', () {
      test('round-trips all required fields', () {
        final json = {
          'id': 'wallet-abc',
          'user_id': 'user-xyz',
          'balance_dt': 5000,
          'lifetime_purchased_dt': 20000,
          'lifetime_spent_dt': 15000,
          'created_at': baseCreatedAt.toIso8601String(),
          'updated_at': baseUpdatedAt.toIso8601String(),
        };

        final wallet = Wallet.fromJson(json);
        final serialized = wallet.toJson();
        final restored = Wallet.fromJson(serialized);

        expect(restored.id, equals('wallet-abc'));
        expect(restored.userId, equals('user-xyz'));
        expect(restored.balanceDt, equals(5000));
        expect(restored.lifetimePurchasedDt, equals(20000));
        expect(restored.lifetimeSpentDt, equals(15000));
        expect(restored.createdAt, equals(wallet.createdAt));
        expect(restored.updatedAt, equals(wallet.updatedAt));
      });

      test('defaults optional fields to 0 when missing', () {
        final json = {
          'id': 'wallet-1',
          'user_id': 'user-1',
          'created_at': baseCreatedAt.toIso8601String(),
          'updated_at': baseUpdatedAt.toIso8601String(),
        };

        final wallet = Wallet.fromJson(json);
        expect(wallet.balanceDt, equals(0));
        expect(wallet.lifetimePurchasedDt, equals(0));
        expect(wallet.lifetimeSpentDt, equals(0));
      });
    });
  });

  // ---------------------------------------------------------------------------
  // LedgerEntry
  // ---------------------------------------------------------------------------

  group('LedgerEntry', () {
    group('type boolean flags', () {
      test('isPurchase is true only for purchase type', () {
        expect(makeLedgerEntry(entryType: 'purchase').isPurchase, isTrue);
        expect(makeLedgerEntry(entryType: 'tip').isPurchase, isFalse);
        expect(makeLedgerEntry(entryType: 'refund').isPurchase, isFalse);
        expect(makeLedgerEntry(entryType: 'payout').isPurchase, isFalse);
      });

      test('isTip is true only for tip type', () {
        expect(makeLedgerEntry(entryType: 'tip').isTip, isTrue);
        expect(makeLedgerEntry(entryType: 'purchase').isTip, isFalse);
        expect(makeLedgerEntry(entryType: 'refund').isTip, isFalse);
        expect(makeLedgerEntry(entryType: 'payout').isTip, isFalse);
      });

      test('isRefund is true only for refund type', () {
        expect(makeLedgerEntry(entryType: 'refund').isRefund, isTrue);
        expect(makeLedgerEntry(entryType: 'purchase').isRefund, isFalse);
        expect(makeLedgerEntry(entryType: 'tip').isRefund, isFalse);
        expect(makeLedgerEntry(entryType: 'payout').isRefund, isFalse);
      });

      test('isPayout is true only for payout type', () {
        expect(makeLedgerEntry(entryType: 'payout').isPayout, isTrue);
        expect(makeLedgerEntry(entryType: 'purchase').isPayout, isFalse);
        expect(makeLedgerEntry(entryType: 'tip').isPayout, isFalse);
        expect(makeLedgerEntry(entryType: 'refund').isPayout, isFalse);
      });

      test('all flags are false for unknown type', () {
        final entry = makeLedgerEntry(entryType: 'bonus');
        expect(entry.isPurchase, isFalse);
        expect(entry.isTip, isFalse);
        expect(entry.isRefund, isFalse);
        expect(entry.isPayout, isFalse);
      });
    });

    group('displayIcon', () {
      test('purchase returns credit card emoji', () {
        expect(
            makeLedgerEntry(entryType: 'purchase').displayIcon, equals('💳'));
      });

      test('tip returns heart emoji', () {
        expect(makeLedgerEntry(entryType: 'tip').displayIcon, equals('💝'));
      });

      test('paid_reply returns speech bubble emoji', () {
        expect(
          makeLedgerEntry(entryType: 'paid_reply').displayIcon,
          equals('💬'),
        );
      });

      test('private_card returns card emoji', () {
        expect(
          makeLedgerEntry(entryType: 'private_card').displayIcon,
          equals('🎴'),
        );
      });

      test('refund returns return arrow emoji', () {
        expect(makeLedgerEntry(entryType: 'refund').displayIcon, equals('↩️'));
      });

      test('payout returns money bag emoji', () {
        expect(makeLedgerEntry(entryType: 'payout').displayIcon, equals('💰'));
      });

      test('bonus returns gift emoji', () {
        expect(makeLedgerEntry(entryType: 'bonus').displayIcon, equals('🎁'));
      });

      test('unknown type returns memo emoji', () {
        expect(makeLedgerEntry(entryType: 'unknown').displayIcon, equals('📝'));
      });
    });

    group('displayTitle', () {
      test('purchase returns "DT 구매"', () {
        expect(makeLedgerEntry(entryType: 'purchase').displayTitle,
            equals('DT 구매'));
      });

      test('tip returns "후원"', () {
        expect(makeLedgerEntry(entryType: 'tip').displayTitle, equals('후원'));
      });

      test('paid_reply returns "유료 답장"', () {
        expect(
          makeLedgerEntry(entryType: 'paid_reply').displayTitle,
          equals('유료 답장'),
        );
      });

      test('private_card returns "프라이빗 카드"', () {
        expect(
          makeLedgerEntry(entryType: 'private_card').displayTitle,
          equals('프라이빗 카드'),
        );
      });

      test('refund returns "환불"', () {
        expect(makeLedgerEntry(entryType: 'refund').displayTitle, equals('환불'));
      });

      test('payout returns "정산"', () {
        expect(makeLedgerEntry(entryType: 'payout').displayTitle, equals('정산'));
      });

      test('bonus returns "보너스"', () {
        expect(makeLedgerEntry(entryType: 'bonus').displayTitle, equals('보너스'));
      });

      test('unknown type returns "거래"', () {
        expect(makeLedgerEntry(entryType: 'other').displayTitle, equals('거래'));
      });
    });

    group('fromJson round-trip', () {
      test('round-trips all fields', () {
        final json = {
          'id': 'ledger-abc',
          'idempotency_key': 'idem-key-1',
          'from_wallet_id': 'wallet-from',
          'to_wallet_id': 'wallet-to',
          'amount_dt': 500,
          'entry_type': 'tip',
          'reference_type': 'donation',
          'reference_id': 'donation-1',
          'description': '후원: 500 DT',
          'status': 'completed',
          'created_at': baseCreatedAt.toIso8601String(),
        };

        final entry = LedgerEntry.fromJson(json);

        expect(entry.id, equals('ledger-abc'));
        expect(entry.idempotencyKey, equals('idem-key-1'));
        expect(entry.fromWalletId, equals('wallet-from'));
        expect(entry.toWalletId, equals('wallet-to'));
        expect(entry.amountDt, equals(500));
        expect(entry.entryType, equals('tip'));
        expect(entry.referenceType, equals('donation'));
        expect(entry.referenceId, equals('donation-1'));
        expect(entry.description, equals('후원: 500 DT'));
        expect(entry.status, equals('completed'));
      });

      test('defaults status to "completed" when missing', () {
        final json = {
          'id': 'ledger-1',
          'idempotency_key': 'key-1',
          'amount_dt': 100,
          'entry_type': 'purchase',
          'created_at': baseCreatedAt.toIso8601String(),
        };

        final entry = LedgerEntry.fromJson(json);
        expect(entry.status, equals('completed'));
      });

      test('handles null optional fields', () {
        final json = {
          'id': 'ledger-1',
          'idempotency_key': 'key-1',
          'from_wallet_id': null,
          'to_wallet_id': null,
          'amount_dt': 100,
          'entry_type': 'purchase',
          'reference_type': null,
          'reference_id': null,
          'description': null,
          'status': 'completed',
          'created_at': baseCreatedAt.toIso8601String(),
        };

        final entry = LedgerEntry.fromJson(json);
        expect(entry.fromWalletId, isNull);
        expect(entry.toWalletId, isNull);
        expect(entry.referenceType, isNull);
        expect(entry.referenceId, isNull);
        expect(entry.description, isNull);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // DtPackage (repository inline model)
  // ---------------------------------------------------------------------------

  group('DtPackage (repository model)', () {
    group('totalDt', () {
      test('returns dtAmount when bonusDt is 0', () {
        final pkg = makeDtPackage(dtAmount: 1000, bonusDt: 0);
        expect(pkg.totalDt, equals(1000));
      });

      test('returns sum of dtAmount and bonusDt', () {
        final pkg = makeDtPackage(dtAmount: 1000, bonusDt: 200);
        expect(pkg.totalDt, equals(1200));
      });

      test('handles large values', () {
        final pkg = makeDtPackage(dtAmount: 100000, bonusDt: 20000);
        expect(pkg.totalDt, equals(120000));
      });
    });

    group('formattedPrice', () {
      test('formats with comma and 원 suffix', () {
        final pkg = makeDtPackage(priceKrw: 49000);
        expect(pkg.formattedPrice, equals('49,000원'));
      });

      test('formats small price without comma', () {
        final pkg = makeDtPackage(priceKrw: 100);
        expect(pkg.formattedPrice, equals('100원'));
      });

      test('formats one million', () {
        final pkg = makeDtPackage(priceKrw: 1000000);
        expect(pkg.formattedPrice, equals('1,000,000원'));
      });

      test('formats zero price', () {
        final pkg = makeDtPackage(priceKrw: 0);
        expect(pkg.formattedPrice, equals('0원'));
      });
    });

    group('formattedDt', () {
      test('formats total DT with "DT" suffix', () {
        final pkg = makeDtPackage(dtAmount: 1000, bonusDt: 0);
        expect(pkg.formattedDt, equals('1,000 DT'));
      });

      test('includes bonus in formatted total', () {
        final pkg = makeDtPackage(dtAmount: 1000, bonusDt: 200);
        expect(pkg.formattedDt, equals('1,200 DT'));
      });

      test('formats small amount without comma', () {
        final pkg = makeDtPackage(dtAmount: 100, bonusDt: 0);
        expect(pkg.formattedDt, equals('100 DT'));
      });
    });

    group('bonusText', () {
      test('returns empty string when bonusDt is 0', () {
        final pkg = makeDtPackage(bonusDt: 0);
        expect(pkg.bonusText, isEmpty);
      });

      test('returns formatted bonus with + prefix and 보너스 suffix', () {
        final pkg = makeDtPackage(bonusDt: 50);
        expect(pkg.bonusText, equals('+50 보너스'));
      });

      test('formats large bonus with comma', () {
        final pkg = makeDtPackage(bonusDt: 2000);
        expect(pkg.bonusText, equals('+2,000 보너스'));
      });
    });

    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'id': 'pkg-abc',
          'name': '프리미엄 패키지',
          'dt_amount': 5000,
          'bonus_dt': 1000,
          'price_krw': 49000,
          'is_popular': true,
          'is_active': true,
        };

        final pkg = DtPackage.fromJson(json);

        expect(pkg.id, equals('pkg-abc'));
        expect(pkg.name, equals('프리미엄 패키지'));
        expect(pkg.dtAmount, equals(5000));
        expect(pkg.bonusDt, equals(1000));
        expect(pkg.priceKrw, equals(49000));
        expect(pkg.isPopular, isTrue);
        expect(pkg.isActive, isTrue);
      });

      test('defaults bonus_dt to 0 when missing', () {
        final json = {
          'id': 'pkg-1',
          'name': 'Basic',
          'dt_amount': 1000,
          'price_krw': 10000,
        };

        final pkg = DtPackage.fromJson(json);
        expect(pkg.bonusDt, equals(0));
      });

      test('defaults is_popular to false when missing', () {
        final json = {
          'id': 'pkg-1',
          'name': 'Basic',
          'dt_amount': 1000,
          'price_krw': 10000,
        };

        final pkg = DtPackage.fromJson(json);
        expect(pkg.isPopular, isFalse);
      });

      test('defaults is_active to true when missing', () {
        final json = {
          'id': 'pkg-1',
          'name': 'Basic',
          'dt_amount': 1000,
          'price_krw': 10000,
        };

        final pkg = DtPackage.fromJson(json);
        expect(pkg.isActive, isTrue);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // DtPurchase
  // ---------------------------------------------------------------------------

  group('DtPurchase', () {
    group('totalDt', () {
      test('returns dtAmount when bonusDt is 0', () {
        final purchase = makeDtPurchase(dtAmount: 1000, bonusDt: 0);
        expect(purchase.totalDt, equals(1000));
      });

      test('includes bonus in total', () {
        final purchase = makeDtPurchase(dtAmount: 1000, bonusDt: 200);
        expect(purchase.totalDt, equals(1200));
      });
    });

    group('unusedDt', () {
      test('returns totalDt when dtUsed is 0', () {
        final purchase = makeDtPurchase(dtAmount: 1000, bonusDt: 0, dtUsed: 0);
        expect(purchase.unusedDt, equals(1000));
      });

      test('returns remaining DT after usage', () {
        final purchase =
            makeDtPurchase(dtAmount: 1000, bonusDt: 200, dtUsed: 300);
        expect(purchase.unusedDt, equals(900));
      });

      test('returns 0 when all DT is used', () {
        final purchase =
            makeDtPurchase(dtAmount: 1000, bonusDt: 0, dtUsed: 1000);
        expect(purchase.unusedDt, equals(0));
      });
    });

    group('status boolean flags', () {
      test('isPending is true only for pending status', () {
        expect(makeDtPurchase(status: 'pending').isPending, isTrue);
        expect(makeDtPurchase(status: 'paid').isPending, isFalse);
        expect(makeDtPurchase(status: 'refunded').isPending, isFalse);
        expect(makeDtPurchase(status: 'cancelled').isPending, isFalse);
        expect(makeDtPurchase(status: 'failed').isPending, isFalse);
      });

      test('isPaid is true only for paid status', () {
        expect(makeDtPurchase(status: 'paid').isPaid, isTrue);
        expect(makeDtPurchase(status: 'pending').isPaid, isFalse);
        expect(makeDtPurchase(status: 'refunded').isPaid, isFalse);
        expect(makeDtPurchase(status: 'cancelled').isPaid, isFalse);
        expect(makeDtPurchase(status: 'failed').isPaid, isFalse);
      });

      test('isRefunded is true only for refunded status', () {
        expect(makeDtPurchase(status: 'refunded').isRefunded, isTrue);
        expect(makeDtPurchase(status: 'paid').isRefunded, isFalse);
        expect(makeDtPurchase(status: 'pending').isRefunded, isFalse);
      });

      test('isCancelled is true only for cancelled status', () {
        expect(makeDtPurchase(status: 'cancelled').isCancelled, isTrue);
        expect(makeDtPurchase(status: 'paid').isCancelled, isFalse);
        expect(makeDtPurchase(status: 'failed').isCancelled, isFalse);
      });

      test('isFailed is true only for failed status', () {
        expect(makeDtPurchase(status: 'failed').isFailed, isTrue);
        expect(makeDtPurchase(status: 'paid').isFailed, isFalse);
        expect(makeDtPurchase(status: 'cancelled').isFailed, isFalse);
      });
    });

    group('canRefund', () {
      test('returns false when status is not paid', () {
        final future = DateTime.now().add(const Duration(days: 7));

        expect(
          makeDtPurchase(
            status: 'pending',
            dtUsed: 0,
            refundEligibleUntil: future,
          ).canRefund,
          isFalse,
        );

        expect(
          makeDtPurchase(
            status: 'refunded',
            dtUsed: 0,
            refundEligibleUntil: future,
          ).canRefund,
          isFalse,
        );

        expect(
          makeDtPurchase(
            status: 'cancelled',
            dtUsed: 0,
            refundEligibleUntil: future,
          ).canRefund,
          isFalse,
        );

        expect(
          makeDtPurchase(
            status: 'failed',
            dtUsed: 0,
            refundEligibleUntil: future,
          ).canRefund,
          isFalse,
        );
      });

      test('returns false when dtUsed is greater than 0', () {
        final future = DateTime.now().add(const Duration(days: 7));

        final purchase = makeDtPurchase(
          status: 'paid',
          dtUsed: 100,
          refundEligibleUntil: future,
        );

        expect(purchase.canRefund, isFalse);
      });

      test('returns false when refundEligibleUntil is null', () {
        final purchase = makeDtPurchase(
          status: 'paid',
          dtUsed: 0,
          refundEligibleUntil: null,
        );

        expect(purchase.canRefund, isFalse);
      });

      test('returns false when refundEligibleUntil is in the past', () {
        final past = DateTime.now().subtract(const Duration(days: 1));

        final purchase = makeDtPurchase(
          status: 'paid',
          dtUsed: 0,
          refundEligibleUntil: past,
        );

        expect(purchase.canRefund, isFalse);
      });

      test('returns true when paid, dtUsed is 0, and within eligible window',
          () {
        final future = DateTime.now().add(const Duration(days: 7));

        final purchase = makeDtPurchase(
          status: 'paid',
          dtUsed: 0,
          refundEligibleUntil: future,
        );

        expect(purchase.canRefund, isTrue);
      });
    });

    group('fromJson round-trip', () {
      test('parses all fields correctly', () {
        final paidAt = DateTime(2025, 1, 10, 9, 0, 0);
        final refundEligibleUntil = DateTime(2025, 1, 17, 9, 0, 0);

        final json = {
          'id': 'purchase-abc',
          'user_id': 'user-xyz',
          'package_id': 'pkg-abc',
          'dt_amount': 5000,
          'bonus_dt': 1000,
          'price_krw': 49000,
          'payment_method': 'card',
          'payment_provider': 'toss',
          'payment_provider_transaction_id': 'txn-123',
          'status': 'paid',
          'dt_used': 0,
          'refund_eligible_until': refundEligibleUntil.toIso8601String(),
          'created_at': baseCreatedAt.toIso8601String(),
          'paid_at': paidAt.toIso8601String(),
          'refunded_at': null,
        };

        final purchase = DtPurchase.fromJson(json);

        expect(purchase.id, equals('purchase-abc'));
        expect(purchase.userId, equals('user-xyz'));
        expect(purchase.packageId, equals('pkg-abc'));
        expect(purchase.dtAmount, equals(5000));
        expect(purchase.bonusDt, equals(1000));
        expect(purchase.priceKrw, equals(49000));
        expect(purchase.paymentMethod, equals('card'));
        expect(purchase.paymentProvider, equals('toss'));
        expect(purchase.paymentProviderTransactionId, equals('txn-123'));
        expect(purchase.status, equals('paid'));
        expect(purchase.dtUsed, equals(0));
        expect(purchase.refundedAt, isNull);
        expect(purchase.isPaid, isTrue);
      });

      test('defaults optional fields correctly when missing', () {
        final json = {
          'id': 'purchase-1',
          'user_id': 'user-1',
          'package_id': 'pkg-1',
          'dt_amount': 1000,
          'price_krw': 10000,
          'created_at': baseCreatedAt.toIso8601String(),
        };

        final purchase = DtPurchase.fromJson(json);

        expect(purchase.bonusDt, equals(0));
        expect(purchase.status, equals('pending'));
        expect(purchase.dtUsed, equals(0));
        expect(purchase.refundEligibleUntil, isNull);
        expect(purchase.paidAt, isNull);
        expect(purchase.refundedAt, isNull);
        expect(purchase.paymentMethod, isNull);
        expect(purchase.paymentProvider, isNull);
        expect(purchase.paymentProviderTransactionId, isNull);
      });

      test('parses refundEligibleUntil correctly', () {
        final eligibleUntil = DateTime(2025, 3, 1);

        final json = {
          'id': 'purchase-1',
          'user_id': 'user-1',
          'package_id': 'pkg-1',
          'dt_amount': 1000,
          'price_krw': 10000,
          'status': 'paid',
          'refund_eligible_until': eligibleUntil.toIso8601String(),
          'created_at': baseCreatedAt.toIso8601String(),
        };

        final purchase = DtPurchase.fromJson(json);
        expect(purchase.refundEligibleUntil, equals(eligibleUntil));
      });
    });
  });
}
