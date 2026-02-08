import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/daily_question_set.dart';
import '../../../data/models/question_card.dart';
import '../../../providers/daily_question_set_provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';

/// Panel showing today's 3 question cards for fans to vote
class DailyQuestionCardsPanel extends ConsumerStatefulWidget {
  final String channelId;
  final Function(QuestionCard card)? onCardSelected;
  final bool compact;
  final Color? accentColor;

  const DailyQuestionCardsPanel({
    super.key,
    required this.channelId,
    this.onCardSelected,
    this.compact = false,
    this.accentColor,
  });

  @override
  ConsumerState<DailyQuestionCardsPanel> createState() =>
      _DailyQuestionCardsPanelState();
}

class _DailyQuestionCardsPanelState
    extends ConsumerState<DailyQuestionCardsPanel> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    // compact 모드일 때는 기본 접힌 상태
    _isExpanded = !widget.compact;
    // Load question set on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dailyQuestionSetProvider(widget.channelId).notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyQuestionSetProvider(widget.channelId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return switch (state) {
      DailyQuestionSetInitial() || DailyQuestionSetLoading() => _buildLoading(),
      DailyQuestionSetError(message: final msg) => _buildError(msg),
      DailyQuestionSetLoaded(set: final set) => _buildContent(set, isDark),
      DailyQuestionSetVoting(set: final set, votingCardId: final cardId) =>
        _buildContent(set, isDark, votingCardId: cardId),
    };
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: 120, height: 20),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SkeletonLoader.card(width: 200, height: 120),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 32),
          const SizedBox(height: 8),
          Text(
            '질문 카드를 불러올 수 없습니다',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textSubDark
                  : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref
                .read(dailyQuestionSetProvider(widget.channelId).notifier)
                .load(),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(DailyQuestionSet set, bool isDark, {String? votingCardId}) {
    final title = set.hasVoted ? '투표 결과' : '오늘의 질문';
    final subtitle = set.hasVoted
        ? '${set.totalVotes}명 참여'
        : '${set.totalVotes}명 참여';

    return Column(
      children: [
        // Collapsible header
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              color: isDark
                  ? (widget.accentColor ?? AppColors.primary500).withValues(alpha: 0.06)
                  : (widget.accentColor ?? AppColors.primary500).withValues(alpha: 0.04),
            ),
            child: Row(
              children: [
                Icon(
                  set.hasVoted ? Icons.how_to_vote_outlined : Icons.quiz_outlined,
                  size: 18,
                  color: set.hasVoted ? AppColors.star : (widget.accentColor ?? AppColors.primary500),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
                const Spacer(),
                if (set.hasVoted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '완료',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                Text(
                  _isExpanded ? '접기' : '펼치기',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable content
        AnimatedCrossFade(
          firstChild: _buildInnerContent(set, isDark, votingCardId: votingCardId),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
          sizeCurve: Curves.easeInOut,
        ),

        // Divider
        Divider(
          height: 1,
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ],
    );
  }

  Widget _buildInnerContent(DailyQuestionSet set, bool isDark, {String? votingCardId}) {
    if (set.hasVoted) {
      return _VotedResultView(
        set: set,
        isDark: isDark,
        compact: widget.compact,
        accentColor: widget.accentColor,
      );
    }

    return _VotingCardsView(
      set: set,
      isDark: isDark,
      compact: widget.compact,
      votingCardId: votingCardId,
      accentColor: widget.accentColor,
      onVote: (cardId) async {
        final success = await ref
            .read(dailyQuestionSetProvider(widget.channelId).notifier)
            .vote(cardId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('투표했어요!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      onCardSelected: widget.onCardSelected,
    );
  }
}

/// View for voting on cards (before voting)
class _VotingCardsView extends StatelessWidget {
  final DailyQuestionSet set;
  final bool isDark;
  final bool compact;
  final String? votingCardId;
  final Color? accentColor;
  final Function(String cardId) onVote;
  final Function(QuestionCard card)? onCardSelected;

  const _VotingCardsView({
    required this.set,
    required this.isDark,
    required this.compact,
    this.votingCardId,
    this.accentColor,
    required this.onVote,
    this.onCardSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '마음에 드는 질문에 투표해 주세요',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 10),

          // Cards
          SizedBox(
            height: compact ? 110 : 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: set.cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final card = set.cards[index];
                final isVoting = votingCardId == card.id;

                return _QuestionCardTile(
                  card: card,
                  isDark: isDark,
                  compact: compact,
                  isVoting: isVoting,
                  accentColor: accentColor,
                  onTap: () => _showVoteConfirmation(context, card),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showVoteConfirmation(BuildContext context, QuestionCard card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _VoteConfirmationSheet(
        card: card,
        isDark: Theme.of(context).brightness == Brightness.dark,
        accentColor: accentColor,
        onConfirm: () {
          Navigator.pop(context);
          onVote(card.id);
        },
      ),
    );
  }
}

/// Single question card tile
class _QuestionCardTile extends StatelessWidget {
  final QuestionCard card;
  final bool isDark;
  final bool compact;
  final bool isVoting;
  final bool showResult;
  final double? votePercentage;
  final bool isWinner;
  final bool isVoted;
  final Color? accentColor;
  final VoidCallback? onTap;

  const _QuestionCardTile({
    required this.card,
    required this.isDark,
    this.compact = false,
    this.isVoting = false,
    this.showResult = false,
    this.votePercentage,
    this.isWinner = false,
    this.isVoted = false,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = compact ? 160.0 : 200.0;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isVoted
        ? (accentColor ?? AppColors.primary500)
        : isWinner
            ? AppColors.star
            : (isDark ? AppColors.borderDark : AppColors.border);

    return GestureDetector(
      onTap: isVoting ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isVoted
              ? (accentColor ?? AppColors.primary500).withValues(alpha: 0.1)
              : isWinner
                  ? AppColors.star.withValues(alpha: 0.1)
                  : bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isVoted || isWinner ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Level badge
                Row(
                  children: [
                    _LevelBadge(level: card.level, accentColor: accentColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        card.subdeckDisplayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Question text
                Flexible(
                  child: Text(
                    card.cardText,
                    style: TextStyle(
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                      height: 1.4,
                    ),
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Result bar (if showing results)
                if (showResult && votePercentage != null) ...[
                  const SizedBox(height: 6),
                  _VoteProgressBar(
                    percentage: votePercentage!,
                    isWinner: isWinner,
                    isVoted: isVoted,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${card.voteCount}표 (${votePercentage!.toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isVoted
                          ? (accentColor ?? AppColors.primary500)
                          : isWinner
                              ? AppColors.star
                              : (isDark
                                  ? AppColors.textSubDark
                                  : AppColors.textSubLight),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),

            // Voting indicator
            if (isVoting)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

            // Voted check
            if (isVoted && showResult)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: (accentColor ?? AppColors.primary500),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Level badge
class _LevelBadge extends StatelessWidget {
  final int level;
  final Color? accentColor;

  const _LevelBadge({required this.level, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      1 => AppColors.success,
      2 => AppColors.warning,
      3 => (accentColor ?? AppColors.primary500),
      _ => AppColors.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Lv.$level',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Vote confirmation bottom sheet
class _VoteConfirmationSheet extends StatelessWidget {
  final QuestionCard card;
  final bool isDark;
  final Color? accentColor;
  final VoidCallback onConfirm;

  const _VoteConfirmationSheet({
    required this.card,
    required this.isDark,
    this.accentColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 40,
                  color: (accentColor ?? AppColors.primary500),
                ),
                const SizedBox(height: 12),
                Text(
                  '이 질문에 투표할까요?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 16),

                // Question preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceAltDark
                        : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _LevelBadge(level: card.level, accentColor: accentColor),
                          const SizedBox(width: 8),
                          Text(
                            card.subdeckDisplayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSubDark
                                  : AppColors.textSubLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        card.cardText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  '투표 후에는 변경할 수 없어요',
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

          const SizedBox(height: 20),

          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('투표하기'),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }
}

/// View for showing results (after voting)
class _VotedResultView extends StatelessWidget {
  final DailyQuestionSet set;
  final bool isDark;
  final bool compact;
  final Color? accentColor;

  const _VotedResultView({
    required this.set,
    required this.isDark,
    this.compact = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final winningCard = set.winningCard;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cards with results
          SizedBox(
            height: compact ? 120 : 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: set.cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final card = set.cards[index];
                final isVoted = set.userVote == card.id;
                final isWinner = winningCard?.id == card.id;

                return _QuestionCardTile(
                  card: card,
                  isDark: isDark,
                  compact: compact,
                  showResult: true,
                  votePercentage: set.getVotePercentage(card.id),
                  isWinner: isWinner,
                  accentColor: accentColor,
                  isVoted: isVoted,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Vote progress bar
class _VoteProgressBar extends StatelessWidget {
  final double percentage;
  final bool isWinner;
  final bool isVoted;
  final Color? accentColor;

  const _VoteProgressBar({
    required this.percentage,
    this.isWinner = false,
    this.isVoted = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isVoted
        ? (accentColor ?? AppColors.primary500)
        : isWinner
            ? AppColors.star
            : AppColors.textMuted;

    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (percentage / 100).clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
