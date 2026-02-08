import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/animation_utils.dart';
import '../../providers/auth_provider.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/mock_chat_repository.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'widgets/todays_voted_question_section.dart';

/// Creator Dashboard Screen - CRM 통합 대시보드
/// - 수익 요약 및 통계
/// - 팬 인사이트
/// - 빠른 실행 버튼
/// - 최근 활동
class CreatorDashboardScreen extends ConsumerStatefulWidget {
  const CreatorDashboardScreen({super.key});

  @override
  ConsumerState<CreatorDashboardScreen> createState() =>
      _CreatorDashboardScreenState();
}

class _CreatorDashboardScreenState
    extends ConsumerState<CreatorDashboardScreen> {
  final MockArtistInboxRepository _repository = MockArtistInboxRepository();
  InboxStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _repository.getInboxStats('channel_1');
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(currentProfileProvider);
    final isDemoMode = ref.watch(isDemoModeProvider);

    return Column(
      children: [
        // Header
        _buildHeader(context, isDark, profile?.displayName ?? '크리에이터'),

        // Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              await _loadStats();
            },
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Revenue Summary Card
                  SlideFadeAnimation.fromBottom(
                    delay: const Duration(milliseconds: 50),
                    child: _buildRevenueSummaryCard(isDark, isDemoMode),
                  ),
                  const SizedBox(height: 20),

                  // Quick Actions
                  SlideFadeAnimation.fromBottom(
                    delay: const Duration(milliseconds: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('빠른 실행', isDark),
                        const SizedBox(height: 12),
                        _buildQuickActions(context, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Revenue Chart Section
                  SlideFadeAnimation.fromBottom(
                    delay: const Duration(milliseconds: 150),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('월별 수익 추이', isDark, onMore: () => context.push('/creator/crm')),
                        const SizedBox(height: 12),
                        _buildRevenueChart(isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Fan Insights
                  SlideFadeAnimation.fromBottom(
                    delay: const Duration(milliseconds: 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('팬 인사이트', isDark, onMore: () => context.push('/creator/crm')),
                        const SizedBox(height: 12),
                        _buildFanInsights(isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Today's Question Cards (creator view)
                  SlideFadeAnimation.fromBottom(
                    delay: const Duration(milliseconds: 250),
                    child: TodaysVotedQuestionSection(
                      channelId: 'channel_1',
                      onAnswerCard: (card, setId) {
                        // Navigate to chat with the question context
                        context.go('/creator/chat');
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Grid
                  SlideFadeAnimation.fromBottom(
                    delay: const Duration(milliseconds: 300),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('오늘의 현황', isDark),
                        const SizedBox(height: 12),
                        _buildStatsGrid(isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Activity
                  SlideFadeAnimation.fromBottom(
                    delay: const Duration(milliseconds: 350),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('최근 활동', isDark),
                        const SizedBox(height: 12),
                        _buildRecentActivity(isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark, {VoidCallback? onMore}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        if (onMore != null)
          GestureDetector(
            onTap: onMore,
            child: Text(
              '더보기',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, String name) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '대시보드',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '안녕하세요, $name님!',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => context.push('/settings'),
                icon: Icon(
                  Icons.settings_outlined,
                  color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  size: 26,
                ),
              ),
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: Stack(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                      size: 26,
                    ),
                    if ((_stats?.unreadMessages ?? 0) > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.surfaceLight,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSummaryCard(bool isDark, bool isDemoMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.9),
            AppColors.primary600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isDemoMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '데모 모드',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 16,
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
          Text(
            '이번 달 총 수익',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '1,245,000 DT',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _RevenueDetailItem(
                label: '후원',
                value: '845,000',
                icon: Icons.diamond_rounded,
              ),
              const SizedBox(width: 24),
              _RevenueDetailItem(
                label: '구독',
                value: '400,000',
                icon: Icons.people_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    final actions = [
      _QuickActionData(
        icon: Icons.chat_bubble_rounded,
        label: '채팅',
        color: AppColors.primary,
        onTap: () => context.go('/creator/chat'),
      ),
      _QuickActionData(
        icon: Icons.mail_rounded,
        label: '프라이빗 카드',
        color: const Color(0xFF7C4DFF),
        onTap: () => context.push('/creator/chat'),
      ),
      _QuickActionData(
        icon: Icons.bar_chart_rounded,
        label: 'CRM 상세',
        color: const Color(0xFF448AFF),
        onTap: () => context.push('/creator/crm'),
      ),
      _QuickActionData(
        icon: Icons.account_balance_wallet_rounded,
        label: '출금',
        color: const Color(0xFF66BB6A),
        onTap: () => context.push('/creator/crm'),
      ),
      _QuickActionData(
        icon: Icons.poll_rounded,
        label: '투표 만들기',
        color: const Color(0xFFEC407A),
        onTap: () => context.push('/creator/chat'),
      ),
      _QuickActionData(
        icon: Icons.people_alt_rounded,
        label: '팬 관리',
        color: const Color(0xFF26A69A),
        onTap: () => context.push('/creator/crm'),
      ),
    ];

    return Column(
      children: [
        for (int row = 0; row < 3; row++) ...[
          if (row > 0) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: actions[row * 2].icon,
                  label: actions[row * 2].label,
                  color: actions[row * 2].color,
                  isDark: isDark,
                  onTap: actions[row * 2].onTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionCard(
                  icon: actions[row * 2 + 1].icon,
                  label: actions[row * 2 + 1].label,
                  color: actions[row * 2 + 1].color,
                  isDark: isDark,
                  onTap: actions[row * 2 + 1].onTap,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRevenueChart(bool isDark) {
    final data = [
      _ChartData('9월', 820000),
      _ChartData('10월', 950000),
      _ChartData('11월', 1100000),
      _ChartData('12월', 1245000),
    ];
    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

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
        children: [
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((item) {
                final height = (item.value / maxValue) * 120;
                final isLast = item == data.last;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${(item.value / 10000).toInt()}만',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isLast
                                ? AppColors.primary
                                : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isLast
                                  ? [AppColors.primary, AppColors.primary600]
                                  : [
                                      (isDark ? Colors.grey[600]! : Colors.grey[300]!),
                                      (isDark ? Colors.grey[700]! : Colors.grey[400]!),
                                    ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFanInsights(bool isDark) {
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
        children: [
          Row(
            children: [
              Expanded(
                child: _FanTierItem(
                  tier: 'VIP',
                  count: 125,
                  color: Colors.amber,
                  isDark: isDark,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              Expanded(
                child: _FanTierItem(
                  tier: 'STANDARD',
                  count: 625,
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              Expanded(
                child: _FanTierItem(
                  tier: 'BASIC',
                  count: 500,
                  color: Colors.grey,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '총 구독자',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
                const Spacer(),
                Text(
                  '1,250명',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+15',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
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

  Widget _buildStatsGrid(bool isDark) {
    if (_isLoading) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: List.generate(4, (_) => _SkeletonStatCard(isDark: isDark)),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _StatCard(
          icon: Icons.mail_rounded,
          iconColor: Colors.teal,
          label: '읽지 않은 메시지',
          value: '${_stats?.unreadMessages ?? 23}',
          isDark: isDark,
        ),
        _StatCard(
          icon: Icons.diamond_rounded,
          iconColor: Colors.pink,
          label: '후원 메시지',
          value: '${_stats?.donationMessages ?? 5}',
          isDark: isDark,
        ),
        _StatCard(
          icon: Icons.star_rounded,
          iconColor: Colors.amber,
          label: '하이라이트',
          value: '${_stats?.highlightedMessages ?? 3}',
          isDark: isDark,
        ),
        _StatCard(
          icon: Icons.send_rounded,
          iconColor: Colors.blue,
          label: '보낸 전체메시지',
          value: '12',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildRecentActivity(bool isDark) {
    final activities = [
      _ActivityItem(
        icon: Icons.diamond,
        iconColor: Colors.pink,
        title: '하늘덕후님이 500 DT를 후원했어요',
        time: '2시간 전',
      ),
      _ActivityItem(
        icon: Icons.chat_bubble,
        iconColor: Colors.teal,
        title: '별빛팬님이 메시지를 보냈어요',
        time: '3시간 전',
      ),
      _ActivityItem(
        icon: Icons.person_add,
        iconColor: Colors.blue,
        title: '새로운 구독자 15명이 추가되었어요',
        time: '오늘',
      ),
      _ActivityItem(
        icon: Icons.trending_up,
        iconColor: Colors.green,
        title: '이번 주 수익이 23% 증가했어요',
        time: '어제',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: activities.map((activity) {
          return _buildActivityTile(activity, isDark,
              isLast: activity == activities.last);
        }).toList(),
      ),
    );
  }

  Widget _buildActivityTile(_ActivityItem activity, bool isDark,
      {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activity.iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              activity.icon,
              color: activity.iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.time,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.textMutedDark : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _RevenueDetailItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _RevenueDetailItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            Text(
              '$value DT',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          // Icon area
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          // Text area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FanTierItem extends StatelessWidget {
  final String tier;
  final int count;
  final Color color;
  final bool isDark;

  const _FanTierItem({
    required this.tier,
    required this.count,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tier,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$count명',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
      ],
    );
  }
}

class _SkeletonStatCard extends StatelessWidget {
  final bool isDark;
  const _SkeletonStatCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          const SkeletonLoader(width: 44, height: 44, borderRadius: BorderRadius.all(Radius.circular(12))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SkeletonLoader.text(width: 48, height: 18),
                SizedBox(height: 6),
                SkeletonLoader.text(width: 72, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _ChartData {
  final String label;
  final double value;

  const _ChartData(this.label, this.value);
}

class _ActivityItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
  });
}
