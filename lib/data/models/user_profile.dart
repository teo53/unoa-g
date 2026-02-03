/// User Profile Models - Re-exports and Legacy Support
///
/// This file provides backward compatibility for existing code.
/// For new code, import directly from:
/// - `data/models/user.dart` for UserAuthProfile and UserDisplayProfile

// Re-export from unified user models
export 'user.dart' show UserAuthProfile, UserDisplayProfile, UserBase;

// Legacy alias for UI display profile
// @deprecated Use UserDisplayProfile instead
import 'user.dart';
typedef UserProfile = UserDisplayProfile;

/// Transaction Model for wallet history
class Transaction {
  final String id;
  final String description;
  final int amount;
  final DateTime timestamp;
  final TransactionType type;

  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.timestamp,
    required this.type,
  });

  String get formattedAmount {
    final sign = type == TransactionType.credit ? '+' : '-';
    return '$sign$amount DT';
  }

  String get formattedDate {
    return '${timestamp.year}.${timestamp.month.toString().padLeft(2, '0')}.${timestamp.day.toString().padLeft(2, '0')}';
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      description: json['description'] as String? ?? '',
      amount: json['amount'] as int? ?? json['amount_dt'] as int? ?? 0,
      timestamp: DateTime.parse(json['timestamp'] as String? ?? json['created_at'] as String),
      type: (json['type'] as String? ?? json['entry_type'] as String?) == 'credit'
          ? TransactionType.credit
          : TransactionType.debit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'type': type == TransactionType.credit ? 'credit' : 'debit',
    };
  }
}

enum TransactionType {
  credit,
  debit,
}

// Note: DTPackage has been moved to dt_package.dart
// Use: import 'package:unoa/data/models/dt_package.dart';
