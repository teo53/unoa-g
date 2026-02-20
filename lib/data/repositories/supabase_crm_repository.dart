import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/fan_note.dart';
import '../models/fan_tag.dart';
import '../models/fan_profile_summary.dart';
import 'crm_repository.dart';

/// Supabase implementation of ICrmRepository
/// 크리에이터-팬 CRM 데이터를 Supabase에서 관리
class SupabaseCrmRepository implements ICrmRepository {
  final SupabaseClient _supabase;

  SupabaseCrmRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseConfig.client;

  // ============================================
  // Fan Profile
  // ============================================

  @override
  Future<FanProfileSummary> getFanProfile(
      String creatorId, String fanId) async {
    try {
      // 1. 사용자 프로필 조회
      final profileResponse = await _supabase
          .from('user_profiles')
          .select('display_name, avatar_url')
          .eq('id', fanId)
          .maybeSingle();

      // 2. 구독 정보 조회
      final subResponse = await _supabase
          .from('subscriptions')
          .select('tier, created_at')
          .eq('subscriber_id', fanId)
          .eq('channel_id', creatorId)
          .eq('is_active', true)
          .maybeSingle();

      // 3. 메모 조회
      final note = await getNote(creatorId, fanId);

      // 4. 태그 조회
      final tags = await getFanTags(creatorId, fanId);

      // 5. DT 사용액 조회 (wallet_ledger 합산)
      final dtResponse = await _supabase
          .from('wallet_ledger')
          .select('amount')
          .eq('user_id', fanId)
          .eq('recipient_id', creatorId)
          .lt('amount', 0);

      final totalDtSpent = (dtResponse as List).fold<int>(
          0, (sum, row) => sum + ((row['amount'] as num?)?.abs().toInt() ?? 0));

      // 구독 일수 계산
      int subscribedDays = 0;
      if (subResponse != null && subResponse['created_at'] != null) {
        final subDate = DateTime.parse(subResponse['created_at'] as String);
        subscribedDays = DateTime.now().difference(subDate).inDays;
      }

      return FanProfileSummary(
        fanId: fanId,
        displayName:
            profileResponse?['display_name'] as String? ?? '알 수 없는 사용자',
        avatarUrl: profileResponse?['avatar_url'] as String?,
        tier: subResponse?['tier'] as String? ?? 'BASIC',
        subscribedDays: subscribedDays,
        totalDtSpent: totalDtSpent,
        note: note,
        tags: tags,
      );
    } catch (e) {
      AppLogger.error(e, tag: 'CRM', message: 'Error fetching fan profile');
      rethrow;
    }
  }

  // ============================================
  // Notes
  // ============================================

  @override
  Future<FanNote?> getNote(String creatorId, String fanId) async {
    try {
      final response = await _supabase
          .from('fan_notes')
          .select()
          .eq('creator_id', creatorId)
          .eq('fan_id', fanId)
          .maybeSingle();

      if (response == null) return null;
      return FanNote.fromJson(response);
    } catch (e) {
      AppLogger.error(e, tag: 'CRM', message: 'Error fetching note');
      return null;
    }
  }

  @override
  Future<FanNote> upsertNote(
      String creatorId, String fanId, String content) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('fan_notes')
          .upsert(
            {
              'creator_id': creatorId,
              'fan_id': fanId,
              'content': content,
              'updated_at': now,
            },
            onConflict: 'creator_id, fan_id',
          )
          .select()
          .single();

      return FanNote.fromJson(response);
    } catch (e) {
      AppLogger.error(e, tag: 'CRM', message: 'Error upserting note');
      rethrow;
    }
  }

  // ============================================
  // Tags
  // ============================================

  @override
  Future<List<FanTag>> getCreatorTags(String creatorId) async {
    try {
      final response = await _supabase
          .from('fan_tags')
          .select()
          .eq('creator_id', creatorId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((row) => FanTag.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error(e, tag: 'CRM', message: 'Error fetching tags');
      return [];
    }
  }

  @override
  Future<FanTag> createTag(String creatorId, String name, String color) async {
    try {
      final response = await _supabase
          .from('fan_tags')
          .insert({
            'creator_id': creatorId,
            'tag_name': name,
            'tag_color': color,
          })
          .select()
          .single();

      return FanTag.fromJson(response);
    } catch (e) {
      AppLogger.error(e, tag: 'CRM', message: 'Error creating tag');
      rethrow;
    }
  }

  @override
  Future<void> deleteTag(String tagId) async {
    try {
      await _supabase.from('fan_tags').delete().eq('id', tagId);
    } catch (e) {
      AppLogger.error(e, tag: 'CRM', message: 'Error deleting tag');
      rethrow;
    }
  }

  @override
  Future<void> assignTag(String fanId, String tagId, String assignedBy) async {
    try {
      await _supabase.from('fan_tag_assignments').upsert(
        {
          'fan_id': fanId,
          'tag_id': tagId,
          'assigned_by': assignedBy,
        },
        onConflict: 'fan_id, tag_id',
      );
    } catch (e) {
      AppLogger.error(e, tag: 'CRM', message: 'Error assigning tag');
      rethrow;
    }
  }

  @override
  Future<void> removeTagAssignment(String fanId, String tagId) async {
    try {
      await _supabase
          .from('fan_tag_assignments')
          .delete()
          .eq('fan_id', fanId)
          .eq('tag_id', tagId);
    } catch (e) {
      AppLogger.error(e, tag: 'CRM', message: 'Error removing tag');
      rethrow;
    }
  }

  @override
  Future<List<FanTag>> getFanTags(String creatorId, String fanId) async {
    try {
      // fan_tag_assignments JOIN fan_tags
      final response = await _supabase
          .from('fan_tag_assignments')
          .select('tag_id, fan_tags!inner(*)')
          .eq('fan_id', fanId)
          .eq('fan_tags.creator_id', creatorId);

      return (response as List).map((row) {
        final tagData = row['fan_tags'] as Map<String, dynamic>;
        return FanTag.fromJson(tagData);
      }).toList();
    } catch (e) {
      AppLogger.error(e, tag: 'CRM', message: 'Error fetching fan tags');
      return [];
    }
  }
}
