import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/funding_provider.dart';

/// Campaign statistics screen for creators
class CampaignStatsScreen extends ConsumerWidget {
  final String campaignId;

  const CampaignStatsScreen({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final campaign = ref.watch(fundingProvider.notifier).getCampaignById(campaignId);
    final stats = ref.watch(fundingProvider.notifier).getStatsForCampaign(campaignId);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        title: Text(
          '펀딩 통계',
          style: TextStyle(
            color: isDark ? AppColors.textDark : AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.textDark : AppColors.text,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Campaign title
          if (campaign != null) ...[
            Text(
              campaign.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textDark : AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              campaign.status.label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Key metrics
          _buildMetricsGrid(isDark, stats),

          const SizedBox(height: 24),

          // Funding progress
          _buildSection(
            isDark,
            '펀딩 달성률',
            _buildProgressSection(isDark, stats),
          ),

          const SizedBox(height: 16),

          // Tier distribution
          _buildSection(
            isDark,
            '리워드별 후원자 분포',
            _buildTierDistribution(isDark, stats),
          ),

          const SizedBox(height: 16),

          // Daily funding data
          _buildSection(
            isDark,
            '일별 후원 현황',
            _buildDailyChart(isDark, stats),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(bool isDark, CampaignStats stats) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            isDark: isDark,
            label: '총 후원자',
            value: '${stats.totalBackers}명',
            icon: Icons.people_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            isDark: isDark,
            label: '총 모금액',
            value: '${_formatNumber(stats.totalRaisedKrw)}원',
            icon: Icons.savings_rounded,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(bool isDark, CampaignStats stats) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${stats.fundingPercent.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: stats.fundingPercent >= 100
                    ? AppColors.success
                    : AppColors.primary,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '평균 후원금',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                  ),
                ),
                Text(
                  '${_formatNumber(stats.avgPledgeKrw)}원',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDark : AppColors.text,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (stats.fundingPercent / 100).clamp(0.0, 1.0),
            backgroundColor: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
            valueColor: AlwaysStoppedAnimation<Color>(
              stats.fundingPercent >= 100 ? AppColors.success : AppColors.primary,
            ),
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_formatNumber(stats.totalRaisedKrw)}원',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
            ),
            Text(
              stats.daysLeft > 0 ? 'D-${stats.daysLeft}' : '마감',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: stats.daysLeft <= 3 ? AppColors.danger : (isDark ? AppColors.textMutedDark : AppColors.textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTierDistribution(bool isDark, CampaignStats stats) {
    if (stats.tierDistribution.isEmpty) {
      return Text(
        '아직 후원자가 없습니다',
        style: TextStyle(
          color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
        ),
      );
    }

    final total = stats.tierDistribution.values.fold(0, (a, b) => a + b);
    final colors = [AppColors.primary, AppColors.success, AppColors.warning, AppColors.danger];

    return Column(
      children: stats.tierDistribution.entries.toList().asMap().entries.map((entry) {
        final idx = entry.key;
        final tierName = entry.value.key;
        final count = entry.value.value;
        final pct = total > 0 ? count / total : 0.0;
        final color = colors[idx % colors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tierName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textDark : AppColors.text,
                    ),
                  ),
                  Text(
                    '$count명 (${(pct * 100).toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDailyChart(bool isDark, CampaignStats stats) {
    if (stats.dailyData.isEmpty) {
      return Text(
        '아직 데이터가 없습니다',
        style: TextStyle(
          color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
        ),
      );
    }

    final maxAmount = stats.dailyData.map((d) => d.amount).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        // Bar chart
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: stats.dailyData.map((d) {
              final pct = maxAmount > 0 ? d.amount / maxAmount : 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Tooltip(
                    message: '${d.date.month}/${d.date.day}: ${_formatNumber(d.amount)}원',
                    child: Container(
                      height: (pct * 100).clamp(4.0, 120.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.7),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        // Date labels (first and last)
        if (stats.dailyData.length >= 2)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${stats.dailyData.first.date.month}/${stats.dailyData.first.date.day}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                ),
              ),
              Text(
                '${stats.dailyData.last.date.month}/${stats.dailyData.last.date.day}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSection(bool isDark, String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDark : AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 100000000) {
      return '${(number / 100000000).toStringAsFixed(1)}억';
    } else if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(0)}만';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}천';
    }
    return number.toString();
  }
}

class _MetricCard extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.isDark,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
