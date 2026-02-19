/// Mock Challenge Repository
/// 데모 모드용 챌린지 레포지토리
library;

import '../../core/config/demo_config.dart';
import '../models/challenge.dart';
import 'challenge_repository.dart';

class MockChallengeRepository implements IChallengeRepository {
  final List<Challenge> _challenges = [
    Challenge(
      id: 'challenge_1',
      channelId: DemoConfig.demoChannelId,
      creatorId: DemoConfig.demoCreatorId,
      title: '내 최애곡 인증 챌린지',
      description: '가장 좋아하는 곡을 들으며 인증샷을 찍어주세요!',
      rules: '1. 음악 앱 화면 포함 캡처\n2. 본인 얼굴 불필요\n3. 한 장만 제출',
      challengeType: ChallengeType.photo,
      status: ChallengeStatus.active,
      rewardType: RewardType.dt,
      rewardAmountDt: 500,
      maxWinners: 3,
      startAt: DateTime.now().subtract(const Duration(days: 2)),
      endAt: DateTime.now().add(const Duration(days: 5)),
      thumbnailUrl: DemoConfig.avatarUrl('challenge1'),
      totalSubmissions: 15,
      totalVotes: 42,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Challenge(
      id: 'challenge_2',
      channelId: DemoConfig.demoChannelId,
      creatorId: DemoConfig.demoCreatorId,
      title: '응원 메시지 챌린지',
      description: '컴백을 위한 응원 메시지를 남겨주세요!',
      challengeType: ChallengeType.text,
      status: ChallengeStatus.voting,
      rewardType: RewardType.shoutout,
      rewardDescription: '다음 라이브에서 닉네임 불러드림',
      maxWinners: 5,
      startAt: DateTime.now().subtract(const Duration(days: 7)),
      endAt: DateTime.now().subtract(const Duration(days: 1)),
      votingEndAt: DateTime.now().add(const Duration(days: 2)),
      totalSubmissions: 28,
      totalVotes: 156,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
    Challenge(
      id: 'challenge_3',
      channelId: DemoConfig.demoChannelId,
      creatorId: DemoConfig.demoCreatorId,
      title: '팬아트 콘테스트',
      description: '자유롭게 그린 팬아트를 공유해주세요',
      challengeType: ChallengeType.photo,
      status: ChallengeStatus.completed,
      rewardType: RewardType.dt,
      rewardAmountDt: 1000,
      maxWinners: 1,
      startAt: DateTime.now().subtract(const Duration(days: 14)),
      endAt: DateTime.now().subtract(const Duration(days: 7)),
      totalSubmissions: 35,
      totalVotes: 210,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

  final List<ChallengeSubmission> _submissions = [
    ChallengeSubmission(
      id: 'sub_1',
      challengeId: 'challenge_1',
      fanId: 'fan_1',
      content: '이 노래 들으면서 새벽 산책했어요!',
      mediaUrl: DemoConfig.avatarUrl('sub1'),
      mediaType: 'image',
      status: SubmissionStatus.approved,
      voteCount: 12,
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
      fanDisplayName: '하늘덕후',
      fanAvatarUrl: DemoConfig.avatarUrl('fan1'),
    ),
    ChallengeSubmission(
      id: 'sub_2',
      challengeId: 'challenge_1',
      fanId: 'fan_2',
      content: '카페에서 듣고 있어요~',
      mediaUrl: DemoConfig.avatarUrl('sub2'),
      mediaType: 'image',
      status: SubmissionStatus.approved,
      voteCount: 8,
      submittedAt: DateTime.now().subtract(const Duration(hours: 18)),
      fanDisplayName: '별빛팬',
      fanAvatarUrl: DemoConfig.avatarUrl('fan2'),
    ),
    ChallengeSubmission(
      id: 'sub_3',
      challengeId: 'challenge_1',
      fanId: 'fan_3',
      content: '출근길에 매일 듣는 노래!',
      mediaUrl: DemoConfig.avatarUrl('sub3'),
      mediaType: 'image',
      status: SubmissionStatus.pending,
      voteCount: 0,
      submittedAt: DateTime.now().subtract(const Duration(hours: 3)),
      fanDisplayName: '달빛소녀',
      fanAvatarUrl: DemoConfig.avatarUrl('fan3'),
    ),
  ];

  final Set<String> _myVotes = {};

  @override
  Future<List<Challenge>> getChallenges({
    required String channelId,
    ChallengeStatus? status,
    int limit = 20,
    int offset = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var result = _challenges.where((c) => c.channelId == channelId);
    if (status != null) {
      result = result.where((c) => c.status == status);
    }
    return result.skip(offset).take(limit).toList();
  }

  @override
  Future<Challenge> getChallenge(String challengeId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _challenges.firstWhere((c) => c.id == challengeId);
  }

  @override
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
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final challenge = Challenge(
      id: 'challenge_${DateTime.now().millisecondsSinceEpoch}',
      channelId: channelId,
      creatorId: DemoConfig.demoCreatorId,
      title: title,
      description: description,
      rules: rules,
      challengeType: challengeType,
      status: ChallengeStatus.draft,
      rewardType: rewardType,
      rewardAmountDt: rewardAmountDt,
      rewardDescription: rewardDescription,
      maxSubmissions: maxSubmissions,
      maxWinners: maxWinners,
      startAt: startAt,
      endAt: endAt,
      votingEndAt: votingEndAt,
      thumbnailUrl: thumbnailUrl,
      createdAt: DateTime.now(),
    );
    _challenges.insert(0, challenge);
    return challenge;
  }

  @override
  Future<Challenge> updateChallengeStatus(
    String challengeId,
    ChallengeStatus status,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _challenges.indexWhere((c) => c.id == challengeId);
    if (idx == -1) throw StateError('Challenge not found');
    final updated = _challenges[idx].copyWith(status: status);
    _challenges[idx] = updated;
    return updated;
  }

  @override
  Future<List<ChallengeSubmission>> getSubmissions({
    required String challengeId,
    SubmissionStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var result = _submissions.where((s) => s.challengeId == challengeId);
    if (status != null) {
      result = result.where((s) => s.status == status);
    }
    return result.skip(offset).take(limit).toList();
  }

  @override
  Future<ChallengeSubmission> submitEntry({
    required String challengeId,
    String? content,
    String? mediaUrl,
    String? mediaType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final submission = ChallengeSubmission(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      challengeId: challengeId,
      fanId: DemoConfig.demoFanId,
      content: content,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      submittedAt: DateTime.now(),
      fanDisplayName: DemoConfig.demoFanName,
    );
    _submissions.add(submission);
    // Update challenge submission count
    final idx = _challenges.indexWhere((c) => c.id == challengeId);
    if (idx != -1) {
      _challenges[idx] = _challenges[idx].copyWith(
        totalSubmissions: _challenges[idx].totalSubmissions + 1,
      );
    }
    return submission;
  }

  @override
  Future<ChallengeSubmission> reviewSubmission({
    required String submissionId,
    required SubmissionStatus status,
    String? comment,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _submissions.indexWhere((s) => s.id == submissionId);
    if (idx == -1) throw StateError('Submission not found');
    final updated = _submissions[idx].copyWith(
      status: status,
      creatorComment: comment,
      reviewedAt: DateTime.now(),
    );
    _submissions[idx] = updated;
    return updated;
  }

  @override
  Future<void> vote(String submissionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_myVotes.contains(submissionId)) {
      throw StateError('Already voted');
    }
    _myVotes.add(submissionId);
    final idx = _submissions.indexWhere((s) => s.id == submissionId);
    if (idx != -1) {
      _submissions[idx] = _submissions[idx].copyWith(
        voteCount: _submissions[idx].voteCount + 1,
      );
    }
  }

  @override
  Future<ChallengeSubmission?> getMySubmission(String challengeId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _submissions.firstWhere(
        (s) => s.challengeId == challengeId && s.fanId == DemoConfig.demoFanId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> hasVoted(String submissionId) async {
    return _myVotes.contains(submissionId);
  }
}
