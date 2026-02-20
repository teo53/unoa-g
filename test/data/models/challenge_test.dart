import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/challenge.dart';

void main() {
  group('ChallengeType', () {
    test('fromString parses all types', () {
      expect(ChallengeType.fromString('photo'), ChallengeType.photo);
      expect(ChallengeType.fromString('text'), ChallengeType.text);
      expect(ChallengeType.fromString('video'), ChallengeType.video);
      expect(ChallengeType.fromString('quiz'), ChallengeType.quiz);
      expect(ChallengeType.fromString('unknown'), ChallengeType.photo);
    });

    test('displayName returns Korean labels', () {
      expect(ChallengeType.photo.displayName, '사진 챌린지');
      expect(ChallengeType.text.displayName, '텍스트 챌린지');
      expect(ChallengeType.video.displayName, '영상 챌린지');
      expect(ChallengeType.quiz.displayName, '퀴즈 챌린지');
    });
  });

  group('ChallengeStatus', () {
    test('fromString parses all statuses', () {
      expect(ChallengeStatus.fromString('draft'), ChallengeStatus.draft);
      expect(ChallengeStatus.fromString('active'), ChallengeStatus.active);
      expect(ChallengeStatus.fromString('voting'), ChallengeStatus.voting);
      expect(
          ChallengeStatus.fromString('completed'), ChallengeStatus.completed);
      expect(ChallengeStatus.fromString('archived'), ChallengeStatus.archived);
      expect(ChallengeStatus.fromString('invalid'), ChallengeStatus.draft);
    });

    test('displayName returns Korean labels', () {
      expect(ChallengeStatus.active.displayName, '진행 중');
      expect(ChallengeStatus.voting.displayName, '투표 중');
      expect(ChallengeStatus.completed.displayName, '완료');
    });
  });

  group('RewardType', () {
    test('fromString parses all reward types', () {
      expect(RewardType.fromString('dt'), RewardType.dt);
      expect(RewardType.fromString('badge'), RewardType.badge);
      expect(RewardType.fromString('shoutout'), RewardType.shoutout);
      expect(RewardType.fromString('custom'), RewardType.custom);
    });
  });

  group('Challenge', () {
    final now = DateTime(2025, 7, 1, 12, 0, 0);
    final sampleJson = {
      'id': 'ch_1',
      'channel_id': 'channel_1',
      'creator_id': 'creator_1',
      'title': '팬아트 챌린지',
      'description': '자유롭게 그려주세요',
      'rules': '1장만 제출 가능',
      'challenge_type': 'photo',
      'status': 'active',
      'reward_type': 'dt',
      'reward_amount_dt': 500,
      'reward_description': null,
      'max_submissions': 0,
      'max_winners': 3,
      'start_at': now.toIso8601String(),
      'end_at': now.add(const Duration(days: 7)).toIso8601String(),
      'voting_end_at': null,
      'thumbnail_url': 'https://example.com/thumb.jpg',
      'total_submissions': 15,
      'total_votes': 42,
      'created_at': now.toIso8601String(),
      'updated_at': null,
    };

    test('fromJson creates correct instance', () {
      final challenge = Challenge.fromJson(sampleJson);

      expect(challenge.id, 'ch_1');
      expect(challenge.channelId, 'channel_1');
      expect(challenge.title, '팬아트 챌린지');
      expect(challenge.challengeType, ChallengeType.photo);
      expect(challenge.status, ChallengeStatus.active);
      expect(challenge.rewardType, RewardType.dt);
      expect(challenge.rewardAmountDt, 500);
      expect(challenge.maxWinners, 3);
      expect(challenge.totalSubmissions, 15);
      expect(challenge.totalVotes, 42);
    });

    test('toJson produces correct map', () {
      final challenge = Challenge.fromJson(sampleJson);
      final json = challenge.toJson();

      expect(json['id'], 'ch_1');
      expect(json['title'], '팬아트 챌린지');
      expect(json['challenge_type'], 'photo');
      expect(json['status'], 'active');
      expect(json['reward_amount_dt'], 500);
    });

    test('round-trip fromJson → toJson preserves data', () {
      final c1 = Challenge.fromJson(sampleJson);
      final json = c1.toJson();
      final c2 = Challenge.fromJson(json);

      expect(c2.id, c1.id);
      expect(c2.title, c1.title);
      expect(c2.challengeType, c1.challengeType);
      expect(c2.status, c1.status);
      expect(c2.rewardAmountDt, c1.rewardAmountDt);
    });

    test('computed properties', () {
      final challenge = Challenge.fromJson(sampleJson);

      expect(challenge.isActive, true);
      expect(challenge.isVoting, false);
      expect(challenge.isCompleted, false);
      expect(challenge.hasVotingPhase, false);
      expect(challenge.isUnlimited, true);
    });

    test('copyWith creates modified copy', () {
      final challenge = Challenge.fromJson(sampleJson);
      final updated = challenge.copyWith(
        status: ChallengeStatus.voting,
        totalSubmissions: 25,
      );

      expect(updated.status, ChallengeStatus.voting);
      expect(updated.totalSubmissions, 25);
      expect(updated.title, challenge.title);
      expect(updated.id, challenge.id);
    });

    test('equality based on id', () {
      final c1 = Challenge.fromJson(sampleJson);
      final c2 = Challenge.fromJson(sampleJson);
      expect(c1, equals(c2));
    });

    test('handles null optional fields', () {
      final minJson = {
        'id': 'ch_2',
        'channel_id': 'ch_1',
        'creator_id': 'cr_1',
        'title': '간단한 챌린지',
        'start_at': now.toIso8601String(),
        'end_at': now.add(const Duration(days: 3)).toIso8601String(),
        'created_at': now.toIso8601String(),
      };
      final challenge = Challenge.fromJson(minJson);

      expect(challenge.description, null);
      expect(challenge.rules, null);
      expect(challenge.thumbnailUrl, null);
      expect(challenge.votingEndAt, null);
      expect(challenge.rewardAmountDt, 0);
      expect(challenge.maxSubmissions, 0);
    });
  });

  group('SubmissionStatus', () {
    test('fromString parses all statuses', () {
      expect(SubmissionStatus.fromString('pending'), SubmissionStatus.pending);
      expect(
          SubmissionStatus.fromString('approved'), SubmissionStatus.approved);
      expect(
          SubmissionStatus.fromString('rejected'), SubmissionStatus.rejected);
      expect(SubmissionStatus.fromString('winner'), SubmissionStatus.winner);
      expect(SubmissionStatus.fromString('unknown'), SubmissionStatus.pending);
    });

    test('displayName returns Korean labels', () {
      expect(SubmissionStatus.pending.displayName, '심사 대기');
      expect(SubmissionStatus.winner.displayName, '우승');
    });
  });

  group('ChallengeSubmission', () {
    final now = DateTime(2025, 7, 2, 15, 0, 0);
    final sampleJson = {
      'id': 'sub_1',
      'challenge_id': 'ch_1',
      'fan_id': 'fan_1',
      'content': '응원합니다!',
      'media_url': 'https://example.com/photo.jpg',
      'media_type': 'image',
      'status': 'approved',
      'vote_count': 12,
      'creator_comment': '좋아요!',
      'submitted_at': now.toIso8601String(),
      'reviewed_at': now.add(const Duration(hours: 2)).toIso8601String(),
      'fan_display_name': '열혈팬',
      'fan_avatar_url': 'https://example.com/avatar.jpg',
    };

    test('fromJson creates correct instance', () {
      final sub = ChallengeSubmission.fromJson(sampleJson);

      expect(sub.id, 'sub_1');
      expect(sub.challengeId, 'ch_1');
      expect(sub.fanId, 'fan_1');
      expect(sub.content, '응원합니다!');
      expect(sub.mediaUrl, 'https://example.com/photo.jpg');
      expect(sub.status, SubmissionStatus.approved);
      expect(sub.voteCount, 12);
      expect(sub.creatorComment, '좋아요!');
      expect(sub.fanDisplayName, '열혈팬');
    });

    test('toJson produces correct map', () {
      final sub = ChallengeSubmission.fromJson(sampleJson);
      final json = sub.toJson();

      expect(json['id'], 'sub_1');
      expect(json['content'], '응원합니다!');
      expect(json['status'], 'approved');
      expect(json['vote_count'], 12);
    });

    test('computed properties', () {
      final sub = ChallengeSubmission.fromJson(sampleJson);

      expect(sub.hasMedia, true);
      expect(sub.isWinner, false);
      expect(sub.isPending, false);
    });

    test('winner submission', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json['status'] = 'winner';
      final sub = ChallengeSubmission.fromJson(json);

      expect(sub.isWinner, true);
    });

    test('copyWith creates modified copy', () {
      final sub = ChallengeSubmission.fromJson(sampleJson);
      final updated = sub.copyWith(
        status: SubmissionStatus.winner,
        voteCount: 25,
      );

      expect(updated.status, SubmissionStatus.winner);
      expect(updated.voteCount, 25);
      expect(updated.content, sub.content);
    });

    test('equality based on id', () {
      final s1 = ChallengeSubmission.fromJson(sampleJson);
      final s2 = ChallengeSubmission.fromJson(sampleJson);
      expect(s1, equals(s2));
    });
  });
}
