import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/demo_ops_config.dart';
import '../core/supabase/supabase_client.dart';
import 'auth_provider.dart';

// ── Models ──

/// Banner source type — 정렬 우선순위: ops > fan_ad > creator_promo
enum BannerSourceType {
  ops,          // 운영자 발행 배너
  fanAd,        // 팬 유료 광고 (fan_ads 테이블)
  creatorPromo, // 크리에이터 자체 홍보 (미래 확장용)
}

/// A published banner from app_public_config
class OpsPublishedBanner {
  final String id;
  final String title;
  final String placement;
  final String imageUrl;
  final String linkUrl;
  final String linkType;
  final int priority;
  final String targetAudience;
  /// 배너 출처 구분 (정렬 및 렌더링 분기에 사용)
  final BannerSourceType sourceType;
  /// fan_ads.id — sourceType == fanAd 일 때만 non-null
  final String? fanAdId;

  const OpsPublishedBanner({
    required this.id,
    required this.title,
    required this.placement,
    required this.imageUrl,
    required this.linkUrl,
    required this.linkType,
    required this.priority,
    required this.targetAudience,
    this.sourceType = BannerSourceType.ops,
    this.fanAdId,
  });

  factory OpsPublishedBanner.fromJson(Map<String, dynamic> json) {
    final sourceRaw = json['source_type'] as String? ?? 'ops';
    final sourceType = switch (sourceRaw) {
      'fan_ad'        => BannerSourceType.fanAd,
      'creator_promo' => BannerSourceType.creatorPromo,
      _               => BannerSourceType.ops,
    };
    return OpsPublishedBanner(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      placement: json['placement'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      linkUrl: json['link_url'] as String? ?? '',
      linkType: json['link_type'] as String? ?? 'none',
      priority: json['priority'] as int? ?? 0,
      targetAudience: json['target_audience'] as String? ?? 'all',
      sourceType: sourceType,
      fanAdId: json['fan_ad_id'] as String?,
    );
  }
}

/// A published feature flag
class OpsPublishedFlag {
  final bool enabled;
  final int rolloutPercent;
  final Map<String, dynamic> payload;

  const OpsPublishedFlag({
    required this.enabled,
    required this.rolloutPercent,
    required this.payload,
  });

