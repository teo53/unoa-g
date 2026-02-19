import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/settlement_provider.dart';
import 'crm_revenue_tab.dart' show formatNumber;

/// Withdrawal tab for Creator CRM
/// Shows balance, withdraw button, history, and pending earnings info
/// 정산 데이터를 settlement_provider에서 연동
class CrmWithdrawalTab extends ConsumerWidget {
  const CrmWithdrawalTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(settlementProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Available balance
          _BalanceCard(isDark: isDark, summary: state.summary),
          const SizedBox(height: 20),

          // Quick action buttons
          Row(
            children: [
              Expanded(
                child: _WithdrawButton(isDark: isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/creator/settlement'),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('정산 내역'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Withdrawal history
          _WithdrawalHistoryCard(isDark: isDark),
          const SizedBox(height: 20),

          // Pending earnings explanation
          _PendingEarningsCard(isDark: isDark),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final bool isDark;
  final SettlementSummary summary;

  const _BalanceCard({required this.isDark, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.success,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '지급 가능 잔액',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${formatNumber(summary.totalPayout)}원',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '총 ${summary.settlementCount}건 정산 완료',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '정산 대기 중: 400,000 DT (7일 후 지급 가능)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawButton extends StatelessWidget {
  final bool isDark;

  const _WithdrawButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showWithdrawSheet(context, isDark),
        icon: const Icon(Icons.account_balance_rounded),
        label: const Text('지급 신청하기'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.primary),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  void _showWithdrawSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '지급 신청',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '지급 가능 금액',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '845,000 DT (≈ ₩845,000)',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _WithdrawInfoRow(
                    label: '등록 계좌',
                    value: '신한은행 110-***-***890',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _WithdrawInfoRow(
                    label: '지급 수수료',
                    value: '0 DT (무료)',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _WithdrawInfoRow(
                    label: '예상 입금일',
                    value: '영업일 기준 1-2일',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('지급 신청이 완료되었습니다'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '전액 지급 신청',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WithdrawInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _WithdrawInfoRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
      ],
    );
  }
}

class _WithdrawalHistoryCard extends StatelessWidget {
  final bool isDark;

  const _WithdrawalHistoryCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final history = [
      _Withdrawal(500000, DateTime(2024, 6, 15), 'completed'),
      _Withdrawal(300000, DateTime(2024, 5, 20), 'completed'),
      _Withdrawal(250000, DateTime(2024, 4, 10), 'completed'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '지급 내역',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                ],
              ),
              Text(
                '총 지급: ${formatNumber(1050000)} DT',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...history.map((w) => _WithdrawalHistoryTile(
                withdrawal: w,
                isDark: isDark,
              )),
        ],
      ),
    );
  }
}

class _Withdrawal {
  final int amount;
  final DateTime date;
  final String status;

  const _Withdrawal(this.amount, this.date, this.status);
}

class _WithdrawalHistoryTile extends StatelessWidget {
  final _Withdrawal withdrawal;
  final bool isDark;

  const _WithdrawalHistoryTile({
    required this.withdrawal,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatNumber(withdrawal.amount)} DT 지급',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                Text(
                  '${withdrawal.date.year}.${withdrawal.date.month.toString().padLeft(2, '0')}.${withdrawal.date.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '완료',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingEarningsCard extends StatelessWidget {
  final bool isDark;

  const _PendingEarningsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.verified.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.verified.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.verified, size: 20),
              SizedBox(width: 8),
              Text(
                '정산 안내',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.verified,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• 후원 수익은 7일 후 지급 가능합니다\n'
            '• 구독 수익은 매월 1일에 정산됩니다\n'
            '• 지급 수수료는 무료입니다\n'
            '• 최소 지급 금액은 10,000 DT입니다',
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
        ],
      ),
    );
  }
}
