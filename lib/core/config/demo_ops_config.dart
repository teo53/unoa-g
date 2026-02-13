/// Demo mock data for Ops CRM runtime configuration
/// Used when DEMO_MODE is active (no Supabase connection)
library;

class DemoOpsConfig {
  DemoOpsConfig._();

  /// Demo banners for the app
  static final List<Map<String, dynamic>> demoBanners = [
    {
      'id': 'demo-banner-1',
      'title': '신규 아티스트 오픈 기념 이벤트',
      'placement': 'home_top',
      'image_url': 'https://picsum.photos/seed/unoa-banner1/800/400',
      'link_url': '/discover',
      'link_type': 'internal',
      'priority': 10,
      'target_audience': 'all',
      'start_at': null,
      'end_at': null,
    },
    {
      'id': 'demo-banner-2',
      'title': 'VIP 전용 특별 혜택 안내',
      'placement': 'home_bottom',
      'image_url': 'https://picsum.photos/seed/unoa-banner2/800/400',
      'link_url': '/subscriptions',
      'link_type': 'internal',
      'priority': 5,
      'target_audience': 'vip',
      'start_at': null,
      'end_at': null,
    },
  ];

  /// Demo feature flags
  static final Map<String, Map<String, dynamic>> demoFlags = {
    'dark_mode_v2': {
      'enabled': true,
      'rollout_percent': 50,
      'payload': {'variant': 'new_palette'},
    },
    'gift_feature': {
      'enabled': false,
      'rollout_percent': 0,
      'payload': {},
    },
  };

  /// Demo config hash (for ETag-like caching)
  static const String demoConfigHash = 'demo-hash-001';

  /// Get demo banners for a specific placement
  static List<Map<String, dynamic>> getBannersForPlacement(String placement) {
    return demoBanners.where((b) => b['placement'] == placement).toList()
      ..sort((a, b) => (b['priority'] as int).compareTo(a['priority'] as int));
  }

  /// Check if a demo feature flag is enabled
  static bool isFlagEnabled(String flagKey) {
    final flag = demoFlags[flagKey];
    if (flag == null) return false;
    return flag['enabled'] == true;
  }
}
