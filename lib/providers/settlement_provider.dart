import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/demo_config.dart';
import 'auth_provider.dart';

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
    this.dtToKrwRate = 1.0,
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
      dtToKrwRate: (json['dt_to_krw_rate'] as num?)?.toDouble() ?? 1.0,
      dtRevenueKrw: (json['dt_revenue_krw'] as num?)?.toInt() ?? 0,
      fundingCampaignsCount: (json['funding_campaigns_count'] as num?)?.toInt() ?? 0,
      fundingPledgesCount: (json['funding_pledges_count'] as num?)?.toInt() ?? 0,
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
      Settlement(
        id: 'demo_settlement_1',
        payoutId: 'demo_payout_1',
        creatorId: DemoConfig.demoCreatorId,
        periodStart: '${now.year}-${(now.month - 1).toString().padLeft(2, '0')}-01',
        periodEnd: '${now.year}-${(now.month - 1).toString().padLeft(2, '0')}-${DateTime(now.year, now.month, 0).day}',
        dtTipsCount: 45,
        dtTipsGross: 350000,
        dtCardsCount: 12,
        dtCardsGross: 180000,
        dtRepliesCount: 8,
        dtRepliesGross: 24000,
        dtTotalGross: 554000,
        dtRevenueKrw: 554000,
        fundingCampaignsCount: 1,
        fundingPledgesCount: 23,
        fundingRevenueKrw: 690000,
        totalRevenueKrw: 1244000,
        platformFeeRate: 20.0,
        platformFeeKrw: 248800,
        incomeType: 'business_income',
        taxRate: 3.3,
        incomeTaxKrw: 29857,
        localTaxKrw: 2986,
        withholdingTaxKrw: 32843,
        netPayoutKrw: 962357,
        createdAt: DateTime(now.year, now.month, 1),
      ),
      Settlement(
        id: 'demo_settlement_2',
        payoutId: 'demo_payout_2',
        creatorId: DemoConfig.demoCreatorId,
        periodStart: '${now.year}-${(now.month - 2).toString().padLeft(2, '0')}-01',
        periodEnd: '${now.year}-${(now.month - 2).toString().padLeft(2, '0')}-${DateTime(now.year, now.month - 1, 0).day}',
        dtTipsCount: 38,
        dtTipsGross: 280000,
        dtCardsCount: 8,
        dtCardsGross: 120000,
        dtRepliesCount: 5,
        dtRepliesGross: 15000,
        dtTotalGross: 415000,
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
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(isLoading: false, error: '로그인이 필요합니다');
        return;
      }

      // 정산 명세서 조회
      final response = await supabase
          .from('settlement_statements')
          .select('*')
          .eq('creator_id', userId)
          .order('period_start', ascending: false)
          .limit(24);

      final settlements = (response as List)
          .map((json) => Settlement.fromJson(json as Map<String, dynamic>))
          .toList();

      // 세금 설정 조회
      final payoutSettings = await supabase
          .from('payout_settings')
          .select('income_type')
          .eq('creator_id', userId)
          .maybeSingle();

      final incomeType = (payoutSettings?['income_type'] as String?) ?? 'business_income';

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
      debugPrint('Settlement load error: $e');
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
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await supabase.from('payout_settings').upsert({
        'creator_id': userId,
        'income_type': incomeType,
        'updated_at': DateTime.now().toIso8601String(),
      });

      state = state.copyWith(incomeType: incomeType);
      return true;
    } catch (e) {
      debugPrint('Income type update error: $e');
      return false;
    }
  }

  /// CSV 내보내기
  Future<String?> exportCsv(String periodStart, String periodEnd) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        'settlement-export',
        body: {
          'type': 'csv',
          'periodStart': periodStart,
          'periodEnd': periodEnd,
        },
      );
      // CSV 데이터 반환
      return response.data?.toString();
    } catch (e) {
      debugPrint('Export error: $e');
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
