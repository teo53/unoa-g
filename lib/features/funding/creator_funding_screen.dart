import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'create_campaign_screen.dart';
import 'funding_detail_screen.dart';

/// Creator's funding screen with 2 tabs: My Campaigns & Explore
class CreatorFundingScreen extends ConsumerStatefulWidget {
  final bool showBackButton;

  const CreatorFundingScreen({
    super.key,
    this.showBackButton = false,
  });

  @override
  ConsumerState<CreatorFundingScreen> createState() =>
      _CreatorFundingScreenState();
}

class _CreatorFundingScreenState extends ConsumerState<CreatorFundingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _mainTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDemoMode = ref.watch(isDemoModeProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            _buildMainTabBar(isDark),
            Expanded(
              child: TabBarView(
                controller: _mainTabController,
                children: [
                  _MyCampaignsTab(isDemoMode: isDemoMode),
                  _ExploreCampaignsTab(isDemoMode: isDemoMode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Row(
        children: [
          Text(
            '펀딩',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primary600,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateCampaignScreen(),
                ),
              );
            },
            tooltip: '새 펀딩 만들기',
          ),
        ],
      ),
    );
  }

  Widget _buildMainTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _mainTabController,
        indicator: BoxDecoration(
          color: AppColors.primary600,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.onPrimary,
        unselectedLabelColor:
            isDark ? AppColors.textMutedDark : AppColors.textMuted,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: '내 캠페인'),
          Tab(text: '탐색하기'),
        ],
      ),
    );
  }
}

// ============================================================================
// My Campaigns Tab (내 캠페인)
// ============================================================================

class _MyCampaignsTab extends StatefulWidget {
  final bool isDemoMode;

  const _MyCampaignsTab({required this.isDemoMode});

  @override
  State<_MyCampaignsTab> createState() => _MyCampaignsTabState();
}

