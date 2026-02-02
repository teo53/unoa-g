import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    group('displayName', () {
      test('returns name when no English name', () {
        const profile = UserProfile(
          id: 'user-1',
          name: '김민수',
          username: 'minsu_kim',
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        expect(profile.displayName, equals('김민수'));
      });

      test('returns name with English name when available', () {
        const profile = UserProfile(
          id: 'user-1',
          name: '김민수',
          englishName: 'Minsu Kim',
          username: 'minsu_kim',
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        expect(profile.displayName, equals('김민수 (Minsu Kim)'));
      });
    });

    group('default values', () {
      test('tier defaults to STANDARD', () {
        const profile = UserProfile(
          id: 'user-1',
          name: 'Test',
          username: 'test',
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        expect(profile.tier, equals('STANDARD'));
      });

      test('subscriptionCount defaults to 0', () {
        const profile = UserProfile(
          id: 'user-1',
          name: 'Test',
          username: 'test',
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        expect(profile.subscriptionCount, equals(0));
      });

      test('dtBalance defaults to 0', () {
        const profile = UserProfile(
          id: 'user-1',
          name: 'Test',
          username: 'test',
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        expect(profile.dtBalance, equals(0));
      });

      test('nextPaymentDate defaults to null', () {
        const profile = UserProfile(
          id: 'user-1',
          name: 'Test',
          username: 'test',
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        expect(profile.nextPaymentDate, isNull);
      });
    });
  });

  group('Transaction', () {
    group('formattedAmount', () {
      test('returns positive format for credit', () {
        final transaction = Transaction(
          id: 'tx-1',
          description: 'DT 충전',
          amount: 1000,
          timestamp: DateTime(2024, 1, 15),
          type: TransactionType.credit,
        );

        expect(transaction.formattedAmount, equals('+1000 DT'));
      });

      test('returns negative format for debit', () {
        final transaction = Transaction(
          id: 'tx-1',
          description: '후원',
          amount: 500,
          timestamp: DateTime(2024, 1, 15),
          type: TransactionType.debit,
        );

        expect(transaction.formattedAmount, equals('-500 DT'));
      });

      test('handles zero amount for credit', () {
        final transaction = Transaction(
          id: 'tx-1',
          description: 'Test',
          amount: 0,
          timestamp: DateTime(2024, 1, 15),
          type: TransactionType.credit,
        );

        expect(transaction.formattedAmount, equals('+0 DT'));
      });

      test('handles zero amount for debit', () {
        final transaction = Transaction(
          id: 'tx-1',
          description: 'Test',
          amount: 0,
          timestamp: DateTime(2024, 1, 15),
          type: TransactionType.debit,
        );

        expect(transaction.formattedAmount, equals('-0 DT'));
      });

      test('handles large amounts', () {
        final transaction = Transaction(
          id: 'tx-1',
          description: 'Large purchase',
          amount: 999999,
          timestamp: DateTime(2024, 1, 15),
          type: TransactionType.credit,
        );

        expect(transaction.formattedAmount, equals('+999999 DT'));
      });
    });

    group('formattedDate', () {
      test('formats date with zero-padded month and day', () {
        final transaction = Transaction(
          id: 'tx-1',
          description: 'Test',
          amount: 100,
          timestamp: DateTime(2024, 1, 5),
          type: TransactionType.credit,
        );

        expect(transaction.formattedDate, equals('2024.01.05'));
      });

      test('formats date with double-digit month and day', () {
        final transaction = Transaction(
          id: 'tx-1',
          description: 'Test',
          amount: 100,
          timestamp: DateTime(2024, 12, 25),
          type: TransactionType.credit,
        );

        expect(transaction.formattedDate, equals('2024.12.25'));
      });

      test('formats date on month boundary', () {
        final transaction = Transaction(
          id: 'tx-1',
          description: 'Test',
          amount: 100,
          timestamp: DateTime(2024, 9, 30),
          type: TransactionType.credit,
        );

        expect(transaction.formattedDate, equals('2024.09.30'));
      });

      test('formats date at start of year', () {
        final transaction = Transaction(
          id: 'tx-1',
          description: 'Test',
          amount: 100,
          timestamp: DateTime(2024, 1, 1),
          type: TransactionType.credit,
        );

        expect(transaction.formattedDate, equals('2024.01.01'));
      });

      test('formats date at end of year', () {
        final transaction = Transaction(
          id: 'tx-1',
          description: 'Test',
          amount: 100,
          timestamp: DateTime(2024, 12, 31),
          type: TransactionType.credit,
        );

        expect(transaction.formattedDate, equals('2024.12.31'));
      });
    });
  });

  group('TransactionType', () {
    test('has credit and debit values', () {
      expect(TransactionType.values, hasLength(2));
      expect(TransactionType.values, contains(TransactionType.credit));
      expect(TransactionType.values, contains(TransactionType.debit));
    });
  });

  group('DTPackage', () {
    group('formattedPrice', () {
      test('formats price with comma separators', () {
        const package = DTPackage(
          id: 'pkg-1',
          name: '1000 DT',
          amount: 1000,
          price: 1100,
        );

        expect(package.formattedPrice, equals('₩1,100'));
      });

      test('formats large price with multiple commas', () {
        const package = DTPackage(
          id: 'pkg-1',
          name: '10000 DT',
          amount: 10000,
          price: 99000,
        );

        expect(package.formattedPrice, equals('₩99,000'));
      });

      test('formats very large price', () {
        const package = DTPackage(
          id: 'pkg-1',
          name: 'Premium',
          amount: 100000,
          price: 1000000,
        );

        expect(package.formattedPrice, equals('₩1,000,000'));
      });

      test('formats price without comma for small amounts', () {
        const package = DTPackage(
          id: 'pkg-1',
          name: 'Starter',
          amount: 100,
          price: 100,
        );

        expect(package.formattedPrice, equals('₩100'));
      });

      test('formats price at thousand boundary', () {
        const package = DTPackage(
          id: 'pkg-1',
          name: 'Basic',
          amount: 1000,
          price: 1000,
        );

        expect(package.formattedPrice, equals('₩1,000'));
      });

      test('formats price just under thousand', () {
        const package = DTPackage(
          id: 'pkg-1',
          name: 'Mini',
          amount: 500,
          price: 999,
        );

        expect(package.formattedPrice, equals('₩999'));
      });
    });

    group('default values', () {
      test('bonusAmount defaults to null', () {
        const package = DTPackage(
          id: 'pkg-1',
          name: 'Basic',
          amount: 1000,
          price: 1100,
        );

        expect(package.bonusAmount, isNull);
      });

      test('isPopular defaults to false', () {
        const package = DTPackage(
          id: 'pkg-1',
          name: 'Basic',
          amount: 1000,
          price: 1100,
        );

        expect(package.isPopular, isFalse);
      });
    });

    group('bonus amount', () {
      test('can have bonus amount', () {
        const package = DTPackage(
          id: 'pkg-1',
          name: 'Premium',
          amount: 10000,
          price: 9900,
          bonusAmount: 1000,
        );

        expect(package.bonusAmount, equals(1000));
      });
    });

    group('popular flag', () {
      test('can be marked as popular', () {
        const package = DTPackage(
          id: 'pkg-1',
          name: 'Popular Package',
          amount: 5000,
          price: 4900,
          isPopular: true,
        );

        expect(package.isPopular, isTrue);
      });
    });
  });
}
