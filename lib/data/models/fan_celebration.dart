/// Fan birthday/celebration registration per channel.
///
/// Privacy: Only month/day stored — no birth year.
/// Consent: Explicit toggle + timestamp.
class FanCelebration {
  final String id;
  final String userId;
  final String channelId;
  final int? birthMonth;
  final int? birthDay;
  final bool birthdayVisible;
  final DateTime? visibilityConsentAt;
  final DateTime subscriptionStartedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FanCelebration({
    required this.id,
    required this.userId,
    required this.channelId,
    this.birthMonth,
    this.birthDay,
    this.birthdayVisible = false,
    this.visibilityConsentAt,
    required this.subscriptionStartedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FanCelebration.fromJson(Map<String, dynamic> json) {
    return FanCelebration(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      channelId: json['channel_id'] as String,
      birthMonth: json['birth_month'] as int?,
      birthDay: json['birth_day'] as int?,
      birthdayVisible: json['birthday_visible'] as bool? ?? false,
      visibilityConsentAt: json['visibility_consent_at'] != null
          ? DateTime.parse(json['visibility_consent_at'] as String)
          : null,
      subscriptionStartedAt: json['subscription_started_at'] != null
          ? DateTime.parse(json['subscription_started_at'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'channel_id': channelId,
        'birth_month': birthMonth,
        'birth_day': birthDay,
        'birthday_visible': birthdayVisible,
        'visibility_consent_at': visibilityConsentAt?.toIso8601String(),
        'subscription_started_at': subscriptionStartedAt.toIso8601String(),
      };

  /// Whether the fan has registered a birthday.
  bool get hasBirthday => birthMonth != null && birthDay != null;

  /// Formatted birthday string (e.g., "3월 15일").
  String get birthdayLabel {
    if (!hasBirthday) return '미등록';
    return '$birthMonth월 $birthDay일';
  }

  FanCelebration copyWith({
    int? birthMonth,
    int? birthDay,
    bool? birthdayVisible,
    DateTime? visibilityConsentAt,
  }) {
    return FanCelebration(
      id: id,
      userId: userId,
      channelId: channelId,
      birthMonth: birthMonth ?? this.birthMonth,
      birthDay: birthDay ?? this.birthDay,
      birthdayVisible: birthdayVisible ?? this.birthdayVisible,
      visibilityConsentAt: visibilityConsentAt ?? this.visibilityConsentAt,
      subscriptionStartedAt: subscriptionStartedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
