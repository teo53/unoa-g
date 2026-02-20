import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/demo_config.dart';
import '../core/supabase/supabase_client.dart';
import '../core/utils/app_logger.dart';
import 'auth_provider.dart';
import 'repository_providers.dart';

// ============================================================================
// Models
// ============================================================================

/// F-P1-5: Safe DateTime parsing with null fallback
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  try {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed == null) {
        AppLogger.warning(
          'Failed to parse DateTime from string: "$value"',
          tag: 'FundingProvider',
        );
      }
      return parsed;
    }
    return null;
  } catch (e) {
    AppLogger.warning(
      'Exception parsing DateTime: $value, error: $e',
      tag: 'FundingProvider',
    );
    return null;
  }
}

/// Campaign status enum
enum CampaignStatus {
  draft,
  active,
  paused,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case CampaignStatus.draft:
        return '준비중';
      case CampaignStatus.active:
        return '진행중';
      case CampaignStatus.paused:
        return '일시정지';
      case CampaignStatus.completed:
        return '종료';
      case CampaignStatus.cancelled:
        return '취소됨';
    }
  }

  String get value {
    switch (this) {
      case CampaignStatus.draft:
        return 'draft';
      case CampaignStatus.active:
        return 'active';
      case CampaignStatus.paused:
        return 'paused';
      case CampaignStatus.completed:
        return 'completed';
      case CampaignStatus.cancelled:
        return 'cancelled';
    }
  }

  static CampaignStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return CampaignStatus.draft;
      case 'active':
        return CampaignStatus.active;
      case 'paused':
        return CampaignStatus.paused;
      case 'completed':
        return CampaignStatus.completed;
      case 'cancelled':
        return CampaignStatus.cancelled;
      default:
        return CampaignStatus.draft;
    }
  }
}

