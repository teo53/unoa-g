import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/mock/mock_polls.dart';
import '../../../data/models/poll_draft.dart';

/// Dashboard section showing AI-recommended poll previews.
///
/// Displays 2 poll draft cards so the artist can quickly see and
/// tap to open the full poll suggestion sheet.
class AiPollPreviewSection extends StatelessWidget {
  final String channelId;
  final VoidCallback onOpenPollSheet;

  const AiPollPreviewSection({
    super.key,
    required this.channelId,
    required this.onOpenPollSheet,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Show first 2 poll drafts as preview
    final previews = MockPolls.sampleDrafts.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with "더보기" to open full sheet
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.poll_outlined,
                  size: 20,
                  color: AppColors.primary500,
                ),
                const SizedBox(width: 6),
                Text(
                  'AI 추천 투표',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: onOpenPollSheet,
              child: const Text(
                '전체 보기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '팬들과 대화를 시작해보세요',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
        ),
        const SizedBox(height: 12),
        // Preview cards
        ...previews.map((draft) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _PollPreviewCard(
            draft: draft,
            isDark: isDark,
            onTap: onOpenPollSheet,
          ),
        )),
      ],
    );
  }
}

class _PollPreviewCard extends StatelessWidget {
  final PollDraft draft;
  final bool isDark;
  final VoidCallback onTap;

  const _PollPreviewCard({
    required this.draft,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                draft.categoryLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Question text
            Expanded(
              child: Text(
                draft.question,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ],
        ),
      ),
    );
  }
}
