import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/demo_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Admin Dashboard Screen
/// KPI 카드 4개 + 빠른 액션 + 최근 활동
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 대시보드'),
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo mode banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.08),
                borderRadius: AppRadius.mdBR,
                border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_rounded,
                      size: 16, color: Colors.indigo[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '관리자 데모 모드 — Mock 데이터가 표시됩니다',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.indigo[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // KPI Cards
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    icon: Icons.people_rounded,
                    label: '총 크리에이터',
                    value: '${DemoConfig.sampleArtists.length}',
                    color: Colors.blue,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    icon: Icons.group_rounded,
                    label: '총 구독자',
                    value: '${DemoConfig.demoSubscriberCount}',
                    color: Colors.green,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    icon: Icons.payments_rounded,
                    label: '월 총매출',
                    value: _formatKrw(DemoConfig.demoMonthlyRevenue),
                    color: Colors.orange,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    icon: Icons.pending_actions_rounded,
                    label: '대기 정산',
                    value: '3건',
                    color: Colors.red,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              '빠른 액션',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.account_balance_wallet_rounded,
                    label: '정산 심사',
                    count: 3,
                    color: Colors.blue,
                    isDark: isDark,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.people_rounded,
                    label: '크리에이터 관리',
                    count: 0,
                    color: Colors.green,
                    isDark: isDark,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.flag_rounded,
                    label: '신고 확인',
                    count: 2,
                    color: Colors.red,
                    isDark: isDark,
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Activity (Audit Log)
            Text(
              '최근 활동',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ..._mockRecentActivities.map((activity) => _ActivityItem(
                  icon: activity['icon'] as IconData,
                  title: activity['title'] as String,
                  time: activity['time'] as String,
                  isDark: isDark,
                )),
          ],
        ),
      ),
    );
  }

  String _formatKrw(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 10000).toStringAsFixed(0)}만원';
    }
    return '${(amount / 1000).toStringAsFixed(0)}천원';
  }
}

final List<Map<String, dynamic>> _mockRecentActivities = [
  {
    'icon': Icons.check_circle_outline,
    'title': 'WAKER 정산 승인 완료 (2026-01)',
    'time': '2시간 전',
  },
  {
    'icon': Icons.person_add_rounded,
    'title': '새 크리에이터 "루나" 가입 승인',
    'time': '5시간 전',
  },
  {
    'icon': Icons.flag_outlined,
    'title': '스팸 신고 처리 완료 (#R-0023)',
    'time': '1일 전',
  },
  {
    'icon': Icons.payment_rounded,
    'title': 'MOONLIGHT 펀딩 환불 처리',
    'time': '2일 전',
  },
  {
    'icon': Icons.warning_amber_rounded,
    'title': '크리에이터 "별빛" 경고 발송',
    'time': '3일 전',
  },
];

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: AppRadius.lgBR,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.smBR,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgBR,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: AppRadius.lgBR,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 24, color: color),
                  if (count > 0)
                    Positioned(
                      top: -6,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final bool isDark;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.time,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
        ],
      ),
    );
  }
}
