// Agency-related models for creator-side agency integration.
// These models represent the agency data as seen by a creator
// (read-only contract info, agency profile, settlement breakdown).

/// Basic agency information (read-only for creators)
class Agency {
  final String id;
  final String name;
  final String? logoUrl;
  final String status;

  const Agency({
    required this.id,
    required this.name,
    this.logoUrl,
    this.status = 'active',
  });

  factory Agency.fromJson(Map<String, dynamic> json) {
    return Agency(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }
}

/// Agency contract as seen by the creator
class AgencyContract {
  final String id;
  final String agencyId;
  final String agencyName;
  final String? agencyLogoUrl;
  final String status;
  final double revenueShareRate;
  final String settlementPeriod;
  final String? contractStartDate;
  final String? contractEndDate;
  final bool hasPowerOfAttorney;
  final String? notes;
  final String createdAt;

  const AgencyContract({
    required this.id,
    required this.agencyId,
    required this.agencyName,
    this.agencyLogoUrl,
    required this.status,
    required this.revenueShareRate,
    this.settlementPeriod = 'monthly',
    this.contractStartDate,
    this.contractEndDate,
    this.hasPowerOfAttorney = false,
    this.notes,
    required this.createdAt,
  });

  factory AgencyContract.fromJson(Map<String, dynamic> json) {
    return AgencyContract(
      id: json['id'] as String,
      agencyId: json['agency_id'] as String,
      agencyName: json['agency_name'] as String? ?? '',
      agencyLogoUrl: json['agency_logo_url'] as String?,
      status: json['status'] as String,
      revenueShareRate: (json['revenue_share_rate'] as num?)?.toDouble() ?? 0.0,
      settlementPeriod: json['settlement_period'] as String? ?? 'monthly',
      contractStartDate: json['contract_start_date'] as String?,
      contractEndDate: json['contract_end_date'] as String?,
      hasPowerOfAttorney: json['power_of_attorney_url'] != null,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';

  String get statusLabel {
    switch (status) {
      case 'active':
        return '활성';
      case 'pending':
        return '승인 대기';
      case 'paused':
        return '일시정지';
      case 'terminated':
        return '해지';
      default:
        return status;
    }
  }

  String get settlementPeriodLabel {
    switch (settlementPeriod) {
      case 'weekly':
        return '주간';
      case 'biweekly':
        return '격주';
      case 'monthly':
        return '월간';
      default:
        return settlementPeriod;
    }
  }

  String get contractPeriodLabel {
    if (contractStartDate == null) return '-';
    final start = contractStartDate!.substring(0, 10);
    if (contractEndDate == null) return '$start ~ 무기한';
    final end = contractEndDate!.substring(0, 10);
    return '$start ~ $end';
  }

  String get settlementModeLabel =>
      hasPowerOfAttorney ? '통합 정산 (위임장)' : '개별 정산';
}

/// Agency invitation (pending contract) for acceptance UI
class AgencyInvitation {
  final String contractId;
  final String agencyId;
  final String agencyName;
  final String? agencyLogoUrl;
  final double revenueShareRate;
  final String? contractStartDate;
  final String? contractEndDate;
  final String settlementPeriod;
  final bool hasPowerOfAttorney;
  final String? notes;
  final String createdAt;

  const AgencyInvitation({
    required this.contractId,
    required this.agencyId,
    required this.agencyName,
    this.agencyLogoUrl,
    required this.revenueShareRate,
    this.contractStartDate,
    this.contractEndDate,
    this.settlementPeriod = 'monthly',
    this.hasPowerOfAttorney = false,
    this.notes,
    required this.createdAt,
  });

  factory AgencyInvitation.fromJson(Map<String, dynamic> json) {
    return AgencyInvitation(
      contractId: json['id'] as String,
      agencyId: json['agency_id'] as String,
      agencyName: json['agency_name'] as String? ?? '',
      agencyLogoUrl: json['agency_logo_url'] as String?,
      revenueShareRate: (json['revenue_share_rate'] as num?)?.toDouble() ?? 0.0,
      contractStartDate: json['contract_start_date'] as String?,
      contractEndDate: json['contract_end_date'] as String?,
      settlementPeriod: json['settlement_period'] as String? ?? 'monthly',
      hasPowerOfAttorney: json['power_of_attorney_url'] != null,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
    );
  }
}
