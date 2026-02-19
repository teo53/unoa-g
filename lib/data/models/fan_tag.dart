/// Fan Tag Models
/// 크리에이터가 팬을 분류하는 태그 시스템
library;

/// 크리에이터가 생성한 태그
class FanTag {
  final String id;
  final String creatorId;
  final String tagName;
  final String tagColor;
  final String? description;
  final int fanCount;
  final DateTime createdAt;

  const FanTag({
    required this.id,
    required this.creatorId,
    required this.tagName,
    required this.tagColor,
    this.description,
    this.fanCount = 0,
    required this.createdAt,
  });

  factory FanTag.fromJson(Map<String, dynamic> json) {
    return FanTag(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      tagName: json['tag_name'] as String,
      tagColor: json['tag_color'] as String? ?? '#808080',
      description: json['description'] as String?,
      fanCount: json['fan_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'tag_name': tagName,
      'tag_color': tagColor,
      'description': description,
      'fan_count': fanCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  FanTag copyWith({
    String? id,
    String? creatorId,
    String? tagName,
    String? tagColor,
    String? description,
    int? fanCount,
    DateTime? createdAt,
  }) {
    return FanTag(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      tagName: tagName ?? this.tagName,
      tagColor: tagColor ?? this.tagColor,
      description: description ?? this.description,
      fanCount: fanCount ?? this.fanCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 기본 태그 색상 팔레트 (8색)
  static const List<String> colorPalette = [
    '#FF6B6B', // 빨강
    '#FF8E53', // 주황
    '#FFC107', // 노랑
    '#4CAF50', // 초록
    '#42A5F5', // 파랑
    '#7C4DFF', // 보라
    '#EC407A', // 핑크
    '#78909C', // 회색
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FanTag &&
        other.id == id &&
        other.creatorId == creatorId &&
        other.tagName == tagName;
  }

  @override
  int get hashCode {
    return Object.hash(id, creatorId, tagName);
  }

  @override
  String toString() {
    return 'FanTag(id: $id, tagName: $tagName, color: $tagColor, fanCount: $fanCount)';
  }
}

/// 팬-태그 할당 정보
class FanTagAssignment {
  final String fanId;
  final String tagId;
  final String assignedBy;
  final DateTime assignedAt;

  const FanTagAssignment({
    required this.fanId,
    required this.tagId,
    required this.assignedBy,
    required this.assignedAt,
  });

  factory FanTagAssignment.fromJson(Map<String, dynamic> json) {
    return FanTagAssignment(
      fanId: json['fan_id'] as String,
      tagId: json['tag_id'] as String,
      assignedBy: json['assigned_by'] as String,
      assignedAt: DateTime.parse(json['assigned_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fan_id': fanId,
      'tag_id': tagId,
      'assigned_by': assignedBy,
      'assigned_at': assignedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FanTagAssignment &&
        other.fanId == fanId &&
        other.tagId == tagId;
  }

  @override
  int get hashCode {
    return Object.hash(fanId, tagId);
  }

  @override
  String toString() {
    return 'FanTagAssignment(fanId: $fanId, tagId: $tagId)';
  }
}
