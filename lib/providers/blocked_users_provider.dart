import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_client.dart';
import '../core/utils/app_logger.dart';
import '../data/models/blocked_user.dart';
import 'auth_provider.dart';

/// 차단된 사용자 목록 프로바이더
final blockedUsersProvider = FutureProvider<List<BlockedUser>>((ref) async {
  final authState = ref.watch(authProvider);

  // 데모 모드: 빈 목록
  if (authState is AuthDemoMode) {
    return [];
  }

  // 미인증: 빈 목록
  if (authState is! AuthAuthenticated) {
    return [];
  }

  try {
    final userId = authState.user.id;
    final response = await SupabaseConfig.client.from('user_blocks').select('''
          id, blocker_id, blocked_id, reason, created_at,
          blocked_profile:user_profiles!user_blocks_blocked_id_fkey(display_name, avatar_url)
        ''').eq('blocker_id', userId).order('created_at', ascending: false);

    return (response as List)
        .map((row) => BlockedUser.fromJson(row as Map<String, dynamic>))
        .toList();
  } catch (e) {
    AppLogger.error(e, tag: 'Block', message: 'Error fetching blocked users');
    return [];
  }
});

/// 사용자 차단 해제
Future<bool> unblockUser(WidgetRef ref, String blockedId) async {
  try {
    // RPC 호출: unblock_user()
    await SupabaseConfig.client.rpc('unblock_user', params: {
      'target_user_id': blockedId,
    });

    // 목록 갱신
    ref.invalidate(blockedUsersProvider);

    AppLogger.debug('Unblocked user: $blockedId', tag: 'Block');
    return true;
  } catch (e) {
    AppLogger.error(e, tag: 'Block', message: 'Error unblocking user');
    return false;
  }
}
