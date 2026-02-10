/// DT Package Model
/// Unified model for DT (Diamond Token) packages
/// Used for in-app purchases of virtual currency
library;

class DtPackage {
  final String id;
  final String name;
  final int dtAmount;
  final int bonusDt;
  final int priceKrw;
  final bool isPopular;
  final bool isActive;

  const DtPackage({
    required this.id,
    required this.name,
    required this.dtAmount,
    this.bonusDt = 0,
    required this.priceKrw,
    this.isPopular = false,
    this.isActive = true,
  });

  /// Total DT amount including bonus
  int get totalDt => dtAmount + bonusDt;

  /// Formatted price in KRW
  String get formattedPrice => '${_formatNumber(priceKrw)}원';

  /// Formatted total DT
  String get formattedDt => '${_formatNumber(totalDt)} DT';

  /// Bonus text for display
  String get bonusText => bonusDt > 0 ? '+${_formatNumber(bonusDt)} 보너스' : '';

  /// Calculate price per DT
  double get pricePerDt => priceKrw / totalDt;

  /// Formatted price per DT
  String get formattedPricePerDt => '${pricePerDt.toStringAsFixed(0)}원/DT';

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  factory DtPackage.fromJson(Map<String, dynamic> json) {
    return DtPackage(
      id: json['id'] as String,
      name: json['name'] as String,
      dtAmount: json['dt_amount'] as int,
      bonusDt: json['bonus_dt'] as int? ?? 0,
      priceKrw: json['price_krw'] as int,
      isPopular: json['is_popular'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dt_amount': dtAmount,
      'bonus_dt': bonusDt,
      'price_krw': priceKrw,
      'is_popular': isPopular,
      'is_active': isActive,
    };
  }

  DtPackage copyWith({
    String? id,
    String? name,
    int? dtAmount,
    int? bonusDt,
    int? priceKrw,
    bool? isPopular,
    bool? isActive,
  }) {
    return DtPackage(
      id: id ?? this.id,
      name: name ?? this.name,
      dtAmount: dtAmount ?? this.dtAmount,
      bonusDt: bonusDt ?? this.bonusDt,
      priceKrw: priceKrw ?? this.priceKrw,
      isPopular: isPopular ?? this.isPopular,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DtPackage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DtPackage{id: $id, name: $name, dtAmount: $dtAmount, bonusDt: $bonusDt, priceKrw: $priceKrw}';
  }
}
