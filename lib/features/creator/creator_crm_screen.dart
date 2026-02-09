import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/crm_revenue_tab.dart';
import 'widgets/crm_fan_tab.dart';
import 'widgets/crm_content_tab.dart';
import 'widgets/crm_withdrawal_tab.dart';

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
                CrmRevenueTab(
                  selectedPeriod: _selectedPeriod,
                  onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
                ),
                const CrmFanTab(),
                const CrmContentTab(),
                const CrmWithdrawalTab(),
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
