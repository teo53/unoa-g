class UserProfile {
  final String id;
  final String name;
  final String? englishName;
  final String username;
  final String avatarUrl;
  final String tier; // STANDARD, VIP
  final int subscriptionCount;
  final int dtBalance;
  final DateTime? nextPaymentDate;

  const UserProfile({
    required this.id,
    required this.name,
    this.englishName,
    required this.username,
    required this.avatarUrl,
    this.tier = 'STANDARD',
    this.subscriptionCount = 0,
    this.dtBalance = 0,
    this.nextPaymentDate,
  });

  String get displayName =>
      englishName != null ? '$name ($englishName)' : name;
}

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
}

enum TransactionType {
  credit,
  debit,
}

class DTPackage {
  final String id;
  final String name;
  final int amount;
  final int price;
  final int? bonusAmount;
  final bool isPopular;

  const DTPackage({
    required this.id,
    required this.name,
    required this.amount,
    required this.price,
    this.bonusAmount,
    this.isPopular = false,
  });

  String get formattedPrice => '₩${price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
}
