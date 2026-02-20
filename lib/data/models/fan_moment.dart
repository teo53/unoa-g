/// Fan Moment Model
/// 팬이 수집한 특별 순간들 (프라이빗 카드, 하이라이트, 미디어 등)
library;

/// 모먼트 소스 타입
enum MomentSourceType {
  privateCard,
  highlight,
  mediaMessage,
  donationReply,
  welcome,
  manual,
}

class FanMoment {
  final String id;
  final String fanId;
  final String channelId;
  final MomentSourceType sourceType;
  final String? sourceMessageId;
  final String? sourceCardId;
  final String? title;
  final String? content;
  final String? mediaUrl;
  final String? mediaType; // 'image', 'video', 'voice'
  final String? thumbnailUrl;
  final String? artistName;
  final String? artistAvatarUrl;
  final bool isFavorite;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime collectedAt;

  const FanMoment({
    required this.id,
    required this.fanId,
    required this.channelId,
    required this.sourceType,
    this.sourceMessageId,
    this.sourceCardId,
    this.title,
    this.content,
    this.mediaUrl,
    this.mediaType,
    this.thumbnailUrl,
    this.artistName,
    this.artistAvatarUrl,
    this.isFavorite = false,
    this.metadata,
    required this.createdAt,
    required this.collectedAt,
  });

  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;
  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';
  bool get isVoice => mediaType == 'voice';

  /// 모먼트 소스 타입에 따른 라벨
  String get sourceLabel {
    switch (sourceType) {
      case MomentSourceType.privateCard:
        return '프라이빗 카드';
      case MomentSourceType.highlight:
        return '하이라이트';
      case MomentSourceType.mediaMessage:
        return '미디어';
      case MomentSourceType.donationReply:
        return '후원 답장';
      case MomentSourceType.welcome:
        return '웰컴 메시지';
      case MomentSourceType.manual:
        return '저장한 메시지';
    }
  }

  factory FanMoment.fromJson(Map<String, dynamic> json) {
    return FanMoment(
      id: json['id'] as String,
      fanId: json['fan_id'] as String,
      channelId: json['channel_id'] as String,
      sourceType: _parseSourceType(json['source_type'] as String),
      sourceMessageId: json['source_message_id'] as String?,
      sourceCardId: json['source_card_id'] as String?,
      title: json['title'] as String?,
      content: json['content'] as String?,
      mediaUrl: json['media_url'] as String?,
      mediaType: json['media_type'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      artistName: json['artist_name'] as String?,
      artistAvatarUrl: json['artist_avatar_url'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      collectedAt: json['collected_at'] != null
          ? DateTime.parse(json['collected_at'] as String)
          : DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fan_id': fanId,
      'channel_id': channelId,
      'source_type': _sourceTypeToString(sourceType),
      'source_message_id': sourceMessageId,
      'source_card_id': sourceCardId,
      'title': title,
      'content': content,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'thumbnail_url': thumbnailUrl,
      'artist_name': artistName,
      'artist_avatar_url': artistAvatarUrl,
      'is_favorite': isFavorite,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'collected_at': collectedAt.toIso8601String(),
    };
  }

  FanMoment copyWith({
    String? id,
    String? fanId,
    String? channelId,
    MomentSourceType? sourceType,
    String? sourceMessageId,
    String? sourceCardId,
    String? title,
    String? content,
    String? mediaUrl,
    String? mediaType,
    String? thumbnailUrl,
    String? artistName,
    String? artistAvatarUrl,
    bool? isFavorite,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? collectedAt,
  }) {
    return FanMoment(
      id: id ?? this.id,
      fanId: fanId ?? this.fanId,
      channelId: channelId ?? this.channelId,
      sourceType: sourceType ?? this.sourceType,
      sourceMessageId: sourceMessageId ?? this.sourceMessageId,
      sourceCardId: sourceCardId ?? this.sourceCardId,
      title: title ?? this.title,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      artistName: artistName ?? this.artistName,
      artistAvatarUrl: artistAvatarUrl ?? this.artistAvatarUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      collectedAt: collectedAt ?? this.collectedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FanMoment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FanMoment(id: $id, sourceType: $sourceType, title: $title)';
  }

  static MomentSourceType _parseSourceType(String value) {
    switch (value) {
      case 'private_card':
        return MomentSourceType.privateCard;
      case 'highlight':
        return MomentSourceType.highlight;
      case 'media_message':
        return MomentSourceType.mediaMessage;
      case 'donation_reply':
        return MomentSourceType.donationReply;
      case 'welcome':
        return MomentSourceType.welcome;
      case 'manual':
        return MomentSourceType.manual;
      default:
        return MomentSourceType.manual;
    }
  }

  static String _sourceTypeToString(MomentSourceType type) {
    switch (type) {
      case MomentSourceType.privateCard:
        return 'private_card';
      case MomentSourceType.highlight:
        return 'highlight';
      case MomentSourceType.mediaMessage:
        return 'media_message';
      case MomentSourceType.donationReply:
        return 'donation_reply';
      case MomentSourceType.welcome:
        return 'welcome';
      case MomentSourceType.manual:
        return 'manual';
    }
  }
}
