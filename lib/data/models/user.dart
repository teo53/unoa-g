/// Unified User Models for UNO A
///
/// This file contains all user-related models:
/// - [UserAuthProfile]: Authentication and authorization data (from auth_provider)
/// - [UserDisplayProfile]: UI display data with subscription and wallet info
/// - [UserBase]: Common interface for all user types

/// Base user interface with common fields
abstract class UserBase {
  String get id;
  String? get displayName;
  String? get avatarUrl;
}

/// User profile for authentication and authorization
///
/// Contains role-based permissions, ban status, and other auth-related data.
/// Sourced from `user_profiles` table in database.
class UserAuthProfile implements UserBase {
  @override
  final String id;
  final String role;
  @override
  final String? displayName;
  @override
  final String? avatarUrl;
  final String? bio;
  final DateTime? dateOfBirth;
  final bool isBanned;
  final String locale;
  final DateTime createdAt;
  final DateTime? guardianConsentAt;
  final int themeColorIndex;
  final String? instagramLink;
  final String? youtubeLink;
  final String? tiktokLink;
  final String? twitterLink;

  const UserAuthProfile({
    required this.id,
    required this.role,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.dateOfBirth,
    this.isBanned = false,
    this.locale = 'ko-KR',
    required this.createdAt,
    this.guardianConsentAt,
    this.themeColorIndex = 0,
    this.instagramLink,
    this.youtubeLink,
    this.tiktokLink,
    this.twitterLink,
  });

  factory UserAuthProfile.fromJson(Map<String, dynamic> json) {
    return UserAuthProfile(
      id: json['id'] as String,
      role: json['role'] as String? ?? 'fan',
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      isBanned: json['is_banned'] as bool? ?? false,
      locale: json['locale'] as String? ?? 'ko-KR',
      createdAt: DateTime.parse(json['created_at'] as String),
      guardianConsentAt: json['guardian_consent_at'] != null
          ? DateTime.parse(json['guardian_consent_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'is_banned': isBanned,
      'locale': locale,
      'created_at': createdAt.toIso8601String(),
      'guardian_consent_at': guardianConsentAt?.toIso8601String(),
    };
  }

  // Role helpers
  bool get isFan => role == 'fan';
  bool get isCreator => role == 'creator';
  bool get isCreatorManager => role == 'creator_manager';
  bool get isAdmin => role == 'admin';

  // Age verification helpers
  int? get age {
    if (dateOfBirth == null) return null;
    return DateTime.now().difference(dateOfBirth!).inDays ~/ 365;
  }

  bool get isMinorUnder14 => (age ?? 100) < 14;
  bool get isMinorUnder19 => (age ?? 100) < 19;
  bool get hasGuardianConsent => guardianConsentAt != null;

  UserAuthProfile copyWith({
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? role,
    bool? isBanned,
    String? locale,
    DateTime? guardianConsentAt,
    int? themeColorIndex,
    String? instagramLink,
    String? youtubeLink,
    String? tiktokLink,
    String? twitterLink,
  }) {
    return UserAuthProfile(
      id: id,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth,
      isBanned: isBanned ?? this.isBanned,
      locale: locale ?? this.locale,
      createdAt: createdAt,
      guardianConsentAt: guardianConsentAt ?? this.guardianConsentAt,
      themeColorIndex: themeColorIndex ?? this.themeColorIndex,
      instagramLink: instagramLink ?? this.instagramLink,
      youtubeLink: youtubeLink ?? this.youtubeLink,
      tiktokLink: tiktokLink ?? this.tiktokLink,
      twitterLink: twitterLink ?? this.twitterLink,
    );
  }
}

/// User profile for UI display purposes
///
/// Contains subscription information, wallet balance, and tier data.
/// Used for displaying user cards, profiles, and subscription status.
class UserDisplayProfile implements UserBase {
  @override
  final String id;
  final String name;
  final String? englishName;
  final String username;
  @override
  final String? avatarUrl;
  final String tier; // STANDARD, VIP
  final int subscriptionCount;
  final int dtBalance;
  final DateTime? nextPaymentDate;

  const UserDisplayProfile({
    required this.id,
    required this.name,
    this.englishName,
    required this.username,
    this.avatarUrl,
    this.tier = 'STANDARD',
    this.subscriptionCount = 0,
    this.dtBalance = 0,
    this.nextPaymentDate,
  });

  @override
  String? get displayName => englishName != null ? '$name ($englishName)' : name;

  String get formattedBalance => '$dtBalance DT';

  String get tierBadge {
    switch (tier.toUpperCase()) {
      case 'VIP':
        return '💎 VIP';
      case 'STANDARD':
      default:
        return '⭐ STANDARD';
    }
  }

  factory UserDisplayProfile.fromJson(Map<String, dynamic> json) {
    return UserDisplayProfile(
      id: json['id'] as String,
      name: json['display_name'] as String? ?? json['name'] as String? ?? 'User',
      englishName: json['english_name'] as String?,
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      tier: json['tier'] as String? ?? 'STANDARD',
      subscriptionCount: json['subscription_count'] as int? ?? 0,
      dtBalance: json['dt_balance'] as int? ?? 0,
      nextPaymentDate: json['next_payment_date'] != null
          ? DateTime.parse(json['next_payment_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': name,
      'english_name': englishName,
      'username': username,
      'avatar_url': avatarUrl,
      'tier': tier,
      'subscription_count': subscriptionCount,
      'dt_balance': dtBalance,
      'next_payment_date': nextPaymentDate?.toIso8601String(),
    };
  }

  UserDisplayProfile copyWith({
    String? id,
    String? name,
    String? englishName,
    String? username,
    String? avatarUrl,
    String? tier,
    int? subscriptionCount,
    int? dtBalance,
    DateTime? nextPaymentDate,
  }) {
    return UserDisplayProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      englishName: englishName ?? this.englishName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      tier: tier ?? this.tier,
      subscriptionCount: subscriptionCount ?? this.subscriptionCount,
      dtBalance: dtBalance ?? this.dtBalance,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
    );
  }
}

/// Convert between user profile types
extension UserProfileConversion on UserAuthProfile {
  /// Create a display profile from auth profile (with default values for UI fields)
  UserDisplayProfile toDisplayProfile({
    String? username,
    String? tier,
    int subscriptionCount = 0,
    int dtBalance = 0,
    DateTime? nextPaymentDate,
  }) {
    return UserDisplayProfile(
      id: id,
      name: displayName ?? 'User',
      username: username ?? '',
      avatarUrl: avatarUrl,
      tier: tier ?? 'STANDARD',
      subscriptionCount: subscriptionCount,
      dtBalance: dtBalance,
      nextPaymentDate: nextPaymentDate,
    );
  }
}
