/// Sticker Provider
/// 스티커 팩 상태 관리 (Riverpod)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/config/demo_config.dart';
import '../data/models/sticker.dart';
import 'auth_provider.dart';
import 'repository_providers.dart';

// ============================================
// Sticker Sets for a Channel (Family Provider)
// ============================================

final stickerSetsProvider =
    FutureProvider.family<List<StickerSet>, String>((ref, channelId) async {
  final authState = ref.watch(authProvider);
  final isDemoMode = authState is AuthDemoMode;

  if (isDemoMode || FeatureFlags.useMockRepositories) {
    return _mockStickerSets(channelId);
  }

  // 실 구현: Supabase에서 조회
  // TODO: SupabaseStickerRepository 구현
  return [];
});

// ============================================
// Purchased Sets for Current User
// ============================================

final purchasedStickerSetsProvider = FutureProvider<Set<String>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is AuthDemoMode) {
    // 데모: 첫 번째 세트만 구매 완료
    return {'sticker_set_demo_001'};
  }
  return {};
});

// ============================================
// Sticker Actions
// ============================================

class StickerActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  StickerActionsNotifier(this._ref) : super(const AsyncData(null));

  /// 스티커 팩 구매
  Future<bool> purchaseStickerSet(String stickerSetId) async {
    state = const AsyncLoading();
    try {
      final authState = _ref.read(authProvider);
      if (authState is AuthDemoMode) {
        // 데모 모드: 즉시 구매 성공
        await Future.delayed(const Duration(milliseconds: 500));
        state = const AsyncData(null);
        _ref.invalidate(purchasedStickerSetsProvider);
        return true;
      }

      // 실 구현: RPC 호출
      // await supabase.rpc('purchase_sticker_set', params: {...});
      state = const AsyncData(null);
      _ref.invalidate(purchasedStickerSetsProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final stickerActionsProvider =
    StateNotifierProvider<StickerActionsNotifier, AsyncValue<void>>((ref) {
  return StickerActionsNotifier(ref);
});

// ============================================
// Mock Data
// ============================================

const _uuid = Uuid();

List<StickerSet> _mockStickerSets(String channelId) {
  final now = DateTime.now();
  return [
    StickerSet(
      id: 'sticker_set_demo_001',
      channelId: channelId,
      creatorId: DemoConfig.demoCreatorId,
      name: '하늘달 기본 스티커',
      description: '하늘달의 귀여운 기본 스티커 팩',
      thumbnailUrl: DemoConfig.avatarUrl('sticker_pack1'),
      priceDt: 0,
      createdAt: now.subtract(const Duration(days: 60)),
      isPurchased: true,
      stickers: List.generate(
        8,
        (i) => Sticker(
          id: _uuid.v4(),
          stickerSetId: 'sticker_set_demo_001',
          name: '스티커 ${i + 1}',
          imageUrl: DemoConfig.avatarUrl('sticker_basic_${i + 1}', size: 120),
          sortOrder: i,
          createdAt: now,
        ),
      ),
    ),
    StickerSet(
      id: 'sticker_set_demo_002',
      channelId: channelId,
      creatorId: DemoConfig.demoCreatorId,
      name: '하늘달 프리미엄 스티커',
      description: 'VIP 전용 특별 스티커 팩 ✨',
      thumbnailUrl: DemoConfig.avatarUrl('sticker_pack2'),
      priceDt: 300,
      createdAt: now.subtract(const Duration(days: 30)),
      isPurchased: false,
      stickers: List.generate(
        6,
        (i) => Sticker(
          id: _uuid.v4(),
          stickerSetId: 'sticker_set_demo_002',
          name: '프리미엄 ${i + 1}',
          imageUrl: DemoConfig.avatarUrl('sticker_premium_${i + 1}', size: 120),
          sortOrder: i,
          createdAt: now,
        ),
      ),
    ),
  ];
}
