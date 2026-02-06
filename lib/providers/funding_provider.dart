import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_client.dart';
import 'auth_provider.dart';

// ============================================================================
// Models
// ============================================================================

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
  final int goalAmountDt;
  final int currentAmountDt;
  final double fundingPercent;
  final int backerCount;
  final DateTime? startAt;
  final DateTime? endAt;
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
    this.goalAmountDt = 0,
    this.currentAmountDt = 0,
    this.fundingPercent = 0,
    this.backerCount = 0,
    this.startAt,
    this.endAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    final goalAmount = (json['goal_amount_dt'] as num?)?.toInt() ?? 0;
    final currentAmount = (json['current_amount_dt'] as num?)?.toInt() ?? 0;
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
      goalAmountDt: goalAmount,
      currentAmountDt: currentAmount,
      fundingPercent: percent,
      backerCount: (json['backer_count'] as num?)?.toInt() ?? 0,
      startAt: json['start_at'] != null ? DateTime.tryParse(json['start_at'] as String) : null,
      endAt: json['end_at'] != null ? DateTime.tryParse(json['end_at'] as String) : null,
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
      'goal_amount_dt': goalAmountDt,
      'current_amount_dt': currentAmountDt,
      'funding_percent': fundingPercent,
      'backer_count': backerCount,
      'start_at': startAt?.toIso8601String(),
      'end_at': endAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  int get daysLeft {
    if (endAt == null) return 0;
    final diff = endAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get isEnded => (endAt != null && endAt!.isBefore(DateTime.now())) || status == CampaignStatus.completed;
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
    int? goalAmountDt,
    int? currentAmountDt,
    double? fundingPercent,
    int? backerCount,
    DateTime? startAt,
    DateTime? endAt,
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
      goalAmountDt: goalAmountDt ?? this.goalAmountDt,
      currentAmountDt: currentAmountDt ?? this.currentAmountDt,
      fundingPercent: fundingPercent ?? this.fundingPercent,
      backerCount: backerCount ?? this.backerCount,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
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
  final int priceDt;
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
    required this.priceDt,
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
      priceDt: (json['price_dt'] as num?)?.toInt() ?? 0,
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
      'price_dt': priceDt,
      'total_quantity': totalQuantity,
      'remaining_quantity': remainingQuantity,
      'pledge_count': pledgeCount,
      'display_order': displayOrder,
      'is_active': isActive,
      'is_featured': isFeatured,
    };
  }

  bool get isSoldOut =>
      totalQuantity != null && (remainingQuantity ?? 0) <= 0;
}

/// Pledge model
class Pledge {
  final String id;
  final String campaignId;
  final String userId;
  final String tierId;
  final int amountDt;
  final int extraSupportDt;
  final bool isAnonymous;
  final String? supportMessage;
  final String status;
  final DateTime createdAt;

  const Pledge({
    required this.id,
    required this.campaignId,
    required this.userId,
    required this.tierId,
    required this.amountDt,
    this.extraSupportDt = 0,
    this.isAnonymous = false,
    this.supportMessage,
    this.status = 'active',
    required this.createdAt,
  });

  int get totalAmount => amountDt + extraSupportDt;
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

  const FundingState({
    this.allCampaigns = const [],
    this.myCampaigns = const [],
    this.myPledges = const [],
    this.demoWalletBalance = 500000,
    this.isLoading = false,
    this.error,
  });

  /// Explore campaigns (all active, not mine)
  List<Campaign> get exploreCampaigns =>
      allCampaigns.where((c) => c.status == CampaignStatus.active).toList();

  /// My active campaigns (includes paused - they show in 진행중 tab)
  List<Campaign> get myActiveCampaigns =>
      myCampaigns.where((c) =>
          c.status == CampaignStatus.active ||
          c.status == CampaignStatus.paused).toList();

  /// My draft campaigns
  List<Campaign> get myDraftCampaigns =>
      myCampaigns.where((c) => c.status == CampaignStatus.draft).toList();

  /// My ended campaigns
  List<Campaign> get myEndedCampaigns =>
      myCampaigns.where((c) =>
          c.status == CampaignStatus.completed ||
          c.status == CampaignStatus.cancelled).toList();

  /// Ending soon campaigns (3 days or less)
  List<Campaign> get endingSoonCampaigns =>
      exploreCampaigns.where((c) => c.daysLeft <= 3 && c.daysLeft >= 0).toList();

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
  int get totalBackers =>
      myCampaigns.fold(0, (sum, c) => sum + c.backerCount);
  int get totalRaisedDt =>
      myCampaigns.fold(0, (sum, c) => sum + c.currentAmountDt);

