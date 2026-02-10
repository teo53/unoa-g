import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/accessibility_helper.dart';
import '../../providers/settlement_provider.dart';
import '../../shared/widgets/app_scaffold.dart';

/// 크리에이터 정산 내역 화면
/// DT 수익 + KRW 수익 분리 표시, 세금 공제 내역
class SettlementHistoryScreen extends ConsumerWidget {
  const SettlementHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(settlementProvider);

    return AppScaffold(
      showStatusBar: true,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              children: [
                AccessibleTapTarget(
                  semanticLabel: '뒤로가기',
                  onTap: () => context.pop(),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                  ),
                ),
                const Expanded(
                  child: Text(
                    '정산 내역',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // 세금 설정
                AccessibleTapTarget(
                  semanticLabel: '세금 설정',
                  onTap: () => context.push('/settings/tax'),
                  child: Icon(
                    Icons.settings_outlined,
                    color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ],
            ),
          ),

          if (state.isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                    const SizedBox(height: 12),
                    Text(state.error!, style: TextStyle(color: isDark ? AppColors.textSubDark : AppColors.textSubLight)),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => ref.read(settlementProvider.notifier).loadSettlements(),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Summary card
                  _buildSummaryCard(isDark, state),
                  const SizedBox(height: 20),

                  // Settlement list
                  Text(
                    '월별 정산 명세서',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (state.settlements.isEmpty)
                    _buildEmptyState(isDark)
                  else
                    ...state.settlements.map((s) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSettlementCard(isDark, s),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark, SettlementState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary600,
            AppColors.primary700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '누적 정산',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatKrw(state.summary.totalPayout)}원',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryItem('총 수익', '${_formatKrw(state.summary.totalRevenue)}원'),
              _buildSummaryItem('수수료', '-${_formatKrw(state.summary.totalFee)}원'),
              _buildSummaryItem('세금', '-${_formatKrw(state.summary.totalTax)}원'),
            ],
          ),
          if (state.summary.pendingAmount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    '정산 대기: ${_formatKrw(state.summary.pendingAmount)}원',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white60),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementCard(bool isDark, Settlement settlement) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                settlement.periodLabel,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  settlement.incomeTypeLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // DT Revenue
          if (settlement.dtTotalGross > 0) ...[
            _buildRevenueRow(
              isDark,
              icon: Icons.chat_bubble_outline,
              label: 'DT 수익 (메시징)',
              sublabel: '팁 ${settlement.dtTipsCount}건 + 카드 ${settlement.dtCardsCount}건 + 답글 ${settlement.dtRepliesCount}건',
              amount: settlement.dtRevenueKrw,
            ),
            const SizedBox(height: 8),
          ],

          // KRW Revenue (Funding)
          if (settlement.fundingRevenueKrw > 0) ...[
            _buildRevenueRow(
              isDark,
              icon: Icons.favorite_outline,
              label: 'KRW 수익 (펀딩)',
              sublabel: '캠페인 ${settlement.fundingCampaignsCount}개 / 후원 ${settlement.fundingPledgesCount}건',
              amount: settlement.fundingRevenueKrw,
            ),
            const SizedBox(height: 8),
          ],

          Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          const SizedBox(height: 8),

          // Breakdown
          _buildBreakdownRow(isDark, '총 수익', settlement.totalRevenueKrw, isBold: true),
          const SizedBox(height: 4),
          _buildBreakdownRow(isDark, '플랫폼 수수료 (${settlement.platformFeeRate.toStringAsFixed(0)}%)', -settlement.platformFeeKrw),
          const SizedBox(height: 4),
          _buildBreakdownRow(isDark, '원천징수세 (${settlement.taxRate.toStringAsFixed(1)}%)', -settlement.withholdingTaxKrw),
          const SizedBox(height: 8),
          Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          const SizedBox(height: 8),
          _buildBreakdownRow(isDark, '순 지급액', settlement.netPayoutKrw,
            isBold: true, color: AppColors.success),
        ],
      ),
    );
  }

  Widget _buildRevenueRow(bool isDark, {
    required IconData icon,
    required String label,
    required String sublabel,
    required int amount,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? AppColors.textSubDark : AppColors.textSubLight),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${_formatKrw(amount)}원',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(bool isDark, String label, int amount, {
    bool isBold = false,
    Color? color,
  }) {
    final isNegative = amount < 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
        ),
        Text(
          '${isNegative ? '-' : ''}${_formatKrw(amount.abs())}원',
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: color ?? (isNegative ? AppColors.danger : (isDark ? AppColors.textMainDark : AppColors.textMainLight)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
          const SizedBox(height: 12),
          Text(
            '아직 정산 내역이 없습니다',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '활동을 시작하면 매월 정산 내역이 생성됩니다',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
        ],
      ),
    );
  }

  String _formatKrw(int amount) {
    if (amount < 0) return '-${_formatKrw(-amount)}';
    if (amount < 1000) return amount.toString();
    final result = StringBuffer();
    final str = amount.toString();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) result.write(',');
      result.write(str[i]);
    }
    return result.toString();
  }
}
