/// Moments Provider
/// 팬 모먼트 상태 관리 (Riverpod)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/fan_moment.dart';
import '../data/repositories/moments_repository.dart';
import '../data/repositories/supabase_moments_repository.dart';
import '../data/repositories/mock_moments_repository.dart';
import 'auth_provider.dart';
import 'repository_providers.dart';

// ============================================
// Repository DI
// ============================================

final momentsRepositoryProvider = Provider<IMomentsRepository>((ref) {
  final authState = ref.watch(authProvider);
  final isDemoMode = authState is AuthDemoMode;
  if (isDemoMode || FeatureFlags.useMockRepositories) {
    return MockMomentsRepository();
  }
  return SupabaseMomentsRepository();
});

// ============================================
// Moments List Provider
// ============================================

/// 모먼트 필터 상태
class MomentsFilter {
  final String? channelId;
  final MomentSourceType? sourceType;
  final bool favoritesOnly;

  const MomentsFilter({
    this.channelId,
    this.sourceType,
    this.favoritesOnly = false,
  });

  MomentsFilter copyWith({
    String? channelId,
    MomentSourceType? sourceType,
    bool? favoritesOnly,
  }) {
    return MomentsFilter(
      channelId: channelId ?? this.channelId,
      sourceType: sourceType,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MomentsFilter &&
        other.channelId == channelId &&
        other.sourceType == sourceType &&
        other.favoritesOnly == favoritesOnly;
  }

  @override
  int get hashCode => Object.hash(channelId, sourceType, favoritesOnly);
}

/// 현재 필터 상태
final momentsFilterProvider =
    StateProvider<MomentsFilter>((ref) => const MomentsFilter());

/// 필터 적용된 모먼트 목록
final momentsListProvider =
    FutureProvider.autoDispose<List<FanMoment>>((ref) async {
  final repo = ref.watch(momentsRepositoryProvider);
  final filter = ref.watch(momentsFilterProvider);

  return repo.getMoments(
    channelId: filter.channelId,
    sourceType: filter.sourceType,
    favoritesOnly: filter.favoritesOnly,
    limit: 50,
  );
});

/// 모먼트 총 개수
final momentsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(momentsRepositoryProvider);
  return repo.getMomentCount();
});

// ============================================
// Moment Actions Notifier
// ============================================

class MomentActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final IMomentsRepository _repo;
  final Ref _ref;

  MomentActionsNotifier(this._repo, this._ref) : super(const AsyncData(null));

  /// 메시지를 모먼트로 저장
  Future<FanMoment?> saveMessage({
    required String channelId,
    required String messageId,
    required String content,
    String? mediaUrl,
    String? mediaType,
    String? artistName,
    String? artistAvatarUrl,
  }) async {
    state = const AsyncLoading();
    try {
      final moment = await _repo.saveMessageAsMoment(
        channelId: channelId,
        messageId: messageId,
        content: content,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        artistName: artistName,
        artistAvatarUrl: artistAvatarUrl,
      );
      state = const AsyncData(null);
      _invalidateMoments();
      return moment;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// 즐겨찾기 토글
  Future<void> toggleFavorite(String momentId) async {
    try {
      await _repo.toggleFavorite(momentId);
      _invalidateMoments();
    } catch (_) {
      // 에러 무시 (UI 낙관적 업데이트 유지)
    }
  }

  /// 모먼트 삭제
  Future<void> deleteMoment(String momentId) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteMoment(momentId);
      state = const AsyncData(null);
      _invalidateMoments();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void _invalidateMoments() {
    _ref.invalidate(momentsListProvider);
    _ref.invalidate(momentsCountProvider);
  }
}

final momentActionsProvider =
    StateNotifierProvider<MomentActionsNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(momentsRepositoryProvider);
  return MomentActionsNotifier(repo, ref);
});