/// Funding campaign model
class Campaign {
  final String id;
  final String? creatorId;
  final String title;
  final String? subtitle;
  final String? description;
  final String? category;
  final String? coverImageUrl;
  final CampaignStatus status;
  final int goalAmountKrw;
  final int currentAmountKrw;
  final double fundingPercent;
  final int backerCount;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? targetArtist;
  final List<String> detailImages;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Campaign({
    required this.id,
    this.creatorId,
    required this.title,
    this.subtitle,
    this.description,
    this.category,
    this.coverImageUrl,
    this.status = CampaignStatus.draft,
    this.goalAmountKrw = 0,
    this.currentAmountKrw = 0,
    this.fundingPercent = 0,
    this.backerCount = 0,
    this.startAt,
    this.endAt,
    this.targetArtist,
    this.detailImages = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    final goalAmount = (json['goal_amount_krw'] as num?)?.toInt() ?? 0;
    final currentAmount = (json['current_amount_krw'] as num?)?.toInt() ?? 0;
    final percent = json['funding_percent'] != null
        ? (json['funding_percent'] as num).toDouble()
        : (goalAmount > 0 ? (currentAmount / goalAmount * 100) : 0.0);

    return Campaign(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String?,
      title: json['title'] as String? ?? '제목 없음',
      subtitle: json['subtitle'] as String?,
      description: json['description_md'] ?? json['description'] as String?,
      category: json['category'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      status: CampaignStatus.fromString(json['status'] as String? ?? 'draft'),
      goalAmountKrw: goalAmount,
      currentAmountKrw: currentAmount,
      fundingPercent: percent,
      backerCount: (json['backer_count'] as num?)?.toInt() ?? 0,
      startAt: _parseDateTime(json['start_at']),
      endAt: _parseDateTime(json['end_at']),
      targetArtist: json['target_artist'] as String?,
      detailImages: json['detail_images'] != null
          ? List<String>.from(json['detail_images'] as List)
          : const [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'title': title,
      'subtitle': subtitle,
      'description_md': description,
      'category': category,
      'cover_image_url': coverImageUrl,
      'status': status.value,
      'goal_amount_krw': goalAmountKrw,
      'current_amount_krw': currentAmountKrw,
      'funding_percent': fundingPercent,
      'backer_count': backerCount,
      'start_at': startAt?.toIso8601String(),
      'end_at': endAt?.toIso8601String(),
      'target_artist': targetArtist,
      'detail_images': detailImages,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  int get daysLeft {
    // F-P1-5: Null-safe endAt handling
    if (endAt == null) {
      AppLogger.debug(
        'Campaign $id has null endAt, returning 0 daysLeft',
        tag: 'Campaign',
      );
      return 0;
    }
    final diff = endAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get isEnded =>
      (endAt != null && endAt!.isBefore(DateTime.now())) ||
      status == CampaignStatus.completed;
  bool get isActive => status == CampaignStatus.active && !isEnded;
  bool get isDraft => status == CampaignStatus.draft;
  bool get isSuccessful => fundingPercent >= 100;

  Campaign copyWith({
    String? title,
    String? subtitle,
    String? description,
    String? category,
    String? coverImageUrl,
    CampaignStatus? status,
    int? goalAmountKrw,
    int? currentAmountKrw,
    double? fundingPercent,
    int? backerCount,
    DateTime? startAt,
    DateTime? endAt,
    String? targetArtist,
    List<String>? detailImages,
  }) {
    return Campaign(
      id: id,
      creatorId: creatorId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      category: category ?? this.category,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      status: status ?? this.status,
      goalAmountKrw: goalAmountKrw ?? this.goalAmountKrw,
      currentAmountKrw: currentAmountKrw ?? this.currentAmountKrw,
      fundingPercent: fundingPercent ?? this.fundingPercent,
      backerCount: backerCount ?? this.backerCount,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      targetArtist: targetArtist ?? this.targetArtist,
      detailImages: detailImages ?? this.detailImages,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Reward tier model
class RewardTier {
  final String id;
  final String campaignId;
  final String title;
  final String? description;
  final int priceKrw;
  final int? totalQuantity;
  final int? remainingQuantity;
  final int pledgeCount;
  final int displayOrder;
  final bool isActive;
  final bool isFeatured;

  const RewardTier({
    required this.id,
    required this.campaignId,
    required this.title,
    this.description,
    required this.priceKrw,
    this.totalQuantity,
    this.remainingQuantity,
    this.pledgeCount = 0,
    this.displayOrder = 0,
    this.isActive = true,
    this.isFeatured = false,
  });

  factory RewardTier.fromJson(Map<String, dynamic> json) {
    return RewardTier(
      id: json['id'] as String,
      campaignId: json['campaign_id'] as String,
      title: json['title'] as String? ?? '리워드',
      description: json['description'] as String?,
      priceKrw: (json['price_krw'] as num?)?.toInt() ?? 0,
      totalQuantity: (json['total_quantity'] as num?)?.toInt(),
      remainingQuantity: (json['remaining_quantity'] as num?)?.toInt(),
      pledgeCount: (json['pledge_count'] as num?)?.toInt() ?? 0,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'campaign_id': campaignId,
      'title': title,
      'description': description,
      'price_krw': priceKrw,
      'total_quantity': totalQuantity,
      'remaining_quantity': remainingQuantity,
      'pledge_count': pledgeCount,
      'display_order': displayOrder,
      'is_active': isActive,
      'is_featured': isFeatured,
    };
  }

  bool get isSoldOut => totalQuantity != null && (remainingQuantity ?? 0) <= 0;
}

/// Pledge model
class Pledge {
  final String id;
  final String campaignId;
  final String userId;
  final String tierId;
  final String? tierTitle;
  final String? campaignTitle;
  final int amountKrw;
  final bool isAnonymous;
  final String? supportMessage;
  final String status;
  final DateTime createdAt;

  const Pledge({
    required this.id,
    required this.campaignId,
    required this.userId,
    required this.tierId,
    this.tierTitle,
    this.campaignTitle,
    required this.amountKrw,
    this.isAnonymous = false,
    this.supportMessage,
    this.status = 'active',
    required this.createdAt,
  });

  int get totalAmount => amountKrw;
}

/// Backer model (for creator's backer list)
class Backer {
  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String tierTitle;
  final int amountKrw;
  final bool isAnonymous;
  final String? supportMessage;
  final DateTime createdAt;

  const Backer({
    required this.id,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.tierTitle,
    required this.amountKrw,
    this.isAnonymous = false,
    this.supportMessage,
    required this.createdAt,
  });
}

/// Campaign stats model
class CampaignStats {
  final int totalBackers;
  final int totalRaisedKrw;
  final double fundingPercent;
  final int daysLeft;
  final int avgPledgeKrw;
  final Map<String, int> tierDistribution;
  final List<DailyFundingData> dailyData;

  const CampaignStats({
    required this.totalBackers,
    required this.totalRaisedKrw,
    required this.fundingPercent,
    required this.daysLeft,
    required this.avgPledgeKrw,
    required this.tierDistribution,
    required this.dailyData,
  });
}

class DailyFundingData {
  final DateTime date;
  final int amount;
  final int backerCount;

  const DailyFundingData({
    required this.date,
    required this.amount,
    required this.backerCount,
  });
}

// ============================================================================
// State
// ============================================================================

/// Funding state
class FundingState {
  final List<Campaign> allCampaigns;
  final List<Campaign> myCampaigns;
  final List<Pledge> myPledges;
  final int demoWalletBalance;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const FundingState({
    this.allCampaigns = const [],
    this.myCampaigns = const [],
    this.myPledges = const [],
    this.demoWalletBalance = 500000,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  /// Filter by search query
  List<Campaign> _applySearch(List<Campaign> campaigns) {
    if (searchQuery.isEmpty) return campaigns;
    final q = searchQuery.toLowerCase();
    return campaigns
        .where((c) =>
            c.title.toLowerCase().contains(q) ||
            (c.subtitle?.toLowerCase().contains(q) ?? false) ||
            (c.category?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  /// Explore campaigns (all active, not mine)
  List<Campaign> get exploreCampaigns => _applySearch(
      allCampaigns.where((c) => c.status == CampaignStatus.active).toList());

  /// My active campaigns (includes paused - they show in 진행중 tab)
  List<Campaign> get myActiveCampaigns => myCampaigns
      .where((c) =>
          c.status == CampaignStatus.active ||
          c.status == CampaignStatus.paused)
      .toList();

  /// My draft campaigns
  List<Campaign> get myDraftCampaigns =>
      myCampaigns.where((c) => c.status == CampaignStatus.draft).toList();

  /// My ended campaigns
  List<Campaign> get myEndedCampaigns => myCampaigns
      .where((c) =>
          c.status == CampaignStatus.completed ||
          c.status == CampaignStatus.cancelled)
      .toList();

  /// Ending soon campaigns (3 days or less)
  List<Campaign> get endingSoonCampaigns => exploreCampaigns
      .where((c) => c.daysLeft <= 3 && c.daysLeft >= 0)
      .toList();

  /// Popular campaigns (sorted by backer count)
  List<Campaign> get popularCampaigns {
    final sorted = List<Campaign>.from(exploreCampaigns);
    sorted.sort((a, b) => b.backerCount.compareTo(a.backerCount));
    return sorted;
  }

  /// New campaigns (sorted by created date)
  List<Campaign> get newCampaigns {
    final sorted = List<Campaign>.from(exploreCampaigns);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Summary stats for creator dashboard
  int get totalActiveCampaigns => myActiveCampaigns.length;
  int get totalBackers => myCampaigns.fold(0, (sum, c) => sum + c.backerCount);
  int get totalRaisedKrw =>
      myCampaigns.fold(0, (sum, c) => sum + c.currentAmountKrw);

  FundingState copyWith({
    List<Campaign>? allCampaigns,
    List<Campaign>? myCampaigns,
    List<Pledge>? myPledges,
    int? demoWalletBalance,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return FundingState(
      allCampaigns: allCampaigns ?? this.allCampaigns,
      myCampaigns: myCampaigns ?? this.myCampaigns,
      myPledges: myPledges ?? this.myPledges,
      demoWalletBalance: demoWalletBalance ?? this.demoWalletBalance,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ============================================================================
// Notifier
// ============================================================================

class FundingNotifier extends StateNotifier<FundingState> {
  final Ref _ref;

  FundingNotifier(this._ref) : super(const FundingState()) {
    _initialize();
  }

  void _initialize() {
    final isDemoMode = _ref.read(isDemoModeProvider);
    if (isDemoMode) {
      _loadDemoData();
    } else {
      _loadRealData();
    }

    // Listen to auth changes
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthDemoMode) {
        _loadDemoData();
      } else if (next is AuthAuthenticated) {
        _loadRealData();
      } else {
        state = const FundingState();
      }
    });
  }

  // ========== Demo Data ==========

  void _loadDemoData() {
    final now = DateTime.now();

    final exploreCampaigns = [
      Campaign(
        id: 'demo_campaign_1',
        creatorId: 'creator_minji',
        title: '김민지 1st 미니앨범 "Butterfly" 펀딩',
        subtitle: '데뷔 1주년 기념 스페셜 앨범',
        description: '''안녕하세요, 김민지입니다! 💕

데뷔 1주년을 맞아 첫 번째 미니앨범 "Butterfly"를 준비하게 되었어요.

이번 앨범에는 제가 직접 작사에 참여한 곡들도 수록될 예정이에요. 팬 여러분들께 드리고 싶은 이야기들을 담았습니다.

**앨범 구성**
- 타이틀곡 "Butterfly"
- 수록곡 4곡
- 팬을 위한 히든 트랙

**펀딩 목표**
이번 펀딩을 통해 더 높은 퀄리티의 앨범과 뮤직비디오를 제작하고 싶어요!

팬 여러분의 응원이 큰 힘이 됩니다. 사랑해요! 🦋''',
        category: '앨범',
        coverImageUrl: 'https://picsum.photos/seed/funding1/800/450',
        status: CampaignStatus.active,
        goalAmountKrw: 50000000,
        currentAmountKrw: 42350000,
        fundingPercent: 84.7,
        backerCount: 1523,
        endAt: now.add(const Duration(days: 12)),
        createdAt: now.subtract(const Duration(days: 18)),
      ),
      Campaign(
        id: 'demo_campaign_2',
        creatorId: 'creator_junho',
        title: '이준호 팬미팅 "With You" 개최 프로젝트',
        subtitle: '팬들과 함께하는 특별한 시간',
        description: '''팬 여러분, 안녕하세요! 이준호입니다.

팬미팅 "With You"에 여러분을 초대합니다!

**행사 내용**
- 토크 세션
- 미니 콘서트
- 팬 사인회
- 게임 타임
- 특별 선물 증정

**일시 및 장소**
목표 달성 시 서울 코엑스 아티움에서 개최 예정입니다.

함께해주세요! ❤️''',
        category: '팬미팅',
        coverImageUrl: 'https://picsum.photos/seed/funding2/800/450',
        status: CampaignStatus.active,
        goalAmountKrw: 30000000,
        currentAmountKrw: 38500000,
        fundingPercent: 128.3,
        backerCount: 2891,
        endAt: now.add(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 28)),
      ),
      Campaign(
        id: 'demo_campaign_3',
        creatorId: 'creator_seoyeon',
        title: '박서연 화보집 "BLOOM" 제작',
        subtitle: '봄을 닮은 청순 콘셉트',
        description: '''첫 화보집 "BLOOM"을 준비합니다! 🌸

봄을 콘셉트로 한 다양한 모습을 담았어요.

**화보집 구성**
- 100페이지 이상 분량
- 청순/걸리시/시크 3가지 콘셉트
- 미공개 셀카 포함
- 친필 사인 가능 (VIP 티어)

많은 관심 부탁드려요!''',
        category: '화보집',
        coverImageUrl: 'https://picsum.photos/seed/funding3/800/450',
        status: CampaignStatus.active,
        goalAmountKrw: 20000000,
        currentAmountKrw: 15200000,
        fundingPercent: 76.0,
        backerCount: 847,
        endAt: now.add(const Duration(days: 25)),
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Campaign(
        id: 'demo_campaign_4',
        creatorId: 'creator_nova',
        title: 'NOVA 그룹 콘서트 굿즈 제작',
        subtitle: '월드투어 기념 한정판',
        description: '''NOVA 첫 월드투어 기념 한정판 굿즈!

**굿즈 라인업**
- 응원봉 (새 버전)
- 포토북
- 아크릴 스탠드
- 포토카드 세트
- 포스터

모든 굿즈는 투어 한정 디자인입니다!''',
        category: '굿즈',
        coverImageUrl: 'https://picsum.photos/seed/funding4/800/450',
        status: CampaignStatus.active,
        goalAmountKrw: 100000000,
        currentAmountKrw: 89000000,
        fundingPercent: 89.0,
        backerCount: 4521,
        endAt: now.add(const Duration(days: 7)),
        createdAt: now.subtract(const Duration(days: 23)),
      ),
      Campaign(
        id: 'demo_campaign_5',
        creatorId: 'creator_yuna',
        title: '최유나 생일 서포트 펀딩',
        subtitle: '팬들의 마음을 담은 생일 선물',
        description: '''최유나님의 생일을 축하합니다! 🎂

팬들의 마음을 모아 특별한 생일 선물을 준비하고자 합니다.

**서포트 내용**
- 지하철 광고 (강남역)
- 카페 컵홀더 이벤트
- LED 전광판 축하 영상
- 생일 케이크 및 꽃다발

함께 축하해주세요!''',
        category: '서포트',
        coverImageUrl: 'https://picsum.photos/seed/funding5/800/450',
        status: CampaignStatus.active,
        goalAmountKrw: 10000000,
        currentAmountKrw: 12500000,
        fundingPercent: 125.0,
        backerCount: 632,
        endAt: now.add(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 14)),
      ),
    ];

    final myCampaigns = [
      Campaign(
        id: 'demo_my_campaign_1',
        creatorId: DemoConfig.demoCreatorId,
        title: '나의 첫 미니앨범 "Dream" 제작 펀딩',
        subtitle: '팬 여러분과 함께 만드는 앨범',
        description: '팬 여러분과 함께 만드는 첫 앨범입니다.',
        category: '앨범',
        coverImageUrl: 'https://picsum.photos/seed/mycampaign1/800/450',
        status: CampaignStatus.active,
        goalAmountKrw: 30000000,
        currentAmountKrw: 18500000,
        fundingPercent: 61.7,
        backerCount: 892,
        endAt: now.add(const Duration(days: 15)),
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      Campaign(
        id: 'demo_my_campaign_draft',
        creatorId: DemoConfig.demoCreatorId,
        title: '새 콘서트 굿즈 제작 (준비중)',
        subtitle: '',
        category: '굿즈',
        status: CampaignStatus.draft,
        goalAmountKrw: 0,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Campaign(
        id: 'demo_my_campaign_ended',
        creatorId: DemoConfig.demoCreatorId,
        title: '팬미팅 "Together" 개최 펀딩',
        subtitle: '성공적으로 마감되었습니다!',
        description: '성공적으로 종료된 팬미팅 펀딩입니다.',
        category: '팬미팅',
        coverImageUrl: 'https://picsum.photos/seed/mycampaignended/800/450',
        status: CampaignStatus.completed,
        goalAmountKrw: 25000000,
        currentAmountKrw: 32000000,
        fundingPercent: 128.0,
        backerCount: 1245,
        endAt: now.subtract(const Duration(days: 10)),
        createdAt: now.subtract(const Duration(days: 40)),
      ),
    ];

    state = FundingState(
      allCampaigns: exploreCampaigns,
      myCampaigns: myCampaigns,
      demoWalletBalance: 500000,
    );
  }

  Future<void> _loadRealData() async {
    state = state.copyWith(isLoading: true);

    try {
      final client = SupabaseConfig.client;
      final userId = client.auth.currentUser?.id;

      // Load all active campaigns
      final allResponse = await client
          .from('funding_campaigns')
          .select('*')
          .eq('status', 'active')
          .order('end_at', ascending: true)
          .limit(50);

      final allCampaigns =
          (allResponse as List).map((json) => Campaign.fromJson(json)).toList();

      // Load my campaigns if creator
      List<Campaign> myCampaigns = [];
      List<Pledge> myPledges = [];
      if (userId != null) {
        final myResponse = await client
            .from('funding_campaigns')
            .select('*')
            .eq('creator_id', userId)
            .order('created_at', ascending: false);

        myCampaigns = (myResponse as List)
            .map((json) => Campaign.fromJson(json))
            .toList();

        // Load my pledges as a fan
        try {
          final repo = _ref.read(fundingRepositoryProvider);
          final pledgeData = await repo.getMyPledges();
          myPledges = pledgeData.map((json) {
            final tierData =
                json['funding_reward_tiers'] as Map<String, dynamic>?;
            final campaignData =
                json['funding_campaigns'] as Map<String, dynamic>?;
            return Pledge(
              id: json['id'] as String,
              campaignId: json['campaign_id'] as String,
              userId: json['user_id'] as String,
              tierId: json['tier_id'] as String? ?? '',
              tierTitle: tierData?['title'] as String?,
              campaignTitle: campaignData?['title'] as String?,
              amountKrw: (json['amount_krw'] as num?)?.toInt() ?? 0,
              isAnonymous: json['is_anonymous'] as bool? ?? false,
              supportMessage: json['support_message'] as String?,
              status: json['status'] as String? ?? 'paid',
              createdAt: json['created_at'] != null
                  ? DateTime.parse(json['created_at'] as String)
                  : DateTime.now(),
            );
          }).toList();
        } catch (e) {
          if (kDebugMode) debugPrint('[Funding] loadMyPledges error: $e');
        }
      }

      state = state.copyWith(
        allCampaigns: allCampaigns,
        myCampaigns: myCampaigns,
        myPledges: myPledges,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ========== CRUD Operations ==========

  /// Get tiers for a campaign
  Future<List<RewardTier>> getTiersForCampaign(String campaignId) async {
    final isDemoMode = _ref.read(isDemoModeProvider);

    if (isDemoMode || campaignId.startsWith('demo_')) {
      return _getDemoTiers(campaignId);
    }

    try {
      final repo = _ref.read(fundingRepositoryProvider);
      final data = await repo.getTiersForCampaign(campaignId);
      if (data.isEmpty) return _getDemoTiers(campaignId);
      return data.map((json) => RewardTier.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[Funding] getTiers error: $e');
      return _getDemoTiers(campaignId);
    }
  }

  /// Demo tiers fallback
  List<RewardTier> _getDemoTiers(String campaignId) {
    return [
      RewardTier(
        id: '${campaignId}_tier_1',
        campaignId: campaignId,
        title: '응원 참여',
        description: '펀딩 참여 인증서 (디지털)\n감사 메시지 (카카오톡)',
        priceKrw: 5000,
        pledgeCount: 423,
        displayOrder: 1,
      ),
      RewardTier(
        id: '${campaignId}_tier_2',
        campaignId: campaignId,
        title: '기본 리워드',
        description: '응원 참여 포함\n디지털 포토카드 5장\n팬명 크레딧 등재',
        priceKrw: 15000,
        totalQuantity: 1000,
        remainingQuantity: 347,
        pledgeCount: 653,
        displayOrder: 2,
        isFeatured: true,
      ),
      RewardTier(
        id: '${campaignId}_tier_3',
        campaignId: campaignId,
        title: '스페셜 리워드',
        description: '기본 리워드 포함\n실물 포토카드 세트\n사인 폴라로이드 1장 (랜덤)\n한정판 포스터',
        priceKrw: 50000,
        totalQuantity: 300,
        remainingQuantity: 89,
        pledgeCount: 211,
        displayOrder: 3,
      ),
      RewardTier(
        id: '${campaignId}_tier_4',
        campaignId: campaignId,
        title: 'VIP 리워드',
        description: '스페셜 리워드 포함\n영상 통화 팬사인회 참여권\n친필 사인 앨범\n프리미엄 굿즈 세트',
        priceKrw: 150000,
        totalQuantity: 50,
        remainingQuantity: 0,
        pledgeCount: 50,
        displayOrder: 4,
      ),
    ];
  }

  /// Get a campaign by ID
  Campaign? getCampaignById(String id) {
    try {
      return state.allCampaigns.firstWhere((c) => c.id == id);
    } catch (_) {
      try {
        return state.myCampaigns.firstWhere((c) => c.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  /// Create a new campaign (draft)
  Future<Campaign> createCampaign({
    required String title,
    String? subtitle,
    String? description,
    String? category,
    String? coverImageUrl,
    int goalAmountKrw = 0,
    DateTime? startAt,
    DateTime? endAt,
    String? targetArtist,
    List<String>? detailImages,
  }) async {
    final isDemoMode = _ref.read(isDemoModeProvider);

    if (isDemoMode) {
      final newCampaign = Campaign(
        id: 'demo_new_${DateTime.now().millisecondsSinceEpoch}',
        creatorId: DemoConfig.demoCreatorId,
        title: title,
        subtitle: subtitle,
        description: description,
        category: category,
        coverImageUrl: coverImageUrl,
        status: CampaignStatus.draft,
        goalAmountKrw: goalAmountKrw,
        startAt: startAt,
        endAt: endAt,
        targetArtist: targetArtist,
        detailImages: detailImages ?? const [],
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        myCampaigns: [newCampaign, ...state.myCampaigns],
      );

      return newCampaign;
    }

    // Real implementation
    final client = SupabaseConfig.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await client
        .from('funding_campaigns')
        .insert({
          'creator_id': userId,
          'title': title,
          'subtitle': subtitle,
          'description_md': description,
          'category': category,
          'cover_image_url': coverImageUrl,
          'status': 'draft',
          'goal_amount_krw': goalAmountKrw,
          'start_at': startAt?.toIso8601String(),
          'end_at': endAt?.toIso8601String(),
          'target_artist': targetArtist,
          'detail_images': detailImages,
        })
        .select()
        .single();

    final newCampaign = Campaign.fromJson(response);
    state = state.copyWith(
      myCampaigns: [newCampaign, ...state.myCampaigns],
    );
    return newCampaign;
  }

  /// Update an existing campaign
  Future<void> updateCampaign(
    String campaignId, {
    String? title,
    String? subtitle,
    String? description,
    String? category,
    String? coverImageUrl,
    int? goalAmountKrw,
    DateTime? startAt,
    DateTime? endAt,
    String? targetArtist,
    List<String>? detailImages,
  }) async {
    final isDemoMode = _ref.read(isDemoModeProvider);

    if (isDemoMode) {
      final updatedMyCampaigns = state.myCampaigns.map((c) {
        if (c.id == campaignId) {
          return c.copyWith(
            title: title,
            subtitle: subtitle,
            description: description,
            category: category,
            coverImageUrl: coverImageUrl,
            goalAmountKrw: goalAmountKrw,
            startAt: startAt,
            endAt: endAt,
            targetArtist: targetArtist,
            detailImages: detailImages,
          );
        }
        return c;
      }).toList();

      state = state.copyWith(myCampaigns: updatedMyCampaigns);
      return;
    }

    // Real implementation
    final client = SupabaseConfig.client;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (title != null) updates['title'] = title;
    if (subtitle != null) updates['subtitle'] = subtitle;
    if (description != null) updates['description_md'] = description;
    if (category != null) updates['category'] = category;
    if (coverImageUrl != null) updates['cover_image_url'] = coverImageUrl;
    if (goalAmountKrw != null) updates['goal_amount_krw'] = goalAmountKrw;
    if (startAt != null) updates['start_at'] = startAt.toIso8601String();
    if (endAt != null) updates['end_at'] = endAt.toIso8601String();
    if (targetArtist != null) updates['target_artist'] = targetArtist;
    if (detailImages != null) updates['detail_images'] = detailImages;

    await client.from('funding_campaigns').update(updates).eq('id', campaignId);

    await _loadRealData();
  }

  /// Start a draft campaign (change status to active)
  Future<void> startCampaign(String campaignId) async {
    final isDemoMode = _ref.read(isDemoModeProvider);

    if (isDemoMode) {
      final updatedMyCampaigns = state.myCampaigns.map((c) {
        if (c.id == campaignId) {
          return c.copyWith(
            status: CampaignStatus.active,
            startAt: DateTime.now(),
          );
        }
        return c;
      }).toList();

      state = state.copyWith(myCampaigns: updatedMyCampaigns);
      return;
    }

    final client = SupabaseConfig.client;
    await client.from('funding_campaigns').update({
      'status': 'active',
      'start_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', campaignId);

    await _loadRealData();
  }

  /// Pause an active campaign
  Future<void> pauseCampaign(String campaignId) async {
    final isDemoMode = _ref.read(isDemoModeProvider);

    if (isDemoMode) {
      final updatedMyCampaigns = state.myCampaigns.map((c) {
        if (c.id == campaignId) {
          return c.copyWith(status: CampaignStatus.paused);
        }
        return c;
      }).toList();

      state = state.copyWith(myCampaigns: updatedMyCampaigns);
      return;
    }

    final client = SupabaseConfig.client;
    await client.from('funding_campaigns').update({
      'status': 'paused',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', campaignId);

    await _loadRealData();
  }

  /// Resume a paused campaign
  Future<void> resumeCampaign(String campaignId) async {
    final isDemoMode = _ref.read(isDemoModeProvider);

    if (isDemoMode) {
      final updatedMyCampaigns = state.myCampaigns.map((c) {
        if (c.id == campaignId) {
          return c.copyWith(status: CampaignStatus.active);
        }
        return c;
      }).toList();

      state = state.copyWith(myCampaigns: updatedMyCampaigns);
      return;
    }

    final client = SupabaseConfig.client;
    await client.from('funding_campaigns').update({
      'status': 'active',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', campaignId);

    await _loadRealData();
  }

  /// Submit a pledge (fan supporting a campaign)
  Future<Pledge> submitPledge({
    required String campaignId,
    required String tierId,
    required int amountKrw,
    bool isAnonymous = false,
    String? supportMessage,
  }) async {
    final isDemoMode = _ref.read(isDemoModeProvider);

    if (isDemoMode) {
      // Check wallet balance
      if (state.demoWalletBalance < amountKrw) {
        throw Exception('잔액이 부족합니다');
      }

      final campaign = getCampaignById(campaignId);
      final tiers = _getDemoTiers(campaignId);
      final tier = tiers.where((t) => t.id == tierId).firstOrNull;

      final pledge = Pledge(
        id: 'demo_pledge_${DateTime.now().millisecondsSinceEpoch}',
        campaignId: campaignId,
        userId: 'demo_user_001',
        tierId: tierId,
        tierTitle: tier?.title,
        campaignTitle: campaign?.title,
        amountKrw: amountKrw,
        isAnonymous: isAnonymous,
        supportMessage: supportMessage,
        createdAt: DateTime.now(),
      );

      // Update campaign stats
      final updatedAll = state.allCampaigns.map((c) {
        if (c.id == campaignId) {
          final newAmount = c.currentAmountKrw + amountKrw;
          final newPercent =
              c.goalAmountKrw > 0 ? (newAmount / c.goalAmountKrw * 100) : 0.0;
          return c.copyWith(
            currentAmountKrw: newAmount,
            fundingPercent: newPercent,
            backerCount: c.backerCount + 1,
          );
        }
        return c;
      }).toList();

      state = state.copyWith(
        allCampaigns: updatedAll,
        myPledges: [pledge, ...state.myPledges],
        demoWalletBalance: state.demoWalletBalance - amountKrw,
      );

      return pledge;
    }

    // Real implementation — call atomic DB function via repository
    final repo = _ref.read(fundingRepositoryProvider);
    final result = await repo.submitPledge(
      campaignId: campaignId,
      tierId: tierId,
      amountKrw: amountKrw,
      isAnonymous: isAnonymous,
      supportMessage: supportMessage,
    );

    final pledgeId = result['pledge_id'] as String?;
    if (pledgeId == null) {
      throw Exception(result['error']?.toString() ?? '후원에 실패했습니다');
    }

    final client = SupabaseConfig.client;
    final pledge = Pledge(
      id: pledgeId,
      campaignId: campaignId,
      userId: client.auth.currentUser?.id ?? '',
      tierId: tierId,
      amountKrw: amountKrw,
      isAnonymous: isAnonymous,
      supportMessage: supportMessage,
      createdAt: DateTime.now(),
    );

    await _loadRealData();
    return pledge;
  }

  /// Save campaign as draft
  Future<Campaign> saveDraft({
    String? existingCampaignId,
    required String title,
    String? subtitle,
    String? description,
    String? category,
    String? coverImageUrl,
    int goalAmountKrw = 0,
    DateTime? startAt,
    DateTime? endAt,
    String? targetArtist,
    List<String>? detailImages,
  }) async {
    if (existingCampaignId != null) {
      await updateCampaign(
        existingCampaignId,
        title: title,
        subtitle: subtitle,
        description: description,
        category: category,
        coverImageUrl: coverImageUrl,
        goalAmountKrw: goalAmountKrw,
        startAt: startAt,
        endAt: endAt,
        targetArtist: targetArtist,
        detailImages: detailImages,
      );
      return getCampaignById(existingCampaignId)!;
    }

    return createCampaign(
      title: title,
      subtitle: subtitle,
      description: description,
      category: category,
      coverImageUrl: coverImageUrl,
      goalAmountKrw: goalAmountKrw,
      startAt: startAt,
      endAt: endAt,
      targetArtist: targetArtist,
      detailImages: detailImages,
    );
  }

  /// Submit campaign for review/activation
  Future<void> submitCampaign({
    String? existingCampaignId,
    required String title,
    String? subtitle,
    String? description,
    String? category,
    String? coverImageUrl,
    required int goalAmountKrw,
    DateTime? startAt,
    required DateTime endAt,
    String? targetArtist,
    List<String>? detailImages,
  }) async {
    final isDemoMode = _ref.read(isDemoModeProvider);

    if (existingCampaignId != null) {
      await updateCampaign(
        existingCampaignId,
        title: title,
        subtitle: subtitle,
        description: description,
        category: category,
        coverImageUrl: coverImageUrl,
        goalAmountKrw: goalAmountKrw,
        startAt: startAt,
        endAt: endAt,
        targetArtist: targetArtist,
        detailImages: detailImages,
      );

      if (isDemoMode) {
        await startCampaign(existingCampaignId);
      }
    } else {
      final campaign = await createCampaign(
        title: title,
        subtitle: subtitle,
        description: description,
        category: category,
        coverImageUrl: coverImageUrl,
        goalAmountKrw: goalAmountKrw,
        startAt: startAt,
        endAt: endAt,
        targetArtist: targetArtist,
        detailImages: detailImages,
      );

      if (isDemoMode) {
        await startCampaign(campaign.id);
      }
    }
  }

  /// Search campaigns
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Get backers for a campaign
  Future<List<Backer>> getBackersForCampaign(String campaignId) async {
    final isDemoMode = _ref.read(isDemoModeProvider);

    if (isDemoMode || campaignId.startsWith('demo_')) {
      return _getDemoBackers(campaignId);
    }

    try {
      final repo = _ref.read(fundingRepositoryProvider);
      final data = await repo.getBackersForCampaign(campaignId);
      if (data.isEmpty) return _getDemoBackers(campaignId);

      return data.map((json) {
        final tierData = json['funding_reward_tiers'] as Map<String, dynamic>?;
        final userData = json['user_profiles'] as Map<String, dynamic>?;
        final isAnon = json['is_anonymous'] as bool? ?? false;

        return Backer(
          id: json['id'] as String,
          userId: json['user_id'] as String,
          displayName:
              isAnon ? '익명' : (userData?['display_name'] as String? ?? '후원자'),
          avatarUrl: isAnon ? null : userData?['avatar_url'] as String?,
          tierTitle: tierData?['title'] as String? ?? '후원',
          amountKrw: (json['amount_krw'] as num?)?.toInt() ?? 0,
          isAnonymous: isAnon,
          supportMessage: json['support_message'] as String?,
          createdAt: json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[Funding] getBackers error: $e');
      return _getDemoBackers(campaignId);
    }
  }

  /// Demo backers fallback
  List<Backer> _getDemoBackers(String campaignId) {
    final campaign = getCampaignById(campaignId);
    if (campaign == null) return [];

    final now = DateTime.now();
    final demoNames = [
      '하늘별',
      '달빛소녀',
      '봄바람',
      '꿈나래',
      '은하수',
      '민트초코',
      '해바라기',
      '별빛가루',
      '달콤이',
      '뮤직러버',
      '핑크빛',
      '코코넛밀크',
      '블루오션',
      '스타라이트',
      '체리블라썸',
    ];
    final demoTiers = _getDemoTiers(campaignId);
    final messages = [
      '항상 응원합니다!',
      '최고의 아티스트! 화이팅!',
      '데뷔 때부터 팬이에요',
      null,
      '사랑해요! 꼭 성공하길 바랍니다',
      null,
      '팬미팅에서 만나요!',
      '앨범 너무 기대돼요!',
      null,
      '항상 행복하세요',
    ];

    final count = campaign.backerCount.clamp(0, 15);
    return List.generate(count, (i) {
      final tier = demoTiers[i % demoTiers.length];
      final isAnon = i % 7 == 3;
      return Backer(
        id: '${campaignId}_backer_$i',
        userId: 'user_$i',
        displayName: isAnon ? '익명' : demoNames[i % demoNames.length],
        tierTitle: tier.title,
        amountKrw: tier.priceKrw + (i % 3 == 0 ? 5000 : 0),
        isAnonymous: isAnon,
        supportMessage: messages[i % messages.length],
        createdAt: now.subtract(Duration(days: i, hours: i * 3)),
      );
    });
  }

  /// Get stats for a campaign
  Future<CampaignStats> getStatsForCampaign(String campaignId) async {
    final campaign = getCampaignById(campaignId);
    if (campaign == null) {
      return const CampaignStats(
        totalBackers: 0,
        totalRaisedKrw: 0,
        fundingPercent: 0,
        daysLeft: 0,
        avgPledgeKrw: 0,
        tierDistribution: {},
        dailyData: [],
      );
    }

    final isDemoMode = _ref.read(isDemoModeProvider);

    if (!isDemoMode && !campaignId.startsWith('demo_')) {
      try {
        final repo = _ref.read(fundingRepositoryProvider);
        final data = await repo.getStatsForCampaign(campaignId);

        // Build tier distribution from real data
        final tierDist = <String, int>{};
        final tierStats = data['tier_stats'] as List?;
        if (tierStats != null) {
          for (final t in tierStats) {
            final map = t as Map<String, dynamic>;
            tierDist[map['title'] as String? ?? ''] =
                (map['pledge_count'] as num?)?.toInt() ?? 0;
          }
        }

        // Build daily data from real data
        final dailyDataRaw = data['daily_data'] as List?;
        final dailyData = <DailyFundingData>[];
        if (dailyDataRaw != null && dailyDataRaw.isNotEmpty) {
          for (final d in dailyDataRaw) {
            final map = d as Map<String, dynamic>;
            dailyData.add(DailyFundingData(
              date: DateTime.parse(map['date'] as String),
              amount: (map['amount'] as num?)?.toInt() ?? 0,
              backerCount: (map['backer_count'] as num?)?.toInt() ?? 0,
            ));
          }
        }

        // If we got real tier data, use it; otherwise fall through to demo
        if (tierDist.isNotEmpty || dailyData.isNotEmpty) {
          return CampaignStats(
            totalBackers: campaign.backerCount,
            totalRaisedKrw: campaign.currentAmountKrw,
            fundingPercent: campaign.fundingPercent,
            daysLeft: campaign.daysLeft,
            avgPledgeKrw: campaign.backerCount > 0
                ? campaign.currentAmountKrw ~/ campaign.backerCount
                : 0,
            tierDistribution: tierDist,
            dailyData: dailyData,
          );
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[Funding] getStats error: $e');
      }
    }

    // Fallback: generate stats from campaign data
    return _generateDemoStats(campaign, campaignId);
  }

  CampaignStats _generateDemoStats(Campaign campaign, String campaignId) {
    final demoTiers = _getDemoTiers(campaignId);
    final tierDist = <String, int>{};
    for (final tier in demoTiers) {
      tierDist[tier.title] = tier.pledgeCount;
    }

    final now = DateTime.now();
    final totalDays = campaign.startAt != null
        ? now.difference(campaign.startAt!).inDays.clamp(1, 30)
        : 14;
    final dailyAvg =
        campaign.backerCount > 0 ? campaign.currentAmountKrw ~/ totalDays : 0;

    final dailyData = List.generate(totalDays.clamp(1, 14), (i) {
      final day = now.subtract(Duration(days: totalDays - 1 - i));
      final variance = (i * 17 + 7) % 11 - 5;
      final amount =
          (dailyAvg + dailyAvg * variance ~/ 10).clamp(0, dailyAvg * 3);
      final backers =
          (campaign.backerCount ~/ totalDays + variance).clamp(1, 100);
      return DailyFundingData(
        date: day,
        amount: amount,
        backerCount: backers,
      );
    });

    return CampaignStats(
      totalBackers: campaign.backerCount,
      totalRaisedKrw: campaign.currentAmountKrw,
      fundingPercent: campaign.fundingPercent,
      daysLeft: campaign.daysLeft,
      avgPledgeKrw: campaign.backerCount > 0
          ? campaign.currentAmountKrw ~/ campaign.backerCount
          : 0,
      tierDistribution: tierDist,
      dailyData: dailyData,
    );
  }

  /// Refresh data
  Future<void> refresh() async {
    final isDemoMode = _ref.read(isDemoModeProvider);
    if (isDemoMode) {
      // In demo mode, just return - data is already in memory
      return;
    }
    await _loadRealData();
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Main funding provider
final fundingProvider =
    StateNotifierProvider<FundingNotifier, FundingState>((ref) {
  return FundingNotifier(ref);
});

/// Explore campaigns (active)
final exploreCampaignsProvider = Provider<List<Campaign>>((ref) {
  return ref.watch(fundingProvider).exploreCampaigns;
});

/// Ending soon campaigns
final endingSoonCampaignsProvider = Provider<List<Campaign>>((ref) {
  return ref.watch(fundingProvider).endingSoonCampaigns;
});

/// Popular campaigns
final popularCampaignsProvider = Provider<List<Campaign>>((ref) {
  return ref.watch(fundingProvider).popularCampaigns;
});

/// New campaigns
final newCampaignsProvider = Provider<List<Campaign>>((ref) {
  return ref.watch(fundingProvider).newCampaigns;
});

/// My campaigns
final myCampaignsProvider = Provider<List<Campaign>>((ref) {
  return ref.watch(fundingProvider).myCampaigns;
});

/// My active campaigns
final myActiveCampaignsProvider = Provider<List<Campaign>>((ref) {
  return ref.watch(fundingProvider).myActiveCampaigns;
});

/// My draft campaigns
final myDraftCampaignsProvider = Provider<List<Campaign>>((ref) {
  return ref.watch(fundingProvider).myDraftCampaigns;
});

/// My ended campaigns
final myEndedCampaignsProvider = Provider<List<Campaign>>((ref) {
  return ref.watch(fundingProvider).myEndedCampaigns;
});

/// Demo wallet balance
final demoWalletBalanceProvider = Provider<int>((ref) {
  return ref.watch(fundingProvider).demoWalletBalance;
});

/// My pledges
final myPledgesProvider = Provider<List<Pledge>>((ref) {
  return ref.watch(fundingProvider).myPledges;
});

/// Funding loading state
final fundingLoadingProvider = Provider<bool>((ref) {
  return ref.watch(fundingProvider).isLoading;
});
