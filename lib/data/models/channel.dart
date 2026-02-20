/// Channel Model
/// One channel per artist for broadcast messaging
library;

class Channel {
  final String id;
  final String artistId;
  final String name;
  final String? description;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 아티스트 테마 색상 인덱스 (0-5, ArtistThemeColors.presets 참조)
  final int themeColorIndex;

  /// 캡처 방지 설정 (true: 앱 내에서 스크린샷/녹화 방지 활성화)
  final bool screenshotWarningEnabled;

  // Optional joined data
  final int? subscriberCount;
  final int? unreadCount;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;

  const Channel({
    required this.id,
    required this.artistId,
    required this.name,
    this.description,
    this.avatarUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.themeColorIndex = 0,
    this.screenshotWarningEnabled = true,
    this.subscriberCount,
    this.unreadCount,
    this.lastMessagePreview,
    this.lastMessageAt,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] as String,
      artistId: json['artist_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      themeColorIndex: json['theme_color_index'] as int? ?? 0,
      screenshotWarningEnabled:
          json['screenshot_warning_enabled'] as bool? ?? true,
      subscriberCount: json['subscriber_count'] as int?,
      unreadCount: json['unread_count'] as int?,
      lastMessagePreview: json['last_message_preview'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'artist_id': artistId,
      'name': name,
      'description': description,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'theme_color_index': themeColorIndex,
      'screenshot_warning_enabled': screenshotWarningEnabled,
    };
  }

  Channel copyWith({
    String? id,
    String? artistId,
    String? name,
    String? description,
    String? avatarUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? themeColorIndex,
    bool? screenshotWarningEnabled,
    int? subscriberCount,
    int? unreadCount,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
  }) {
    return Channel(
      id: id ?? this.id,
      artistId: artistId ?? this.artistId,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      themeColorIndex: themeColorIndex ?? this.themeColorIndex,
      screenshotWarningEnabled:
          screenshotWarningEnabled ?? this.screenshotWarningEnabled,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}

/// Subscription status and age info
class Subscription {
  final String id;
  final String userId;
  final String channelId;
  final String tier; // 'BASIC', 'STANDARD', 'VIP'
  final DateTime startedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final bool autoRenew;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Subscription({
    required this.id,
    required this.userId,
    required this.channelId,
    required this.tier,
    required this.startedAt,
    this.expiresAt,
    this.isActive = true,
    this.autoRenew = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Days since subscription started
  int get daysSubscribed => DateTime.now().difference(startedAt).inDays;

  /// Get formatted subscription duration
  String get formattedDuration {
    final days = daysSubscribed;
    if (days == 0) return '오늘 시작';
    if (days == 1) return '1일째';
    if (days < 30) return '$days일째';
    if (days < 365) {
      final months = days ~/ 30;
      return '$months개월째';
    }
    final years = days ~/ 365;
    return '$years년째';
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      channelId: json['channel_id'] as String,
      tier: json['tier'] as String? ?? 'STANDARD',
      startedAt: DateTime.parse(json['started_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      autoRenew: json['auto_renew'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'channel_id': channelId,
      'tier': tier,
      'started_at': startedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
      'auto_renew': autoRenew,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Subscription pricing configuration
class SubscriptionPricing {
  final int monthlyPriceKrw;
  final String currency;
  final String billingCycle;
  final int trialDays;
  final bool autoRenewal;

  const SubscriptionPricing({
    required this.monthlyPriceKrw,
    this.currency = 'KRW',
    this.billingCycle = 'monthly',
    this.trialDays = 0,
    this.autoRenewal = true,
  });

  /// Default pricing: 4,900원/월 per artist
  static const SubscriptionPricing defaultPricing = SubscriptionPricing(
    monthlyPriceKrw: 4900,
  );

  String get formattedPrice => '${_formatNumber(monthlyPriceKrw)}원';

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  factory SubscriptionPricing.fromJson(Map<String, dynamic> json) {
    return SubscriptionPricing(
      monthlyPriceKrw: json['monthly_price_krw'] as int? ?? 4900,
      currency: json['currency'] as String? ?? 'KRW',
      billingCycle: json['billing_cycle'] as String? ?? 'monthly',
      trialDays: json['trial_days'] as int? ?? 0,
      autoRenewal: json['auto_renewal'] as bool? ?? true,
    );
  }
}