class _MyCampaignsTabState extends State<_MyCampaignsTab>
    with SingleTickerProviderStateMixin {
  late TabController _statusTabController;
  final List<String> _statusTabs = ['진행중', '준비중', '종료됨'];

  @override
  void initState() {
    super.initState();
    _statusTabController =
        TabController(length: _statusTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _statusTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Summary card
        _buildSummaryCard(isDark),

        // Status filter tabs
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: _statusTabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnimatedBuilder(
                  animation: _statusTabController,
                  builder: (context, child) {
                    final isSelected = _statusTabController.index == index;
                    return GestureDetector(
                      onTap: () => _statusTabController.animateTo(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary600
                              : (isDark
                                  ? AppColors.surfaceAltDark
                                  : AppColors.surfaceAlt),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.onPrimary
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
            }).toList(),
          ),
        ),

        // Campaign list
        Expanded(
          child: TabBarView(
            controller: _statusTabController,
            children: [
              _CreatorCampaignList(
                  status: 'active', isDemoMode: widget.isDemoMode),
              _CreatorCampaignList(
                  status: 'draft', isDemoMode: widget.isDemoMode),
              _CreatorCampaignList(
                  status: 'ended', isDemoMode: widget.isDemoMode),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary600,
            AppColors.primary700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary600.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryStatItem(
                  icon: Icons.campaign_rounded,
                  label: '진행중',
                  value: '1',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _SummaryStatItem(
                  icon: Icons.people_rounded,
                  label: '총 후원자',
                  value: '892',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _SummaryStatItem(
                  icon: Icons.savings_rounded,
                  label: '총 모금액',
                  value: '18.5M',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryStatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Creator Campaign List (My Campaigns)
// ============================================================================

class _CreatorCampaignList extends StatefulWidget {
  final String status;
  final bool isDemoMode;

  const _CreatorCampaignList({
    required this.status,
    this.isDemoMode = false,
  });

  @override
  State<_CreatorCampaignList> createState() => _CreatorCampaignListState();
}

class _CreatorCampaignListState extends State<_CreatorCampaignList>
    with AutomaticKeepAliveClientMixin {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _campaigns = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  @override
  void didUpdateWidget(_CreatorCampaignList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDemoMode != widget.isDemoMode) {
      _loadCampaigns();
    }
  }

  Future<void> _loadCampaigns() async {
    setState(() => _isLoading = true);

    if (widget.isDemoMode) {
      setState(() {
        _campaigns = _getDemoCampaigns();
        _isLoading = false;
      });
      return;
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      String statusFilter = widget.status;
      if (widget.status == 'ended') {
        statusFilter = 'completed';
      }

      final response = await _supabase
          .from('funding_campaigns')
          .select('*')
          .eq('creator_id', userId)
          .eq('status', statusFilter)
          .order('created_at', ascending: false);

      setState(() {
        _campaigns = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getDemoCampaigns() {
    final now = DateTime.now();

    if (widget.status == 'active') {
      return [
        {
          'id': 'demo_my_campaign_1',
          'title': '나의 첫 미니앨범 "Dream" 제작 펀딩',
          'subtitle': '팬 여러분과 함께 만드는 앨범',
          'cover_image_url': 'https://picsum.photos/seed/mycampaign1/800/450',
          'status': 'active',
          'goal_amount_dt': 30000000,
          'current_amount_dt': 18500000,
          'funding_percent': 61.7,
          'backer_count': 892,
          'end_at': now.add(const Duration(days: 15)).toIso8601String(),
          'created_at':
              now.subtract(const Duration(days: 15)).toIso8601String(),
        },
      ];
    } else if (widget.status == 'draft') {
      return [
        {
          'id': 'demo_my_campaign_draft',
          'title': '새 콘서트 굿즈 제작 (준비중)',
          'subtitle': '',
          'cover_image_url': null,
          'status': 'draft',
          'goal_amount_dt': 0,
          'current_amount_dt': 0,
          'funding_percent': 0,
          'backer_count': 0,
          'end_at': null,
          'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        },
      ];
    } else {
      return [
        {
          'id': 'demo_my_campaign_ended',
          'title': '팬미팅 "Together" 개최 펀딩',
          'subtitle': '성공적으로 마감되었습니다!',
          'cover_image_url':
              'https://picsum.photos/seed/mycampaignended/800/450',
          'status': 'completed',
          'goal_amount_dt': 25000000,
          'current_amount_dt': 32000000,
          'funding_percent': 128.0,
          'backer_count': 1245,
          'end_at': now.subtract(const Duration(days: 10)).toIso8601String(),
          'created_at':
              now.subtract(const Duration(days: 40)).toIso8601String(),
        },
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_campaigns.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return RefreshIndicator(
      onRefresh: _loadCampaigns,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _campaigns.length,
        itemBuilder: (context, index) {
          return _CreatorCampaignCard(
            campaign: _campaigns[index],
            onTap: () => _showCampaignOptions(_campaigns[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    String message;
    IconData icon;

    switch (widget.status) {
      case 'active':
        message = '진행 중인 펀딩이 없습니다';
        icon = Icons.campaign_outlined;
        break;
      case 'draft':
        message = '준비 중인 펀딩이 없습니다';
        icon = Icons.edit_note_outlined;
        break;
      default:
        message = '종료된 펀딩이 없습니다';
        icon = Icons.archive_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
          ),
          if (widget.status == 'draft' || widget.status == 'active') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateCampaignScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('새 펀딩 만들기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary600,
                foregroundColor: AppColors.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCampaignOptions(Map<String, dynamic> campaign) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                campaign['title'] ?? '펀딩',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDark : AppColors.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('상세 보기'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FundingDetailScreen(
                      campaignId: campaign['id'],
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('펀딩 수정'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateCampaignScreen(
                      campaignId: campaign['id'],
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text('통계 보기'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('통계 기능은 준비 중입니다')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('후원자 목록'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('후원자 목록 기능은 준비 중입니다')),
                );
              },
            ),
            if (campaign['status'] == 'draft')
              ListTile(
                leading: Icon(Icons.publish_outlined, color: AppColors.primary),
                title: Text(
                  '펀딩 시작하기',
                  style: TextStyle(color: AppColors.primary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('펀딩 시작 기능은 준비 중입니다')),
                  );
                },
              ),
            if (campaign['status'] == 'active')
              ListTile(
                leading: Icon(Icons.pause_circle_outline,
                    color: AppColors.warning),
                title: Text(
                  '펀딩 일시정지',
                  style: TextStyle(color: AppColors.warning),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('일시정지 기능은 준비 중입니다')),
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _CreatorCampaignCard extends StatelessWidget {
  final Map<String, dynamic> campaign;
  final VoidCallback onTap;

  const _CreatorCampaignCard({
    required this.campaign,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fundingPercent =
        (campaign['funding_percent'] as num?)?.toDouble() ?? 0;
    final status = campaign['status'] as String? ?? 'draft';
    final endAt = DateTime.tryParse(campaign['end_at'] ?? '');
    final daysLeft =
        endAt != null ? endAt.difference(DateTime.now()).inDays : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    campaign['cover_image_url'] != null
                        ? Image.network(
                            campaign['cover_image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildPlaceholder(isDark),
                          )
                        : _buildPlaceholder(isDark),

                    // Status badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _buildStatusBadge(status),
                    ),

                    // Edit button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_horiz,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    campaign['title'] ?? '제목 없음',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDark : AppColors.text,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (status != 'draft') ...[
                    const SizedBox(height: 12),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (fundingPercent / 100).clamp(0, 1),
                        backgroundColor: isDark
                            ? AppColors.surfaceAltDark
                            : AppColors.surfaceAlt,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          fundingPercent >= 100
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Stats row
                    Row(
                      children: [
                        Text(
                          '${fundingPercent.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: fundingPercent >= 100
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${campaign['backer_count'] ?? 0}명 후원',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMuted,
                          ),
                        ),
                        const Spacer(),
                        if (status == 'active' && daysLeft > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: daysLeft <= 3
                                  ? AppColors.danger100
                                  : (isDark
                                      ? AppColors.surfaceAltDark
                                      : AppColors.surfaceAlt),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'D-$daysLeft',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: daysLeft <= 3
                                    ? AppColors.danger
                                    : (isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMuted),
                              ),
                            ),
                          ),
                        if (status == 'completed')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: fundingPercent >= 100
                                  ? AppColors.success100
                                  : AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              fundingPercent >= 100 ? '성공' : '미달성',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: fundingPercent >= 100
                                    ? AppColors.success
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      '펀딩 정보를 입력해주세요',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark ? AppColors.textMutedDark : AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'active':
        bgColor = AppColors.success.withOpacity(0.9);
        textColor = Colors.white;
        label = '진행중';
        break;
      case 'draft':
        bgColor = AppColors.warning.withOpacity(0.9);
        textColor = Colors.white;
        label = '준비중';
        break;
      case 'completed':
        bgColor = Colors.grey.withOpacity(0.9);
        textColor = Colors.white;
        label = '종료';
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.9);
        textColor = Colors.white;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// ============================================================================
// Explore Campaigns Tab (탐색하기) - Fan-like experience
// ============================================================================

class _ExploreCampaignsTab extends StatefulWidget {
  final bool isDemoMode;

  const _ExploreCampaignsTab({required this.isDemoMode});

  @override
  State<_ExploreCampaignsTab> createState() => _ExploreCampaignsTabState();
}

class _ExploreCampaignsTabState extends State<_ExploreCampaignsTab>
    with SingleTickerProviderStateMixin {
  late TabController _filterTabController;
  final List<String> _filterTabs = ['진행중', '마감임박', '인기', '신규'];

  @override
  void initState() {
    super.initState();
    _filterTabController =
        TabController(length: _filterTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _filterTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '펀딩 검색...',
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) {
                      // TODO: Implement search
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Filter tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _filterTabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnimatedBuilder(
                  animation: _filterTabController,
                  builder: (context, child) {
                    final isSelected = _filterTabController.index == index;
                    return GestureDetector(
                      onTap: () => _filterTabController.animateTo(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.text)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark
                                    ? AppColors.borderDark
                                    : AppColors.border),
                          ),
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? (isDark
                                    ? AppColors.textDark
                                    : AppColors.surface)
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
            }).toList(),
          ),
        ),

        // Campaign list
        Expanded(
          child: TabBarView(
            controller: _filterTabController,
            children: [
              _ExploreCampaignList(
                  filter: 'active', isDemoMode: widget.isDemoMode),
              _ExploreCampaignList(
                  filter: 'ending_soon', isDemoMode: widget.isDemoMode),
              _ExploreCampaignList(
                  filter: 'popular', isDemoMode: widget.isDemoMode),
              _ExploreCampaignList(filter: 'new', isDemoMode: widget.isDemoMode),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExploreCampaignList extends StatefulWidget {
  final String filter;
  final bool isDemoMode;

  const _ExploreCampaignList({required this.filter, this.isDemoMode = false});

  @override
  State<_ExploreCampaignList> createState() => _ExploreCampaignListState();
}

class _ExploreCampaignListState extends State<_ExploreCampaignList>
    with AutomaticKeepAliveClientMixin {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _campaigns = [];
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  @override
  void didUpdateWidget(_ExploreCampaignList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDemoMode != widget.isDemoMode) {
      _loadCampaigns();
    }
  }

  Future<void> _loadCampaigns() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (widget.isDemoMode) {
      setState(() {
        _campaigns = _getDemoCampaigns();
        _isLoading = false;
      });
      return;
    }

    try {
      List<Map<String, dynamic>> response;

      switch (widget.filter) {
        case 'ending_soon':
          response = await _supabase
              .from('funding_campaigns')
              .select('*')
              .eq('status', 'active')
              .lte('end_at',
                  DateTime.now().add(const Duration(days: 3)).toIso8601String())
              .order('end_at', ascending: true)
              .limit(20);
          break;
        case 'popular':
          response = await _supabase
              .from('funding_campaigns')
              .select('*')
              .eq('status', 'active')
              .order('backer_count', ascending: false)
              .limit(20);
          break;
        case 'new':
          response = await _supabase
              .from('funding_campaigns')
              .select('*')
              .eq('status', 'active')
              .order('created_at', ascending: false)
              .limit(20);
          break;
        default:
          response = await _supabase
              .from('funding_campaigns')
              .select('*')
              .eq('status', 'active')
              .order('end_at', ascending: true)
              .limit(20);
      }

      setState(() {
        _campaigns = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getDemoCampaigns() {
    final now = DateTime.now();

    final demoCampaigns = [
      {
        'id': 'demo_campaign_1',
        'title': '김민지 1st 미니앨범 "Butterfly" 펀딩',
        'subtitle': '데뷔 1주년 기념 스페셜 앨범',
        'cover_image_url': 'https://picsum.photos/seed/funding1/800/450',
        'status': 'active',
        'goal_amount_dt': 50000000,
        'current_amount_dt': 42350000,
        'funding_percent': 84.7,
        'backer_count': 1523,
        'end_at': now.add(const Duration(days: 12)).toIso8601String(),
        'created_at': now.subtract(const Duration(days: 18)).toIso8601String(),
      },
      {
        'id': 'demo_campaign_2',
        'title': '이준호 팬미팅 "With You" 개최 프로젝트',
        'subtitle': '팬들과 함께하는 특별한 시간',
        'cover_image_url': 'https://picsum.photos/seed/funding2/800/450',
        'status': 'active',
        'goal_amount_dt': 30000000,
        'current_amount_dt': 38500000,
        'funding_percent': 128.3,
        'backer_count': 2891,
        'end_at': now.add(const Duration(days: 2)).toIso8601String(),
        'created_at': now.subtract(const Duration(days: 28)).toIso8601String(),
      },
      {
        'id': 'demo_campaign_3',
        'title': '박서연 화보집 "BLOOM" 제작',
        'subtitle': '봄을 닮은 청순 콘셉트',
        'cover_image_url': 'https://picsum.photos/seed/funding3/800/450',
        'status': 'active',
        'goal_amount_dt': 20000000,
        'current_amount_dt': 15200000,
        'funding_percent': 76.0,
        'backer_count': 847,
        'end_at': now.add(const Duration(days: 25)).toIso8601String(),
        'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'id': 'demo_campaign_4',
        'title': 'NOVA 그룹 콘서트 굿즈 제작',
        'subtitle': '월드투어 기념 한정판',
        'cover_image_url': 'https://picsum.photos/seed/funding4/800/450',
        'status': 'active',
        'goal_amount_dt': 100000000,
        'current_amount_dt': 89000000,
        'funding_percent': 89.0,
        'backer_count': 4521,
        'end_at': now.add(const Duration(days: 7)).toIso8601String(),
        'created_at': now.subtract(const Duration(days: 23)).toIso8601String(),
      },
      {
        'id': 'demo_campaign_5',
        'title': '최유나 생일 서포트 펀딩',
        'subtitle': '팬들의 마음을 담은 생일 선물',
        'cover_image_url': 'https://picsum.photos/seed/funding5/800/450',
        'status': 'active',
        'goal_amount_dt': 10000000,
        'current_amount_dt': 12500000,
        'funding_percent': 125.0,
        'backer_count': 632,
        'end_at': now.add(const Duration(days: 1)).toIso8601String(),
        'created_at': now.subtract(const Duration(days: 14)).toIso8601String(),
      },
    ];

    switch (widget.filter) {
      case 'ending_soon':
        return demoCampaigns.where((c) {
          final endAt = DateTime.parse(c['end_at'] as String);
          return endAt.difference(now).inDays <= 3;
        }).toList();
      case 'popular':
        final sorted = List<Map<String, dynamic>>.from(demoCampaigns);
        sorted.sort(
            (a, b) => (b['backer_count'] as int).compareTo(a['backer_count'] as int));
        return sorted;
      case 'new':
        final sorted = List<Map<String, dynamic>>.from(demoCampaigns);
        sorted.sort((a, b) {
          final aDate = DateTime.parse(a['created_at'] as String);
          final bDate = DateTime.parse(b['created_at'] as String);
          return bDate.compareTo(aDate);
        });
        return sorted;
      default:
        return demoCampaigns;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              '데이터를 불러오지 못했습니다',
              style: TextStyle(
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadCampaigns,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              '진행 중인 펀딩이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCampaigns,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _campaigns.length,
        itemBuilder: (context, index) {
          return _ExploreCampaignCard(
            campaign: _campaigns[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FundingDetailScreen(
                    campaignId: _campaigns[index]['id'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ExploreCampaignCard extends StatelessWidget {
  final Map<String, dynamic> campaign;
  final VoidCallback onTap;

  const _ExploreCampaignCard({
    required this.campaign,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fundingPercent =
        (campaign['funding_percent'] as num?)?.toDouble() ?? 0;
    final endAt = DateTime.tryParse(campaign['end_at'] ?? '');
    final daysLeft =
        endAt != null ? endAt.difference(DateTime.now()).inDays : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: campaign['cover_image_url'] != null
                    ? Image.network(
                        campaign['cover_image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
                      )
                    : _buildPlaceholder(isDark),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    campaign['title'] ?? '제목 없음',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDark : AppColors.text,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (campaign['subtitle'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      campaign['subtitle'],
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark ? AppColors.textMutedDark : AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (fundingPercent / 100).clamp(0, 1),
                      backgroundColor: isDark
                          ? AppColors.surfaceAltDark
                          : AppColors.surfaceAlt,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        fundingPercent >= 100
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                      minHeight: 6,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Stats row
                  Row(
                    children: [
                      // Funding percent
                      Text(
                        '${fundingPercent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: fundingPercent >= 100
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),

                      const Spacer(),

                      // Amount
                      Text(
                        '${_formatNumber(campaign['current_amount_dt'] ?? 0)} DT',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textDark : AppColors.text,
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Days left
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: daysLeft <= 3
                              ? AppColors.danger100
                              : (isDark
                                  ? AppColors.surfaceAltDark
                                  : AppColors.surfaceAlt),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          daysLeft > 0 ? 'D-$daysLeft' : '마감',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: daysLeft <= 3
                                ? AppColors.danger
                                : (isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
        ),
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
