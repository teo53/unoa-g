import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/poll_message.dart';

/// Chat timeline card for a poll message.
///
/// Shows question, voteable options, and results (when applicable).
class PollMessageCard extends StatelessWidget {
  final PollMessage poll;
  final bool isDark;
  final bool isCreator;
  final Function(String optionId)? onVote;

  const PollMessageCard({
    super.key,
    required this.poll,
    required this.isDark,
    this.isCreator = false,
    this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poll icon + question
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.poll_outlined,
                size: 18,
                color: AppColors.primary500,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  poll.question,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Options
          ...poll.options.map((option) {
            final isMyVote = poll.myVoteOptionIds?.contains(option.id) ?? false;
            final showResults = poll.canShowResults;
            final percentage = poll.percentageFor(option.id);
            final voteCount = poll.voteCountFor(option.id);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _PollOptionButton(
                text: option.text,
                isMyVote: isMyVote,
                showResults: showResults,
                percentage: percentage,
                voteCount: voteCount,
                isDark: isDark,
                isEnded: poll.isEnded,
                onTap: (!poll.isEnded && onVote != null)
                    ? () => onVote!(option.id)
                    : null,
              ),
            );
          }),

          const SizedBox(height: 6),

          // Footer: total votes + status
          Row(
            children: [
              Text(
                '${poll.totalVotes}명 참여',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
              if (poll.isEnded) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '투표 마감',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PollOptionButton extends StatelessWidget {
  final String text;
  final bool isMyVote;
  final bool showResults;
  final double percentage;
  final int voteCount;
  final bool isDark;
  final bool isEnded;
  final VoidCallback? onTap;

  const _PollOptionButton({
    required this.text,
    required this.isMyVote,
    required this.showResults,
    required this.percentage,
    required this.voteCount,
    required this.isDark,
    required this.isEnded,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMyVote
              ? AppColors.primary500.withValues(alpha: 0.1)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isMyVote
                ? AppColors.primary500
                : (isDark ? Colors.grey[600]! : Colors.grey[300]!),
            width: isMyVote ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Progress bar background (only if showing results)
            if (showResults)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isMyVote
                          ? AppColors.primary500.withValues(alpha: 0.15)
                          : (isDark
                              ? Colors.grey[700]!.withValues(alpha: 0.5)
                              : Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            // Content
            Row(
              children: [
                if (isMyVote)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.primary500,
                    ),
                  ),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isMyVote ? FontWeight.w600 : FontWeight.w400,
                      color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                    ),
                  ),
                ),
                if (showResults)
                  Text(
                    '${(percentage * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
