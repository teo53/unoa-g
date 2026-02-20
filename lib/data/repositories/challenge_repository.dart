/// Challenge Repository Interface
/// 챌린지 시스템 추상 레포지토리
library;

import '../models/challenge.dart';

abstract class IChallengeRepository {
  /// 채널의 챌린지 목록 조회
  Future<List<Challenge>> getChallenges({
    required String channelId,
    ChallengeStatus? status,
    int limit = 20,
    int offset = 0,
  });

  /// 챌린지 상세 조회
  Future<Challenge> getChallenge(String challengeId);

  /// 챌린지 생성 (크리에이터)
  Future<Challenge> createChallenge({
    required String channelId,
    required String title,
    String? description,
    String? rules,
    required ChallengeType challengeType,
    required RewardType rewardType,
    int rewardAmountDt = 0,
    String? rewardDescription,
    int maxSubmissions = 0,
    int maxWinners = 1,
    required DateTime startAt,
    required DateTime endAt,
    DateTime? votingEndAt,
    String? thumbnailUrl,
  });

  /// 챌린지 상태 변경
  Future<Challenge> updateChallengeStatus(
    String challengeId,
    ChallengeStatus status,
  );

  /// 제출물 목록 조회
  Future<List<ChallengeSubmission>> getSubmissions({
    required String challengeId,
    SubmissionStatus? status,
    int limit = 50,
    int offset = 0,
  });

  /// 제출물 생성 (팬)
  Future<ChallengeSubmission> submitEntry({
    required String challengeId,
    String? content,
    String? mediaUrl,
    String? mediaType,
  });

  /// 제출물 심사 (크리에이터)
  Future<ChallengeSubmission> reviewSubmission({
    required String submissionId,
    required SubmissionStatus status,
    String? comment,
  });

  /// 투표
  Future<void> vote(String submissionId);

  /// 내 제출물 조회
  Future<ChallengeSubmission?> getMySubmission(String challengeId);

  /// 투표 여부 확인
  Future<bool> hasVoted(String submissionId);
}
