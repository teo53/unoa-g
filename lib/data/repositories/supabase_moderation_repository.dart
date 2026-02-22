import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';

/// Repository for moderation operations: reports, blocks, hidden fans
class SupabaseModerationRepository {
  final SupabaseClient _supabase;

  SupabaseModerationRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseConfig.client;

  String get _currentUserId => _supabase.currentUserId;

  // ============================================
  // Reports
  // ============================================

  Future<void> submitReport({
    required String channelId,
    required String reason,
    required String description,
  }) async {
    await _supabase.from('reports').insert({
      'reporter_id': _currentUserId,
      'channel_id': channelId,
      'reason': reason,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ============================================
  // User Blocks
  // ============================================

  Future<void> blockUser(String blockedId) async {
    await _supabase.from('user_blocks').insert({
      'blocker_id': _currentUserId,
      'blocked_id': blockedId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unblockUser(String blockedId) async {
    await _supabase
        .from('user_blocks')
        .delete()
        .eq('blocker_id', _currentUserId)
        .eq('blocked_id', blockedId);
  }

  // ============================================
  // Hidden Fans
  // ============================================

  Future<void> hideFan(String fanId, {String reason = 'manual_hide'}) async {
    await _supabase.from('hidden_fans').upsert(
      {
        'creator_id': _currentUserId,
        'fan_id': fanId,
        'reason': reason,
      },
      onConflict: 'creator_id,fan_id',
    );
  }

  Future<void> unhideFan(String fanId) async {
    await _supabase
        .from('hidden_fans')
        .delete()
        .eq('creator_id', _currentUserId)
        .eq('fan_id', fanId);
  }
}
