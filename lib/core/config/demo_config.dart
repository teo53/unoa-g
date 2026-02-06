/// Demo Mode Configuration
///
/// Centralized configuration for demo mode data and settings.
/// All demo/mock data values should reference this file for easy maintenance.
class DemoConfig {
  DemoConfig._();

  // ============================================================
  // Demo User IDs
  // ============================================================

  /// Demo creator user ID
  static const String demoCreatorId = 'demo_creator_001';

  /// Demo fan user ID
  static const String demoFanId = 'demo_user_001';

  /// Demo channel ID
  static const String demoChannelId = 'demo_channel_001';

  // ============================================================
  // Demo User Names
  // ============================================================

  /// Demo creator display name
  static const String demoCreatorName = '하늘달 (데모)';

  /// Demo creator English name
  static const String demoCreatorNameEn = 'HaneulDal';

  /// Demo fan display name
  static const String demoFanName = '데모 팬';

  /// Demo creator bio
  static const String demoCreatorBio =
      '버츄얼 유튜버 하늘달입니다. 데모 모드로 크리에이터 기능을 체험 중입니다.';

  /// Demo fan bio
  static const String demoFanBio = '데모 모드로 앱을 체험 중입니다.';

  // ============================================================
  // Demo Wallet Values
  // ============================================================

  /// Initial DT (Digital Token) balance for demo users
  static const int initialDtBalance = 15000;

  /// Initial Star balance for demo users
  static const int initialStarBalance = 50;

  /// Demo charge amount options (in KRW)
  static const List<int> chargeAmountOptions = [
    1000,
    3000,
    5000,
    10000,
    30000,
    50000,
  ];

  // ============================================================
  // Demo Avatar URLs
  // ============================================================

  /// Base URL for placeholder avatars
  static const String avatarBaseUrl = 'https://picsum.photos/seed';

  /// Demo creator avatar URL
  static String get demoCreatorAvatarUrl => '$avatarBaseUrl/vtuber1/200';

  /// Generate avatar URL with seed
  static String avatarUrl(String seed, {int size = 200}) =>
      '$avatarBaseUrl/$seed/$size';

  /// Demo artist avatar seeds
  static const List<String> artistAvatarSeeds = [
    'vtuber1',
    'vtuber2',
    'vtuber3',
    'kpop1',
    'kpop2',
    'kpop3',
    'idol1',
    'idol2',
    'idol3',
    'artist1',
    'artist2',
    'artist3',
  ];

  /// Demo fan avatar seeds
  static const List<String> fanAvatarSeeds = [
    'fan1',
    'fan2',
    'fan3',
    'user1',
    'user2',
    'user3',
  ];

  // ============================================================
  // Demo Banner Images
  // ============================================================

  /// Banner image base URL
  static const String bannerBaseUrl = 'https://picsum.photos/seed';

  /// Generate banner URL
  static String bannerUrl(String seed, {int width = 400, int height = 200}) =>
      '$bannerBaseUrl/$seed/$width/$height';

  /// Demo banner seeds
  static const List<String> bannerSeeds = [
    'banner1',
    'banner2',
    'banner3',
    'promo1',
    'promo2',
    'event1',
  ];

  // ============================================================
  // Demo Statistics
  // ============================================================

  /// Demo subscriber count
  static const int demoSubscriberCount = 1234;

  /// Demo total messages sent
  static const int demoTotalMessages = 567;

  /// Demo today's new subscribers
  static const int demoTodayNewSubscribers = 12;

  /// Demo today's messages
  static const int demoTodayMessages = 45;

  /// Demo today's hearts received
  static const int demoTodayHearts = 89;

  /// Demo monthly revenue (in KRW)
  static const int demoMonthlyRevenue = 1250000;

  // ============================================================
  // Demo Artist Data
  // ============================================================

  /// Sample artist names for demo
  static const List<Map<String, String>> sampleArtists = [
    {'name': '하늘달', 'nameEn': 'HaneulDal', 'category': 'VTuber'},
    {'name': '별빛', 'nameEn': 'Starlight', 'category': 'VTuber'},
    {'name': '민서', 'nameEn': 'Minseo', 'category': 'K-POP'},
    {'name': '루나', 'nameEn': 'Luna', 'category': 'K-POP'},
    {'name': '지우', 'nameEn': 'Jiwoo', 'category': 'Indie'},
    {'name': '소라', 'nameEn': 'Sora', 'category': 'Idol'},
  ];

  /// Artist categories
  static const List<String> artistCategories = [
    '전체',
    'VTuber',
    'K-POP',
    'Idol',
    'Indie',
    'Actor',
  ];

  // ============================================================
  // Demo Funding Campaign Data
  // ============================================================

  /// Demo funding goal amounts
  static const List<int> fundingGoalAmounts = [
    500000,
    1000000,
    2000000,
    5000000,
  ];

  /// Demo funding campaign titles
  static const List<String> fundingCampaignTitles = [
    '신규 앨범 제작 프로젝트',
    '팬미팅 개최 펀딩',
    '굿즈 제작 프로젝트',
    '콘서트 투어 지원',
  ];

  // ============================================================
  // Demo Message Templates
  // ============================================================

  /// Sample broadcast messages
  static const List<String> sampleBroadcastMessages = [
    '안녕하세요 여러분! 오늘도 좋은 하루 보내세요 💕',
    '오늘 방송 준비 중이에요! 잠시 후에 만나요~',
    '새 영상 업로드했어요! 많이 봐주세요 🎬',
    '팬 여러분 덕분에 행복해요. 항상 감사합니다!',
  ];

  /// Sample fan reply messages
  static const List<String> sampleFanReplies = [
    '오늘도 응원해요! 화이팅 💪',
    '방송 기다리고 있어요~',
    '항상 행복하세요!',
    '최고예요! 사랑해요 ❤️',
  ];

  // ============================================================
  // Time-related Demo Data
  // ============================================================

  /// Demo subscription start date (days ago)
  static const int demoSubscriptionDaysAgo = 120;

  /// Demo account creation date (days ago)
  static const int demoAccountCreatedDaysAgo = 365;
}
