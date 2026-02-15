import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';

/// User profile model
class UserProfile {
  final String id;
  final String role; // 'fan', 'creator', 'creator_manager', 'admin'
  final String? displayName;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final DateTime? guardianConsentAt;
  final String locale;
  final bool isBanned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.role,
    this.displayName,
    this.avatarUrl,
    this.dateOfBirth,
    this.guardianConsentAt,
    this.locale = 'ko-KR',
    this.isBanned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isFan => role == 'fan';
  bool get isCreator => role == 'creator';
  bool get isCreatorManager => role == 'creator_manager';
  bool get isAdmin => role == 'admin';

  int? get age {
    if (dateOfBirth == null) return null;
    return DateTime.now().difference(dateOfBirth!).inDays ~/ 365;
  }

  bool get isMinor => age != null && age! < 19;
  bool get needsGuardianConsent => isMinor && guardianConsentAt == null;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      role: json['role'] as String? ?? 'fan',
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      guardianConsentAt: json['guardian_consent_at'] != null
          ? DateTime.parse(json['guardian_consent_at'] as String)
          : null,
      locale: json['locale'] as String? ?? 'ko-KR',
      isBanned: json['is_banned'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'guardian_consent_at': guardianConsentAt?.toIso8601String(),
      'locale': locale,
      'is_banned': isBanned,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? role,
    String? displayName,
    String? avatarUrl,
    DateTime? dateOfBirth,
    DateTime? guardianConsentAt,
    String? locale,
    bool? isBanned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      guardianConsentAt: guardianConsentAt ?? this.guardianConsentAt,
      locale: locale ?? this.locale,
      isBanned: isBanned ?? this.isBanned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Creator profile model
class CreatorProfile {
  final String id;
  final String userId;
  final String? channelId;
  final String stageName;
  final List<String> categories;
  final Map<String, dynamic> socialLinks;
  final String? bankCode;
  final String? bankAccountLast4;
  final String? accountHolderName;
  final double withholdingTaxRate;
  final bool payoutVerified;
  final int totalSubscribers;
  final int totalRevenueKrw;
  final DateTime createdAt;

  const CreatorProfile({
    required this.id,
    required this.userId,
    this.channelId,
    required this.stageName,
    this.categories = const [],
    this.socialLinks = const {},
    this.bankCode,
    this.bankAccountLast4,
    this.accountHolderName,
    this.withholdingTaxRate = 0.033,
    this.payoutVerified = false,
    this.totalSubscribers = 0,
    this.totalRevenueKrw = 0,
    required this.createdAt,
  });

  bool get canReceivePayout => payoutVerified && bankCode != null;

  factory CreatorProfile.fromJson(Map<String, dynamic> json) {
    return CreatorProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      channelId: json['channel_id'] as String?,
      stageName: json['stage_name'] as String,
      categories: List<String>.from(json['categories'] ?? []),
      socialLinks: Map<String, dynamic>.from(json['social_links'] ?? {}),
      bankCode: json['bank_code'] as String?,
      bankAccountLast4: json['bank_account_last4'] as String?,
      accountHolderName: json['account_holder_name'] as String?,
      withholdingTaxRate:
          (json['withholding_tax_rate'] as num?)?.toDouble() ?? 0.033,
      payoutVerified: json['payout_verified'] as bool? ?? false,
      totalSubscribers: json['total_subscribers'] as int? ?? 0,
      totalRevenueKrw: json['total_revenue_krw'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'channel_id': channelId,
      'stage_name': stageName,
      'categories': categories,
      'social_links': socialLinks,
      'bank_code': bankCode,
      'bank_account_last4': bankAccountLast4,
      'account_holder_name': accountHolderName,
      'withholding_tax_rate': withholdingTaxRate,
      'payout_verified': payoutVerified,
      'total_subscribers': totalSubscribers,
      'total_revenue_krw': totalRevenueKrw,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Creator settings model
class CreatorSettings {
  final String creatorId;
  final String roomType; // 'broadcast_only', 'limited', 'open'
  final int fanDailyLimit;
  final int paidReplyPriceDt;
  final String welcomeMessage;
  final String? welcomeMediaUrl;
  final bool autoWelcomeEnabled;
  final DateTime createdAt;

  const CreatorSettings({
    required this.creatorId,
    this.roomType = 'limited',
    this.fanDailyLimit = 3,
    this.paidReplyPriceDt = 10,
    this.welcomeMessage = '안녕하세요! 제 채널에 오신 것을 환영합니다.',
    this.welcomeMediaUrl,
    this.autoWelcomeEnabled = true,
    required this.createdAt,
  });

  bool get isBroadcastOnly => roomType == 'broadcast_only';
  bool get isLimited => roomType == 'limited';
  bool get isOpen => roomType == 'open';

  factory CreatorSettings.fromJson(Map<String, dynamic> json) {
    return CreatorSettings(
      creatorId: json['creator_id'] as String,
      roomType: json['room_type'] as String? ?? 'limited',
      fanDailyLimit: json['fan_daily_limit'] as int? ?? 3,
      paidReplyPriceDt: json['paid_reply_price_dt'] as int? ?? 10,
      welcomeMessage:
          json['welcome_message'] as String? ?? '안녕하세요! 제 채널에 오신 것을 환영합니다.',
      welcomeMediaUrl: json['welcome_media_url'] as String?,
      autoWelcomeEnabled: json['auto_welcome_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'creator_id': creatorId,
      'room_type': roomType,
      'fan_daily_limit': fanDailyLimit,
      'paid_reply_price_dt': paidReplyPriceDt,
      'welcome_message': welcomeMessage,
      'welcome_media_url': welcomeMediaUrl,
      'auto_welcome_enabled': autoWelcomeEnabled,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Supabase Profile Repository
class SupabaseProfileRepository {
  final SupabaseClient _supabase;

  SupabaseProfileRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseConfig.client;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    return user.id;
  }

  // ============================================
  // User Profiles
  // ============================================

  /// Get current user's profile
  Future<UserProfile?> getCurrentProfile() async {
    final response = await _supabase
        .from('user_profiles')
        .select()
        .eq('id', _currentUserId)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  /// Get a user profile by ID
  Future<UserProfile?> getProfile(String userId) async {
    final response = await _supabase
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  /// Update user profile
  Future<UserProfile> updateProfile({
    String? displayName,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? locale,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (displayName != null) updates['display_name'] = displayName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (dateOfBirth != null) {
      updates['date_of_birth'] = dateOfBirth.toIso8601String().split('T')[0];
    }
    if (locale != null) updates['locale'] = locale;

    final response = await _supabase
        .from('user_profiles')
        .update(updates)
        .eq('id', _currentUserId)
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  /// Record guardian consent for minors
  Future<UserProfile> recordGuardianConsent() async {
    final response = await _supabase
        .from('user_profiles')
        .update({
          'guardian_consent_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', _currentUserId)
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  /// Upload avatar image and update profile
  Future<String> uploadAvatar(List<int> imageBytes, String fileName) async {
    final path = 'avatars/$_currentUserId/$fileName';

    await _supabase.storage
        .from('user-content')
        .uploadBinary(path, imageBytes as dynamic);

    // TODO: Phase B — user-content 버킷 private 전환 시 signed URL 적용
    final url = _supabase.storage.from('user-content').getPublicUrl(path);

    await updateProfile(avatarUrl: url);

    return url;
  }

  // ============================================
  // Creator Profiles
  // ============================================

  /// Get current user's creator profile
  Future<CreatorProfile?> getCreatorProfile() async {
    final response = await _supabase
        .from('creator_profiles')
        .select()
        .eq('user_id', _currentUserId)
        .maybeSingle();

    if (response == null) return null;
    return CreatorProfile.fromJson(response);
  }

  /// Get creator profile by user ID
  Future<CreatorProfile?> getCreatorProfileByUserId(String userId) async {
    final response = await _supabase
        .from('creator_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return CreatorProfile.fromJson(response);
  }

  /// Create creator profile (upgrade from fan to creator)
  Future<CreatorProfile> createCreatorProfile({
    required String stageName,
    List<String> categories = const [],
    Map<String, dynamic> socialLinks = const {},
  }) async {
    // First update user role to creator
    await _supabase.from('user_profiles').update({
      'role': 'creator',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _currentUserId);

    // Create creator profile
    final response = await _supabase
        .from('creator_profiles')
        .insert({
          'user_id': _currentUserId,
          'stage_name': stageName,
          'categories': categories,
          'social_links': socialLinks,
        })
        .select()
        .single();

    final profile = CreatorProfile.fromJson(response);

    // Create channel for this creator
    await _supabase.from('channels').insert({
      'artist_id': _currentUserId,
      'name': stageName,
    });

    return profile;
  }

  /// Update creator profile
  Future<CreatorProfile> updateCreatorProfile({
    String? stageName,
    List<String>? categories,
    Map<String, dynamic>? socialLinks,
  }) async {
    final updates = <String, dynamic>{};

    if (stageName != null) updates['stage_name'] = stageName;
    if (categories != null) updates['categories'] = categories;
    if (socialLinks != null) updates['social_links'] = socialLinks;

    if (updates.isEmpty) {
      final current = await getCreatorProfile();
      if (current == null) throw StateError('Creator profile not found');
      return current;
    }

    final response = await _supabase
        .from('creator_profiles')
        .update(updates)
        .eq('user_id', _currentUserId)
        .select()
        .single();

    return CreatorProfile.fromJson(response);
  }

  /// Setup payout info for creator
  Future<CreatorProfile> setupPayoutInfo({
    required String bankCode,
    required String bankAccountNumber,
    required String accountHolderName,
  }) async {
    // In production, encrypt bank account number before storing
    final last4 = bankAccountNumber.length >= 4
        ? bankAccountNumber.substring(bankAccountNumber.length - 4)
        : bankAccountNumber;

    final response = await _supabase
        .from('creator_profiles')
        .update({
          'bank_code': bankCode,
          'bank_account_last4': last4,
          'account_holder_name': accountHolderName,
          // In production, store encrypted version:
          // 'bank_account_encrypted': encryptedAccountNumber,
        })
        .eq('user_id', _currentUserId)
        .select()
        .single();

    return CreatorProfile.fromJson(response);
  }

  // ============================================
  // Creator Settings
  // ============================================

  /// Get creator settings
  Future<CreatorSettings?> getCreatorSettings() async {
    final response = await _supabase
        .from('creator_settings')
        .select()
        .eq('creator_id', _currentUserId)
        .maybeSingle();

    if (response == null) return null;
    return CreatorSettings.fromJson(response);
  }

  /// Update creator settings
  Future<CreatorSettings> updateCreatorSettings({
    String? roomType,
    int? fanDailyLimit,
    int? paidReplyPriceDt,
    String? welcomeMessage,
    String? welcomeMediaUrl,
    bool? autoWelcomeEnabled,
  }) async {
    final updates = <String, dynamic>{};

    if (roomType != null) updates['room_type'] = roomType;
    if (fanDailyLimit != null) updates['fan_daily_limit'] = fanDailyLimit;
    if (paidReplyPriceDt != null) {
      updates['paid_reply_price_dt'] = paidReplyPriceDt;
    }
    if (welcomeMessage != null) updates['welcome_message'] = welcomeMessage;
    if (welcomeMediaUrl != null) updates['welcome_media_url'] = welcomeMediaUrl;
    if (autoWelcomeEnabled != null) {
      updates['auto_welcome_enabled'] = autoWelcomeEnabled;
    }

    final response = await _supabase
        .from('creator_settings')
        .upsert({
          'creator_id': _currentUserId,
          ...updates,
        })
        .select()
        .single();

    return CreatorSettings.fromJson(response);
  }

  // ============================================
  // Creator Managers
  // ============================================

  /// Add a manager to creator account
  Future<void> addManager(String managerUserId) async {
    // Get creator profile
    final creator = await getCreatorProfile();
    if (creator == null) throw StateError('Creator profile not found');

    await _supabase.from('creator_managers').insert({
      'creator_id': _currentUserId,
      'manager_id': managerUserId,
      'permissions': {
        'can_send_broadcast': true,
        'can_reply': true,
        'can_view_analytics': true,
        'can_manage_settings': false,
      },
    });

    // Update manager's role
    await _supabase.from('user_profiles').update({
      'role': 'creator_manager',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', managerUserId);
  }

  /// Remove a manager from creator account
  Future<void> removeManager(String managerUserId) async {
    await _supabase
        .from('creator_managers')
        .delete()
        .eq('creator_id', _currentUserId)
        .eq('manager_id', managerUserId);

    // Check if manager has other creator assignments
    final otherAssignments = await _supabase
        .from('creator_managers')
        .select('id')
        .eq('manager_id', managerUserId);

    if (otherAssignments.isEmpty) {
      // Downgrade to fan if no other assignments
      await _supabase.from('user_profiles').update({
        'role': 'fan',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', managerUserId);
    }
  }

  /// Get all managers for current creator
  Future<List<Map<String, dynamic>>> getManagers() async {
    final response = await _supabase.from('creator_managers').select('''
          *,
          user_profiles!manager_id (
            display_name,
            avatar_url
          )
        ''').eq('creator_id', _currentUserId);

    return List<Map<String, dynamic>>.from(response);
  }
}
