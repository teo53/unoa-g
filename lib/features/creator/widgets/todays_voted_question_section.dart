import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/daily_question_set.dart';
import '../../../providers/daily_question_set_provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';

/// Section showing today's voted questions for creator dashboard
class TodaysVotedQuestionSection extends ConsumerStatefulWidget {
  final String channelId;
  final Function(QuestionCardStat card, String setId)? onAnswerCard;

  const TodaysVotedQuestionSection({
    super.key,
    required this.channelId,
    this.onAnswerCard,
  });

  @override
  ConsumerState<TodaysVotedQuestionSection> createState() =>
      _TodaysVotedQuestionSectionState();
}

class _TodaysVotedQuestionSectionState
    extends ConsumerState<TodaysVotedQuestionSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(todaysQuestionStatsProvider(widget.channelId).notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todaysQuestionStatsProvider(widget.channelId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: switch (state) {
        TodaysQuestionStatsInitial() ||
        TodaysQuestionStatsLoading() =>
          _buildLoading(),
        TodaysQuestionStatsError(message: final msg) => _buildError(msg),
        TodaysQuestionStatsLoaded(stats: final stats) =>
          _buildContent(stats, isDark),
      },
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: 150, height: 24),
          const SizedBox(height: 12),
          const SkeletonLoader(width: double.infinity, height: 80),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(height: 8),
          Text(
            '질문 통계를 불러올 수 없습니다',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textSubDark
                  : AppColors.textSubLight,
            ),
          ),
          TextButton(
            onPressed: () => ref
                .read(todaysQuestionStatsProvider(widget.channelId).notifier)
                .load(),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(TodaysQuestionStats stats, bool isDark) {
    if (!stats.hasSet) {
      return _buildNoSet(isDark);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.question_answer_outlined,
                size: 22,
                color: AppColors.primary500,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘의 질문',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                    Text(
                      '팬들이 고른 질문에 답해보세요',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                    ),
                  ],
                ),
              ),
              _StatBadge(
                icon: Icons.people_outline,
                value: '${stats.totalVotes}',
                label: '참여',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Question cards (sorted by votes)
          ...stats.cards.asMap().entries.map((entry) {
            final index = entry.key;
            final card = entry.value;
            final isFirst = index == 0 && stats.totalVotes > 0;

            return Padding(
              padding: EdgeInsets.only(bottom: index < stats.cards.length - 1 ? 12 : 0),
              child: _QuestionStatCard(
                card: card,
                rank: index + 1,
                totalVotes: stats.totalVotes,
                isWinner: isFirst,
                isDark: isDark,
                onAnswer: widget.onAnswerCard != null && !card.isAnswered
                    ? () => widget.onAnswerCard!(card, stats.setId!)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNoSet(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 48,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
          const SizedBox(height: 12),
          Text(
            '오늘의 질문이 아직 없어요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '팬이 채팅에 접속하면 질문이 생성됩니다',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionStatCard extends StatelessWidget {
  final QuestionCardStat card;
  final int rank;
  final int totalVotes;
  final bool isWinner;
  final bool isDark;
  final VoidCallback? onAnswer;

  const _QuestionStatCard({
    required this.card,
    required this.rank,
    required this.totalVotes,
    required this.isWinner,
    required this.isDark,
    this.onAnswer,
  });

  double get votePercentage {
    if (totalVotes == 0) return 0;
    return (card.voteCount / totalVotes) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = card.isAnswered
        ? AppColors.success
        : isWinner
            ? AppColors.star
            : (isDark ? AppColors.borderDark : AppColors.border);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: card.isAnswered
            ? AppColors.success.withValues(alpha: 0.05)
            : isWinner
                ? AppColors.star.withValues(alpha: 0.05)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: card.isAnswered || isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: rank, level, status
          Row(
            children: [
              // Rank badge
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isWinner
                      ? AppColors.star
                      : (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isWinner
                          ? Colors.white
                          : (isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getLevelColor(card.level).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Lv.${card.level}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getLevelColor(card.level),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              Text(
                _getSubdeckName(card.subdeck),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),

              const Spacer(),

              // Status / Action
              if (card.isAnswered)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check,
                        size: 12,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '답변 완료',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                )
              else if (onAnswer != null)
                TextButton.icon(
                  onPressed: onAnswer,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('답변하기'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary600,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Question text
          Text(
            card.cardText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 10),

          // Vote bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: (isWinner ? AppColors.star : AppColors.primary500)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (votePercentage / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isWinner ? AppColors.star : AppColors.primary500,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${card.voteCount}표 (${votePercentage.toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isWinner
                      ? AppColors.star
                      : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.primary500;
      default:
        return AppColors.textMuted;
    }
  }

  String _getSubdeckName(String subdeck) {
    switch (subdeck) {
      case 'icebreaker':
        return '아이스브레이커';
      case 'daily_scene':
        return '일상';
      case 'behind_story':
        return '비하인드';
      case 'roleplay_flavor':
        return '롤플레이';
      case 'deep_but_safe':
        return '깊은 대화';
      default:
        return subdeck;
    }
  }
}
