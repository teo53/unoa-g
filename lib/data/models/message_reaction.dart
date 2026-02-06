/// Message Reaction Model
/// 메시지 리액션 (하트 반응) 데이터 모델

class MessageReaction {
  final String id;
  final String messageId;
  final String userId;
  final String reactionType;
  final DateTime createdAt;

  const MessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    this.reactionType = 'heart',
    required this.createdAt,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      userId: json['user_id'] as String,
      reactionType: json['reaction_type'] as String? ?? 'heart',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'user_id': userId,
      'reaction_type': reactionType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MessageReaction copyWith({
    String? id,
    String? messageId,
    String? userId,
    String? reactionType,
    DateTime? createdAt,
  }) {
    return MessageReaction(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      reactionType: reactionType ?? this.reactionType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageReaction &&
        other.id == id &&
        other.messageId == messageId &&
        other.userId == userId &&
        other.reactionType == reactionType;
  }

  @override
  int get hashCode {
    return Object.hash(id, messageId, userId, reactionType);
  }

  @override
  String toString() {
    return 'MessageReaction(id: $id, messageId: $messageId, userId: $userId, reactionType: $reactionType)';
  }
}

/// 리액션 정보 (개수 + 현재 사용자 여부)
class ReactionInfo {
  final int count;
  final bool hasReacted;

  const ReactionInfo({
    required this.count,
    required this.hasReacted,
  });

  factory ReactionInfo.fromJson(Map<String, dynamic> json) {
    return ReactionInfo(
      count: json['reaction_count'] as int? ?? 0,
      hasReacted: json['has_reacted'] as bool? ?? false,
    );
  }

  ReactionInfo copyWith({
    int? count,
    bool? hasReacted,
  }) {
    return ReactionInfo(
      count: count ?? this.count,
      hasReacted: hasReacted ?? this.hasReacted,
    );
  }

  /// 리액션 토글 후 상태 계산
  ReactionInfo toggle() {
    if (hasReacted) {
      return ReactionInfo(count: count - 1, hasReacted: false);
    } else {
      return ReactionInfo(count: count + 1, hasReacted: true);
    }
  }

  static const empty = ReactionInfo(count: 0, hasReacted: false);
}
