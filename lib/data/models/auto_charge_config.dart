/// DT Auto-Charge Configuration Model
/// 자동충전 설정 데이터 모델
library;

class AutoChargeConfig {
  final String id;
  final String userId;
  final bool isEnabled;
  final int thresholdDt;
  final int chargeAmountDt;
  final String? chargePackageId;
  final String? billingKeyId;
  final int maxMonthlyCharges;
  final int chargesThisMonth;
  final DateTime? lastChargedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AutoChargeConfig({
    required this.id,
    required this.userId,
    this.isEnabled = false,
    this.thresholdDt = 100,
    this.chargeAmountDt = 1000,
    this.chargePackageId,
    this.billingKeyId,
    this.maxMonthlyCharges = 5,
    this.chargesThisMonth = 0,
    this.lastChargedAt,
    required this.createdAt,
    this.updatedAt,
  });

  bool get hasBillingKey => billingKeyId != null;
  bool get canChargeThisMonth => chargesThisMonth < maxMonthlyCharges;
  int get remainingCharges => maxMonthlyCharges - chargesThisMonth;

  factory AutoChargeConfig.fromJson(Map<String, dynamic> json) {
    return AutoChargeConfig(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      isEnabled: json['is_enabled'] as bool? ?? false,
      thresholdDt: json['threshold_dt'] as int? ?? 100,
      chargeAmountDt: json['charge_amount_dt'] as int? ?? 1000,
      chargePackageId: json['charge_package_id'] as String?,
      billingKeyId: json['billing_key_id'] as String?,
      maxMonthlyCharges: json['max_monthly_charges'] as int? ?? 5,
      chargesThisMonth: json['charges_this_month'] as int? ?? 0,
      lastChargedAt: json['last_charged_at'] != null
          ? DateTime.parse(json['last_charged_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'is_enabled': isEnabled,
      'threshold_dt': thresholdDt,
      'charge_amount_dt': chargeAmountDt,
      'charge_package_id': chargePackageId,
      'billing_key_id': billingKeyId,
      'max_monthly_charges': maxMonthlyCharges,
      'charges_this_month': chargesThisMonth,
      'last_charged_at': lastChargedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  AutoChargeConfig copyWith({
    String? id,
    String? userId,
    bool? isEnabled,
    int? thresholdDt,
    int? chargeAmountDt,
    String? chargePackageId,
    String? billingKeyId,
    int? maxMonthlyCharges,
    int? chargesThisMonth,
    DateTime? lastChargedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AutoChargeConfig(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isEnabled: isEnabled ?? this.isEnabled,
      thresholdDt: thresholdDt ?? this.thresholdDt,
      chargeAmountDt: chargeAmountDt ?? this.chargeAmountDt,
      chargePackageId: chargePackageId ?? this.chargePackageId,
      billingKeyId: billingKeyId ?? this.billingKeyId,
      maxMonthlyCharges: maxMonthlyCharges ?? this.maxMonthlyCharges,
      chargesThisMonth: chargesThisMonth ?? this.chargesThisMonth,
      lastChargedAt: lastChargedAt ?? this.lastChargedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AutoChargeConfig && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
