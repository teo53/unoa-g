import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';

/// Repository for agency contract operations
class SupabaseAgencyRepository {
  final SupabaseClient _supabase;

  SupabaseAgencyRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseConfig.client;

  String get _currentUserId => _supabase.currentUserId;

  /// Get the creator_profiles.id for current user
  Future<Map<String, dynamic>?> getCreatorProfile() async {
    return await _supabase
        .from('creator_profiles')
        .select('id, agency_id')
        .eq('user_id', _currentUserId)
        .maybeSingle();
  }

  /// Get active agency contract with agency info
  Future<Map<String, dynamic>?> getActiveContract(
      String creatorProfileId) async {
    return await _supabase
        .from('agency_creators')
        .select('''
          id, agency_id, status, revenue_share_rate, settlement_period,
          contract_start_date, contract_end_date, power_of_attorney_url,
          notes, created_at,
          agencies!inner(name, logo_url)
        ''')
        .eq('creator_profile_id', creatorProfileId)
        .eq('status', 'active')
        .maybeSingle();
  }

  /// Get pending agency invitations
  Future<List<Map<String, dynamic>>> getPendingInvitations(
      String creatorProfileId) async {
    final response = await _supabase.from('agency_creators').select('''
          id, agency_id, revenue_share_rate, settlement_period,
          contract_start_date, contract_end_date, power_of_attorney_url,
          notes, created_at,
          agencies!inner(name, logo_url)
        ''').eq('creator_profile_id', creatorProfileId).eq('status', 'pending');
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Accept or reject agency invitation
  Future<dynamic> respondToInvitation({
    required String contractId,
    required bool accept,
  }) async {
    return await _supabase.rpc('accept_agency_contract', params: {
      'p_contract_id': contractId,
      'p_accept': accept,
    });
  }
}
