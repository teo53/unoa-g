import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'funding_detail_screen.dart';

/// Main funding screen showing active campaigns
class FundingScreen extends ConsumerStatefulWidget {
  const FundingScreen({super.key});

  @override
  ConsumerState<FundingScreen> createState() => _FundingScreenState();
}

class _FundingScreenState extends ConsumerState<FundingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  final List<String> _tabs = ['진행중', '마감임박', '인기', '신규'];

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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildTabBar(isDark),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CampaignList(filter: 'active', isDemoMode: isDemoMode),
                  _CampaignList(filter: 'ending_soon', isDemoMode: isDemoMode),
                  _CampaignList(filter: 'popular', isDemoMode: isDemoMode),
                  _CampaignList(filter: 'new', isDemoMode: isDemoMode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Text(
            '펀딩',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : AppColors.text,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }
}

class _CampaignList extends StatefulWidget {
  final String filter;
  final bool isDemoMode;

  const _CampaignList({required this.filter, this.isDemoMode = false});

  @override
  State<_CampaignList> createState() => _CampaignListState();
}

class _CampaignListState extends State<_CampaignList>
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
  void didUpdateWidget(_CampaignList oldWidget) {
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

    // Demo mode: show demo campaigns
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
              .lte('end_at', DateTime.now().add(const Duration(days: 3)).toIso8601String())
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

  /// Generate demo campaigns for demo mode
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

    // Filter based on tab
    switch (widget.filter) {
      case 'ending_soon':
        return demoCampaigns.where((c) {
          final endAt = DateTime.parse(c['end_at'] as String);
          return endAt.difference(now).inDays <= 3;
        }).toList();
      case 'popular':
        final sorted = List<Map<String, dynamic>>.from(demoCampaigns);
        sorted.sort((a, b) => (b['backer_count'] as int).compareTo(a['backer_count'] as int));
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
        padding: const EdgeInsets.all(20),
        itemCount: _campaigns.length,
        itemBuilder: (context, index) {
          return _CampaignCard(
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

class _CampaignCard extends StatelessWidget {
  final Map<String, dynamic> campaign;
  final VoidCallback onTap;

  const _CampaignCard({
    required this.campaign,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fundingPercent = (campaign['funding_percent'] as num?)?.toDouble() ?? 0;
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
                        color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
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
                              : (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          daysLeft > 0 ? 'D-$daysLeft' : '마감',
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
