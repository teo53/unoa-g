import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'create_campaign_screen.dart';

/// Creator's funding management screen
class CreatorFundingScreen extends ConsumerStatefulWidget {
  const CreatorFundingScreen({super.key});

  @override
  ConsumerState<CreatorFundingScreen> createState() => _CreatorFundingScreenState();
}

class _CreatorFundingScreenState extends ConsumerState<CreatorFundingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  final List<String> _tabs = ['진행중', '준비중', '종료됨'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDemoMode = ref.watch(isDemoModeProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('펀딩 관리'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
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
      body: Column(
        children: [
          _buildTabBar(isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CreatorCampaignList(status: 'active', isDemoMode: isDemoMode),
                _CreatorCampaignList(status: 'draft', isDemoMode: isDemoMode),
                _CreatorCampaignList(status: 'ended', isDemoMode: isDemoMode),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateCampaignScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary600,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('새 펀딩'),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary600,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.onPrimary,
        unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMuted,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }
}

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
          'created_at': now.subtract(const Duration(days: 15)).toIso8601String(),
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
          'cover_image_url': 'https://picsum.photos/seed/mycampaignended/800/450',
          'status': 'completed',
          'goal_amount_dt': 25000000,
          'current_amount_dt': 32000000,
          'funding_percent': 128.0,
          'backer_count': 1245,
          'end_at': now.subtract(const Duration(days: 10)).toIso8601String(),
          'created_at': now.subtract(const Duration(days: 40)).toIso8601String(),
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
                // TODO: Navigate to stats screen
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
                // TODO: Navigate to backers list
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
                  // TODO: Publish campaign
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('펀딩 시작 기능은 준비 중입니다')),
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
    final fundingPercent = (campaign['funding_percent'] as num?)?.toDouble() ?? 0;
    final status = campaign['status'] as String? ?? 'draft';
    final endAt = DateTime.tryParse(campaign['end_at'] ?? '');
    final daysLeft = endAt != null ? endAt.difference(DateTime.now()).inDays : 0;

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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    campaign['cover_image_url'] != null
                        ? Image.network(
                            campaign['cover_image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
                          )
                        : _buildPlaceholder(isDark),

                    // Status badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _buildStatusBadge(status),
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
                        backgroundColor: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          fundingPercent >= 100 ? AppColors.success : AppColors.primary,
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
                            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
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
                                  : (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'D-$daysLeft',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: daysLeft <= 3
                                    ? AppColors.danger
                                    : (isDark ? AppColors.textMutedDark : AppColors.textMuted),
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
                        color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
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
