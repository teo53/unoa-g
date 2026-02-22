import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';

/// Repository for DT auto-charge configuration
class SupabaseAutoChargeRepository {
  final SupabaseClient _supabase;

  SupabaseAutoChargeRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseConfig.client;

  String get _currentUserId => _supabase.currentUserId;

  /// Get auto-charge config for current user
  Future<Map<String, dynamic>?> getConfig() async {
    return await _supabase
        .from('dt_auto_charge_config')
        .select()
        .eq('user_id', _currentUserId)
        .maybeSingle();
  }

  /// Save auto-charge configuration
  Future<void> saveConfig({
    required bool isEnabled,
    required int thresholdDt,
    required int chargeAmountDt,
    required int maxMonthlyCharges,
  }) async {
    await _supabase.from('dt_auto_charge_config').upsert(
      {
        'user_id': _currentUserId,
        'is_enabled': isEnabled,
        'threshold_dt': thresholdDt,
        'charge_amount_dt': chargeAmountDt,
        'max_monthly_charges': maxMonthlyCharges,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }
}
