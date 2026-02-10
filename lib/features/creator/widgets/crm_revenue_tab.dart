import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Revenue tab for Creator CRM
/// Shows total earnings, revenue breakdown, monthly chart, and recent transactions
class CrmRevenueTab extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const CrmRevenueTab({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          _PeriodSelector(
            selected: selectedPeriod,
            onChanged: onPeriodChanged,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // Total earnings card
          _TotalEarningsCard(isDark: isDark),
          const SizedBox(height: 20),

          // Revenue breakdown
          _RevenueBreakdownCard(isDark: isDark),
          const SizedBox(height: 20),

          // Monthly chart
          _MonthlyRevenueChart(isDark: isDark),
          const SizedBox(height: 20),

          // Recent transactions
          _RecentTransactionsCard(isDark: isDark),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final String selected;
  final Function(String) onChanged;
  final bool isDark;

  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final periods = ['오늘', '이번 주', '이번 달', '3개월', '전체'];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final period = periods[index];
          final isSelected = period == selected;

          return GestureDetector(
            onTap: () => onChanged(period),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                period,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TotalEarningsCard extends StatelessWidget {
  final bool isDark;

  const _TotalEarningsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '총 수익',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '+23%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '1,245,000 DT',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '≈ ₩1,245,000',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              _EarningsStat(
                label: '출금 가능',
                value: '845,000 DT',
              ),
              SizedBox(width: 24),
              _EarningsStat(
                label: '대기 중',
                value: '400,000 DT',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarningsStat extends StatelessWidget {
  final String label;
  final String value;

  const _EarningsStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _RevenueBreakdownCard extends StatelessWidget {
  final bool isDark;

  const _RevenueBreakdownCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = [
      const _RevenueItem('후원', 520000, Colors.pink, 0.54),
      const _RevenueItem('구독', 450000, Colors.blue, 0.46),
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
            children: [
              const Icon(
                Icons.pie_chart_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '수익 구성',
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
          const SizedBox(height: 20),

          // Progress bars
          ...items.map((item) => _RevenueProgressBar(
                item: item,
                isDark: isDark,
              )),

          const SizedBox(height: 12),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '합계',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
                ),
              ),
              Text(
                '970,000 DT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueItem {
  final String label;
  final int amount;
  final Color color;
  final double percentage;

  const _RevenueItem(this.label, this.amount, this.color, this.percentage);
}

class _RevenueProgressBar extends StatelessWidget {
  final _RevenueItem item;
  final bool isDark;

  const _RevenueProgressBar({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${formatNumber(item.amount)} DT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(item.percentage * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.percentage,
              backgroundColor: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              valueColor: AlwaysStoppedAnimation(item.color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyRevenueChart extends StatelessWidget {
  final bool isDark;

  const _MonthlyRevenueChart({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final data = [
      const _ChartData('1월', 450000),
      const _ChartData('2월', 520000),
      const _ChartData('3월', 380000),
      const _ChartData('4월', 620000),
      const _ChartData('5월', 780000),
      const _ChartData('6월', 1245000),
    ];
    final maxValue = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);

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
            children: [
              const Icon(
                Icons.show_chart_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '월별 수익 추이',
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
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((item) {
                final height = (item.value / maxValue) * 120;
                final isLast = item == data.last;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        formatCompact(item.value),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
                          color: isLast
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 32,
                        height: height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: isLast
                                ? [AppColors.primary, AppColors.primary600]
                                : [
                                    (isDark
                                            ? Colors.grey[700]
                                            : Colors.grey[300])!
                                        .withValues(alpha: 0.5),
                                    (isDark
                                        ? Colors.grey[600]
                                        : Colors.grey[200])!,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.month,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  final String month;
  final int value;

  const _ChartData(this.month, this.value);
}

class _RecentTransactionsCard extends StatelessWidget {
  final bool isDark;

  const _RecentTransactionsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final transactions = [
      _Transaction('후원', '하늘덕후', 500, DateTime.now()),
      _Transaction('구독', '별빛팬', 4900, DateTime.now().subtract(const Duration(hours: 2))),
      _Transaction('후원', '응원봇', 300, DateTime.now().subtract(const Duration(days: 1))),
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
                    Icons.receipt_long_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '최근 거래',
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
              TextButton(
                onPressed: () {},
                child: const Text(
                  '전체보기',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...transactions.map((t) => _TransactionTile(
                transaction: t,
                isDark: isDark,
              )),
        ],
      ),
    );
  }
}

class _Transaction {
  final String type;
  final String fanName;
  final int amount;
  final DateTime time;

  const _Transaction(this.type, this.fanName, this.amount, this.time);
}

class _TransactionTile extends StatelessWidget {
  final _Transaction transaction;
  final bool isDark;

  const _TransactionTile({required this.transaction, required this.isDark});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (transaction.type) {
      case '후원':
        icon = Icons.diamond_rounded;
        color = Colors.pink;
        break;
      case '구독':
        icon = Icons.card_membership_rounded;
        color = Colors.blue;
        break;
      default:
        icon = Icons.monetization_on;
        color = AppColors.primary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.fanName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                Text(
                  transaction.type,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSubDark
                        : AppColors.textSubLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${formatNumber(transaction.amount)} DT',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
              Text(
                _formatTime(transaction.time),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else {
      return '${diff.inDays}일 전';
    }
  }
}

// =============================================================================
// SHARED HELPER FUNCTIONS
// =============================================================================

String formatNumber(int number) {
  return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
}

String formatCompact(int number) {
  if (number >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(1)}M';
  } else if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(number >= 10000 ? 0 : 1)}K';
  }
  return number.toString();
}
