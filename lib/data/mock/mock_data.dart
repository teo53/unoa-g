import '../models/artist.dart';
import '../models/message.dart';
import '../models/user_profile.dart';
import '../models/dt_package.dart';
import '../../core/constants/asset_paths.dart';
import '../../core/config/demo_config.dart';
import '../../core/config/business_config.dart';

class MockData {
  // Current User - using DemoConfig values
  static final currentUser = UserProfile(
    id: DemoConfig.demoFanId,
    name: '김민지',
    englishName: 'Minji Kim',
    username: '@minji_love_kpop',
    avatarUrl: AssetPaths.userProfile,
    tier: BusinessConfig.subscriptionTiers.last, // VIP
    subscriptionCount: 3,
    dtBalance: DemoConfig.initialDtBalance,
    nextPaymentDate: null,
  );

  // Trending Artists
  static const trendingArtists = [
    Artist(
      id: 'artist_1',
      name: '김민지',
      englishName: 'Minji Kim',
      group: 'NewJeans',
      avatarUrl: AssetPaths.minjiAvatar1,
      followerCount: 520000,
      rank: 1,
      isVerified: true,
      isOnline: true,
      bio: '여러분의 매일이 음악처럼 빛나길 바라요. 오늘도 함께해요!',
      postCount: 231,
      fancams: [
        YouTubeFancam(
          id: 'fancam_1',
          videoId: 'dQw4w9WgXcQ', // Sample video ID
          title: '민지 직캠 | Attention 240315 쇼케이스',
          description: '첫 번째 쇼케이스 무대 직캠입니다!',
          viewCount: 1250000,
          isPinned: true,
        ),
        YouTubeFancam(
          id: 'fancam_2',
          videoId: 'kJQP7kiw5Fk',
          title: '민지 직캠 | Hype Boy 240320 음악방송',
          viewCount: 890000,
        ),
        YouTubeFancam(
          id: 'fancam_3',
          videoId: '9bZkp7q19f0',
          title: '민지 직캠 | Super Shy 팬미팅',
          viewCount: 650000,
        ),
      ],
    ),
    Artist(
      id: 'artist_2',
      name: '이준호',
      englishName: 'Junho Lee',
      group: '2PM',
      avatarUrl: AssetPaths.junhoAvatar,
      followerCount: 300000,
      rank: 2,
      isVerified: true,
      isOnline: false,
      postCount: 156,
      fancams: [
        YouTubeFancam(
          id: 'fancam_4',
          videoId: 'fJ9rUzIMcZQ',
          title: '준호 직캠 | My House 콘서트',
          viewCount: 2100000,
          isPinned: true,
        ),
        YouTubeFancam(
          id: 'fancam_5',
          videoId: 'RgKAFK5djSk',
          title: '준호 직캠 | Again & Again',
          viewCount: 1500000,
        ),
      ],
    ),
    Artist(
      id: 'artist_3',
      name: '박서연',
      group: 'Solo',
      avatarUrl: AssetPaths.seoyeonAvatar,
      followerCount: 180000,
      rank: 3,
      isVerified: false,
      isOnline: false,
      postCount: 89,
      fancams: [
        YouTubeFancam(
          id: 'fancam_6',
          videoId: 'hT_nvWreIhg',
          title: '서연 직캠 | 데뷔 무대',
          viewCount: 320000,
          isPinned: true,
        ),
      ],
    ),
  ];

  // Subscribed Artists
  static const subscribedArtists = [
    Artist(
      id: 'artist_1',
      name: '김민지',
      avatarUrl: AssetPaths.chatMinji,
      followerCount: 520000,
      isVerified: true,
      isOnline: true,
      tier: 'STANDARD',
    ),
    Artist(
      id: 'artist_2',
      name: '이준호',
      avatarUrl: AssetPaths.chatJunho,
      followerCount: 300000,
      isVerified: false,
      isOnline: false,
      tier: 'STANDARD',
    ),
    Artist(
      id: 'artist_4',
      name: '최현수',
      avatarUrl: AssetPaths.hyunsuAvatar,
      followerCount: 120000,
      isVerified: false,
      isOnline: true,
      tier: 'VIP',
    ),
  ];

