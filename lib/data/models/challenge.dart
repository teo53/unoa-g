/// Challenge Models
/// 챌린지 시스템 데이터 모델
library;

/// 챌린지 타입
enum ChallengeType {
  photo,
  text,
  video,
  quiz;

  static ChallengeType fromString(String value) {
    switch (value) {
      case 'photo':
        return ChallengeType.photo;
      case 'text':
        return ChallengeType.text;
      case 'video':
        return ChallengeType.video;
      case 'quiz':
        return ChallengeType.quiz;
      default:
        return ChallengeType.photo;
    }
  }

  String get displayName {
    switch (this) {
      case ChallengeType.photo:
        return '사진 챌린지';
      case ChallengeType.text:
        return '텍스트 챌린지';
      case ChallengeType.video:
        return '영상 챌린지';
      case ChallengeType.quiz:
        return '퀴즈 챌린지';
    }
  }
}

/// 챌린지 상태
enum ChallengeStatus {
  draft,
  active,
  voting,
  completed,
  archived;

  static ChallengeStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return ChallengeStatus.draft;
      case 'active':
        return ChallengeStatus.active;
      case 'voting':
        return ChallengeStatus.voting;
      case 'completed':
        return ChallengeStatus.completed;
      case 'archived':
        return ChallengeStatus.archived;
      default:
        return ChallengeStatus.draft;
    }
  }

  String get displayName {
    switch (this) {
      case ChallengeStatus.draft:
        return '준비 중';
      case ChallengeStatus.active:
        return '진행 중';
      case ChallengeStatus.voting:
        return '투표 중';
      case ChallengeStatus.completed:
        return '완료';
      case ChallengeStatus.archived:
        return '보관됨';
    }
  }
}

/// 보상 타입
enum RewardType {
  dt,
  badge,
  shoutout,
  custom;

  static RewardType fromString(String value) {
    switch (value) {
      case 'dt':
        return RewardType.dt;
      case 'badge':
        return RewardType.badge;
      case 'shoutout':
        return RewardType.shoutout;
      case 'custom':
        return RewardType.custom;
      default:
        return RewardType.dt;
    }
  }

  String get displayName {
    switch (this) {
      case RewardType.dt:
        return 'DT 보상';
      case RewardType.badge:
        return '배지';
      case RewardType.shoutout:
        return '샤라웃';
      case RewardType.custom:
        return '커스텀 보상';
    }
  }
}

