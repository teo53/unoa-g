import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/fan_tag.dart';
import '../../../providers/fan_crm_provider.dart';
import 'create_tag_dialog.dart';

/// 팬 태그 칩 위젯
/// 할당된 태그 표시 + 태그 추가/제거
class FanTagChips extends ConsumerWidget {
  final String fanId;

  const FanTagChips({super.key, required this.fanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fanTagsAsync = ref.watch(fanTagsProvider(fanId));

    return fanTagsAsync.when(
      loading: () => const SizedBox(
        height: 32,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => Text(
        '태그 로드 실패',
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
        ),
      ),
      data: (tags) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          // 할당된 태그들
          ...tags.map((tag) => _buildTagChip(context, ref, tag, isDark)),
          // "+" 추가 버튼
          _buildAddButton(context, ref, tags, isDark),
        ],
      ),
    );
  }

  Widget _buildTagChip(
    BuildContext context,
    WidgetRef ref,
    FanTag tag,
    bool isDark,
  ) {
    final color = _parseColor(tag.tagColor);

    return Chip(
      label: Text(
        tag.tagName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      deleteIcon: Icon(Icons.close, size: 14, color: color),
      onDeleted: () => removeTagFromFan(ref, fanId, tag.id),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildAddButton(
    BuildContext context,
    WidgetRef ref,
    List<FanTag> assignedTags,
    bool isDark,
  ) {
    return ActionChip(
      avatar: Icon(
        Icons.add,
        size: 16,
        color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
      ),
      label: Text(
        '태그 추가',
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
        ),
      ),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      side: BorderSide(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        style: BorderStyle.solid,
      ),
      onPressed: () => _showTagSelector(context, ref, assignedTags, isDark),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  void _showTagSelector(
    BuildContext context,
    WidgetRef ref,
    List<FanTag> assignedTags,
    bool isDark,
  ) {
    final allTagsAsync = ref.read(creatorTagsProvider);

    allTagsAsync.when(
      data: (allTags) {
        final assignedIds = assignedTags.map((t) => t.id).toSet();
        final unassigned =
            allTags.where((t) => !assignedIds.contains(t.id)).toList();

        showModalBottomSheet(
          context: context,
          backgroundColor:
              isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) => _TagSelectorSheet(
            unassignedTags: unassigned,
            fanId: fanId,
            isDark: isDark,
          ),
        );
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  Color _parseColor(String hex) {
    try {
      final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
      return Color(value | 0xFF000000);
    } catch (_) {
      return Colors.grey;
    }
  }
}

/// 태그 선택 바텀시트 (기존 태그 선택 + 신규 생성)
class _TagSelectorSheet extends ConsumerWidget {
  final List<FanTag> unassignedTags;
  final String fanId;
  final bool isDark;

  const _TagSelectorSheet({
    required this.unassignedTags,
    required this.fanId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '태그 추가',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),

          if (unassignedTags.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '사용 가능한 태그가 없습니다',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: unassignedTags.map((tag) {
                final color = _parseColor(tag.tagColor);
                return ActionChip(
                  label: Text(
                    tag.tagName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  backgroundColor: color.withValues(alpha: 0.12),
                  side: BorderSide(color: color.withValues(alpha: 0.3)),
                  onPressed: () {
                    assignTagToFan(ref, fanId, tag.id);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),

          const SizedBox(height: 16),

          // 신규 태그 생성 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                final result = await CreateTagDialog.show(context);
                if (result != null && context.mounted) {
                  final tag = await createTag(
                    ref,
                    result['name']!,
                    result['color']!,
                  );
                  if (tag != null) {
                    await assignTagToFan(ref, fanId, tag.id);
                  }
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('새 태그 만들기'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
      return Color(value | 0xFF000000);
    } catch (_) {
      return Colors.grey;
    }
  }
}
