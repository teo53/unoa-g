import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/funding_provider.dart';
import 'campaign_backers_screen.dart';
import 'campaign_stats_screen.dart';
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
                children: const [
                  _MyCampaignsTab(),
                  _ExploreCampaignsTab(),
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
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primary600,
            ),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateCampaignScreen(),
                ),
              );
              if (result == true) {
                ref.read(fundingProvider.notifier).refresh();
              }
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

class _MyCampaignsTab extends ConsumerStatefulWidget {
  const _MyCampaignsTab();

  @override
  ConsumerState<_MyCampaignsTab> createState() => _MyCampaignsTabState();
}

class _MyCampaignsTabState extends ConsumerState<_MyCampaignsTab>
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
    final fundingState = ref.watch(fundingProvider);

    return Column(
      children: [
        // Summary card
        _buildSummaryCard(isDark, fundingState),

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
            children: const [
              _CreatorCampaignList(status: 'active'),
              _CreatorCampaignList(status: 'draft'),
              _CreatorCampaignList(status: 'ended'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(bool isDark, FundingState fundingState) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.primary100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: (isDark ? Colors.white : AppColors.primary500)
                .withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary600.withValues(alpha: 0.3),
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
                  value: '${fundingState.totalActiveCampaigns}',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: (isDark ? Colors.white : AppColors.primary500)
                    .withValues(alpha: 0.2),
              ),
              Expanded(
                child: _SummaryStatItem(
                  icon: Icons.people_rounded,
                  label: '총 후원자',
                  value: _formatCompactNumber(fundingState.totalBackers),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: (isDark ? Colors.white : AppColors.primary500)
                    .withValues(alpha: 0.2),
              ),
              Expanded(
                child: _SummaryStatItem(
                  icon: Icons.savings_rounded,
                  label: '총 모금액',
                  value: _formatCompactNumber(fundingState.totalRaisedKrw),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCompactNumber(int number) {
    if (number >= 100000000) {
      return '${(number / 100000000).toStringAsFixed(1)}억';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(1)}만';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon,
            color: isDark
                ? Colors.white.withValues(alpha: 0.9)
                : AppColors.primary600,
            size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.primary700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? Colors.white.withValues(alpha: 0.8)
                : AppColors.primary600.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Creator Campaign List (My Campaigns) - Provider-based
// ============================================================================

class _CreatorCampaignList extends ConsumerWidget {
  final String status;

  const _CreatorCampaignList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = ref.watch(fundingLoadingProvider);

    List<Campaign> campaigns;
    switch (status) {
      case 'active':
        campaigns = ref.watch(myActiveCampaignsProvider);
        break;
      case 'draft':
        campaigns = ref.watch(myDraftCampaignsProvider);
        break;
      case 'ended':
        campaigns = ref.watch(myEndedCampaignsProvider);
        break;
      default:
        campaigns = [];
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (campaigns.isEmpty) {
      return _buildEmptyState(context, isDark);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(fundingProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: campaigns.length,
        itemBuilder: (context, index) {
          final campaign = campaigns[index];
          return _CreatorCampaignCard(
            campaign: campaign,
            onTap: () => _showCampaignOptions(context, ref, campaign),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    String message;
    IconData icon;

    switch (status) {
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
          if (status == 'draft' || status == 'active') ...[
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

  void _showCampaignOptions(
      BuildContext context, WidgetRef ref, Campaign campaign) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
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
                campaign.title,
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
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FundingDetailScreen(
                      campaignId: campaign.id,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('펀딩 수정'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateCampaignScreen(
                      campaignId: campaign.id,
                    ),
                  ),
                );
                if (result == true) {
                  ref.read(fundingProvider.notifier).refresh();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text('통계 보기'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CampaignStatsScreen(
                      campaignId: campaign.id,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('후원자 목록'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CampaignBackersScreen(
                      campaignId: campaign.id,
                    ),
                  ),
                );
              },
            ),
            if (campaign.status == CampaignStatus.draft)
              ListTile(
                leading: const Icon(Icons.publish_outlined,
                    color: AppColors.primary),
                title: const Text(
                  '펀딩 시작하기',
                  style: TextStyle(color: AppColors.primary),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  try {
                    await ref
                        .read(fundingProvider.notifier)
                        .startCampaign(campaign.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('펀딩이 시작되었습니다!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('오류: $e')),
                      );
                    }
                  }
                },
              ),
            if (campaign.status == CampaignStatus.active)
              ListTile(
                leading: const Icon(Icons.pause_circle_outline,
                    color: AppColors.warning),
                title: const Text(
                  '펀딩 일시정지',
                  style: TextStyle(color: AppColors.warning),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  try {
                    await ref
                        .read(fundingProvider.notifier)
                        .pauseCampaign(campaign.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('펀딩이 일시정지되었습니다')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('오류: $e')),
                      );
                    }
                  }
                },
              ),
            if (campaign.status == CampaignStatus.paused)
              ListTile(
                leading: const Icon(Icons.play_circle_outline,
                    color: AppColors.success),
                title: const Text(
                  '펀딩 재개하기',
                  style: TextStyle(color: AppColors.success),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  try {
                    await ref
                        .read(fundingProvider.notifier)
                        .resumeCampaign(campaign.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('펀딩이 재개되었습니다!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('오류: $e')),
                      );
                    }
                  }
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
  final Campaign campaign;
  final VoidCallback onTap;

  const _CreatorCampaignCard({
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    campaign.coverImageUrl != null
                        ? Image.network(
                            campaign.coverImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildPlaceholder(isDark),
                          )
                        : _buildPlaceholder(isDark),

                    // Status badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _buildStatusBadge(campaign.status),
                    ),

                    // More button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
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
                    campaign.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDark : AppColors.text,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (campaign.status != CampaignStatus.draft) ...[
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
                        const SizedBox(width: 8),
                        Text(
                          '${campaign.backerCount}명 후원',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMuted,
                          ),
                        ),
                        const Spacer(),
                        if (campaign.status == CampaignStatus.active &&
                            daysLeft > 0)
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
                        if (campaign.status == CampaignStatus.paused)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '일시정지',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        if (campaign.status == CampaignStatus.completed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: campaign.isSuccessful
                                  ? AppColors.success100
                                  : AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              campaign.isSuccessful ? '성공' : '미달성',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: campaign.isSuccessful
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
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMuted,
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

  Widget _buildStatusBadge(CampaignStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case CampaignStatus.active:
        bgColor = AppColors.success.withValues(alpha: 0.9);
        textColor = Colors.white;
        label = '진행중';
        break;
      case CampaignStatus.draft:
        bgColor = AppColors.warning.withValues(alpha: 0.9);
        textColor = Colors.white;
        label = '준비중';
        break;
      case CampaignStatus.paused:
        bgColor = AppColors.warning.withValues(alpha: 0.9);
        textColor = Colors.white;
        label = '일시정지';
        break;
      case CampaignStatus.completed:
        bgColor = Colors.grey.withValues(alpha: 0.9);
        textColor = Colors.white;
        label = '종료';
        break;
      case CampaignStatus.cancelled:
        bgColor = AppColors.danger.withValues(alpha: 0.9);
        textColor = Colors.white;
        label = '취소됨';
        break;
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
// Explore Campaigns Tab (탐색하기) - Provider-based
// ============================================================================

class _ExploreCampaignsTab extends ConsumerStatefulWidget {
  const _ExploreCampaignsTab();

  @override
  ConsumerState<_ExploreCampaignsTab> createState() =>
      _ExploreCampaignsTabState();
}

class _ExploreCampaignsTabState extends ConsumerState<_ExploreCampaignsTab>
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
                    onChanged: (value) {
                      ref.read(fundingProvider.notifier).setSearchQuery(value);
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
            children: const [
              _ExploreCampaignList(filter: 'active'),
              _ExploreCampaignList(filter: 'ending_soon'),
              _ExploreCampaignList(filter: 'popular'),
              _ExploreCampaignList(filter: 'new'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExploreCampaignList extends ConsumerWidget {
  final String filter;

  const _ExploreCampaignList({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      return const Center(child: CircularProgressIndicator());
    }

    if (campaigns.isEmpty) {
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
      onRefresh: () => ref.read(fundingProvider.notifier).refresh(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: campaigns.length,
        itemBuilder: (context, index) {
          final campaign = campaigns[index];
          return _ExploreCampaignCard(
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

class _ExploreCampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback onTap;

  const _ExploreCampaignCard({
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
