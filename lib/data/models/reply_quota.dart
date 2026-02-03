/// Reply Quota Model
/// Tracks available reply tokens per user per channel
/// Fromm/Bubble style: 3 replies per artist broadcast

class ReplyQuota {
  final String id;
  final String userId;
  final String channelId;
  final int tokensAvailable;
  final int tokensUsed;
  final String? lastBroadcastId;
  final DateTime? lastBroadcastAt;
  final DateTime? lastReplyAt;
  final bool fallbackAvailable;
  final DateTime? fallbackUsedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReplyQuota({
    required this.id,
    required this.userId,
    required this.channelId,
    required this.tokensAvailable,
    required this.tokensUsed,
    this.lastBroadcastId,
    this.lastBroadcastAt,
    this.lastReplyAt,
    this.fallbackAvailable = false,
    this.fallbackUsedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Can the user send a reply?
  bool get canReply => tokensAvailable > 0 || fallbackAvailable;

  /// Total tokens (regular + fallback)
  int get totalAvailable => tokensAvailable + (fallbackAvailable ? 1 : 0);

  /// Is this a fallback situation (no broadcast for 7 days)?
  bool get isFallbackOnly => tokensAvailable == 0 && fallbackAvailable;

  factory ReplyQuota.fromJson(Map<String, dynamic> json) {
    return ReplyQuota(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      channelId: json['channel_id'] as String,
      tokensAvailable: json['tokens_available'] as int? ?? 0,
      tokensUsed: json['tokens_used'] as int? ?? 0,
      lastBroadcastId: json['last_broadcast_id'] as String?,
      lastBroadcastAt: json['last_broadcast_at'] != null
          ? DateTime.parse(json['last_broadcast_at'] as String)
          : null,
      lastReplyAt: json['last_reply_at'] != null
          ? DateTime.parse(json['last_reply_at'] as String)
          : null,
      fallbackAvailable: json['fallback_available'] as bool? ?? false,
      fallbackUsedAt: json['fallback_used_at'] != null
          ? DateTime.parse(json['fallback_used_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'channel_id': channelId,
      'tokens_available': tokensAvailable,
      'tokens_used': tokensUsed,
      'last_broadcast_id': lastBroadcastId,
      'last_broadcast_at': lastBroadcastAt?.toIso8601String(),
      'last_reply_at': lastReplyAt?.toIso8601String(),
      'fallback_available': fallbackAvailable,
      'fallback_used_at': fallbackUsedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ReplyQuota copyWith({
    String? id,
    String? userId,
    String? channelId,
    int? tokensAvailable,
    int? tokensUsed,
    String? lastBroadcastId,
    DateTime? lastBroadcastAt,
    DateTime? lastReplyAt,
    bool? fallbackAvailable,
    DateTime? fallbackUsedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReplyQuota(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      channelId: channelId ?? this.channelId,
      tokensAvailable: tokensAvailable ?? this.tokensAvailable,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      lastBroadcastId: lastBroadcastId ?? this.lastBroadcastId,
      lastBroadcastAt: lastBroadcastAt ?? this.lastBroadcastAt,
      lastReplyAt: lastReplyAt ?? this.lastReplyAt,
      fallbackAvailable: fallbackAvailable ?? this.fallbackAvailable,
      fallbackUsedAt: fallbackUsedAt ?? this.fallbackUsedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create a decremented copy after sending a reply
  ReplyQuota afterReply() {
    if (tokensAvailable > 0) {
      return copyWith(
        tokensAvailable: tokensAvailable - 1,
        tokensUsed: tokensUsed + 1,
        lastReplyAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else if (fallbackAvailable) {
      return copyWith(
        fallbackAvailable: false,
        fallbackUsedAt: DateTime.now(),
        lastReplyAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }

  /// Empty quota (no replies available)
  static ReplyQuota empty(String userId, String channelId) {
    final now = DateTime.now();
    return ReplyQuota(
      id: '',
      userId: userId,
      channelId: channelId,
      tokensAvailable: 0,
      tokensUsed: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Get character limit based on subscription days
  /// Uses default Bubble-style progression if no custom limits set
  static int getCharacterLimitForDays(int daysSubscribed) {
    return CharacterLimits.defaultLimits.getLimitForDays(daysSubscribed);
  }
}

/// Character limit based on subscription age
class CharacterLimitRule {
  final int minDays;
  final int maxChars;

  const CharacterLimitRule({
    required this.minDays,
    required this.maxChars,
  });

  factory CharacterLimitRule.fromJson(Map<String, dynamic> json) {
    return CharacterLimitRule(
      minDays: json['min_days'] as int,
      maxChars: json['max_chars'] as int,
    );
  }
}

/// Character limits configuration (Bubble-style progression)
class CharacterLimits {
  final int baseLimit;
  final List<CharacterLimitRule> progression;

  const CharacterLimits({
    required this.baseLimit,
    required this.progression,
  });

  /// Get the character limit for a user based on subscription days
  int getLimitForDays(int daysSubscribed) {
    int limit = baseLimit;
    for (final rule in progression) {
      if (daysSubscribed >= rule.minDays) {
        limit = rule.maxChars;
      }
    }
    return limit;
  }

  factory CharacterLimits.fromJson(Map<String, dynamic> json) {
    final progressionList = (json['progression'] as List?)
            ?.map((e) => CharacterLimitRule.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return CharacterLimits(
      baseLimit: json['base_limit'] as int? ?? 50,
      progression: progressionList,
    );
  }

  /// Default Bubble-style character limits
  static const CharacterLimits defaultLimits = CharacterLimits(
    baseLimit: 50,
    progression: [
      CharacterLimitRule(minDays: 1, maxChars: 50),
      CharacterLimitRule(minDays: 50, maxChars: 50),
      CharacterLimitRule(minDays: 77, maxChars: 77),
      CharacterLimitRule(minDays: 100, maxChars: 100),
      CharacterLimitRule(minDays: 150, maxChars: 150),
      CharacterLimitRule(minDays: 200, maxChars: 200),
      CharacterLimitRule(minDays: 300, maxChars: 300),
      CharacterLimitRule(minDays: 365, maxChars: 300),
    ],
  );
}