  // Chat Threads
  static final chatThreads = [
    ChatThread(
      id: 'chat_1',
      artistId: 'artist_1',
      artistName: '김민지',
      artistEnglishName: 'Minji Kim',
      artistAvatarUrl: AssetPaths.chatMinji,
      lastMessage: '오늘 공연 와줘서 너무 고마워요!',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 1)),
      unreadCount: 2,
      isOnline: true,
      isVerified: true,
      isPinned: true,
    ),
    ChatThread(
      id: 'chat_2',
      artistId: 'artist_2',
      artistName: '이준호',
      artistEnglishName: 'Junho Lee',
      artistAvatarUrl: AssetPaths.chatJunho,
      lastMessage: '다음 주 일정 공유할게요. 확인해주세요!',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      unreadCount: 1,
      isOnline: false,
      isVerified: false,
      isStar: true,
    ),
    ChatThread(
      id: 'chat_3',
      artistId: 'artist_3',
      artistName: '박서연',
      artistAvatarUrl: AssetPaths.chatSeoyeon,
      lastMessage: '사진 보내주셔서 감사합니다 :)',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      isOnline: false,
      isVerified: false,
    ),
    ChatThread(
      id: 'chat_4',
      artistId: 'artist_4',
      artistName: '최현수',
      artistAvatarUrl: AssetPaths.chatHyunsu,
      lastMessage: '이번 앨범 컨셉 어때요?',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      isOnline: false,
      isVerified: false,
    ),
    ChatThread(
      id: 'chat_5',
      artistId: 'artist_5',
      artistName: '정수민',
      artistAvatarUrl: AssetPaths.suminAvatar,
      lastMessage: '라이브 방송 공지 확인해주세요~',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      isOnline: false,
      isVerified: false,
    ),
  ];

  // Sample Messages for Chat Thread
  static final sampleMessages = [
    Message(
      id: 'msg_1',
      senderId: 'artist_1',
      content: '',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      type: MessageType.image,
      imageUrl: AssetPaths.concertImage,
    ),
    Message(
      id: 'msg_2',
      senderId: 'artist_1',
      content: '오늘 공연 와줘서 너무 고마워요!\n다들 조심히 들어갔나요? 너무 즐거웠어요!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      type: MessageType.text,
    ),
    Message(
      id: 'msg_3',
      senderId: 'user_1',
      content: '언니 오늘 무대 진짜 최고였어요!! 목소리 듣고 울뻔... 푹 쉬세요!!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 28)),
      type: MessageType.text,
      isRead: true,
    ),
    Message(
      id: 'msg_4',
      senderId: 'artist_1',
      content: '고마워요!! 다음에 또 봐요~~',
      timestamp: DateTime.now().subtract(const Duration(minutes: 27)),
      type: MessageType.text,
    ),
  ];

  // Story Users
  static const storyUsers = [
    {
      'name': '내 스토리',
      'avatarUrl': '',
      'isAddStory': true,
      'hasNewStory': false,
    },
    {
      'name': '김민지',
      'avatarUrl': AssetPaths.storyMinji,
      'isAddStory': false,
      'hasNewStory': true,
    },
    {
      'name': '이준호',
      'avatarUrl': AssetPaths.storyJunho,
      'isAddStory': false,
      'hasNewStory': true,
    },
    {
      'name': '박서연',
      'avatarUrl': AssetPaths.chatSeoyeon,
      'isAddStory': false,
      'hasNewStory': false,
    },
    {
      'name': '최현수',
      'avatarUrl': AssetPaths.chatHyunsu,
      'isAddStory': false,
      'hasNewStory': false,
    },
  ];

  // DT Packages - using BusinessConfig values
  static final dtPackages = [
    DtPackage(
      id: 'pkg_1',
      name: '스타터',
      dtAmount: BusinessConfig.chargeAmounts[0], // 1000
      priceKrw: BusinessConfig.chargeAmounts[0] * BusinessConfig.dtPerKrw,
    ),
    DtPackage(
      id: 'pkg_2',
      name: '베이직',
      dtAmount: BusinessConfig.chargeAmounts[2], // 5000
      priceKrw: BusinessConfig.chargeAmounts[2] * BusinessConfig.dtPerKrw,
      bonusDt: 50,
    ),
    DtPackage(
      id: 'pkg_3',
      name: '스탠다드',
      dtAmount: BusinessConfig.chargeAmounts[3], // 10000
      priceKrw: BusinessConfig.chargeAmounts[3] * BusinessConfig.dtPerKrw,
      bonusDt: 150,
      isPopular: true,
    ),
    DtPackage(
      id: 'pkg_4',
      name: '프리미엄',
      dtAmount: BusinessConfig.chargeAmounts[4], // 30000
      priceKrw: BusinessConfig.chargeAmounts[4] * BusinessConfig.dtPerKrw,
      bonusDt: 600,
    ),
  ];

  // Transactions
  static final transactions = [
    Transaction(
      id: 'txn_1',
      description: '김민지 메시지 전송',
      amount: 10,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: TransactionType.debit,
    ),
    Transaction(
      id: 'txn_2',
      description: 'DT 충전 (스탠다드)',
      amount: 1150,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: TransactionType.credit,
    ),
    Transaction(
      id: 'txn_3',
      description: '이준호 메시지 전송',
      amount: 10,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: TransactionType.debit,
    ),
  ];

  // Profile Highlights
  static const highlights = [
    {'name': '콘서트', 'imageUrl': AssetPaths.highlightConcert, 'hasNew': false},
    {'name': '일상', 'imageUrl': AssetPaths.highlightDaily, 'hasNew': true},
    {'name': 'Q&A', 'imageUrl': AssetPaths.highlightQA, 'hasNew': false},
  ];

  // Store Products
  static const products = [
    {
      'name': '2024 시즌 그리팅 패키지',
      'price': 45000,
      'imageUrl': AssetPaths.product1,
      'isNew': true,
      'isSoldOut': false,
    },
    {
      'name': '한정판 포토카드 세트 A',
      'price': 12000,
      'imageUrl': AssetPaths.product2,
      'isNew': false,
      'isSoldOut': true,
    },
  ];

  // Feed Posts
  static const feeds = [
    {
      'content': '오늘 녹음 끝났어요! 새 앨범 기대해주세요. 팬 여러분 덕분에 힘이 납니다.',
      'imageUrl': AssetPaths.highlightDaily,
      'time': '2시간 전',
      'likes': 15234,
      'comments': 892,
    },
    {
      'content': '콘서트 연습 중이에요. 이번에도 멋진 무대 보여드릴게요!',
      'imageUrl': null,
      'time': '어제',
      'likes': 8421,
      'comments': 456,
    },
    {
      'content': '여러분 맛있는 저녁 드셨나요? 저는 오늘 삼겹살 먹었어요. 다이어트는 내일부터...',
      'imageUrl': null,
      'time': '2일 전',
      'likes': 12567,
      'comments': 1203,
    },
  ];

  // Subscriptions
  static final mySubscriptions = [
    Subscription(
      id: 'sub_1',
      artistId: 'artist_1',
      artistName: '김민지',
      avatarUrl: AssetPaths.chatMinji,
      tier: 'VIP',
      price: 15000,
      nextBillingDate: DateTime.now().add(const Duration(days: 3)),
      isExpiringSoon: true,
    ),
    Subscription(
      id: 'sub_2',
      artistId: 'artist_2',
      artistName: '이준호',
      avatarUrl: AssetPaths.chatJunho,
      tier: 'STANDARD',
      price: 9900,
      nextBillingDate: DateTime.now().add(const Duration(days: 15)),
      isExpiringSoon: false,
    ),
    Subscription(
      id: 'sub_3',
      artistId: 'artist_4',
      artistName: '최현수',
      avatarUrl: AssetPaths.chatHyunsu,
      tier: 'BASIC',
      price: 4900,
      nextBillingDate: DateTime.now().add(const Duration(days: 22)),
      isExpiringSoon: false,
    ),
  ];
}

// Subscription Model
class Subscription {
  final String id;
  final String artistId;
  final String artistName;
  final String avatarUrl;
  final String tier;
  final int price;
  final DateTime nextBillingDate;
  final bool isExpiringSoon;

  const Subscription({
    required this.id,
    required this.artistId,
    required this.artistName,
    required this.avatarUrl,
    required this.tier,
    required this.price,
    required this.nextBillingDate,
    this.isExpiringSoon = false,
  });

  String get formattedPrice {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return '₩$formatted';
  }

  String get formattedNextBilling {
    final diff = nextBillingDate.difference(DateTime.now()).inDays;
    if (diff <= 0) return '오늘';
    if (diff == 1) return '내일';
    if (diff <= 7) return '$diff일 후';
    return '${nextBillingDate.month}월 ${nextBillingDate.day}일';
  }
}
