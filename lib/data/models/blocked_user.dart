/// Blocked User Model
/// 차단된 사용자 정보 (설정 > 차단 관리용)
library;

class BlockedUser {
  final String id;
  final String blockerId;
  final String blockedId;
  final String? reason;
  final DateTime createdAt;
  final String? blockedUserName;
  final String? blockedUserAvatar;

  const BlockedUser({
    required this.id,
    required this.blockerId,
    required this.blockedId,
    this.reason,
    required this.createdAt,
    this.blockedUserName,
    this.blockedUserAvatar,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    // user_profiles JOIN 결과 처리
    final profile = json['blocked_profile'] as Map<String, dynamic>?;
    return BlockedUser(
      id: json['id'] as String,
      blockerId: json['blocker_id'] as String,
      blockedId: json['blocked_id'] as String,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      blockedUserName: profile?['display_name'] as String? ??
          json['blocked_user_name'] as String?,
      blockedUserAvatar: profile?['avatar_url'] as String? ??
          json['blocked_user_avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blocker_id': blockerId,
      'blocked_id': blockedId,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
      'blocked_user_name': blockedUserName,
      'blocked_user_avatar': blockedUserAvatar,
    };
  }

  BlockedUser copyWith({
    String? id,
    String? blockerId,
    String? blockedId,
    String? reason,
    DateTime? createdAt,
    String? blockedUserName,
    String? blockedUserAvatar,
  }) {
    return BlockedUser(
      id: id ?? this.id,
      blockerId: blockerId ?? this.blockerId,
      blockedId: blockedId ?? this.blockedId,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      blockedUserName: blockedUserName ?? this.blockedUserName,
      blockedUserAvatar: blockedUserAvatar ?? this.blockedUserAvatar,
    );
  }

  /// 차단 일자 표시
  String get blockedDateText {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays == 0) return '오늘';
    if (diff.inDays == 1) return '어제';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}주 전';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}개월 전';
    return '${diff.inDays ~/ 365}년 전';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlockedUser &&
        other.id == id &&
        other.blockerId == blockerId &&
        other.blockedId == blockedId;
  }

  @override
  int get hashCode {
    return Object.hash(id, blockerId, blockedId);
  }

  @override
  String toString() {
    return 'BlockedUser(id: $id, blockedId: $blockedId, name: $blockedUserName)';
  }
}
