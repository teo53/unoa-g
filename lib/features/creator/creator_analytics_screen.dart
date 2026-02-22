import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_logger.dart';
import '../../providers/auth_provider.dart';
import '../../providers/repository_providers.dart';
import '../../shared/widgets/skeleton_loader.dart';

/// Creator analytics/statistics screen
class CreatorAnalyticsScreen extends ConsumerStatefulWidget {
  const CreatorAnalyticsScreen({super.key});

  @override
  ConsumerState<CreatorAnalyticsScreen> createState() =>
      _CreatorAnalyticsScreenState();
}

class _CreatorAnalyticsScreenState
    extends ConsumerState<CreatorAnalyticsScreen> {
  String _selectedPeriod = '이번 주';
  final List<String> _periods = ['오늘', '이번 주', '이번 달', '전체'];

  // Data state
  bool _isLoading = true;
  String? _error;
  _CreatorStats _stats = const _CreatorStats();
  List<_WeeklyData> _weeklyData = [];
  List<_PopularMessage> _popularMessages = [];

  // Demo fallback data
  static const _demoStats = _CreatorStats(
    totalSubscribers: 1250,
    subscriberGrowth: 15,
    totalMessages: 892,
    donationMessages: 156,
    totalDtEarned: 245000,
    weeklyDtEarned: 12500,
    responseRate: 23,
  );

  static final _demoWeeklyData = [
    _WeeklyData('월', 45, 12),
    _WeeklyData('화', 62, 18),
    _WeeklyData('수', 38, 8),
    _WeeklyData('목', 71, 22),
    _WeeklyData('금', 55, 15),
    _WeeklyData('토', 89, 28),
    _WeeklyData('일', 67, 20),
  ];

  static final _demoPopularMessages = [
    _PopularMessage('오늘 연습 끝났어요! 집 가는 중~', 127, '2시간 전'),
    _PopularMessage('컴백 준비 중... 기대해주세요!', 98, '어제'),
    _PopularMessage('오늘 날씨 너무 좋다 ☀️', 76, '2일 전'),
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    final isDemoMode = ref.read(isDemoModeProvider);

    if (isDemoMode) {
      setState(() {
        _stats = _demoStats;
        _weeklyData = _demoWeeklyData;
        _popularMessages = _demoPopularMessages;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _error = '인증 정보를 확인할 수 없습니다';
          _isLoading = false;
        });
        return;
      }

      // Get creator's channel ID via repository
      final channelId =
          await ref.read(creatorChatRepositoryProvider).getCreatorChannelId();

      if (channelId == null) {
        setState(() {
          _error = '채널 정보를 찾을 수 없습니다';
          _isLoading = false;
        });
        return;
      }

      // Load data in parallel
      final results = await Future.wait([
        _fetchSubscriberStats(supabase, channelId),
        _fetchMessageStats(supabase, channelId),
        _fetchRevenueStats(supabase, userId),
        _fetchWeeklyData(supabase, channelId),
        _fetchPopularMessages(supabase, channelId),
      ]);

      final subscriberData = results[0] as Map<String, int>;
      final messageData = results[1] as Map<String, int>;
      final revenueData = results[2] as Map<String, int>;
      final weeklyData = results[3] as List<_WeeklyData>;
      final popularMessages = results[4] as List<_PopularMessage>;

      if (!mounted) return;

      setState(() {
        _stats = _CreatorStats(
          totalSubscribers: subscriberData['total'] ?? 0,
          subscriberGrowth: subscriberData['growth'] ?? 0,
          totalMessages: messageData['total'] ?? 0,
          donationMessages: messageData['donations'] ?? 0,
          totalDtEarned: revenueData['total'] ?? 0,
          weeklyDtEarned: revenueData['weekly'] ?? 0,
          responseRate: messageData['responseRate'] ?? 0,
        );
        _weeklyData = weeklyData;
        _popularMessages = popularMessages;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error(e, message: 'Failed to load analytics data');
      if (mounted) {
        setState(() {
          _error = '데이터를 불러오지 못했습니다';
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, int>> _fetchSubscriberStats(
    SupabaseClient supabase,
    String channelId,
  ) async {
    final activeRes = await supabase
        .from('subscriptions')
        .select('id')
        .eq('channel_id', channelId)
        .eq('is_active', true);

    final total = (activeRes as List).length;

    // Today's growth: subscriptions created today
    final todayStart = DateTime.now().toUtc();
    final todayStartStr =
        DateTime.utc(todayStart.year, todayStart.month, todayStart.day)
            .toIso8601String();

    final todayRes = await supabase
        .from('subscriptions')
        .select('id')
        .eq('channel_id', channelId)
        .eq('is_active', true)
        .gte('created_at', todayStartStr);

    final growth = (todayRes as List).length;

    return {'total': total, 'growth': growth};
  }

  Future<Map<String, int>> _fetchMessageStats(
    SupabaseClient supabase,
    String channelId,
  ) async {
    final fanMessages = await supabase
        .from('messages')
        .select('id, delivery_scope')
        .eq('channel_id', channelId)
        .inFilter('delivery_scope',
            ['direct_reply', 'donation_message']).isFilter('deleted_at', null);

    final fanList = fanMessages as List;
    final totalMessages = fanList.length;
    final donationMessages =
        fanList.where((m) => m['delivery_scope'] == 'donation_message').length;

    // Response rate: creator messages / fan messages
    final creatorMessages = await supabase
        .from('messages')
        .select('id')
        .eq('channel_id', channelId)
        .inFilter('delivery_scope', ['broadcast', 'donation_reply']).isFilter(
            'deleted_at', null);

    final creatorCount = (creatorMessages as List).length;
    final responseRate =
        totalMessages > 0 ? ((creatorCount / totalMessages) * 100).round() : 0;

    return {
      'total': totalMessages,
      'donations': donationMessages,
      'responseRate': responseRate,
    };
  }

  Future<Map<String, int>> _fetchRevenueStats(
    SupabaseClient supabase,
    String userId,
  ) async {
    // Total revenue from creator_profiles materialized cache
    final profileRes = await supabase
        .from('creator_profiles')
        .select('total_revenue_krw')
        .eq('user_id', userId)
        .maybeSingle();

    final totalRevenue = (profileRes?['total_revenue_krw'] as int?) ?? 0;

    // Weekly revenue from settlement_statements (last 7 days)
    final weekAgo =
        DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

    final weeklyRes = await supabase
        .from('messages')
        .select('donation_amount')
        .eq('channel_id', userId)
        .eq('delivery_scope', 'donation_message')
        .gte('created_at', weekAgo)
        .isFilter('deleted_at', null);

    int weeklyTotal = 0;
    for (final row in (weeklyRes as List)) {
      weeklyTotal += (row['donation_amount'] as int?) ?? 0;
    }

    return {'total': totalRevenue, 'weekly': weeklyTotal};
  }

  Future<List<_WeeklyData>> _fetchWeeklyData(
    SupabaseClient supabase,
    String channelId,
  ) async {
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final now = DateTime.now();
    final results = <_WeeklyData>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime.utc(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayMessages = await supabase
          .from('messages')
          .select('id, delivery_scope')
          .eq('channel_id', channelId)
          .inFilter('delivery_scope', ['direct_reply', 'donation_message'])
          .gte('created_at', dayStart.toIso8601String())
          .lt('created_at', dayEnd.toIso8601String())
          .isFilter('deleted_at', null);

      final msgList = dayMessages as List;
      final messages = msgList.length;
      final donations = msgList
          .where((m) => m['delivery_scope'] == 'donation_message')
          .length;

      // weekday: 1=Monday ... 7=Sunday
      final dayIndex = (date.weekday - 1) % 7;
      results.add(_WeeklyData(dayNames[dayIndex], messages, donations));
    }

    return results;
  }

  Future<List<_PopularMessage>> _fetchPopularMessages(
    SupabaseClient supabase,
    String channelId,
  ) async {
    // Get recent broadcasts with reply counts
    final broadcasts = await supabase
        .from('messages')
        .select('id, content, created_at')
        .eq('channel_id', channelId)
        .eq('delivery_scope', 'broadcast')
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(10);

    final broadcastList = broadcasts as List;
    if (broadcastList.isEmpty) return [];

    final results = <_PopularMessage>[];

    for (final broadcast in broadcastList) {
      final msgId = broadcast['id'] as String;
      final content = broadcast['content'] as String? ?? '';
      final createdAt = DateTime.parse(broadcast['created_at'] as String);

      // Count replies to this broadcast (via reply_to_id)
      final repliesRes = await supabase
          .from('messages')
          .select('id')
          .eq('channel_id', channelId)
          .eq('reply_to_id', msgId)
          .isFilter('deleted_at', null);

      final replyCount = (repliesRes as List).length;
      final timeAgo = _formatTimeAgo(createdAt);

      results.add(_PopularMessage(content, replyCount, timeAgo));
    }

    // Sort by reply count and take top 3
    results.sort((a, b) => b.replyCount.compareTo(a.replyCount));
    return results.take(3).toList();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${(diff.inDays / 7).floor()}주 전';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDemoMode = ref.watch(isDemoModeProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState(isDark)
            : _error != null
                ? _buildErrorState(isDark)
                : _buildContent(isDark, isDemoMode),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context, isDark)),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: SkeletonLoader.card(
                            width: double.infinity, height: 120)),
                    SizedBox(width: 16),
                    Expanded(
                        child: SkeletonLoader.card(
                            width: double.infinity, height: 120)),
                  ],
                ),
                SizedBox(height: 24),
                SkeletonLoader.card(width: double.infinity, height: 200),
                SizedBox(height: 24),
                SkeletonLoader.card(width: double.infinity, height: 150),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context, isDark)),
        SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color:
                        isDark ? AppColors.textMutedDark : AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error ?? '오류가 발생했습니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _loadAnalyticsData,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark, bool isDemoMode) {
    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, isDark)),
          SliverToBoxAdapter(child: _buildPeriodSelector(isDark)),
          SliverToBoxAdapter(child: _buildStatsCards(isDark)),
          if (_weeklyData.isNotEmpty)
            SliverToBoxAdapter(child: _buildWeeklyChart(isDark)),
          SliverToBoxAdapter(child: _buildMessageStats(isDark)),
          if (_popularMessages.isNotEmpty)
            SliverToBoxAdapter(child: _buildPopularMessages(isDark)),
          if (isDemoMode)
            SliverToBoxAdapter(child: _buildDemoIndicator(isDark)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '통계',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
            onPressed: () {
              _showInfoDialog(context, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _periods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final period = _periods[index];
          final isSelected = period == _selectedPeriod;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPeriod = period;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                borderRadius: BorderRadius.circular(20),
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
                  fontSize: 14,
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

  Widget _buildStatsCards(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: '구독자',
              value: _formatNumber(_stats.totalSubscribers),
              change: '+${_stats.subscriberGrowth}',
              changeLabel: '오늘',
              icon: Icons.people_rounded,
              iconColor: AppColors.primary,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatCard(
              title: '수익',
              value: '${_formatNumber(_stats.totalDtEarned)} DT',
              change: '+${_formatNumber(_stats.weeklyDtEarned)}',
              changeLabel: '이번 주',
              icon: Icons.monetization_on_rounded,
              iconColor: AppColors.success,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(bool isDark) {
    final maxMessages = _weeklyData
        .map((d) => d.messages)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    // Avoid division by zero
    final effectiveMax = maxMessages > 0 ? maxMessages : 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
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
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '주간 활동',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklyData.map((data) {
                final height = (data.messages / effectiveMax) * 120;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 28,
                        height: height,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary500.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.day,
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChartLegend(
                color: AppColors.primary,
                label: '받은 메시지',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageStats(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(24),
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
                Icons.mail_rounded,
                size: 20,
                color: AppColors.verified,
              ),
              const SizedBox(width: 8),
              Text(
                '메시지 통계',
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
          _StatRow(
            label: '받은 답장',
            value: '${_formatNumber(_stats.totalMessages)}개',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _StatRow(
            label: '도네이션 메시지',
            value: '${_stats.donationMessages}개',
            isDark: isDark,
            highlight: true,
          ),
          const SizedBox(height: 12),
          _StatRow(
            label: '평균 응답률',
            value: '${_stats.responseRate}%',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPopularMessages(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
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
                Icons.local_fire_department_rounded,
                size: 20,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                '인기 메시지',
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
          ...List.generate(_popularMessages.length, (index) {
            final message = _popularMessages[index];
            return _PopularMessageTile(
              rank: index + 1,
              message: message,
              isDark: isDark,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDemoIndicator(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.verified.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.verified.withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: AppColors.verified,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '데모 모드에서는 샘플 데이터가 표시됩니다.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.verified,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '통계 안내',
          style: TextStyle(
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        content: Text(
          '통계는 매일 자정에 업데이트됩니다.\n\n'
          '• 구독자: 현재 구독 중인 팬 수\n'
          '• 수익: 도네이션 및 펀딩 수입 합계\n'
          '• 응답률: 팬 메시지 대비 답장 비율',
          style: TextStyle(
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              '확인',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number >= 10000 ? 0 : 1)}K';
    }
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

// Data classes
class _CreatorStats {
  final int totalSubscribers;
  final int subscriberGrowth;
  final int totalMessages;
  final int donationMessages;
  final int totalDtEarned;
  final int weeklyDtEarned;
  final int responseRate;

  const _CreatorStats({
    this.totalSubscribers = 0,
    this.subscriberGrowth = 0,
    this.totalMessages = 0,
    this.donationMessages = 0,
    this.totalDtEarned = 0,
    this.weeklyDtEarned = 0,
    this.responseRate = 0,
  });
}

class _WeeklyData {
  final String day;
  final int messages;
  final int donations;

  _WeeklyData(this.day, this.messages, this.donations);
}

class _PopularMessage {
  final String content;
  final int replyCount;
  final String time;

  _PopularMessage(this.content, this.replyCount, this.time);
}

// Widgets
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final String changeLabel;
  final IconData icon;
  final Color iconColor;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.changeLabel,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                changeLabel,
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

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;

  const _ChartLegend({
    required this.color,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool highlight;

  const _StatRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: highlight
                ? AppColors.primary
                : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
          ),
        ),
      ],
    );
  }
}

class _PopularMessageTile extends StatelessWidget {
  final int rank;
  final _PopularMessage message;
  final bool isDark;

  const _PopularMessageTile({
    required this.rank,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: rank == 1
                  ? AppColors.warning
                  : (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt),
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
                Text(
                  '답장 ${message.replyCount}개 • ${message.time}',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.textMutedDark : AppColors.textMuted,
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