  FundingState copyWith({
    List<Campaign>? allCampaigns,
    List<Campaign>? myCampaigns,
    List<Pledge>? myPledges,
    int? demoWalletBalance,
    bool? isLoading,
    String? error,
  }) {
    return FundingState(
      allCampaigns: allCampaigns ?? this.allCampaigns,
      myCampaigns: myCampaigns ?? this.myCampaigns,
      myPledges: myPledges ?? this.myPledges,
      demoWalletBalance: demoWalletBalance ?? this.demoWalletBalance,
      isLoading: isLoading ?? this.isLoading,
      error: error,
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
        goalAmountDt: 50000000,
        currentAmountDt: 42350000,
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
        goalAmountDt: 30000000,
        currentAmountDt: 38500000,
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
        goalAmountDt: 20000000,
        currentAmountDt: 15200000,
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
        goalAmountDt: 100000000,
        currentAmountDt: 89000000,
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
        goalAmountDt: 10000000,
        currentAmountDt: 12500000,
        fundingPercent: 125.0,
        backerCount: 632,
        endAt: now.add(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 14)),
      ),
    ];

    final myCampaigns = [
      Campaign(
        id: 'demo_my_campaign_1',
        creatorId: 'demo_creator_001',
        title: '나의 첫 미니앨범 "Dream" 제작 펀딩',
        subtitle: '팬 여러분과 함께 만드는 앨범',
        description: '팬 여러분과 함께 만드는 첫 앨범입니다.',
        category: '앨범',
        coverImageUrl: 'https://picsum.photos/seed/mycampaign1/800/450',
        status: CampaignStatus.active,
        goalAmountDt: 30000000,
        currentAmountDt: 18500000,
        fundingPercent: 61.7,
        backerCount: 892,
        endAt: now.add(const Duration(days: 15)),
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      Campaign(
        id: 'demo_my_campaign_draft',
        creatorId: 'demo_creator_001',
        title: '새 콘서트 굿즈 제작 (준비중)',
        subtitle: '',
        category: '굿즈',
        status: CampaignStatus.draft,
        goalAmountDt: 0,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Campaign(
        id: 'demo_my_campaign_ended',
        creatorId: 'demo_creator_001',
        title: '팬미팅 "Together" 개최 펀딩',
        subtitle: '성공적으로 마감되었습니다!',
        description: '성공적으로 종료된 팬미팅 펀딩입니다.',
        category: '팬미팅',
        coverImageUrl: 'https://picsum.photos/seed/mycampaignended/800/450',
        status: CampaignStatus.completed,
        goalAmountDt: 25000000,
        currentAmountDt: 32000000,
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

      final allCampaigns = (allResponse as List)
          .map((json) => Campaign.fromJson(json))
          .toList();

      // Load my campaigns if creator
      List<Campaign> myCampaigns = [];
      if (userId != null) {
        final myResponse = await client
            .from('funding_campaigns')
            .select('*')
            .eq('creator_id', userId)
            .order('created_at', ascending: false);

        myCampaigns = (myResponse as List)
            .map((json) => Campaign.fromJson(json))
            .toList();
      }

      state = state.copyWith(
        allCampaigns: allCampaigns,
        myCampaigns: myCampaigns,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ========== CRUD Operations ==========

  /// Get tiers for a campaign
  List<RewardTier> getTiersForCampaign(String campaignId) {
    // Demo tiers
    return [
      RewardTier(
        id: '${campaignId}_tier_1',
        campaignId: campaignId,
        title: '응원 참여',
        description: '펀딩 참여 인증서 (디지털)\n감사 메시지 (카카오톡)',
        priceDt: 5000,
        pledgeCount: 423,
        displayOrder: 1,
      ),
      RewardTier(
        id: '${campaignId}_tier_2',
        campaignId: campaignId,
        title: '기본 리워드',
        description: '응원 참여 포함\n디지털 포토카드 5장\n팬명 크레딧 등재',
        priceDt: 15000,
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
        priceDt: 50000,
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
        priceDt: 150000,
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
    int goalAmountDt = 0,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    final isDemoMode = _ref.read(isDemoModeProvider);

    if (isDemoMode) {
      final newCampaign = Campaign(
        id: 'demo_new_${DateTime.now().millisecondsSinceEpoch}',
        creatorId: 'demo_creator_001',
        title: title,
        subtitle: subtitle,
        description: description,
        category: category,
        coverImageUrl: coverImageUrl,
        status: CampaignStatus.draft,
        goalAmountDt: goalAmountDt,
        startAt: startAt,
        endAt: endAt,
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

    final response = await client.from('funding_campaigns').insert({
      'creator_id': userId,
      'title': title,
      'subtitle': subtitle,
      'description_md': description,
      'category': category,
      'cover_image_url': coverImageUrl,
      'status': 'draft',
      'goal_amount_dt': goalAmountDt,
      'start_at': startAt?.toIso8601String(),
      'end_at': endAt?.toIso8601String(),
    }).select().single();

    final newCampaign = Campaign.fromJson(response);
    state = state.copyWith(
      myCampaigns: [newCampaign, ...state.myCampaigns],
    );
    return newCampaign;
  }

  /// Update an existing campaign
  Future<void> updateCampaign(String campaignId, {
    String? title,
    String? subtitle,
    String? description,
    String? category,
    String? coverImageUrl,
    int? goalAmountDt,
    DateTime? startAt,
    DateTime? endAt,
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
            goalAmountDt: goalAmountDt,
            startAt: startAt,
            endAt: endAt,
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
    if (goalAmountDt != null) updates['goal_amount_dt'] = goalAmountDt;
    if (startAt != null) updates['start_at'] = startAt.toIso8601String();
    if (endAt != null) updates['end_at'] = endAt.toIso8601String();

    await client.from('funding_campaigns')
        .update(updates)
        .eq('id', campaignId);

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
    required int amountDt,
    int extraSupportDt = 0,
    bool isAnonymous = false,
    String? supportMessage,
  }) async {
    final isDemoMode = _ref.read(isDemoModeProvider);
    final totalAmount = amountDt + extraSupportDt;

    if (isDemoMode) {
      // Check wallet balance
      if (state.demoWalletBalance < totalAmount) {
        throw Exception('DT 잔액이 부족합니다');
      }

      final pledge = Pledge(
        id: 'demo_pledge_${DateTime.now().millisecondsSinceEpoch}',
        campaignId: campaignId,
        userId: 'demo_user_001',
        tierId: tierId,
        amountDt: amountDt,
        extraSupportDt: extraSupportDt,
        isAnonymous: isAnonymous,
        supportMessage: supportMessage,
        createdAt: DateTime.now(),
      );

      // Update campaign stats
      final updatedAll = state.allCampaigns.map((c) {
        if (c.id == campaignId) {
          final newAmount = c.currentAmountDt + totalAmount;
          final newPercent = c.goalAmountDt > 0
              ? (newAmount / c.goalAmountDt * 100)
              : 0.0;
          return c.copyWith(
            currentAmountDt: newAmount,
            fundingPercent: newPercent,
            backerCount: c.backerCount + 1,
          );
        }
        return c;
      }).toList();

      state = state.copyWith(
        allCampaigns: updatedAll,
        myPledges: [pledge, ...state.myPledges],
        demoWalletBalance: state.demoWalletBalance - totalAmount,
      );

      return pledge;
    }

    // Real implementation
    final client = SupabaseConfig.client;
    final response = await client.functions.invoke(
      'funding-pledge',
      body: {
        'campaignId': campaignId,
        'tierId': tierId,
        'amountDt': amountDt,
        'extraSupportDt': extraSupportDt,
        'isAnonymous': isAnonymous,
        'supportMessage': supportMessage,
      },
    );

    final data = response.data as Map<String, dynamic>?;
    if (data?['success'] != true) {
      throw Exception(data?['message'] ?? '후원에 실패했습니다');
    }

    final pledge = Pledge(
      id: data?['pledgeId'] ?? '',
      campaignId: campaignId,
      userId: client.auth.currentUser?.id ?? '',
      tierId: tierId,
      amountDt: amountDt,
      extraSupportDt: extraSupportDt,
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
    int goalAmountDt = 0,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    if (existingCampaignId != null) {
      await updateCampaign(
        existingCampaignId,
        title: title,
        subtitle: subtitle,
        description: description,
        category: category,
        coverImageUrl: coverImageUrl,
        goalAmountDt: goalAmountDt,
        startAt: startAt,
        endAt: endAt,
      );
      return getCampaignById(existingCampaignId)!;
    }

    return createCampaign(
      title: title,
      subtitle: subtitle,
      description: description,
      category: category,
      coverImageUrl: coverImageUrl,
      goalAmountDt: goalAmountDt,
      startAt: startAt,
      endAt: endAt,
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
    required int goalAmountDt,
    DateTime? startAt,
    required DateTime endAt,
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
        goalAmountDt: goalAmountDt,
        startAt: startAt,
        endAt: endAt,
      );

      if (isDemoMode) {
        // In demo, directly activate
        await startCampaign(existingCampaignId);
      }
    } else {
      final campaign = await createCampaign(
        title: title,
        subtitle: subtitle,
        description: description,
        category: category,
        coverImageUrl: coverImageUrl,
        goalAmountDt: goalAmountDt,
        startAt: startAt,
        endAt: endAt,
      );

      if (isDemoMode) {
        await startCampaign(campaign.id);
      }
    }
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

/// Funding loading state
final fundingLoadingProvider = Provider<bool>((ref) {
  return ref.watch(fundingProvider).isLoading;
});
