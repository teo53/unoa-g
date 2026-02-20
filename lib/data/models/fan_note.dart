/// Fan Note Model
/// 크리에이터가 팬에 대해 작성하는 메모
library;

class FanNote {
  final String id;
  final String creatorId;
  final String fanId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FanNote({
    required this.id,
    required this.creatorId,
    required this.fanId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FanNote.fromJson(Map<String, dynamic> json) {
    return FanNote(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      fanId: json['fan_id'] as String,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'fan_id': fanId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FanNote copyWith({
    String? id,
    String? creatorId,
    String? fanId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FanNote(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      fanId: fanId ?? this.fanId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 빈 메모 (신규 생성 전)
  static FanNote empty(String creatorId, String fanId) {
    final now = DateTime.now();
    return FanNote(
      id: '',
      creatorId: creatorId,
      fanId: fanId,
      content: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  bool get isEmpty => content.trim().isEmpty;
  bool get isNotEmpty => !isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FanNote &&
        other.id == id &&
        other.creatorId == creatorId &&
        other.fanId == fanId &&
        other.content == content;
  }

  @override
  int get hashCode {
    return Object.hash(id, creatorId, fanId, content);
  }

  @override
  String toString() {
    return 'FanNote(id: $id, creatorId: $creatorId, fanId: $fanId, content: ${content.length > 20 ? '${content.substring(0, 20)}...' : content})';
  }
}
