import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'crm_revenue_tab.dart' show formatNumber;

/// Fan CRM tab for Creator CRM
/// Shows subscriber stats, tier breakdown, top donors, engagement metrics
class CrmFanTab extends StatelessWidget {
  const CrmFanTab({super.key});

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
              const Icon(Icons.people_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '구독자 현황',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
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
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                '구독 등급별 현황',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _TierRow(
              tier: 'VIP',
              count: 125,
              percentage: 10,
              color: Colors.amber,
              isDark: isDark),
          const SizedBox(height: 12),
          _TierRow(
              tier: 'STANDARD',
              count: 625,
              percentage: 50,
              color: AppColors.primary,
              isDark: isDark),
          const SizedBox(height: 12),
          _TierRow(
              tier: 'BASIC',
              count: 500,
              percentage: 40,
              color: Colors.grey,
              isDark: isDark),
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
      const _Donor('팬클럽회장', 'VIP', 50000, 365),
      const _Donor('응원봇', 'VIP', 25000, 180),
      const _Donor('하늘덕후', 'VIP', 15000, 200),
      const _Donor('열혈팬', 'STANDARD', 3500, 90),
      const _Donor('별빛팬', 'STANDARD', 2000, 45),
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
              const Icon(Icons.diamond_rounded, color: Colors.pink, size: 20),
              const SizedBox(width: 8),
              Text(
                '상위 후원자',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
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
                    color:
                        isDark ? AppColors.textMutedDark : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${formatNumber(donor.totalDonation)} DT',
            style: const TextStyle(
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
              const Icon(Icons.insights_rounded,
                  color: AppColors.verified, size: 20),
              const SizedBox(width: 8),
              Text(
                '참여도 지표',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
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
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
