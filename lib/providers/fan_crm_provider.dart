import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/demo_config.dart';
import '../core/utils/app_logger.dart';
import '../data/models/fan_note.dart';
import '../data/models/fan_tag.dart';
import '../data/models/fan_profile_summary.dart';
import '../data/repositories/crm_repository.dart';
import '../data/repositories/supabase_crm_repository.dart';
import '../data/repositories/mock_crm_repository.dart';
import 'auth_provider.dart';
import 'repository_providers.dart';

// ============================================
// CRM Repository DI
// ============================================

/// CRM repository provider - 데모/실 모드 자동 분기
final crmRepositoryProvider = Provider<ICrmRepository>((ref) {
  final authState = ref.watch(authProvider);
  final isDemoMode = authState is AuthDemoMode;
  if (isDemoMode || FeatureFlags.useMockRepositories) {
    return MockCrmRepository();
  }
  return SupabaseCrmRepository();
});

// ============================================
// 현재 크리에이터 ID
// ============================================

/// 현재 로그인한 크리에이터의 ID
final currentCreatorIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthDemoMode) {
    return DemoConfig.demoCreatorId;
  }
  if (authState is AuthAuthenticated) {
    return authState.user.id;
  }
  return null;
});

// ============================================
// Fan Profile
// ============================================

/// 팬 프로필 요약 (팬ID별)
final fanProfileProvider =
    FutureProvider.family<FanProfileSummary, String>((ref, fanId) async {
  final repo = ref.watch(crmRepositoryProvider);
  final creatorId = ref.watch(currentCreatorIdProvider);
  if (creatorId == null) {
    throw StateError('Not authenticated as creator');
  }
  return repo.getFanProfile(creatorId, fanId);
});

// ============================================
// Fan Memo (Auto-save with debounce)
// ============================================

/// 팬 메모 편집 상태 파라미터
class FanMemoParams {
  final String creatorId;
  final String fanId;

  const FanMemoParams({required this.creatorId, required this.fanId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FanMemoParams &&
          other.creatorId == creatorId &&
          other.fanId == fanId;

  @override
  int get hashCode => Object.hash(creatorId, fanId);
}

/// 팬 메모 StateNotifier (500ms 디바운스 자동저장)
class FanMemoNotifier extends StateNotifier<AsyncValue<FanNote?>> {
  final ICrmRepository _repo;
  final String _creatorId;
  final String _fanId;
  Timer? _debounce;

  FanMemoNotifier({
    required ICrmRepository repo,
    required String creatorId,
    required String fanId,
  })  : _repo = repo,
        _creatorId = creatorId,
        _fanId = fanId,
        super(const AsyncValue.loading()) {
    _loadNote();
  }

  Future<void> _loadNote() async {
    try {
      final note = await _repo.getNote(_creatorId, _fanId);
      if (mounted) {
        state = AsyncValue.data(note);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// 메모 내용 업데이트 (500ms 디바운스)
  void updateMemo(String content) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _save(content);
    });
  }

  /// 즉시 저장 (바텀시트 닫기 전)
  Future<void> saveImmediately(String content) async {
    _debounce?.cancel();
    await _save(content);
  }

  Future<void> _save(String content) async {
    try {
      final note = await _repo.upsertNote(_creatorId, _fanId, content);
      if (mounted) {
        state = AsyncValue.data(note);
      }
      AppLogger.debug('Memo saved for fan $_fanId', tag: 'CRM');
    } catch (e, st) {
      AppLogger.error(e, tag: 'CRM', message: 'Error saving memo');
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

/// 팬 메모 프로바이더 (family)
final fanMemoProvider = StateNotifierProvider.family<FanMemoNotifier,
    AsyncValue<FanNote?>, FanMemoParams>(
  (ref, params) {
    final repo = ref.watch(crmRepositoryProvider);
    return FanMemoNotifier(
      repo: repo,
      creatorId: params.creatorId,
      fanId: params.fanId,
    );
  },
);

// ============================================
// Creator Tags
// ============================================

/// 크리에이터의 전체 태그 목록
final creatorTagsProvider = FutureProvider<List<FanTag>>((ref) async {
  final repo = ref.watch(crmRepositoryProvider);
  final creatorId = ref.watch(currentCreatorIdProvider);
  if (creatorId == null) return [];
  return repo.getCreatorTags(creatorId);
});

/// 특정 팬에 할당된 태그 목록
final fanTagsProvider =
    FutureProvider.family<List<FanTag>, String>((ref, fanId) async {
  final repo = ref.watch(crmRepositoryProvider);
  final creatorId = ref.watch(currentCreatorIdProvider);
  if (creatorId == null) return [];
  return repo.getFanTags(creatorId, fanId);
});

// ============================================
// Tag Actions
// ============================================

/// 태그 생성 액션
Future<FanTag?> createTag(
  WidgetRef ref,
  String name,
  String color,
) async {
  final repo = ref.read(crmRepositoryProvider);
  final creatorId = ref.read(currentCreatorIdProvider);
  if (creatorId == null) return null;

  try {
    final tag = await repo.createTag(creatorId, name, color);
    ref.invalidate(creatorTagsProvider);
    return tag;
  } catch (e) {
    AppLogger.error(e, tag: 'CRM', message: 'Error creating tag');
    return null;
  }
}

/// 태그 할당 액션
Future<void> assignTagToFan(
  WidgetRef ref,
  String fanId,
  String tagId,
) async {
  final repo = ref.read(crmRepositoryProvider);
  final creatorId = ref.read(currentCreatorIdProvider);
  if (creatorId == null) return;

  try {
    await repo.assignTag(fanId, tagId, creatorId);
    ref.invalidate(fanTagsProvider(fanId));
    ref.invalidate(fanProfileProvider(fanId));
    ref.invalidate(creatorTagsProvider);
  } catch (e) {
    AppLogger.error(e, tag: 'CRM', message: 'Error assigning tag');
  }
}

/// 태그 할당 해제 액션
Future<void> removeTagFromFan(
  WidgetRef ref,
  String fanId,
  String tagId,
) async {
  final repo = ref.read(crmRepositoryProvider);
  final creatorId = ref.read(currentCreatorIdProvider);
  if (creatorId == null) return;

  try {
    await repo.removeTagAssignment(fanId, tagId);
    ref.invalidate(fanTagsProvider(fanId));
    ref.invalidate(fanProfileProvider(fanId));
    ref.invalidate(creatorTagsProvider);
  } catch (e) {
    AppLogger.error(e, tag: 'CRM', message: 'Error removing tag');
  }
}

/// 태그 삭제 액션
Future<void> deleteTagAction(WidgetRef ref, String tagId) async {
  final repo = ref.read(crmRepositoryProvider);

  try {
    await repo.deleteTag(tagId);
    ref.invalidate(creatorTagsProvider);
  } catch (e) {
    AppLogger.error(e, tag: 'CRM', message: 'Error deleting tag');
  }
}
