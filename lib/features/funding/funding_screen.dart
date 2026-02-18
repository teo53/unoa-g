import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/funding_provider.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/error_boundary.dart';
import 'funding_detail_screen.dart';

/// Main funding screen showing active campaigns (fan view)
class FundingScreen extends ConsumerStatefulWidget {
  const FundingScreen({super.key});

  @override
  ConsumerState<FundingScreen> createState() => _FundingScreenState();
}

class _FundingScreenState extends ConsumerState<FundingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearching = false;
  final _searchController = TextEditingController();

  final List<String> _tabs = ['진행중', '마감임박', '인기', '신규'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                children: const [
                  _CampaignList(filter: 'active'),
                  _CampaignList(filter: 'ending_soon'),
                  _CampaignList(filter: 'popular'),
                  _CampaignList(filter: 'new'),
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
      child: _isSearching
          ? Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceAltDark
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.iconMutedDark
                              : AppColors.iconMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: '펀딩 검색...',
                              hintStyle: TextStyle(
                                fontSize: 15,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMuted,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: TextStyle(
                              fontSize: 15,
                              color:
                                  isDark ? AppColors.textDark : AppColors.text,
                            ),
                            onChanged: (value) {
                              ref
                                  .read(fundingProvider.notifier)
                                  .setSearchQuery(value);
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              ref
                                  .read(fundingProvider.notifier)
                                  .setSearchQuery('');
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.iconMutedDark
                                  : AppColors.iconMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() => _isSearching = false);
                    _searchController.clear();
                    ref.read(fundingProvider.notifier).setSearchQuery('');
                  },
                  child: Text(
                    '취소',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            )
          : Row(
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
                    color:
                        isDark ? AppColors.textMutedDark : AppColors.textMuted,
                  ),
                  onPressed: () {
                    setState(() => _isSearching = true);
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
        unselectedLabelColor:
            isDark ? AppColors.textMutedDark : AppColors.textMuted,
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

class _CampaignList extends ConsumerWidget {
  final String filter;

  const _CampaignList({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(fundingLoadingProvider);

    List<Campaign> campaigns;
    switch (filter) {
      case 'ending_soon':
        campaigns = ref.watch(endingSoonCampaignsProvider);
        break;
      case 'popular':
        campaigns = ref.watch(popularCampaignsProvider);
        break;
      case 'new':
        campaigns = ref.watch(newCampaignsProvider);
        break;
      default:
        campaigns = ref.watch(exploreCampaignsProvider);
    }

    if (isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: SkeletonCard(width: double.infinity, height: 180),
        ),
      );
    }

    if (campaigns.isEmpty) {
      return const EmptyState(
        title: '진행 중인 펀딩이 없어요',
        message: '새로운 펀딩 프로젝트가 곧 시작됩니다!',
        icon: Icons.campaign_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(fundingProvider.notifier).refresh(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: campaigns.length,
        itemBuilder: (context, index) {
          final campaign = campaigns[index];
          return _CampaignCard(
            campaign: campaign,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FundingDetailScreen(
                    campaignId: campaign.id,
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
  final Campaign campaign;
  final VoidCallback onTap;

  const _CampaignCard({
    required this.campaign,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysLeft = campaign.daysLeft;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                child: campaign.coverImageUrl != null
                    ? Image.network(
                        campaign.coverImageUrl!,
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
                    campaign.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDark : AppColors.text,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (campaign.subtitle != null &&
                      campaign.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      campaign.subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMuted,
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
                      value: (campaign.fundingPercent / 100).clamp(0.0, 1.0),
                      backgroundColor: isDark
                          ? AppColors.surfaceAltDark
                          : AppColors.surfaceAlt,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        campaign.fundingPercent >= 100
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
                        '${campaign.fundingPercent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: campaign.fundingPercent >= 100
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),

                      const Spacer(),

                      // Amount
                      Text(
                        '${_formatNumber(campaign.currentAmountKrw)}원',
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
