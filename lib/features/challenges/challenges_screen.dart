/// Challenges Screen
/// 챌린지 목록 화면
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/demo_config.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/challenge.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/state_widgets.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../core/utils/accessibility_helper.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  final String? channelId;

  const ChallengesScreen({super.key, this.channelId});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  String get _channelId => widget.channelId ?? DemoConfig.demoChannelId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCreator = ref.watch(isCreatorProvider);

    final challengesAsync = ref.watch(challengeListProvider(_channelId));

    return AppScaffold(
      showStatusBar: true,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
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
                    '챌린지',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          // Body
          Expanded(
            child: Stack(
              children: [
                challengesAsync.when(
                  data: (challenges) {
                    if (challenges.isEmpty) {
                      return const EmptyState(
                        title: '진행 중인 챌린지가 없어요',
                        message: '크리에이터가 새로운 챌린지를 만들면\n여기에 표시됩니다',
                        icon: Icons.emoji_events_outlined,
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(challengeListProvider(_channelId));
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: challenges.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final challenge = challenges[index];
                          return _ChallengeCard(
                            challenge: challenge,
                            isDark: isDark,
                            onTap: () =>
                                _showChallengeDetail(context, challenge),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary500,
                    ),
                  ),
                  error: (e, _) => ErrorDisplay(
                    error: e,
                    onRetry: () =>
                        ref.invalidate(challengeListProvider(_channelId)),
                  ),
                ),
                // FAB
                if (isCreator)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.extended(
                      onPressed: () => _showCreateDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('챌린지 만들기'),
                      backgroundColor: AppColors.primary600,
                      foregroundColor: AppColors.onPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChallengeDetail(BuildContext context, Challenge challenge) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChallengeDetailSheet(challenge: challenge),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    var selectedType = ChallengeType.photo;
    var rewardAmount = 500;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('새 챌린지'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '챌린지 제목',
                    hintText: '예: 팬아트 콘테스트',
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: '설명 (선택)',
                    hintText: '챌린지 규칙과 안내사항',
                  ),
                  maxLines: 3,
                  maxLength: 500,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<ChallengeType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: '챌린지 유형'),
                  items: ChallengeType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.displayName),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedType = v);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<int>(
                  value: rewardAmount,
                  decoration: const InputDecoration(labelText: 'DT 보상'),
                  items: [100, 300, 500, 1000, 3000].map((a) {
                    return DropdownMenuItem(
                      value: a,
                      child: Text('$a DT'),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => rewardAmount = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await ref
                    .read(challengeActionsProvider.notifier)
                    .createChallenge(
                      channelId: _channelId,
                      title: titleController.text.trim(),
                      description: descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                      challengeType: selectedType,
                      rewardType: RewardType.dt,
                      rewardAmountDt: rewardAmount,
                      maxWinners: 3,
                      startAt: DateTime.now(),
                      endAt: DateTime.now().add(const Duration(days: 7)),
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('챌린지가 생성되었습니다')),
                  );
                }
              },
              child: const Text('생성'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final bool isDark;
  final VoidCallback onTap;

  const _ChallengeCard({
    required this.challenge,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(challenge.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.base),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 상태 + 타입
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    challenge.status.displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceAltDark
                        : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    challenge.challengeType.displayName,
                    style: TextStyle(
                      color:
                          isDark ? AppColors.textSubDark : AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (challenge.rewardAmountDt > 0) ...[
                  Icon(
                    Icons.stars_rounded,
                    size: 16,
                    color: Colors.amber.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${challenge.rewardAmountDt} DT',
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // 제목
            Text(
              challenge.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (challenge.description != null) ...[
              const SizedBox(height: 4),
              Text(
                challenge.description!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSubDark : AppColors.textMuted,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            // 하단: 참여자 수 + 투표 수
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 16,
                  color: isDark ? AppColors.textSubDark : AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '참여 ${challenge.totalSubmissions}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSubDark : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.thumb_up_outlined,
                  size: 16,
                  color: isDark ? AppColors.textSubDark : AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '투표 ${challenge.totalVotes}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSubDark : AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                if (!challenge.isExpired && challenge.isActive)
                  Text(
                    _formatRemainingTime(challenge.remainingTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.draft:
        return AppColors.textMuted;
      case ChallengeStatus.active:
        return AppColors.success;
      case ChallengeStatus.voting:
        return AppColors.warning;
      case ChallengeStatus.completed:
        return AppColors.verified;
      case ChallengeStatus.archived:
        return AppColors.textMuted;
    }
  }

  String _formatRemainingTime(Duration remaining) {
    if (remaining.isNegative) return '종료됨';
    if (remaining.inDays > 0) return '${remaining.inDays}일 남음';
    if (remaining.inHours > 0) return '${remaining.inHours}시간 남음';
    return '${remaining.inMinutes}분 남음';
  }
}

class _ChallengeDetailSheet extends ConsumerWidget {
  final Challenge challenge;

  const _ChallengeDetailSheet({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final submissionsAsync =
        ref.watch(challengeSubmissionsProvider(challenge.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (challenge.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      challenge.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // 보상 정보
                  if (challenge.rewardAmountDt > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(20),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: Colors.amber.withAlpha(60),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.emoji_events,
                              color: Colors.amber.shade600),
                          const SizedBox(width: 8),
                          Text(
                            '보상: ${challenge.rewardAmountDt} DT',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.amber.shade700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '최대 ${challenge.maxWinners}명',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            // 제출물 목록
            Expanded(
              child: submissionsAsync.when(
                data: (submissions) {
                  if (submissions.isEmpty) {
                    return Center(
                      child: Text(
                        '아직 제출물이 없어요\n첫 번째 참여자가 되어보세요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: submissions.length,
                    itemBuilder: (context, index) {
                      final sub = submissions[index];
                      return _SubmissionTile(
                        submission: sub,
                        isDark: isDark,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorDisplay(
                  error: e,
                  onRetry: () => ref
                      .invalidate(challengeSubmissionsProvider(challenge.id)),
                  compact: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  final ChallengeSubmission submission;
  final bool isDark;

  const _SubmissionTile({
    required this.submission,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: submission.isWinner
            ? Border.all(color: Colors.amber, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // 아바타
          CircleAvatar(
            radius: 20,
            backgroundColor:
                isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
            child: Text(
              (submission.fanDisplayName ?? '?')[0],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          // 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      submission.fanDisplayName ?? '익명',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (submission.isWinner) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '우승',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (submission.content != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    submission.content!,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark ? AppColors.textSubDark : AppColors.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // 투표 수
          Column(
            children: [
              Icon(
                Icons.favorite,
                size: 20,
                color: submission.voteCount > 0
                    ? AppColors.primary500
                    : AppColors.textMuted,
              ),
              const SizedBox(height: 2),
              Text(
                '${submission.voteCount}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSubDark : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
