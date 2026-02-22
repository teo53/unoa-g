import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';

/// Repository for settlement and payout operations
class SupabaseSettlementRepository {
  final SupabaseClient _supabase;

  SupabaseSettlementRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseConfig.client;

  String get _currentUserId => _supabase.currentUserId;

  /// Get settlement statements for the creator
  Future<List<Map<String, dynamic>>> getStatements({int limit = 24}) async {
    final response = await _supabase
        .from('settlement_statements')
        .select('*')
        .eq('creator_id', _currentUserId)
        .order('period_start', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Get payout settings (income type etc.)
  Future<Map<String, dynamic>?> getPayoutSettings() async {
    return await _supabase
        .from('payout_settings')
        .select('income_type')
        .eq('creator_id', _currentUserId)
        .maybeSingle();
  }

  /// Update creator's income type for tax purposes
  Future<void> updateIncomeType(String incomeType) async {
    await _supabase.from('payout_settings').upsert({
      'creator_id': _currentUserId,
      'income_type': incomeType,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Export settlement data as CSV via Edge Function
  Future<Map<String, dynamic>> exportCsv({
    required String periodStart,
    required String periodEnd,
  }) async {
    final response = await _supabase.functions.invoke(
      'settlement-export',
      body: {
        'type': 'csv',
        'periodStart': periodStart,
        'periodEnd': periodEnd,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