  factory OpsPublishedFlag.fromJson(Map<String, dynamic> json) {
    return OpsPublishedFlag(
      enabled: json['enabled'] as bool? ?? false,
      rolloutPercent: json['rollout_percent'] as int? ?? 0,
      payload: json['payload'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Full ops runtime config
class OpsConfig {
  final List<OpsPublishedBanner> banners;
  final Map<String, OpsPublishedFlag> flags;
  final String configHash;
  final DateTime fetchedAt;

  const OpsConfig({
    required this.banners,
    required this.flags,
    required this.configHash,
    required this.fetchedAt,
  });

  /// Empty/default config
  static OpsConfig get empty => OpsConfig(
        banners: const [],
        flags: const {},
        configHash: '',
        fetchedAt: DateTime.now(),
      );

  /// Get banners for a specific placement.
  /// 정렬 기준: 1차 sourceType (ops > fan_ad > creator_promo), 2차 priority 내림차순.
  List<OpsPublishedBanner> bannersForPlacement(String placement) {
    int sourceOrder(BannerSourceType t) => switch (t) {
          BannerSourceType.ops          => 0,
          BannerSourceType.fanAd        => 1,
          BannerSourceType.creatorPromo => 2,
        };
    return banners.where((b) => b.placement == placement).toList()
      ..sort((a, b) {
        final srcCmp = sourceOrder(a.sourceType).compareTo(sourceOrder(b.sourceType));
        if (srcCmp != 0) return srcCmp;
        return b.priority.compareTo(a.priority);
      });
  }

  /// Check if a feature flag is enabled
  bool isFlagEnabled(String flagKey) {
    final flag = flags[flagKey];
    return flag?.enabled ?? false;
  }

  /// Get flag payload
  Map<String, dynamic>? getFlagPayload(String flagKey) {
    return flags[flagKey]?.payload;
  }
}

// ── State ──

class OpsConfigState {
  final OpsConfig config;
  final bool loading;
  final String? error;

  const OpsConfigState({
    required this.config,
    this.loading = false,
    this.error,
  });

  OpsConfigState copyWith({
    OpsConfig? config,
    bool? loading,
    String? error,
  }) {
    return OpsConfigState(
      config: config ?? this.config,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

// ── Cache Keys ──

const _cacheKeyConfig = 'ops_config_json';
const _cacheKeyHash = 'ops_config_hash';
const _cacheKeyTimestamp = 'ops_config_ts';
const _cacheTtlMinutes = 10;

// ── Notifier ──

class OpsConfigNotifier extends StateNotifier<OpsConfigState> {
  final Ref _ref;

  OpsConfigNotifier(this._ref)
      : super(OpsConfigState(config: OpsConfig.empty)) {
    _loadCachedThenFetch();
  }

  /// Load cached config first, then fetch fresh from server
  Future<void> _loadCachedThenFetch() async {
    // Check demo mode
    final isDemoMode = _ref.read(isDemoModeProvider);
    if (isDemoMode) {
      state = OpsConfigState(config: _buildDemoConfig());
      return;
    }

    // Try cache
    await _loadFromCache();

    // Fetch fresh
    await refresh();
  }

  /// Build config from demo data
  OpsConfig _buildDemoConfig() {
    return OpsConfig(
      banners: DemoOpsConfig.demoBanners
          .map((b) => OpsPublishedBanner.fromJson(b))
          .toList(),
      flags: DemoOpsConfig.demoFlags.map(
        (key, value) => MapEntry(key, OpsPublishedFlag.fromJson(value)),
      ),
      configHash: DemoOpsConfig.demoConfigHash,
      fetchedAt: DateTime.now(),
    );
  }

  /// Load config from SharedPreferences cache
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_cacheKeyConfig);
      final cachedHash = prefs.getString(_cacheKeyHash);
      final cachedTs = prefs.getInt(_cacheKeyTimestamp) ?? 0;

      if (configJson == null || cachedHash == null) return;

      // Check TTL
      final age = DateTime.now().millisecondsSinceEpoch - cachedTs;
      if (age > _cacheTtlMinutes * 60 * 1000) return;

      final config = _parseConfig(configJson, cachedHash);
      if (config != null) {
        state = OpsConfigState(config: config);
      }
    } catch (e) {
      // Cache load failure is non-fatal
      if (kDebugMode) debugPrint('[OpsConfig] Cache load error: $e');
    }
  }

  /// Parse JSON config string into OpsConfig (with safe validation)
  OpsConfig? _parseConfig(String jsonStr, String hash) {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final bannersRaw = data['banners'] as List<dynamic>? ?? [];
      final flagsRaw = data['flags'] as Map<String, dynamic>? ?? {};

      final banners = bannersRaw
          .map((b) {
            try {
              return OpsPublishedBanner.fromJson(b as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<OpsPublishedBanner>()
          .toList();

      final flags = <String, OpsPublishedFlag>{};
      for (final entry in flagsRaw.entries) {
        try {
          flags[entry.key] =
              OpsPublishedFlag.fromJson(entry.value as Map<String, dynamic>);
        } catch (_) {
          // Skip invalid flag
        }
      }

      return OpsConfig(
        banners: banners,
        flags: flags,
        configHash: hash,
        fetchedAt: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[OpsConfig] Parse error: $e');
      return null;
    }
  }

  /// Fetch fresh config from Supabase (with ETag-like hash check)
  Future<void> refresh() async {
    // Don't fetch in demo mode
    final isDemoMode = _ref.read(isDemoModeProvider);
    if (isDemoMode) return;

    state = state.copyWith(loading: true, error: null);

    try {
      final client = SupabaseConfig.client;
      final response = await client
          .from('app_public_config')
          .select('banners, flags, config_hash')
          .eq('id', 'current')
          .single();

      final serverHash = response['config_hash'] as String? ?? '';

      // ETag-like check: skip parsing if hash unchanged
      if (serverHash.isNotEmpty && serverHash == state.config.configHash) {
        state = state.copyWith(loading: false);
        return;
      }

      // Parse new config
      final configStr = jsonEncode({
        'banners': response['banners'],
        'flags': response['flags'],
      });

      final newConfig = _parseConfig(configStr, serverHash);
      if (newConfig != null) {
        state = OpsConfigState(config: newConfig);

        // Update cache
        _saveToCache(configStr, serverHash);
      } else {
        state = state.copyWith(loading: false);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[OpsConfig] Fetch error: $e');
      // Graceful degradation: keep existing (cached) config
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  /// Save config to SharedPreferences
  Future<void> _saveToCache(String configJson, String hash) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKeyConfig, configJson);
      await prefs.setString(_cacheKeyHash, hash);
      await prefs.setInt(
          _cacheKeyTimestamp, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) debugPrint('[OpsConfig] Cache save error: $e');
    }
  }
}

// ── Providers ──

/// Main ops config provider
final opsConfigProvider =
    StateNotifierProvider<OpsConfigNotifier, OpsConfigState>((ref) {
  return OpsConfigNotifier(ref);
});

/// Convenience: get banners for a placement
final opsBannersProvider =
    Provider.family<List<OpsPublishedBanner>, String>((ref, placement) {
  final configState = ref.watch(opsConfigProvider);
  return configState.config.bannersForPlacement(placement);
});

/// Convenience: check if a flag is enabled
final opsFlagEnabledProvider = Provider.family<bool, String>((ref, flagKey) {
  final configState = ref.watch(opsConfigProvider);
  return configState.config.isFlagEnabled(flagKey);
});
