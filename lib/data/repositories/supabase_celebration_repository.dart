import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';

/// Repository for celebration operations: birthday, templates, queue
class SupabaseCelebrationRepository {
  final SupabaseClient _supabase;

  SupabaseCelebrationRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseConfig.client;

  // ============================================
  // Fan Birthday
  // ============================================

  Future<void> saveFanBirthday({
    required String userId,
    required String channelId,
    required int birthMonth,
    required int birthDay,
    required bool isVisible,
  }) async {
    await _supabase.from('fan_celebrations').upsert(
      {
        'user_id': userId,
        'channel_id': channelId,
        'birth_month': birthMonth,
        'birth_day': birthDay,
        'birthday_visible': isVisible,
        'visibility_consent_at':
            isVisible ? DateTime.now().toUtc().toIso8601String() : null,
      },
      onConflict: 'user_id,channel_id',
    );
  }

  Future<void> deleteFanBirthday(String userId, String channelId) async {
    await _supabase
        .from('fan_celebrations')
        .delete()
        .eq('user_id', userId)
        .eq('channel_id', channelId);
  }

  // ============================================
  // Celebration Queue
  // ============================================

  Future<Map<String, dynamic>> getCelebrationQueue(String channelId) async {
    final response = await _supabase.rpc(
      'get_celebration_queue',
      params: {'p_channel_id': channelId},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> sendCelebrationMessage({
    required String channelId,
    required String content,
  }) async {
    final result = await _supabase
        .from('messages')
        .insert({
          'channel_id': channelId,
          'sender_type': 'artist',
          'delivery_scope': 'broadcast',
          'content': content,
          'message_type': 'text',
        })
        .select('id')
        .single();
    return result;
  }

  Future<void> markCelebrationSent({
    required String eventId,
    required String messageId,
  }) async {
    await _supabase.from('celebration_events').update({
      'status': 'sent',
      'sent_at': DateTime.now().toUtc().toIso8601String(),
      'message_id': messageId,
    }).eq('id', eventId);
  }

  // ============================================
  // Celebration Templates
  // ============================================

  Future<List<Map<String, dynamic>>> getCelebrationTemplates({
    required String channelId,
    required String eventType,
  }) async {
    final response = await _supabase
        .from('celebration_templates')
        .select()
        .or('channel_id.is.null,channel_id.eq.$channelId')
        .eq('event_type', eventType)
        .eq('is_active', true)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(response as List);
  }
}
