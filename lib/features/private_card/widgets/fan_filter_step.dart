import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/fan_filter.dart';
import '../../../providers/private_card_provider.dart';
import 'fan_filter_bottom_sheet.dart';

/// Step 2: Fan selection with filters
/// - Filter selection button (opens bottom sheet)
/// - Matched fan list with checkboxes
/// - Favorites section (starred fans at top)
/// - Star icon to toggle favorite on each fan
class FanFilterStep extends ConsumerWidget {
  const FanFilterStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final composeState = ref.watch(privateCardComposeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Step header
          _buildStepHeader(isDark, '2', '받을 팬 선택하기'),

          const SizedBox(height: 20),

          // Filter selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // + 추천 필터 선택 button
                GestureDetector(
                  onTap: () async {
                    final filter = await FanFilterBottomSheet.show(
                      context: context,
                    );
                    if (filter != null) {
                      ref.read(privateCardComposeProvider.notifier).selectFilter(filter);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.vip,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          '추천 필터 선택',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // 필터 삭제
                if (composeState.selectedFilter != null)
                  GestureDetector(
                    onTap: () {
                      ref.read(privateCardComposeProvider.notifier).clearFilter();
                    },
                    child: Text(
                      '필터 삭제',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Active filter display
          if (composeState.selectedFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.vip.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.vip.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      composeState.selectedFilter!.icon,
                      size: 18,
                      color: AppColors.vip,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        composeState.selectedFilter!.displayName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.vip,
                        ),
                      ),
                    ),
                    Text(
                      '${composeState.matchedFans.length}명',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.vip,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Text(
                  '필터를 추가해보세요',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.vip.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Select all / deselect all
          if (composeState.matchedFans.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '매칭된 팬 ${composeState.matchedFans.length}명',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      if (composeState.selectedFanIds.length == composeState.matchedFans.length) {
                        ref.read(privateCardComposeProvider.notifier).deselectAllFans();
                      } else {
                        ref.read(privateCardComposeProvider.notifier).selectAllMatchedFans();
                      }
                    },
                    child: Text(
                      composeState.selectedFanIds.length == composeState.matchedFans.length
                          ? '전체 해제'
                          : '전체 선택',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.vip,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Loading
          if (composeState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: AppColors.vip,
                ),
              ),
            ),

          // Fan list
          if (!composeState.isLoading)
            ...composeState.matchedFans.map((fan) {
              final isSelected = composeState.selectedFanIds.contains(fan.userId);
              return _FanListItem(
                fan: fan,
                isSelected: isSelected,
                onToggleSelect: () {
                  ref.read(privateCardComposeProvider.notifier).toggleFanSelection(fan.userId);
                },
                onToggleFavorite: () {
                  ref.read(privateCardComposeProvider.notifier).toggleFavorite(fan.userId);
                },
              );
            }),

          // Empty state
          if (!composeState.isLoading && composeState.matchedFans.isEmpty && composeState.selectedFilter != null)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.person_search_outlined,
                      size: 48,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '매칭되는 팬이 없습니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(bool isDark, String number, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.vip,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual fan row in the selection list
class _FanListItem extends StatelessWidget {
  final FanSummary fan;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onToggleFavorite;

  const _FanListItem({
    required this.fan,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onToggleSelect,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.vip : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? AppColors.vip
                      : isDark
                          ? Colors.grey[600]!
                          : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),

            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
              backgroundImage: fan.avatarUrl != null
                  ? CachedNetworkImageProvider(fan.avatarUrl!)
                  : null,
              child: fan.avatarUrl == null
                  ? Icon(Icons.person, color: isDark ? Colors.grey[500] : Colors.grey[400])
                  : null,
            ),
            const SizedBox(width: 12),

            // Name + info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        fan.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.text,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TierBadge(tier: fan.tier),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '구독 ${fan.formattedDuration}${fan.totalDonation != null && fan.totalDonation! > 0 ? ' · ${fan.totalDonation} DT 후원' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            // Favorite star
            Semantics(
              label: fan.isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가',
              button: true,
              child: GestureDetector(
                onTap: onToggleFavorite,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    fan.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: fan.isFavorite ? AppColors.star : (isDark ? Colors.grey[600] : Colors.grey[400]),
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final String tier;

  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (tier.toUpperCase()) {
      case 'VIP':
        color = AppColors.vip;
        break;
      case 'STANDARD':
        color = AppColors.standard;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tier,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
