/// Sticker Picker Widget
/// 채팅 입력바에서 스티커를 선택하여 전송하는 피커
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/sticker.dart';
import '../../../providers/sticker_provider.dart';

class StickerPicker extends ConsumerStatefulWidget {
  final String channelId;
  final void Function(Sticker sticker) onStickerSelected;
  final VoidCallback onClose;

  const StickerPicker({
    super.key,
    required this.channelId,
    required this.onStickerSelected,
    required this.onClose,
  });

  @override
  ConsumerState<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends ConsumerState<StickerPicker> {
  int _selectedSetIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stickerSetsAsync = ref.watch(stickerSetsProvider(widget.channelId));

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : AppColors.borderLight,
          ),
        ),
      ),
      child: stickerSetsAsync.when(
        data: (sets) {
          if (sets.isEmpty) {
            return _buildEmptyState(isDark);
          }
          return Column(
            children: [
              // 헤더
              _buildHeader(isDark),
              // 스티커 팩 탭
              _buildSetTabs(sets, isDark),
              // 스티커 그리드
              Expanded(
                child: _buildStickerGrid(sets, isDark),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, __) => _buildEmptyState(isDark),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Text(
            '스티커',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textMainLight,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: '스티커 닫기',
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildSetTabs(List<StickerSet> sets, bool isDark) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        itemCount: sets.length,
        itemBuilder: (context, index) {
          final set = sets[index];
          final isSelected = _selectedSetIndex == index;

          return Semantics(
            label: '${set.name} 스티커 팩',
            button: true,
            child: GestureDetector(
              onTap: () {
                if (!set.isPurchased && !set.isFree) {
                  _showPurchaseDialog(set);
                } else {
                  setState(() => _selectedSetIndex = index);
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary500.withAlpha(25)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary500
                        : isDark
                            ? Colors.white12
                            : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (set.thumbnailUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: CachedNetworkImage(
                          imageUrl: set.thumbnailUrl!,
                          width: 20,
                          height: 20,
                        ),
                      ),
                    Text(
                      set.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary500
                            : isDark
                                ? Colors.white70
                                : AppColors.textMainLight,
                      ),
                    ),
                    if (!set.isPurchased && !set.isFree) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.lock_outlined,
                        size: 12,
                        color: isDark ? Colors.white38 : AppColors.textMuted,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStickerGrid(List<StickerSet> sets, bool isDark) {
    if (_selectedSetIndex >= sets.length) return const SizedBox.shrink();

    final selectedSet = sets[_selectedSetIndex];
    final stickers = selectedSet.stickers;

    if (!selectedSet.isPurchased && !selectedSet.isFree) {
      return _buildLockedState(selectedSet, isDark);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: stickers.length,
      itemBuilder: (context, index) {
        final sticker = stickers[index];
        return Semantics(
          label: '${sticker.name} 스티커 전송',
          button: true,
          child: GestureDetector(
            onTap: () => widget.onStickerSelected(sticker),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.base),
              ),
              padding: const EdgeInsets.all(8),
              child: CachedNetworkImage(
                imageUrl: sticker.imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const SizedBox.shrink(),
                errorWidget: (_, __, ___) => Icon(
                  Icons.emoji_emotions_outlined,
                  color: isDark ? Colors.white24 : AppColors.border,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLockedState(StickerSet set, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outlined,
            size: 32,
            color: isDark ? Colors.white38 : AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${set.priceDt} DT로 구매',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => _showPurchaseDialog(set),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('구매하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_emotions_outlined,
            size: 40,
            color: isDark ? Colors.white24 : AppColors.border,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '스티커가 없습니다',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(StickerSet set) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(set.name),
        content: Text(
          '${set.priceDt} DT로 스티커 팩을 구매하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(stickerActionsProvider.notifier)
                  .purchaseStickerSet(set.id);
              if (success && mounted) {
                ref.invalidate(stickerSetsProvider(widget.channelId));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              foregroundColor: Colors.white,
            ),
            child: Text('${set.priceDt} DT 구매'),
          ),
        ],
      ),
    );
  }
}
