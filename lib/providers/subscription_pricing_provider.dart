import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';

/// 구독 가격 정책 모델
class SubscriptionPricingPolicy {
  final String preset; // 'support' | 'standard' | 'premium'
  final double multiplier;
  final String label;

  const SubscriptionPricingPolicy({
    required this.preset,
    required this.multiplier,
    required this.label,
  });

  factory SubscriptionPricingPolicy.standard() {
    return const SubscriptionPricingPolicy(
      preset: 'standard',
      multiplier: 1.0,
      label: '기본가',
    );
  }

  factory SubscriptionPricingPolicy.fromJson(Map<String, dynamic> json) {
    return SubscriptionPricingPolicy(
      preset: json['preset'] as String? ?? 'standard',
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
      label: json['label'] as String? ?? '기본가',
    );
  }

  /// 가격에 multiplier 적용 (100원 단위 반올림)
  int applyTo(int basePrice) {
    return ((basePrice * multiplier) / 100).round() * 100;
  }
}

/// 채널별 구독 가격 정책 조회
/// channelId를 family 파라미터로 받아 해당 채널의 가격 정책 반환
final subscriptionPricingPolicyProvider =
    FutureProvider.family<SubscriptionPricingPolicy, String>(
  (ref, channelId) async {
    // 데모 모드: 기본값 반환
    final authState = ref.read(authProvider);
    if (authState is AuthDemoMode) {
      return SubscriptionPricingPolicy.standard();
    }

    // 프로덕션: policy_config에서 조회
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('policy_config')
          .select('value')
          .eq('key', 'subscription_pricing:$channelId')
          .maybeSingle();

      if (response == null || response['value'] == null) {
        return SubscriptionPricingPolicy.standard();
      }

      return SubscriptionPricingPolicy.fromJson(
        response['value'] as Map<String, dynamic>,
      );
    } catch (_) {
      return SubscriptionPricingPolicy.standard();
    }
  },
);
