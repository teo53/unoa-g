import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'funding_tier_select_screen.dart';

/// Campaign detail screen showing full information
class FundingDetailScreen extends ConsumerStatefulWidget {
  final String campaignId;

  const FundingDetailScreen({
    super.key,
    required this.campaignId,
  });

  @override
  ConsumerState<FundingDetailScreen> createState() => _FundingDetailScreenState();
}

class _FundingDetailScreenState extends ConsumerState<FundingDetailScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _campaign;
  List<Map<String, dynamic>> _tiers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCampaign();
  }

  Future<void> _loadCampaign() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Check if demo mode
    final isDemoMode = ref.read(isDemoModeProvider);
    if (isDemoMode && widget.campaignId.startsWith('demo_')) {
      _loadDemoCampaign();
      return;
    }

    try {
      // Load campaign
      final campaignResponse = await _supabase
          .from('funding_campaigns')
          .select('*')
          .eq('id', widget.campaignId)
          .single();

      // Load tiers
      final tiersResponse = await _supabase
          .from('funding_reward_tiers')
          .select('*')
          .eq('campaign_id', widget.campaignId)
          .eq('is_active', true)
          .order('display_order');

      setState(() {
        _campaign = campaignResponse;
        _tiers = List<Map<String, dynamic>>.from(tiersResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Load demo campaign data
  void _loadDemoCampaign() {
    final now = DateTime.now();

    // Demo campaign details
    final demoCampaigns = {
      'demo_campaign_1': {
        'id': 'demo_campaign_1',
        'title': '김민지 1st 미니앨범 "Butterfly" 펀딩',
        'subtitle': '데뷔 1주년 기념 스페셜 앨범',
        'cover_image_url': 'https://picsum.photos/seed/funding1/800/450',
        'status': 'active',
        'category': '앨범',
        'goal_amount_dt': 50000000,
        'current_amount_dt': 42350000,
        'funding_percent': 84.7,
        'backer_count': 1523,
        'end_at': now.add(const Duration(days: 12)).toIso8601String(),
        'description_md': '''
안녕하세요, 김민지입니다! 💕

데뷔 1주년을 맞아 첫 번째 미니앨범 "Butterfly"를 준비하게 되었어요.

이번 앨범에는 제가 직접 작사에 참여한 곡들도 수록될 예정이에요. 팬 여러분들께 드리고 싶은 이야기들을 담았습니다.

**앨범 구성**
- 타이틀곡 "Butterfly"
- 수록곡 4곡
- 팬을 위한 히든 트랙

**펀딩 목표**
이번 펀딩을 통해 더 높은 퀄리티의 앨범과 뮤직비디오를 제작하고 싶어요!

팬 여러분의 응원이 큰 힘이 됩니다. 사랑해요! 🦋
        ''',
      },
      'demo_campaign_2': {
        'id': 'demo_campaign_2',
        'title': '이준호 팬미팅 "With You" 개최 프로젝트',
        'subtitle': '팬들과 함께하는 특별한 시간',
        'cover_image_url': 'https://picsum.photos/seed/funding2/800/450',
        'status': 'active',
        'category': '팬미팅',
        'goal_amount_dt': 30000000,
        'current_amount_dt': 38500000,
        'funding_percent': 128.3,
        'backer_count': 2891,
        'end_at': now.add(const Duration(days: 2)).toIso8601String(),
        'description_md': '''
팬 여러분, 안녕하세요! 이준호입니다.

팬미팅 "With You"에 여러분을 초대합니다!

**행사 내용**
- 토크 세션
- 미니 콘서트
- 팬 사인회
- 게임 타임
- 특별 선물 증정

**일시 및 장소**
목표 달성 시 서울 코엑스 아티움에서 개최 예정입니다.

함께해주세요! ❤️
        ''',
      },
      'demo_campaign_3': {
        'id': 'demo_campaign_3',
        'title': '박서연 화보집 "BLOOM" 제작',
        'subtitle': '봄을 닮은 청순 콘셉트',
        'cover_image_url': 'https://picsum.photos/seed/funding3/800/450',
        'status': 'active',
        'category': '화보집',
        'goal_amount_dt': 20000000,
        'current_amount_dt': 15200000,
        'funding_percent': 76.0,
        'backer_count': 847,
        'end_at': now.add(const Duration(days: 25)).toIso8601String(),
        'description_md': '''
첫 화보집 "BLOOM"을 준비합니다! 🌸

봄을 콘셉트로 한 다양한 모습을 담았어요.

**화보집 구성**
- 100페이지 이상 분량
- 청순/걸리시/시크 3가지 콘셉트
- 미공개 셀카 포함
- 친필 사인 가능 (VIP 티어)

많은 관심 부탁드려요!
        ''',
      },
      'demo_campaign_4': {
        'id': 'demo_campaign_4',
        'title': 'NOVA 그룹 콘서트 굿즈 제작',
        'subtitle': '월드투어 기념 한정판',
        'cover_image_url': 'https://picsum.photos/seed/funding4/800/450',
        'status': 'active',
        'category': '굿즈',
        'goal_amount_dt': 100000000,
        'current_amount_dt': 89000000,
        'funding_percent': 89.0,
        'backer_count': 4521,
        'end_at': now.add(const Duration(days: 7)).toIso8601String(),
        'description_md': '''
NOVA 첫 월드투어 기념 한정판 굿즈!

**굿즈 라인업**
- 응원봉 (새 버전)
- 포토북
- 아크릴 스탠드
- 포토카드 세트
- 포스터

모든 굿즈는 투어 한정 디자인입니다!
        ''',
      },
      'demo_campaign_5': {
        'id': 'demo_campaign_5',
        'title': '최유나 생일 서포트 펀딩',
        'subtitle': '팬들의 마음을 담은 생일 선물',
        'cover_image_url': 'https://picsum.photos/seed/funding5/800/450',
        'status': 'active',
        'category': '서포트',
        'goal_amount_dt': 10000000,
        'current_amount_dt': 12500000,
        'funding_percent': 125.0,
        'backer_count': 632,
        'end_at': now.add(const Duration(days: 1)).toIso8601String(),
        'description_md': '''
최유나님의 생일을 축하합니다! 🎂

팬들의 마음을 모아 특별한 생일 선물을 준비하고자 합니다.

**서포트 내용**
- 지하철 광고 (강남역)
- 카페 컵홀더 이벤트
- LED 전광판 축하 영상
- 생일 케이크 및 꽃다발

함께 축하해주세요!
        ''',
      },
    };

    final demoTiers = _getDemoTiers(widget.campaignId);

    setState(() {
      _campaign = demoCampaigns[widget.campaignId] ?? demoCampaigns['demo_campaign_1'];
      _tiers = demoTiers;
      _isLoading = false;
    });
  }

  /// Get demo tiers for a campaign
  List<Map<String, dynamic>> _getDemoTiers(String campaignId) {
    return [
      {
        'id': '${campaignId}_tier_1',
        'campaign_id': campaignId,
        'title': '응원 참여',
        'description': '펀딩 참여 인증서 (디지털)\n감사 메시지 (카카오톡)',
        'price_dt': 5000,
        'total_quantity': null,
        'remaining_quantity': null,
        'pledge_count': 423,
        'display_order': 1,
        'is_active': true,
        'is_featured': false,
      },
      {
        'id': '${campaignId}_tier_2',
        'campaign_id': campaignId,
        'title': '기본 리워드',
        'description': '응원 참여 포함\n디지털 포토카드 5장\n팬명 크레딧 등재',
        'price_dt': 15000,
        'total_quantity': 1000,
        'remaining_quantity': 347,
        'pledge_count': 653,
        'display_order': 2,
        'is_active': true,
        'is_featured': true,
      },
      {
        'id': '${campaignId}_tier_3',
        'campaign_id': campaignId,
        'title': '스페셜 리워드',
        'description': '기본 리워드 포함\n실물 포토카드 세트\n사인 폴라로이드 1장 (랜덤)\n한정판 포스터',
        'price_dt': 50000,
        'total_quantity': 300,
        'remaining_quantity': 89,
        'pledge_count': 211,
        'display_order': 3,
        'is_active': true,
        'is_featured': false,
      },
      {
        'id': '${campaignId}_tier_4',
        'campaign_id': campaignId,
        'title': 'VIP 리워드',
        'description': '스페셜 리워드 포함\n영상 통화 팬사인회 참여권\n친필 사인 앨범\n프리미엄 굿즈 세트',
        'price_dt': 150000,
        'total_quantity': 50,
        'remaining_quantity': 0,
        'pledge_count': 50,
        'display_order': 4,
        'is_active': true,
        'is_featured': false,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _campaign == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
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
                '펀딩을 불러오지 못했습니다',
                style: TextStyle(
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadCampaign,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    final campaign = _campaign!;
    final fundingPercent = (campaign['funding_percent'] as num?)?.toDouble() ?? 0;
    final endAt = DateTime.tryParse(campaign['end_at'] ?? '');
    final daysLeft = endAt != null ? endAt.difference(DateTime.now()).inDays : 0;
    final isEnded = daysLeft < 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar with cover image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: campaign['cover_image_url'] != null
                  ? Image.network(
                      campaign['cover_image_url'],
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campaign info
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
                      if (campaign['category'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            campaign['category'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary600,
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Title
                      Text(
                        campaign['title'] ?? '제목 없음',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textDark : AppColors.text,
                        ),
                      ),

                      if (campaign['subtitle'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          campaign['subtitle'],
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Stats card
                      _buildStatsCard(isDark, campaign, fundingPercent, daysLeft),

                      const SizedBox(height: 24),

                      // Description
                      Text(
                        '프로젝트 소개',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textDark : AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        campaign['description_md'] ?? '설명이 없습니다.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: isDark ? AppColors.textDark : AppColors.text,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Reward tiers
                      Text(
                        '리워드 선택',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textDark : AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tier list
                ..._tiers.map((tier) => _buildTierCard(isDark, tier, isEnded)),

                const SizedBox(height: 100), // Bottom padding for FAB
              ],
            ),
          ),
        ],
      ),

      // Support button
      bottomNavigationBar: !isEnded
          ? Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                12 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${fundingPercent.toStringAsFixed(0)}% 달성',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'D-$daysLeft',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FundingTierSelectScreen(
                            campaign: campaign,
                            tiers: _tiers,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '후원하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildStatsCard(
    bool isDark,
    Map<String, dynamic> campaign,
    double fundingPercent,
    int daysLeft,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (fundingPercent / 100).clamp(0, 1),
              backgroundColor: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(
                fundingPercent >= 100 ? AppColors.success : AppColors.primary,
              ),
              minHeight: 10,
            ),
          ),

          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _buildStatItem(
                isDark,
                '달성률',
                '${fundingPercent.toStringAsFixed(0)}%',
                AppColors.primary,
              ),
              _buildStatDivider(isDark),
              _buildStatItem(
                isDark,
                '모인 금액',
                '${_formatNumber(campaign['current_amount_dt'] ?? 0)} DT',
                null,
              ),
              _buildStatDivider(isDark),
              _buildStatItem(
                isDark,
                '후원자',
                '${campaign['backer_count'] ?? 0}명',
                null,
              ),
              _buildStatDivider(isDark),
              _buildStatItem(
                isDark,
                '남은 기간',
                daysLeft > 0 ? 'D-$daysLeft' : '마감',
                daysLeft <= 3 ? AppColors.danger : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    bool isDark,
    String label,
    String value,
    Color? valueColor,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDark ? AppColors.textDark : AppColors.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 1,
      height: 32,
      color: isDark ? AppColors.borderDark : AppColors.border,
    );
  }

  Widget _buildTierCard(bool isDark, Map<String, dynamic> tier, bool isEnded) {
    final isSoldOut = tier['total_quantity'] != null &&
        (tier['remaining_quantity'] ?? 0) <= 0;
    final isDisabled = isEnded || isSoldOut;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDisabled
              ? (isDark ? AppColors.borderDark : AppColors.border)
              : AppColors.primary.withOpacity(0.3),
          width: isDisabled ? 1 : 2,
        ),
      ),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tier['title'] ?? '리워드',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textDark : AppColors.text,
                      ),
                    ),
                  ),
                  if (tier['is_featured'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '인기',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary600,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                '${_formatNumber(tier['price_dt'] ?? 0)} DT',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                tier['description'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                ),
              ),

              const SizedBox(height: 12),

              // Inventory info
              Row(
                children: [
                  if (tier['total_quantity'] != null) ...[
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSoldOut
                          ? '품절'
                          : '${tier['remaining_quantity']}/${tier['total_quantity']} 남음',
                      style: TextStyle(
                        fontSize: 13,
                        color: isSoldOut
                            ? AppColors.danger
                            : (isDark ? AppColors.textMutedDark : AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  Icon(
                    Icons.people_outline_rounded,
                    size: 16,
                    color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${tier['pledge_count'] ?? 0}명 후원',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
