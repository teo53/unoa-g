import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import 'funding_tier_select_screen.dart';

/// Campaign detail screen showing full information
class FundingDetailScreen extends StatefulWidget {
  final String campaignId;

  const FundingDetailScreen({
    super.key,
    required this.campaignId,
  });

  @override
  State<FundingDetailScreen> createState() => _FundingDetailScreenState();
}

class _FundingDetailScreenState extends State<FundingDetailScreen> {
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
