/// Broadcast Chat System - Message Model
/// Fromm/Bubble style 1:1 chat UX with broadcast delivery

enum DeliveryScope {
  /// Artist message to all subscribers
  broadcast,

  /// Fan's reply to artist (uses reply token)
  directReply,

  /// Fan's message with DT donation (100 char limit)
  donationMessage,

  /// Artist's reply to donation message (1:1)
  donationReply,
}

enum BroadcastMessageType {
  text,
  image,
  emoji,
  voice,
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
  });

  bool get isFromArtist => senderType == 'artist';
  bool get isFromFan => senderType == 'fan';
  bool get isBroadcast => deliveryScope == DeliveryScope.broadcast;
  bool get isDonation =>
      deliveryScope == DeliveryScope.donationMessage ||
      deliveryScope == DeliveryScope.donationReply;

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
    }
  }

  static BroadcastMessageType _parseMessageType(String value) {
    switch (value) {
      case 'image':
        return BroadcastMessageType.image;
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
      case BroadcastMessageType.emoji:
        return 'emoji';
      case BroadcastMessageType.voice:
        return 'voice';
    }
  }
}
