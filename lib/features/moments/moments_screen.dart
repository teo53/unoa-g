/// Moments Screen
/// 팬의 특별 순간 모음 (갤러리 그리드 형태)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/fan_moment.dart';
import '../../providers/moments_provider.dart';
import '../../shared/widgets/state_widgets.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../core/utils/accessibility_helper.dart';

class MomentsScreen extends ConsumerStatefulWidget {
  const MomentsScreen({super.key});

  @override
  ConsumerState<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends ConsumerState<MomentsScreen> {
  MomentSourceType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final momentsAsync = ref.watch(momentsListProvider);

    return AppScaffold(
      showStatusBar: true,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                AccessibleTapTarget(
                  semanticLabel: '뒤로가기',
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const Expanded(
                  child: Text(
                    '모먼트',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Favorite toggle
                AccessibleTapTarget(
                  semanticLabel: '즐겨찾기만 보기',
                  onTap: () {
                    final current = ref.read(momentsFilterProvider);
                    ref.read(momentsFilterProvider.notifier).state =
                        current.copyWith(
                      favoritesOnly: !current.favoritesOnly,
                    );
                  },
                  child: Icon(
                    ref.watch(momentsFilterProvider).favoritesOnly
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: ref.watch(momentsFilterProvider).favoritesOnly
                        ? AppColors.primary500
                        : isDark
                            ? AppColors.textSubDark
                            : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Filter chips
          _buildFilterChips(isDark),
          // Moment grid
          Expanded(
            child: momentsAsync.when(
              data: (moments) {
                if (moments.isEmpty) {
                  return const EmptyState(
                    icon: Icons.auto_awesome_outlined,
                    title: '아직 모먼트가 없어요',
                    message: '아티스트와의 특별한 순간이\n자동으로 수집됩니다',
                  );
                }
                return _buildMomentGrid(moments, isDark);
              },
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary500,
                ),
              ),
              error: (error, _) => ErrorDisplay(
                error: error,
                onRetry: () => ref.invalidate(momentsListProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final filters = [
      (null, '전체'),
      (MomentSourceType.privateCard, '프라이빗 카드'),
      (MomentSourceType.highlight, '하이라이트'),
      (MomentSourceType.mediaMessage, '미디어'),
      (MomentSourceType.donationReply, '후원'),
      (MomentSourceType.manual, '저장'),
    ];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final (type, label) = filters[index];
          final isSelected = _selectedFilter == type;

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : isDark
                          ? AppColors.textSubDark
                          : AppColors.text,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary500,
              backgroundColor:
                  isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
              side: BorderSide.none,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = selected ? type : null;
                });
                ref.read(momentsFilterProvider.notifier).state =
                    ref.read(momentsFilterProvider).copyWith(
                          sourceType: selected ? type : null,
                        );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMomentGrid(List<FanMoment> moments, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.8,
      ),
      itemCount: moments.length,
      itemBuilder: (context, index) {
        return _MomentCard(
          moment: moments[index],
          isDark: isDark,
          onTap: () => _showMomentDetail(moments[index]),
          onFavoriteToggle: () {
            ref
                .read(momentActionsProvider.notifier)
                .toggleFavorite(moments[index].id);
          },
        );
      },
    );
  }

  void _showMomentDetail(FanMoment moment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MomentDetailSheet(
        moment: moment,
        isDark: isDark,
        onDelete: () {
          Navigator.pop(context);
          ref.read(momentActionsProvider.notifier).deleteMoment(moment.id);
        },
        onFavoriteToggle: () {
          ref.read(momentActionsProvider.notifier).toggleFavorite(moment.id);
        },
      ),
    );
  }
}

// ============================================
// Moment Card Widget
// ============================================

class _MomentCard extends StatelessWidget {
  final FanMoment moment;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const _MomentCard({
    required this.moment,
    required this.isDark,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '모먼트: ${moment.content ?? moment.sourceLabel}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.base),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 미디어 영역 또는 콘텐츠 미리보기
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (moment.hasMedia)
                      CachedNetworkImage(
                        imageUrl: moment.thumbnailUrl ?? moment.mediaUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: isDark
                              ? AppColors.surfaceAltDark
                              : AppColors.surfaceAlt,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => _buildContentPreview(),
                      )
                    else
                      _buildContentPreview(),

                    // 소스 타입 배지
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _sourceIcon,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              moment.sourceLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 즐겨찾기
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onFavoriteToggle,
                        child: Icon(
                          moment.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 20,
                          color: moment.isFavorite
                              ? AppColors.primary500
                              : Colors.white70,
                          shadows: const [
                            Shadow(blurRadius: 4, color: Colors.black38),
                          ],
                        ),
                      ),
                    ),

                    // 비디오 오버레이
                    if (moment.isVideo)
                      const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          size: 40,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),

              // 하단 정보
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (moment.content != null && moment.content!.isNotEmpty)
                      Text(
                        moment.content!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark ? AppColors.textSubDark : AppColors.text,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (moment.artistAvatarUrl != null) ...[
                          CircleAvatar(
                            radius: 8,
                            backgroundImage: CachedNetworkImageProvider(
                              moment.artistAvatarUrl!,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            moment.artistName ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(moment.collectedAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
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
      ),
    );
  }

  Widget _buildContentPreview() {
    return Container(
      color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: Text(
          moment.content ?? '',
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark ? AppColors.textSubDark : AppColors.text,
          ),
        ),
      ),
    );
  }

  IconData get _sourceIcon {
    switch (moment.sourceType) {
      case MomentSourceType.privateCard:
        return Icons.mail_outline;
      case MomentSourceType.highlight:
        return Icons.auto_awesome;
      case MomentSourceType.mediaMessage:
        return Icons.photo_outlined;
      case MomentSourceType.donationReply:
        return Icons.favorite_outline;
      case MomentSourceType.welcome:
        return Icons.celebration_outlined;
      case MomentSourceType.manual:
        return Icons.bookmark_outline;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return '오늘';
    if (diff.inDays == 1) return '어제';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}주 전';
    return '${date.month}/${date.day}';
  }
}

// ============================================
// Moment Detail Sheet
// ============================================

class _MomentDetailSheet extends StatelessWidget {
  final FanMoment moment;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onFavoriteToggle;

  const _MomentDetailSheet({
    required this.moment,
    required this.isDark,
    required this.onDelete,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // 드래그 핸들
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 헤더
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    // 소스 타입 뱃지
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary500.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        moment.sourceLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        moment.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: moment.isFavorite ? AppColors.primary500 : null,
                      ),
                      onPressed: onFavoriteToggle,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('모먼트 삭제'),
                            content: const Text('이 모먼트를 삭제하시겠습니까?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  onDelete();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                ),
                                child: const Text('삭제'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 본문
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 미디어
                      if (moment.hasMedia) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppRadius.base,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: moment.mediaUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              height: 200,
                              color: isDark
                                  ? AppColors.surfaceAltDark
                                  : AppColors.surfaceAlt,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // 콘텐츠
                      if (moment.content != null &&
                          moment.content!.isNotEmpty) ...[
                        Text(
                          moment.content!,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.text,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // 아티스트 정보
                      Row(
                        children: [
                          if (moment.artistAvatarUrl != null) ...[
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: CachedNetworkImageProvider(
                                moment.artistAvatarUrl!,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                moment.artistName ?? '아티스트',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textMainDark
                                      : AppColors.text,
                                ),
                              ),
                              Text(
                                _formatFullDate(moment.collectedAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
