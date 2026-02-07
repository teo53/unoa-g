import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';

/// Creator CRM Screen - Comprehensive analytics and revenue management
/// Includes: Revenue overview, Fan analytics, Content performance, Withdrawals
class CreatorCRMScreen extends ConsumerStatefulWidget {
  const CreatorCRMScreen({super.key});

  @override
  ConsumerState<CreatorCRMScreen> createState() => _CreatorCRMScreenState();
}

class _CreatorCRMScreenState extends ConsumerState<CreatorCRMScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '이번 달';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          // Header
          _buildHeader(context, isDark),

          // Tab bar
          _buildTabBar(isDark),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _RevenueTab(
                  selectedPeriod: _selectedPeriod,
                  onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
                ),
                const _FanCRMTab(),
                const _ContentPerformanceTab(),
                const _WithdrawalTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '통계 & 수익',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '크리에이터 CRM',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSubDark
                        : AppColors.textSubLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showInfoSheet(context, isDark),
            icon: Icon(
              Icons.info_outline,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor:
            isDark ? AppColors.textSubDark : AppColors.textSubLight,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: '수익'),
          Tab(text: '팬 분석'),
          Tab(text: '콘텐츠'),
          Tab(text: '출금'),
        ],
      ),
    );
  }

  void _showInfoSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CRM 안내',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 16),
            _InfoItem(
              icon: Icons.monetization_on_rounded,
              title: '수익',
              description: '후원, 구독 수익을 확인하고 분석하세요',
              isDark: isDark,
            ),
            _InfoItem(
              icon: Icons.people_rounded,
              title: '팬 분석',
              description: 'VIP 팬, 상위 후원자, 구독자 현황을 파악하세요',
              isDark: isDark,
            ),
            _InfoItem(
              icon: Icons.analytics_rounded,
              title: '콘텐츠',
              description: '어떤 메시지가 가장 반응이 좋은지 확인하세요',
              isDark: isDark,
            ),
            _InfoItem(
              icon: Icons.account_balance_wallet_rounded,
              title: '출금',
              description: '수익을 출금하고 내역을 확인하세요',
              isDark: isDark,
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSubDark
                        : AppColors.textSubLight,
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

// =============================================================================
// REVENUE TAB
// =============================================================================

class _RevenueTab extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const _RevenueTab({
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
        gradient: LinearGradient(
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
          Row(
            children: [
              _EarningsStat(
                label: '출금 가능',
                value: '845,000 DT',
              ),
              const SizedBox(width: 24),
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
      _RevenueItem('후원', 520000, Colors.pink, 0.54),
      _RevenueItem('구독', 450000, Colors.blue, 0.46),
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
              Icon(
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
                    '${_formatNumber(item.amount)} DT',
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
      _ChartData('1월', 450000),
      _ChartData('2월', 520000),
      _ChartData('3월', 380000),
      _ChartData('4월', 620000),
      _ChartData('5월', 780000),
      _ChartData('6월', 1245000),
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
              Icon(
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
                        _formatCompact(item.value),
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
                  Icon(
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
                child: Text(
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
                '+${_formatNumber(transaction.amount)} DT',
                style: TextStyle(
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
// FAN CRM TAB
// =============================================================================

class _FanCRMTab extends StatelessWidget {
  const _FanCRMTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subscriber stats
          _SubscriberStatsCard(isDark: isDark),
          const SizedBox(height: 20),

          // Tier breakdown
          _TierBreakdownCard(isDark: isDark),
          const SizedBox(height: 20),

          // Top donors
          _TopDonorsCard(isDark: isDark),
          const SizedBox(height: 20),

          // Engagement metrics
          _EngagementCard(isDark: isDark),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _SubscriberStatsCard extends StatelessWidget {
  final bool isDark;

  const _SubscriberStatsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.people_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '구독자 현황',
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
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: '총 구독자',
                  value: '1,250',
                  change: '+15',
                  isPositive: true,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: '신규 (이번 달)',
                  value: '89',
                  change: '+12%',
                  isPositive: true,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: '이탈율',
                  value: '3.2%',
                  change: '-0.5%',
                  isPositive: true,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final bool isPositive;
  final bool isDark;

  const _StatItem({
    required this.label,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: (isPositive ? AppColors.success : AppColors.error)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            change,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isPositive ? AppColors.success : AppColors.error,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TierBreakdownCard extends StatelessWidget {
  final bool isDark;

  const _TierBreakdownCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                '구독 등급별 현황',
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
          _TierRow(tier: 'VIP', count: 125, percentage: 10, color: Colors.amber, isDark: isDark),
          const SizedBox(height: 12),
          _TierRow(tier: 'STANDARD', count: 625, percentage: 50, color: AppColors.primary, isDark: isDark),
          const SizedBox(height: 12),
          _TierRow(tier: 'BASIC', count: 500, percentage: 40, color: Colors.grey, isDark: isDark),
        ],
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  final String tier;
  final int count;
  final int percentage;
  final Color color;
  final bool isDark;

  const _TierRow({
    required this.tier,
    required this.count,
    required this.percentage,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tier,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor:
                  isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 50,
          child: Text(
            '$count명',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 35,
          child: Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _TopDonorsCard extends StatelessWidget {
  final bool isDark;

  const _TopDonorsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final donors = [
      _Donor('팬클럽회장', 'VIP', 50000, 365),
      _Donor('응원봇', 'VIP', 25000, 180),
      _Donor('하늘덕후', 'VIP', 15000, 200),
      _Donor('열혈팬', 'STANDARD', 3500, 90),
      _Donor('별빛팬', 'STANDARD', 2000, 45),
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
              Icon(Icons.diamond_rounded, color: Colors.pink, size: 20),
              const SizedBox(width: 8),
              Text(
                '상위 후원자',
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
          const SizedBox(height: 16),
          ...donors.asMap().entries.map((entry) => _DonorTile(
                rank: entry.key + 1,
                donor: entry.value,
                isDark: isDark,
              )),
        ],
      ),
    );
  }
}

class _Donor {
  final String name;
  final String tier;
  final int totalDonation;
  final int subscribeDays;

  const _Donor(this.name, this.tier, this.totalDonation, this.subscribeDays);
}

class _DonorTile extends StatelessWidget {
  final int rank;
  final _Donor donor;
  final bool isDark;

  const _DonorTile({
    required this.rank,
    required this.donor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    if (rank == 1) {
      rankColor = Colors.amber;
    } else if (rank == 2) {
      rankColor = Colors.grey[400]!;
    } else if (rank == 3) {
      rankColor = Colors.brown[400]!;
    } else {
      rankColor = isDark ? Colors.grey[600]! : Colors.grey[300]!;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: rank <= 3 ? 1 : 0.3),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: rank <= 3 ? Colors.white : rankColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      donor.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: donor.tier == 'VIP'
                            ? Colors.amber[100]
                            : AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        donor.tier,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: donor.tier == 'VIP'
                              ? Colors.amber[800]
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${donor.subscribeDays}일째 구독 중',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatNumber(donor.totalDonation)} DT',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.pink,
            ),
          ),
        ],
      ),
    );
  }
}

class _EngagementCard extends StatelessWidget {
  final bool isDark;

  const _EngagementCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.insights_rounded, color: AppColors.verified, size: 20),
              const SizedBox(width: 8),
              Text(
                '참여도 지표',
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
          Row(
            children: [
              Expanded(
                child: _EngagementStat(
                  label: '평균 응답률',
                  value: '23%',
                  icon: Icons.reply_rounded,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _EngagementStat(
                  label: '메시지 열람률',
                  value: '87%',
                  icon: Icons.visibility_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _EngagementStat(
                  label: '평균 구독 기간',
                  value: '142일',
                  icon: Icons.calendar_today_rounded,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _EngagementStat(
                  label: '활성 팬 비율',
                  value: '65%',
                  icon: Icons.local_fire_department_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EngagementStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _EngagementStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
                ),
              ),
              Text(
                label,
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
}

// =============================================================================
// CONTENT PERFORMANCE TAB
// =============================================================================

class _ContentPerformanceTab extends StatelessWidget {
  const _ContentPerformanceTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content stats overview
          _ContentStatsCard(isDark: isDark),
          const SizedBox(height: 20),

          // Best performing messages
          _BestMessagesCard(isDark: isDark),
          const SizedBox(height: 20),

          // Message type performance
          _MessageTypePerformanceCard(isDark: isDark),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _ContentStatsCard extends StatelessWidget {
  final bool isDark;

  const _ContentStatsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.analytics_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '콘텐츠 성과 요약',
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
          Row(
            children: [
              Expanded(
                child: _ContentStatItem(
                  label: '총 브로드캐스트',
                  value: '156',
                  subLabel: '이번 달 +24',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _ContentStatItem(
                  label: '받은 답장',
                  value: '892',
                  subLabel: '평균 5.7개/메시지',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ContentStatItem(
                  label: '평균 열람률',
                  value: '87%',
                  subLabel: '업계 평균 대비 +12%',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _ContentStatItem(
                  label: '평균 응답률',
                  value: '23%',
                  subLabel: '업계 평균 대비 +5%',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContentStatItem extends StatelessWidget {
  final String label;
  final String value;
  final String subLabel;
  final bool isDark;

  const _ContentStatItem({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _BestMessagesCard extends StatelessWidget {
  final bool isDark;

  const _BestMessagesCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final messages = [
      _MessagePerf('오늘 연습 끝났어요! 집 가는 중~', 127, 89, '2시간 전'),
      _MessagePerf('컴백 준비 중... 기대해주세요!', 98, 76, '어제'),
      _MessagePerf('오늘 날씨 너무 좋다 ☀️', 76, 65, '2일 전'),
      _MessagePerf('새 앨범 작업 중이에요 🎵', 68, 58, '3일 전'),
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
              Icon(
                Icons.local_fire_department_rounded,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '반응 좋은 메시지',
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
          const SizedBox(height: 16),
          ...messages.asMap().entries.map((entry) => _MessagePerfTile(
                rank: entry.key + 1,
                message: entry.value,
                isDark: isDark,
              )),
        ],
      ),
    );
  }
}

class _MessagePerf {
  final String content;
  final int replyCount;
  final int readRate;
  final String time;

  const _MessagePerf(this.content, this.replyCount, this.readRate, this.time);
}

class _MessagePerfTile extends StatelessWidget {
  final int rank;
  final _MessagePerf message;
  final bool isDark;

  const _MessagePerfTile({
    required this.rank,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: rank == 1
                  ? Colors.orange
                  : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: rank == 1
                    ? Colors.white
                    : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _PerfBadge(
                      icon: Icons.reply_rounded,
                      value: '답장 ${message.replyCount}',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    _PerfBadge(
                      icon: Icons.visibility_rounded,
                      value: '열람 ${message.readRate}%',
                      color: AppColors.verified,
                    ),
                    const Spacer(),
                    Text(
                      message.time,
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
          ),
        ],
      ),
    );
  }
}

class _PerfBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _PerfBadge({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MessageTypePerformanceCard extends StatelessWidget {
  final bool isDark;

  const _MessageTypePerformanceCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.category_rounded, color: AppColors.verified, size: 20),
              const SizedBox(width: 8),
              Text(
                '메시지 유형별 성과',
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
          const SizedBox(height: 16),
          _TypePerfRow(
            type: '일상 공유',
            count: 68,
            avgReply: 8.2,
            avgRate: 91,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _TypePerfRow(
            type: '작업 근황',
            count: 45,
            avgReply: 12.5,
            avgRate: 94,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _TypePerfRow(
            type: '이벤트/공지',
            count: 23,
            avgReply: 5.3,
            avgRate: 88,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _TypePerfRow(
            type: '인사/감사',
            count: 20,
            avgReply: 6.8,
            avgRate: 85,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _TypePerfRow extends StatelessWidget {
  final String type;
  final int count;
  final double avgReply;
  final int avgRate;
  final bool isDark;

  const _TypePerfRow({
    required this.type,
    required this.count,
    required this.avgReply,
    required this.avgRate,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            type,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
        ),
        Expanded(
          child: Text(
            '${count}개',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            '답장 ${avgReply.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            '열람 $avgRate%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.success,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// WITHDRAWAL TAB
// =============================================================================

class _WithdrawalTab extends StatelessWidget {
  const _WithdrawalTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Available balance
          _BalanceCard(isDark: isDark),
          const SizedBox(height: 20),

          // Quick withdraw button
          _WithdrawButton(isDark: isDark),
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

  const _BalanceCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success,
            AppColors.success.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
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
                '출금 가능 잔액',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '845,000 DT',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '≈ ₩845,000',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '정산 대기 중: 400,000 DT (7일 후 출금 가능)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
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
        label: const Text('출금 신청하기'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.primary),
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
              '출금 신청',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textMainDark
                    : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '출금 가능 금액',
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
                color: isDark
                    ? AppColors.textMainDark
                    : AppColors.textMainLight,
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
                    label: '출금 수수료',
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
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('출금 신청이 완료되었습니다'),
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
                  '전액 출금 신청',
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
                  Icon(
                    Icons.history_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '출금 내역',
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
                '총 출금: ${_formatNumber(1050000)} DT',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
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
            child: Icon(
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
                  '${_formatNumber(withdrawal.amount)} DT 출금',
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
                    color: isDark
                        ? AppColors.textSubDark
                        : AppColors.textSubLight,
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
            child: Text(
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
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.verified, size: 20),
              const SizedBox(width: 8),
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
            '• 후원 수익은 7일 후 출금 가능합니다\n'
            '• 구독 수익은 매월 1일에 정산됩니다\n'
            '• 출금 수수료는 무료입니다\n'
            '• 최소 출금 금액은 10,000 DT입니다',
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

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

String _formatNumber(int number) {
  return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
}

String _formatCompact(int number) {
  if (number >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(1)}M';
  } else if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(number >= 10000 ? 0 : 1)}K';
  }
  return number.toString();
}
