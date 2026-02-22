import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/demo_config.dart';
import '../core/utils/app_logger.dart';
import 'auth_provider.dart';
import 'repository_providers.dart';

// ============================================================================
// Models
// ============================================================================

/// 정산 명세서
class Settlement {
  final String id;
  final String payoutId;
  final String creatorId;
  final String periodStart;
  final String periodEnd;

  // DT 수익
  final int dtTipsCount;
  final int dtTipsGross;
  final int dtCardsCount;
  final int dtCardsGross;
  final int dtRepliesCount;
  final int dtRepliesGross;
  final int dtTotalGross;
  final double dtToKrwRate;
  final int dtRevenueKrw;

  // KRW 수익 (펀딩)
  final int fundingCampaignsCount;
  final int fundingPledgesCount;
  final int fundingRevenueKrw;

  // 합산
  final int totalRevenueKrw;
  final double platformFeeRate;
  final int platformFeeKrw;

  // 세금
  final String incomeType;
  final double taxRate;
  final int incomeTaxKrw;
  final int localTaxKrw;
  final int withholdingTaxKrw;

  // 지급
  final int netPayoutKrw;
  final String? pdfUrl;
  final DateTime createdAt;

  const Settlement({
    required this.id,
    required this.payoutId,
    required this.creatorId,
    required this.periodStart,
    required this.periodEnd,
    this.dtTipsCount = 0,
    this.dtTipsGross = 0,
    this.dtCardsCount = 0,
    this.dtCardsGross = 0,
    this.dtRepliesCount = 0,
    this.dtRepliesGross = 0,
    this.dtTotalGross = 0,
    this.dtToKrwRate = 100.0,
    this.dtRevenueKrw = 0,
    this.fundingCampaignsCount = 0,
    this.fundingPledgesCount = 0,
    this.fundingRevenueKrw = 0,
    this.totalRevenueKrw = 0,
    this.platformFeeRate = 20.0,
    this.platformFeeKrw = 0,
    this.incomeType = 'business_income',
    this.taxRate = 3.3,
    this.incomeTaxKrw = 0,
    this.localTaxKrw = 0,
    this.withholdingTaxKrw = 0,
    this.netPayoutKrw = 0,
    this.pdfUrl,
    required this.createdAt,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['id'] as String,
      payoutId: json['payout_id'] as String,
      creatorId: json['creator_id'] as String,
      periodStart: json['period_start'] as String,
      periodEnd: json['period_end'] as String,
      dtTipsCount: (json['dt_tips_count'] as num?)?.toInt() ?? 0,
      dtTipsGross: (json['dt_tips_gross'] as num?)?.toInt() ?? 0,
      dtCardsCount: (json['dt_cards_count'] as num?)?.toInt() ?? 0,
      dtCardsGross: (json['dt_cards_gross'] as num?)?.toInt() ?? 0,
      dtRepliesCount: (json['dt_replies_count'] as num?)?.toInt() ?? 0,
      dtRepliesGross: (json['dt_replies_gross'] as num?)?.toInt() ?? 0,
      dtTotalGross: (json['dt_total_gross'] as num?)?.toInt() ?? 0,
      dtToKrwRate: (json['dt_to_krw_rate'] as num?)?.toDouble() ?? 100.0,
      dtRevenueKrw: (json['dt_revenue_krw'] as num?)?.toInt() ?? 0,
      fundingCampaignsCount:
          (json['funding_campaigns_count'] as num?)?.toInt() ?? 0,
      fundingPledgesCount:
          (json['funding_pledges_count'] as num?)?.toInt() ?? 0,
      fundingRevenueKrw: (json['funding_revenue_krw'] as num?)?.toInt() ?? 0,
      totalRevenueKrw: (json['total_revenue_krw'] as num?)?.toInt() ?? 0,
      platformFeeRate: (json['platform_fee_rate'] as num?)?.toDouble() ?? 20.0,
      platformFeeKrw: (json['platform_fee_krw'] as num?)?.toInt() ?? 0,
      incomeType: json['income_type'] as String? ?? 'business_income',
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 3.3,
      incomeTaxKrw: (json['income_tax_krw'] as num?)?.toInt() ?? 0,
      localTaxKrw: (json['local_tax_krw'] as num?)?.toInt() ?? 0,
      withholdingTaxKrw: (json['withholding_tax_krw'] as num?)?.toInt() ?? 0,
      netPayoutKrw: (json['net_payout_krw'] as num?)?.toInt() ?? 0,
      pdfUrl: json['pdf_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  String get incomeTypeLabel {
    switch (incomeType) {
      case 'business_income':
        return '사업소득 (3.3%)';
      case 'other_income':
        return '기타소득 (8.8%)';
      case 'invoice':
        return '세금계산서 (0%)';
      case 'non_resident':
        return '비거주자 (22%)';
      default:
        return incomeType;
    }
  }

  String get periodLabel => '$periodStart ~ $periodEnd';
}

/// 정산 요약
class SettlementSummary {
  final int totalRevenue;
  final int totalFee;
  final int totalTax;
  final int totalPayout;
  final int pendingAmount;
  final int settlementCount;

  const SettlementSummary({
    this.totalRevenue = 0,
    this.totalFee = 0,
    this.totalTax = 0,
    this.totalPayout = 0,
    this.pendingAmount = 0,
    this.settlementCount = 0,
  });
}

/// 정산 상태
class SettlementState {
  final List<Settlement> settlements;
  final SettlementSummary summary;
  final String? incomeType;
  final double? taxRate;
  final bool isLoading;
  final String? error;

  const SettlementState({
    this.settlements = const [],
    this.summary = const SettlementSummary(),
    this.incomeType,
    this.taxRate,
    this.isLoading = false,
    this.error,
  });

  SettlementState copyWith({
    List<Settlement>? settlements,
    SettlementSummary? summary,
    String? incomeType,
    double? taxRate,
    bool? isLoading,
    String? error,
  }) {
    return SettlementState(
      settlements: settlements ?? this.settlements,
      summary: summary ?? this.summary,
      incomeType: incomeType ?? this.incomeType,
      taxRate: taxRate ?? this.taxRate,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ============================================================================
// Notifier
// ============================================================================

class SettlementNotifier extends StateNotifier<SettlementState> {
  final Ref _ref;

  SettlementNotifier(this._ref) : super(const SettlementState()) {
    loadSettlements();
  }

  Future<void> loadSettlements() async {
    state = state.copyWith(isLoading: true, error: null);

    final authState = _ref.read(authProvider);
    final isDemoMode = authState is AuthDemoMode;

    if (isDemoMode) {
      await _loadDemoSettlements();
    } else {
      await _loadRealSettlements();
    }
  }

  Future<void> _loadDemoSettlements() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    final settlements = [
      // 데모 정산 1: 1 DT = 100 KRW 기준
      // DT 팁 3500 DT × 100 = 350,000원, 카드 1800 DT × 100 = 180,000원,
      // 답글 240 DT × 100 = 24,000원 → DT 합계 5540 DT = 554,000원
      // 펀딩 690,000원 → 총 수익 1,244,000원
      // 수수료 20% = 248,800원 → 과세대상 995,200원
      // 원천징수 3.3% = 32,842원 (소득세 29,856 + 지방세 2,986)
      // 순 지급 = 962,358원
      Settlement(
        id: 'demo_settlement_1',
        payoutId: 'demo_payout_1',
        creatorId: DemoConfig.demoCreatorId,
        periodStart:
            '${now.year}-${(now.month - 1).toString().padLeft(2, '0')}-01',
        periodEnd:
            '${now.year}-${(now.month - 1).toString().padLeft(2, '0')}-${DateTime(now.year, now.month, 0).day}',
        dtTipsCount: 45,
        dtTipsGross: 3500,
        dtCardsCount: 12,
        dtCardsGross: 1800,
        dtRepliesCount: 8,
        dtRepliesGross: 240,
        dtTotalGross: 5540,
        dtToKrwRate: 100.0,
        dtRevenueKrw: 554000,
        fundingCampaignsCount: 1,
        fundingPledgesCount: 23,
        fundingRevenueKrw: 690000,
        totalRevenueKrw: 1244000,
        platformFeeRate: 20.0,
        platformFeeKrw: 248800,
        incomeType: 'business_income',
        taxRate: 3.3,
        incomeTaxKrw: 29856,
        localTaxKrw: 2986,
        withholdingTaxKrw: 32842,
        netPayoutKrw: 962358,
        createdAt: DateTime(now.year, now.month, 1),
      ),
      // 데모 정산 2: DT만 있는 월
      // DT 팁 2800 DT, 카드 1200 DT, 답글 150 DT = 4150 DT × 100 = 415,000원
      // 수수료 20% = 83,000원 → 과세대상 332,000원
      // 원천징수 3.3% = 10,956원
      // 순 지급 = 321,044원
      Settlement(
        id: 'demo_settlement_2',
        payoutId: 'demo_payout_2',
        creatorId: DemoConfig.demoCreatorId,
        periodStart:
            '${now.year}-${(now.month - 2).toString().padLeft(2, '0')}-01',
        periodEnd:
            '${now.year}-${(now.month - 2).toString().padLeft(2, '0')}-${DateTime(now.year, now.month - 1, 0).day}',
        dtTipsCount: 38,
        dtTipsGross: 2800,
        dtCardsCount: 8,
        dtCardsGross: 1200,
        dtRepliesCount: 5,
        dtRepliesGross: 150,
        dtTotalGross: 4150,
        dtToKrwRate: 100.0,
        dtRevenueKrw: 415000,
        fundingCampaignsCount: 0,
        fundingPledgesCount: 0,
        fundingRevenueKrw: 0,
        totalRevenueKrw: 415000,
        platformFeeRate: 20.0,
        platformFeeKrw: 83000,
        incomeType: 'business_income',
        taxRate: 3.3,
        incomeTaxKrw: 9960,
        localTaxKrw: 996,
        withholdingTaxKrw: 10956,
        netPayoutKrw: 321044,
        createdAt: DateTime(now.year, now.month - 1, 1),
      ),
    ];

    final summary = SettlementSummary(
      totalRevenue: settlements.fold(0, (sum, s) => sum + s.totalRevenueKrw),
      totalFee: settlements.fold(0, (sum, s) => sum + s.platformFeeKrw),
      totalTax: settlements.fold(0, (sum, s) => sum + s.withholdingTaxKrw),
      totalPayout: settlements.fold(0, (sum, s) => sum + s.netPayoutKrw),
      pendingAmount: 400000,
      settlementCount: settlements.length,
    );

    state = SettlementState(
      settlements: settlements,
      summary: summary,
      incomeType: 'business_income',
      taxRate: 3.3,
      isLoading: false,
    );
  }

  Future<void> _loadRealSettlements() async {
    try {
      final repo = _ref.read(settlementRepositoryProvider);

      // 정산 명세서 조회
      final response = await repo.getStatements();

      final settlements =
          response.map((json) => Settlement.fromJson(json)).toList();

      // 세금 설정 조회
      final payoutSettings = await repo.getPayoutSettings();

      final incomeType =
          (payoutSettings?['income_type'] as String?) ?? 'business_income';

      // 요약 계산
      final summary = SettlementSummary(
        totalRevenue: settlements.fold(0, (sum, s) => sum + s.totalRevenueKrw),
        totalFee: settlements.fold(0, (sum, s) => sum + s.platformFeeKrw),
        totalTax: settlements.fold(0, (sum, s) => sum + s.withholdingTaxKrw),
        totalPayout: settlements.fold(0, (sum, s) => sum + s.netPayoutKrw),
        settlementCount: settlements.length,
      );

      state = SettlementState(
        settlements: settlements,
        summary: summary,
        incomeType: incomeType,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error(e, tag: 'Settlement', message: 'Settlement load error');
      state = state.copyWith(isLoading: false, error: '정산 정보를 불러올 수 없습니다');
    }
  }

  /// 소득유형 변경
  Future<bool> updateIncomeType(String incomeType) async {
    final authState = _ref.read(authProvider);
    final isDemoMode = authState is AuthDemoMode;

    if (isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(incomeType: incomeType);
      return true;
    }

    try {
      final repo = _ref.read(settlementRepositoryProvider);
      await repo.updateIncomeType(incomeType);

      state = state.copyWith(incomeType: incomeType);
      return true;
    } catch (e) {
      AppLogger.error(e,
          tag: 'Settlement', message: 'Income type update error');
      return false;
    }
  }

  /// CSV 내보내기
  Future<String?> exportCsv(String periodStart, String periodEnd) async {
    try {
      final repo = _ref.read(settlementRepositoryProvider);
      final result = await repo.exportCsv(
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      return result;
    } catch (e) {
      AppLogger.error(e, tag: 'Settlement', message: 'Settlement export error');
      return null;
    }
  }
}

// ============================================================================
// Providers
// ============================================================================

final settlementProvider =
    StateNotifierProvider<SettlementNotifier, SettlementState>((ref) {
  return SettlementNotifier(ref);
});
