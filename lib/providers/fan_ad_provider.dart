import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

/// Ad package model
class FanAdPackage {
  final String id;
  final String name;
  final String placement;
  final int durationDays;
  final int priceKrw;
  final int? maxImpressions;

  const FanAdPackage({
    required this.id,
    required this.name,
    required this.placement,
    required this.durationDays,
    required this.priceKrw,
    this.maxImpressions,
  });

  String get formattedPrice {
    final formatted = priceKrw.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '${formatted}원';
  }

  String get placementLabel => switch (placement) {
        'home_top' => '홈 배너',
        'discover_top' => '탐색 상단',
        'chat_list' => '채팅 리스트',
        'funding_top' => '펀딩 상단',
        _ => placement,
      };
}

/// Fan ad model
class FanAd {
  final String id;
  final String fanUserId;
  final String packageId;
  final String targetArtistId;
  final String headline;
  final String? description;
  final String? imageUrl;
  final String linkType;
  final String? linkTarget;
  final int paymentAmountKrw;
  final String? paymentId;
  final String paymentStatus;
  final String status;
  final String? rejectReason;
  final DateTime? startDate;
  final DateTime? endDate;
  final int impressions;
  final int clicks;
  final DateTime createdAt;

  const FanAd({
    required this.id,
    required this.fanUserId,
    required this.packageId,
    required this.targetArtistId,
    required this.headline,
    this.description,
    this.imageUrl,
    this.linkType = 'profile',
    this.linkTarget,
    required this.paymentAmountKrw,
    this.paymentId,
    this.paymentStatus = 'pending',
    this.status = 'pending_review',
    this.rejectReason,
    this.startDate,
    this.endDate,
    this.impressions = 0,
    this.clicks = 0,
    required this.createdAt,
  });

  String get statusLabel => switch (status) {
        'pending_review' => '심사 대기',
        'approved' => '승인됨',
        'rejected' => '거절됨',
        'active' => '광고 진행중',
        'completed' => '완료',
        'cancelled' => '취소됨',
        _ => status,
      };

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending_review';
}

/// Demo ad packages
final _demoPackages = [
  const FanAdPackage(
    id: 'pkg_1',
    name: '홈 배너 1일',
    placement: 'home_top',
    durationDays: 1,
    priceKrw: 5000,
  ),
  const FanAdPackage(
    id: 'pkg_2',
    name: '홈 배너 3일',
    placement: 'home_top',
    durationDays: 3,
    priceKrw: 12000,
  ),
  const FanAdPackage(
    id: 'pkg_3',
    name: '탐색 상단 1일',
    placement: 'discover_top',
    durationDays: 1,
    priceKrw: 3000,
  ),
  const FanAdPackage(
    id: 'pkg_4',
    name: '탐색 상단 3일',
    placement: 'discover_top',
    durationDays: 3,
    priceKrw: 8000,
  ),
  const FanAdPackage(
    id: 'pkg_5',
    name: '채팅 리스트 1일',
    placement: 'chat_list',
    durationDays: 1,
    priceKrw: 4000,
  ),
  const FanAdPackage(
    id: 'pkg_6',
    name: '채팅 리스트 3일',
    placement: 'chat_list',
    durationDays: 3,
    priceKrw: 10000,
  ),
  const FanAdPackage(
    id: 'pkg_7',
    name: '펀딩 상단 1일',
    placement: 'funding_top',
    durationDays: 1,
    priceKrw: 3000,
  ),
  const FanAdPackage(
    id: 'pkg_8',
    name: '펀딩 상단 7일',
    placement: 'funding_top',
    durationDays: 7,
    priceKrw: 15000,
  ),
];

/// Demo ads
final _demoAds = [
  FanAd(
    id: 'ad_1',
    fanUserId: 'demo_user_001',
    packageId: 'pkg_1',
    targetArtistId: 'demo_creator_001',
    headline: '하늘달을 응원합니다!',
    description: '최고의 아티스트 하늘달의 음악을 들어보세요',
    linkType: 'profile',
    linkTarget: 'demo_creator_001',
    paymentAmountKrw: 5000,
    paymentStatus: 'paid',
    status: 'active',
    startDate: DateTime.now().subtract(const Duration(hours: 12)),
    endDate: DateTime.now().add(const Duration(hours: 12)),
    impressions: 1250,
    clicks: 87,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  FanAd(
    id: 'ad_2',
    fanUserId: 'demo_user_001',
    packageId: 'pkg_3',
    targetArtistId: 'artist_2',
    headline: '루나의 신곡 들어보세요!',
    linkType: 'profile',
    paymentAmountKrw: 3000,
    paymentStatus: 'paid',
    status: 'completed',
    startDate: DateTime.now().subtract(const Duration(days: 3)),
    endDate: DateTime.now().subtract(const Duration(days: 2)),
    impressions: 3420,
    clicks: 215,
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
  ),
];

/// Available ad packages
final fanAdPackagesProvider = FutureProvider<List<FanAdPackage>>((ref) async {
  final isDemoMode = ref.read(isDemoModeProvider);
  if (isDemoMode) {
    return _demoPackages;
  }

  // TODO: Fetch from Supabase fan_ad_packages
  return _demoPackages;
});

/// My purchased ads
final myFanAdsProvider = FutureProvider<List<FanAd>>((ref) async {
  final isDemoMode = ref.read(isDemoModeProvider);
  if (isDemoMode) {
    return _demoAds;
  }

  // TODO: Fetch from Supabase fan_ads where fan_user_id = auth.uid()
  return _demoAds;
});

/// Submit a new fan ad (creates order + simulates payment in demo)
class FanAdNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  FanAdNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> submitAd({
    required String packageId,
    required String targetArtistId,
    required String headline,
    String? description,
    String? imageUrl,
    String linkType = 'profile',
    String? linkTarget,
  }) async {
    state = const AsyncValue.loading();

    final isDemoMode = _ref.read(isDemoModeProvider);

    try {
      if (isDemoMode) {
        // Simulate payment delay
        await Future.delayed(const Duration(seconds: 1));

        // In demo mode, auto-approve
        if (kDebugMode) {
          debugPrint('[FanAd] Demo: Ad submitted and auto-approved');
        }

        state = const AsyncValue.data(null);
        return true;
      }

      // TODO: Real implementation
      // 1. Create fan_ads record with status 'pending_review'
      // 2. Initiate PortOne payment
      // 3. On payment success, update payment_status to 'paid'
      // 4. Wait for admin approval

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> cancelAd(String adId) async {
    final isDemoMode = _ref.read(isDemoModeProvider);

    if (isDemoMode) {
      if (kDebugMode) {
        debugPrint('[FanAd] Demo: Ad $adId cancelled');
      }
      return true;
    }

    // TODO: Update fan_ads status to 'cancelled', process refund
    return true;
  }
}

final fanAdNotifierProvider =
    StateNotifierProvider<FanAdNotifier, AsyncValue<void>>((ref) {
  return FanAdNotifier(ref);
});
