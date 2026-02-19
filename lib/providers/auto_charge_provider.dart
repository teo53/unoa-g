/// Auto-Charge Provider
/// DT 자동충전 설정 관리 (Riverpod)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/auto_charge_config.dart';
import 'auth_provider.dart';

/// 자동충전 설정 조회
final autoChargeConfigProvider =
    FutureProvider.autoDispose<AutoChargeConfig?>((ref) async {
  final authState = ref.watch(authProvider);

  if (authState is AuthDemoMode) {
    // 데모 모드: 비활성화 상태 반환
    return AutoChargeConfig(
      id: 'demo_config',
      userId: authState.user.id,
      isEnabled: false,
      thresholdDt: 100,
      chargeAmountDt: 1000,
      maxMonthlyCharges: 5,
      chargesThisMonth: 0,
      createdAt: DateTime.now(),
    );
  }

  if (authState is! AuthAuthenticated) return null;

  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser!.id;

  final data = await supabase
      .from('dt_auto_charge_config')
      .select()
      .eq('user_id', userId)
      .maybeSingle();

  if (data == null) return null;
  return AutoChargeConfig.fromJson(data);
});

/// 자동충전 설정 관리 Notifier
class AutoChargeNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AutoChargeNotifier(this._ref) : super(const AsyncData(null));

  /// 자동충전 설정 저장/업데이트
  Future<void> saveConfig({
    required bool isEnabled,
    required int thresholdDt,
    required int chargeAmountDt,
    int maxMonthlyCharges = 5,
  }) async {
    final authState = _ref.read(authProvider);

    if (authState is AuthDemoMode) {
      // 데모 모드: 성공 시뮬레이션
      state = const AsyncLoading();
      await Future.delayed(const Duration(milliseconds: 500));
      state = const AsyncData(null);
      _ref.invalidate(autoChargeConfigProvider);
      return;
    }

    if (authState is! AuthAuthenticated) return;

    state = const AsyncLoading();
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      await supabase.from('dt_auto_charge_config').upsert(
        {
          'user_id': userId,
          'is_enabled': isEnabled,
          'threshold_dt': thresholdDt,
          'charge_amount_dt': chargeAmountDt,
          'max_monthly_charges': maxMonthlyCharges,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );

      state = const AsyncData(null);
      _ref.invalidate(autoChargeConfigProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 자동충전 토글
  Future<void> toggleEnabled(bool isEnabled) async {
    final config = await _ref.read(autoChargeConfigProvider.future);
    if (config == null) {
      await saveConfig(
        isEnabled: isEnabled,
        thresholdDt: 100,
        chargeAmountDt: 1000,
      );
    } else {
      await saveConfig(
        isEnabled: isEnabled,
        thresholdDt: config.thresholdDt,
        chargeAmountDt: config.chargeAmountDt,
        maxMonthlyCharges: config.maxMonthlyCharges,
      );
    }
  }
}

final autoChargeNotifierProvider =
    StateNotifierProvider<AutoChargeNotifier, AsyncValue<void>>((ref) {
  return AutoChargeNotifier(ref);
});
