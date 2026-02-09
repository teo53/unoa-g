import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/user_profile.dart';

void main() {
  group('Transaction', () {
    group('fromJson / toJson', () {
      test('round-trips all fields correctly', () {
        final json = {
          'id': 'tx-1',
          'description': 'DT 충전',
          'amount': 5000,
          'timestamp': '2024-01-15T10:30:00.000Z',
          'type': 'credit',
          'status': 'completed',
        };
        final tx = Transaction.fromJson(json);
        final restored = Transaction.fromJson(tx.toJson());

        expect(restored.id, equals('tx-1'));
        expect(restored.description, equals('DT 충전'));
        expect(restored.amount, equals(5000));
        expect(restored.type, equals(TransactionType.credit));
        expect(restored.status, equals(TransactionStatus.completed));
      });

      test('supports amount_dt and entry_type alternative keys', () {
        final json = {
          'id': 'tx-2',
          'description': '후원',
          'amount_dt': 1000,
          'timestamp': '2024-01-15T10:30:00.000Z',
          'entry_type': 'debit',
        };
        final tx = Transaction.fromJson(json);

        expect(tx.amount, equals(1000));
        expect(tx.type, equals(TransactionType.debit));
      });

      test('supports created_at as alternative to timestamp', () {
        final json = {
          'id': 'tx-3',
          'description': 'Test',
          'amount': 500,
          'created_at': '2024-06-01T12:00:00.000Z',
          'type': 'credit',
        };
        final tx = Transaction.fromJson(json);
        expect(tx.timestamp.year, equals(2024));
        expect(tx.timestamp.month, equals(6));
      });
    });

    group('formattedAmount', () {
      test('returns +N DT for credit', () {
        final tx = Transaction.fromJson({
          'id': 'tx-1',
          'description': '충전',
          'amount': 5000,
          'timestamp': '2024-01-15T10:00:00.000Z',
          'type': 'credit',
        });
        expect(tx.formattedAmount, equals('+5000 DT'));
      });

      test('returns -N DT for debit', () {
        final tx = Transaction.fromJson({
          'id': 'tx-2',
          'description': '후원',
          'amount': 1000,
          'timestamp': '2024-01-15T10:00:00.000Z',
          'type': 'debit',
        });
        expect(tx.formattedAmount, equals('-1000 DT'));
      });
    });

    group('formattedDate', () {
      test('returns YYYY.MM.DD format with zero-padding', () {
        final tx = Transaction.fromJson({
          'id': 'tx-1',
          'description': 'Test',
          'amount': 100,
          'timestamp': '2024-03-05T10:00:00.000Z',
          'type': 'credit',
        });
        expect(tx.formattedDate, equals('2024.03.05'));
      });
    });
  });

  group('TransactionStatus', () {
    group('fromString', () {
      test('parses completed correctly', () {
        expect(
          TransactionStatus.fromString('completed'),
          equals(TransactionStatus.completed),
        );
      });

      test('returns completed for null', () {
        expect(
          TransactionStatus.fromString(null),
          equals(TransactionStatus.completed),
        );
      });

      test('handles case-insensitive matching', () {
        expect(
          TransactionStatus.fromString('PENDING'),
          equals(TransactionStatus.pending),
        );
        expect(
          TransactionStatus.fromString('Failed'),
          equals(TransactionStatus.failed),
        );
      });

      test('returns completed for unknown value', () {
        expect(
          TransactionStatus.fromString('unknown_status'),
          equals(TransactionStatus.completed),
        );
      });

      test('has correct labels', () {
        expect(TransactionStatus.pending.label, equals('대기중'));
        expect(TransactionStatus.completed.label, equals('완료'));
        expect(TransactionStatus.failed.label, equals('실패'));
        expect(TransactionStatus.refunded.label, equals('환불됨'));
      });
    });
  });
}
