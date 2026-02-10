/// Broadcast Chat System - Message Model
/// Fromm/Bubble style 1:1 chat UX with broadcast delivery
library;

enum DeliveryScope {
  /// Artist message to all subscribers
  broadcast,

  /// Fan's reply to artist (uses reply token)
  directReply,

  /// Fan's message with DT donation (100 char limit)
  donationMessage,

  /// Artist's reply to donation message (1:1)
  donationReply,

  /// Fan message shared publicly by artist (visible to all subscribers)
  publicShare,

  /// Private card from artist to selected fans (letter-style special message)
  privateCard,
}

enum BroadcastMessageType {
  text,
  image,
  video,
  emoji,
  voice,
}

/// 메시지 수정 이력
class MessageEditHistory {
  final String id;
  final String messageId;
  final String previousContent;
  final String newContent;
  final DateTime editedAt;
  final String? editReason;

  const MessageEditHistory({
    required this.id,
    required this.messageId,
    required this.previousContent,
    required this.newContent,
    required this.editedAt,
    this.editReason,
  });

  factory MessageEditHistory.fromJson(Map<String, dynamic> json) {
    return MessageEditHistory(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      previousContent: json['previous_content'] as String,
      newContent: json['new_content'] as String,
      editedAt: DateTime.parse(json['edited_at'] as String),
      editReason: json['edit_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'previous_content': previousContent,
      'new_content': newContent,
      'edited_at': editedAt.toIso8601String(),
      'edit_reason': editReason,
    };
  }
}

class BroadcastMessage {
  final String id;
  final String channelId;
  final String senderId;
  final String senderType; // 'artist' or 'fan'
  final DeliveryScope deliveryScope;
  final String? replyToMessageId;
  final String? targetUserId;
  final String? content;
  final BroadcastMessageType messageType;
  final String? mediaUrl;
  final Map<String, dynamic>? mediaMetadata;
  final String? donationId;
  final int? donationAmount;
  final bool isHighlighted;
  final DateTime? highlightedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  // Computed for UI
  final bool? isRead;
  final DateTime? readAt;

  // Sender info (joined from user/subscription)
  final String? senderName;
  final String? senderAvatarUrl;
  final String? senderTier;
  final int? senderDaysSubscribed;

  // Bubble-style personalization (for broadcast messages)
  // templateContent stores the original message with placeholders like {fanName}
  // content stores the personalized version for each fan
  final String? templateContent;

  // 수정 이력 관련 필드
  final bool isEdited;
  final DateTime? lastEditedAt;
  final List<MessageEditHistory>? editHistory;

  // 리액션 관련 필드
  final int reactionCount;
  final bool hasReacted;
  final Map<String, List<String>>? reactions;

  // 고정 메시지
  final bool isPinned;
  final DateTime? pinnedAt;

  // 전체공개 관련 필드
  final bool isPublicShared;
  final String? sharedByArtistId;
  final DateTime? sharedAt;

  const BroadcastMessage({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderType,
    required this.deliveryScope,
    this.replyToMessageId,
    this.targetUserId,
    this.content,
    this.messageType = BroadcastMessageType.text,
    this.mediaUrl,
    this.mediaMetadata,
    this.donationId,
    this.donationAmount,
    this.isHighlighted = false,
    this.highlightedAt,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.isRead,
    this.readAt,
    this.senderName,
    this.senderAvatarUrl,
    this.senderTier,
    this.senderDaysSubscribed,
    this.templateContent,
    this.isEdited = false,
    this.lastEditedAt,
    this.editHistory,
    this.reactionCount = 0,
    this.hasReacted = false,
    this.reactions,
    this.isPinned = false,
    this.pinnedAt,
    this.isPublicShared = false,
    this.sharedByArtistId,
    this.sharedAt,
  });

  /// Check if message has personalization placeholders
  bool get hasPersonalization =>
      templateContent != null && templateContent!.contains('{');

  /// Available placeholders for Bubble-style personalization
  static const List<String> placeholders = [
    '{fanName}',     // Fan's display name
    '{subscribeDays}', // Days subscribed
    '{tier}',        // Subscription tier
  ];