/// 챌린지
class Challenge {
  final String id;
  final String channelId;
  final String creatorId;
  final String title;
  final String? description;
  final String? rules;
  final ChallengeType challengeType;
  final ChallengeStatus status;
  final RewardType rewardType;
  final int rewardAmountDt;
  final String? rewardDescription;
  final int maxSubmissions;
  final int maxWinners;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime? votingEndAt;
  final String? thumbnailUrl;
  final int totalSubmissions;
  final int totalVotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Challenge({
    required this.id,
    required this.channelId,
    required this.creatorId,
    required this.title,
    this.description,
    this.rules,
    this.challengeType = ChallengeType.photo,
    this.status = ChallengeStatus.draft,
    this.rewardType = RewardType.dt,
    this.rewardAmountDt = 0,
    this.rewardDescription,
    this.maxSubmissions = 0,
    this.maxWinners = 1,
    required this.startAt,
    required this.endAt,
    this.votingEndAt,
    this.thumbnailUrl,
    this.totalSubmissions = 0,
    this.totalVotes = 0,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == ChallengeStatus.active;
  bool get isVoting => status == ChallengeStatus.voting;
  bool get isCompleted => status == ChallengeStatus.completed;
  bool get hasVotingPhase => votingEndAt != null;
  bool get isUnlimited => maxSubmissions == 0;

  Duration get remainingTime {
    final now = DateTime.now();
    if (isVoting && votingEndAt != null) {
      return votingEndAt!.difference(now);
    }
    return endAt.difference(now);
  }

  bool get isExpired => remainingTime.isNegative;

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      creatorId: json['creator_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      rules: json['rules'] as String?,
      challengeType: ChallengeType.fromString(
          json['challenge_type'] as String? ?? 'photo'),
      status: ChallengeStatus.fromString(json['status'] as String? ?? 'draft'),
      rewardType: RewardType.fromString(json['reward_type'] as String? ?? 'dt'),
      rewardAmountDt: json['reward_amount_dt'] as int? ?? 0,
      rewardDescription: json['reward_description'] as String?,
      maxSubmissions: json['max_submissions'] as int? ?? 0,
      maxWinners: json['max_winners'] as int? ?? 1,
      startAt: DateTime.parse(json['start_at'] as String),
      endAt: DateTime.parse(json['end_at'] as String),
      votingEndAt: json['voting_end_at'] != null
          ? DateTime.parse(json['voting_end_at'] as String)
          : null,
      thumbnailUrl: json['thumbnail_url'] as String?,
      totalSubmissions: json['total_submissions'] as int? ?? 0,
      totalVotes: json['total_votes'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel_id': channelId,
      'creator_id': creatorId,
      'title': title,
      'description': description,
      'rules': rules,
      'challenge_type': challengeType.name,
      'status': status.name,
      'reward_type': rewardType.name,
      'reward_amount_dt': rewardAmountDt,
      'reward_description': rewardDescription,
      'max_submissions': maxSubmissions,
      'max_winners': maxWinners,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'voting_end_at': votingEndAt?.toIso8601String(),
      'thumbnail_url': thumbnailUrl,
      'total_submissions': totalSubmissions,
      'total_votes': totalVotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Challenge copyWith({
    String? id,
    String? channelId,
    String? creatorId,
    String? title,
    String? description,
    String? rules,
    ChallengeType? challengeType,
    ChallengeStatus? status,
    RewardType? rewardType,
    int? rewardAmountDt,
    String? rewardDescription,
    int? maxSubmissions,
    int? maxWinners,
    DateTime? startAt,
    DateTime? endAt,
    DateTime? votingEndAt,
    String? thumbnailUrl,
    int? totalSubmissions,
    int? totalVotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Challenge(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      creatorId: creatorId ?? this.creatorId,
      title: title ?? this.title,
      description: description ?? this.description,
      rules: rules ?? this.rules,
      challengeType: challengeType ?? this.challengeType,
      status: status ?? this.status,
      rewardType: rewardType ?? this.rewardType,
      rewardAmountDt: rewardAmountDt ?? this.rewardAmountDt,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      maxSubmissions: maxSubmissions ?? this.maxSubmissions,
      maxWinners: maxWinners ?? this.maxWinners,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      votingEndAt: votingEndAt ?? this.votingEndAt,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      totalSubmissions: totalSubmissions ?? this.totalSubmissions,
      totalVotes: totalVotes ?? this.totalVotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Challenge && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// 제출 상태
enum SubmissionStatus {
  pending,
  approved,
  rejected,
  winner;

  static SubmissionStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return SubmissionStatus.pending;
      case 'approved':
        return SubmissionStatus.approved;
      case 'rejected':
        return SubmissionStatus.rejected;
      case 'winner':
        return SubmissionStatus.winner;
      default:
        return SubmissionStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case SubmissionStatus.pending:
        return '심사 대기';
      case SubmissionStatus.approved:
        return '승인됨';
      case SubmissionStatus.rejected:
        return '반려됨';
      case SubmissionStatus.winner:
        return '우승';
    }
  }
}

/// 챌린지 제출물
class ChallengeSubmission {
  final String id;
  final String challengeId;
  final String fanId;
  final String? content;
  final String? mediaUrl;
  final String? mediaType;
  final SubmissionStatus status;
  final int voteCount;
  final String? creatorComment;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  // Join fields
  final String? fanDisplayName;
  final String? fanAvatarUrl;

  const ChallengeSubmission({
    required this.id,
    required this.challengeId,
    required this.fanId,
    this.content,
    this.mediaUrl,
    this.mediaType,
    this.status = SubmissionStatus.pending,
    this.voteCount = 0,
    this.creatorComment,
    required this.submittedAt,
    this.reviewedAt,
    this.fanDisplayName,
    this.fanAvatarUrl,
  });

  bool get hasMedia => mediaUrl != null;
  bool get isWinner => status == SubmissionStatus.winner;
  bool get isPending => status == SubmissionStatus.pending;

  factory ChallengeSubmission.fromJson(Map<String, dynamic> json) {
    return ChallengeSubmission(
      id: json['id'] as String,
      challengeId: json['challenge_id'] as String,
      fanId: json['fan_id'] as String,
      content: json['content'] as String?,
      mediaUrl: json['media_url'] as String?,
      mediaType: json['media_type'] as String?,
      status:
          SubmissionStatus.fromString(json['status'] as String? ?? 'pending'),
      voteCount: json['vote_count'] as int? ?? 0,
      creatorComment: json['creator_comment'] as String?,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      fanDisplayName: json['fan_display_name'] as String?,
      fanAvatarUrl: json['fan_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challenge_id': challengeId,
      'fan_id': fanId,
      'content': content,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'status': status.name,
      'vote_count': voteCount,
      'creator_comment': creatorComment,
      'submitted_at': submittedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
    };
  }

  ChallengeSubmission copyWith({
    String? id,
    String? challengeId,
    String? fanId,
    String? content,
    String? mediaUrl,
    String? mediaType,
    SubmissionStatus? status,
    int? voteCount,
    String? creatorComment,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? fanDisplayName,
    String? fanAvatarUrl,
  }) {
    return ChallengeSubmission(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      fanId: fanId ?? this.fanId,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      status: status ?? this.status,
      voteCount: voteCount ?? this.voteCount,
      creatorComment: creatorComment ?? this.creatorComment,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      fanDisplayName: fanDisplayName ?? this.fanDisplayName,
      fanAvatarUrl: fanAvatarUrl ?? this.fanAvatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChallengeSubmission && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
