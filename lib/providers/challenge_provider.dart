/// Challenge Provider
/// 챌린지 시스템 상태 관리 (Riverpod)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/challenge.dart';
import '../data/repositories/challenge_repository.dart';
import '../data/repositories/supabase_challenge_repository.dart';
import '../data/repositories/mock_challenge_repository.dart';
import 'auth_provider.dart';
import 'repository_providers.dart';

// ============================================
// Repository DI
// ============================================

final challengeRepositoryProvider = Provider<IChallengeRepository>((ref) {
  final authState = ref.watch(authProvider);
  final isDemoMode = authState is AuthDemoMode;
  if (isDemoMode || FeatureFlags.useMockRepositories) {
    return MockChallengeRepository();
  }
  return SupabaseChallengeRepository();
});

// ============================================
// Challenge List Provider
// ============================================

/// 채널별 챌린지 목록
final challengeListProvider = FutureProvider.autoDispose
    .family<List<Challenge>, String>((ref, channelId) async {
  final repo = ref.watch(challengeRepositoryProvider);
  return repo.getChallenges(channelId: channelId);
});

/// 활성 챌린지만 (팬 뷰용)
final activeChallengesProvider = FutureProvider.autoDispose
    .family<List<Challenge>, String>((ref, channelId) async {
  final repo = ref.watch(challengeRepositoryProvider);
  final all = await repo.getChallenges(channelId: channelId);
  return all
      .where((c) =>
          c.status == ChallengeStatus.active ||
          c.status == ChallengeStatus.voting)
      .toList();
});

/// 챌린지 상세
final challengeDetailProvider = FutureProvider.autoDispose
    .family<Challenge, String>((ref, challengeId) async {
  final repo = ref.watch(challengeRepositoryProvider);
  return repo.getChallenge(challengeId);
});

// ============================================
// Submission Providers
// ============================================

/// 챌린지별 제출물 목록
final challengeSubmissionsProvider = FutureProvider.autoDispose
    .family<List<ChallengeSubmission>, String>((ref, challengeId) async {
  final repo = ref.watch(challengeRepositoryProvider);
  return repo.getSubmissions(challengeId: challengeId);
});

/// 내 제출물
final mySubmissionProvider = FutureProvider.autoDispose
    .family<ChallengeSubmission?, String>((ref, challengeId) async {
  final repo = ref.watch(challengeRepositoryProvider);
  return repo.getMySubmission(challengeId);
});

// ============================================
// Challenge Actions Notifier
// ============================================

class ChallengeActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final IChallengeRepository _repo;
  final Ref _ref;

  ChallengeActionsNotifier(this._repo, this._ref)
      : super(const AsyncData(null));

  /// 챌린지 생성
  Future<Challenge?> createChallenge({
    required String channelId,
    required String title,
    String? description,
    String? rules,
    ChallengeType challengeType = ChallengeType.photo,
    RewardType rewardType = RewardType.dt,
    int rewardAmountDt = 0,
    String? rewardDescription,
    int maxWinners = 1,
    required DateTime startAt,
    required DateTime endAt,
    DateTime? votingEndAt,
  }) async {
    state = const AsyncLoading();
    try {
      final challenge = await _repo.createChallenge(
        channelId: channelId,
        title: title,
        description: description,
        rules: rules,
        challengeType: challengeType,
        rewardType: rewardType,
        rewardAmountDt: rewardAmountDt,
        rewardDescription: rewardDescription,
        maxWinners: maxWinners,
        startAt: startAt,
        endAt: endAt,
        votingEndAt: votingEndAt,
      );
      state = const AsyncData(null);
      _ref.invalidate(challengeListProvider);
      return challenge;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// 챌린지 상태 변경
  Future<void> updateStatus(
    String challengeId,
    ChallengeStatus status,
  ) async {
    state = const AsyncLoading();
    try {
      await _repo.updateChallengeStatus(challengeId, status);
      state = const AsyncData(null);
      _ref.invalidate(challengeListProvider);
      _ref.invalidate(challengeDetailProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 제출물 제출
  Future<ChallengeSubmission?> submit({
    required String challengeId,
    String? content,
    String? mediaUrl,
    String? mediaType,
  }) async {
    state = const AsyncLoading();
    try {
      final submission = await _repo.submitEntry(
        challengeId: challengeId,
        content: content,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
      );
      state = const AsyncData(null);
      _ref.invalidate(challengeSubmissionsProvider);
      _ref.invalidate(mySubmissionProvider);
      _ref.invalidate(challengeDetailProvider);
      return submission;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// 제출물 심사
  Future<void> reviewSubmission({
    required String submissionId,
    required SubmissionStatus status,
    String? comment,
  }) async {
    try {
      await _repo.reviewSubmission(
        submissionId: submissionId,
        status: status,
        comment: comment,
      );
      _ref.invalidate(challengeSubmissionsProvider);
    } catch (_) {
      // 에러 무시
    }
  }

  /// 투표
  Future<void> vote(String submissionId) async {
    try {
      await _repo.vote(submissionId);
      _ref.invalidate(challengeSubmissionsProvider);
    } catch (_) {
      // 이미 투표한 경우
    }
  }
}

final challengeActionsProvider =
    StateNotifierProvider<ChallengeActionsNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(challengeRepositoryProvider);
  return ChallengeActionsNotifier(repo, ref);
});