  /// Get personalized content for a specific fan
  /// Returns content with placeholders replaced by actual fan data
  String getPersonalizedContent({
    required String fanName,
    int? subscribeDays,
    String? tier,
  }) {
    String text = templateContent ?? content ?? '';

    text = text.replaceAll('{fanName}', fanName);
    if (subscribeDays != null) {
      text = text.replaceAll('{subscribeDays}', subscribeDays.toString());
    }
    if (tier != null) {
      text = text.replaceAll('{tier}', tier);
    }

    return text;
  }

  bool get isFromArtist => senderType == 'artist';
  bool get isFromFan => senderType == 'fan';
  bool get isBroadcast => deliveryScope == DeliveryScope.broadcast;
  bool get isDonation =>
      deliveryScope == DeliveryScope.donationMessage ||
      deliveryScope == DeliveryScope.donationReply;
  bool get isPublicShare => deliveryScope == DeliveryScope.publicShare || isPublicShared;

  factory BroadcastMessage.fromJson(Map<String, dynamic> json) {
    return BroadcastMessage(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      senderId: json['sender_id'] as String,
      senderType: json['sender_type'] as String,
      deliveryScope: _parseDeliveryScope(json['delivery_scope'] as String),
      replyToMessageId: json['reply_to_message_id'] as String?,
      targetUserId: json['target_user_id'] as String?,
      content: json['content'] as String?,
      messageType: _parseMessageType(json['message_type'] as String? ?? 'text'),
      mediaUrl: json['media_url'] as String?,
      mediaMetadata: json['media_metadata'] as Map<String, dynamic>?,
      donationId: json['donation_id'] as String?,
      donationAmount: json['donation_amount'] as int?,
      isHighlighted: json['is_highlighted'] as bool? ?? false,
      highlightedAt: json['highlighted_at'] != null
          ? DateTime.parse(json['highlighted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      isRead: json['is_read'] as bool?,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      senderName: json['sender_name'] as String?,
      senderAvatarUrl: json['sender_avatar_url'] as String?,
      senderTier: json['sender_tier'] as String?,
      senderDaysSubscribed: json['sender_days_subscribed'] as int?,
      templateContent: json['template_content'] as String?,
      isEdited: json['is_edited'] as bool? ?? false,
      lastEditedAt: json['last_edited_at'] != null
          ? DateTime.parse(json['last_edited_at'] as String)
          : null,
      editHistory: json['edit_history'] != null
          ? (json['edit_history'] as List)
              .map((e) => MessageEditHistory.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      reactionCount: json['reaction_count'] as int? ?? 0,
      hasReacted: json['has_reacted'] as bool? ?? false,
      reactions: json['reactions'] != null
          ? (json['reactions'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<String>.from(v as List)))
          : null,
      isPinned: json['is_pinned'] as bool? ?? false,
      pinnedAt: json['pinned_at'] != null
          ? DateTime.parse(json['pinned_at'] as String)
          : null,
      isPublicShared: json['is_public_shared'] as bool? ?? false,
      sharedByArtistId: json['shared_by_artist_id'] as String?,
      sharedAt: json['shared_at'] != null
          ? DateTime.parse(json['shared_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel_id': channelId,
      'sender_id': senderId,
      'sender_type': senderType,
      'delivery_scope': _deliveryScopeToString(deliveryScope),
      'reply_to_message_id': replyToMessageId,
      'target_user_id': targetUserId,
      'content': content,
      'message_type': _messageTypeToString(messageType),
      'media_url': mediaUrl,
      'media_metadata': mediaMetadata,
      'donation_id': donationId,
      'donation_amount': donationAmount,
      'is_highlighted': isHighlighted,
      'highlighted_at': highlightedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'template_content': templateContent,
      'is_edited': isEdited,
      'last_edited_at': lastEditedAt?.toIso8601String(),
      'edit_history': editHistory?.map((e) => e.toJson()).toList(),
      'reaction_count': reactionCount,
      'has_reacted': hasReacted,
      'reactions': reactions,
      'is_pinned': isPinned,
      'pinned_at': pinnedAt?.toIso8601String(),
      'is_public_shared': isPublicShared,
      'shared_by_artist_id': sharedByArtistId,
      'shared_at': sharedAt?.toIso8601String(),
    };
  }

  BroadcastMessage copyWith({
    String? id,
    String? channelId,
    String? senderId,
    String? senderType,
    DeliveryScope? deliveryScope,
    String? replyToMessageId,
    String? targetUserId,
    String? content,
    BroadcastMessageType? messageType,
    String? mediaUrl,
    Map<String, dynamic>? mediaMetadata,
    String? donationId,
    int? donationAmount,
    bool? isHighlighted,
    DateTime? highlightedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isRead,
    DateTime? readAt,
    String? senderName,
    String? senderAvatarUrl,
    String? senderTier,
    int? senderDaysSubscribed,
    String? templateContent,
    bool? isEdited,
    DateTime? lastEditedAt,
    List<MessageEditHistory>? editHistory,
    int? reactionCount,
    bool? hasReacted,
    Map<String, List<String>>? reactions,
    bool? isPinned,
    DateTime? pinnedAt,
    bool? isPublicShared,
    String? sharedByArtistId,
    DateTime? sharedAt,
  }) {
    return BroadcastMessage(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      deliveryScope: deliveryScope ?? this.deliveryScope,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      targetUserId: targetUserId ?? this.targetUserId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaMetadata: mediaMetadata ?? this.mediaMetadata,
      donationId: donationId ?? this.donationId,
      donationAmount: donationAmount ?? this.donationAmount,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      highlightedAt: highlightedAt ?? this.highlightedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      senderTier: senderTier ?? this.senderTier,
      senderDaysSubscribed: senderDaysSubscribed ?? this.senderDaysSubscribed,
      templateContent: templateContent ?? this.templateContent,
      isEdited: isEdited ?? this.isEdited,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      editHistory: editHistory ?? this.editHistory,
      reactionCount: reactionCount ?? this.reactionCount,
      hasReacted: hasReacted ?? this.hasReacted,
      reactions: reactions ?? this.reactions,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      isPublicShared: isPublicShared ?? this.isPublicShared,
      sharedByArtistId: sharedByArtistId ?? this.sharedByArtistId,
      sharedAt: sharedAt ?? this.sharedAt,
    );
  }

  static DeliveryScope _parseDeliveryScope(String value) {
    switch (value) {
      case 'broadcast':
        return DeliveryScope.broadcast;
      case 'direct_reply':
        return DeliveryScope.directReply;
      case 'donation_message':
        return DeliveryScope.donationMessage;
      case 'donation_reply':
        return DeliveryScope.donationReply;
      case 'public_share':
        return DeliveryScope.publicShare;
      case 'private_card':
        return DeliveryScope.privateCard;
      default:
        return DeliveryScope.broadcast;
    }
  }

  static String _deliveryScopeToString(DeliveryScope scope) {
    switch (scope) {
      case DeliveryScope.broadcast:
        return 'broadcast';
      case DeliveryScope.directReply:
        return 'direct_reply';
      case DeliveryScope.donationMessage:
        return 'donation_message';
      case DeliveryScope.donationReply:
        return 'donation_reply';
      case DeliveryScope.publicShare:
        return 'public_share';
      case DeliveryScope.privateCard:
        return 'private_card';
    }
  }

  static BroadcastMessageType _parseMessageType(String value) {
    switch (value) {
      case 'image':
        return BroadcastMessageType.image;
      case 'video':
        return BroadcastMessageType.video;
      case 'emoji':
        return BroadcastMessageType.emoji;
      case 'voice':
        return BroadcastMessageType.voice;
      default:
        return BroadcastMessageType.text;
    }
  }

  static String _messageTypeToString(BroadcastMessageType type) {
    switch (type) {
      case BroadcastMessageType.text:
        return 'text';
      case BroadcastMessageType.image:
        return 'image';
      case BroadcastMessageType.video:
        return 'video';
      case BroadcastMessageType.emoji:
        return 'emoji';
      case BroadcastMessageType.voice:
        return 'voice';
    }
  }
}
