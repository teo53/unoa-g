import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/app_logger.dart';
import '../core/supabase/supabase_client.dart';
import 'auth_provider.dart';

// ── Model ──

class FanAd {
  final String id;
  final String fanUserId;
  final String artistChannelId;
  final String title;
  final String? body;
  final String? imageUrl;
  final String? linkUrl;
  final String linkType;
  final DateTime startAt;
  final DateTime endAt;
  final int paymentAmountKrw;
  final String paymentStatus;
  final String status;
  final String? rejectionReason;
  final int impressions;
  final int clicks;
  final DateTime createdAt;

  const FanAd({
    required this.id,
    required this.fanUserId,
    required this.artistChannelId,
    required this.title,
    this.body,
    this.imageUrl,
    this.linkUrl,
    required this.linkType,
    required this.startAt,
    required this.endAt,
    required this.paymentAmountKrw,
    required this.paymentStatus,
    required this.status,
    this.rejectionReason,
    required this.impressions,
    required this.clicks,
    required this.createdAt,
  });

  factory FanAd.fromJson(Map<String, dynamic> json) {
    return FanAd(
      id: json['id'] as String,
      fanUserId: json['fan_user_id'] as String,
      artistChannelId: json['artist_channel_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      imageUrl: json['image_url'] as String?,
      linkUrl: json['link_url'] as String?,
      linkType: json['link_type'] as String? ?? 'external',
      startAt: DateTime.parse(json['start_at'] as String),
      endAt: DateTime.parse(json['end_at'] as String),
      paymentAmountKrw: json['payment_amount_krw'] as int,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      status: json['status'] as String? ?? 'pending_review',
      rejectionReason: json['rejection_reason'] as String?,
      impressions: json['impressions'] as int? ?? 0,
      clicks: json['clicks'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isActive => status == 'active';
  bool get isPendingReview => status == 'pending_review';
  bool get isCancellable => status == 'pending_review';
}

// ── Draft (for purchase flow) ──

class FanAdDraft {
  final String? artistChannelId;
  final String title;
  final String body;
  final String? imageUrl;
  final String? linkUrl;
  final String linkType;
  final DateTime? startAt;
  final DateTime? endAt;
  final int paymentAmountKrw;

  const FanAdDraft({
    this.artistChannelId,
    this.title = '',
    this.body = '',
    this.imageUrl,
    this.linkUrl,
    this.linkType = 'external',
    this.startAt,
    this.endAt,
    this.paymentAmountKrw = 0,
  });

  FanAdDraft copyWith({
    String? artistChannelId,
    String? title,
    String? body,
    String? imageUrl,
    String? linkUrl,
    String? linkType,
    DateTime? startAt,
    DateTime? endAt,
    int? paymentAmountKrw,
  }) {
    return FanAdDraft(
      artistChannelId: artistChannelId ?? this.artistChannelId,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      linkType: linkType ?? this.linkType,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      paymentAmountKrw: paymentAmountKrw ?? this.paymentAmountKrw,
    );
  }

  bool get isValid {
    if (artistChannelId == null ||
        title.trim().isEmpty ||
        startAt == null ||
        endAt == null ||
        !endAt!.isAfter(startAt!) ||
        paymentAmountKrw <= 0) {
      return false;
    }
    // URL 스킴 검증 — javascript:/data: 등 위험 스킴 차단
    if (linkUrl != null && linkUrl!.isNotEmpty) {
      final uri = Uri.tryParse(linkUrl!);
      if (uri == null ||
          !['http', 'https'].contains(uri.scheme.toLowerCase())) {
        return false;
      }
    }
    return true;
  }
}

// ── State ──

class FanAdState {
  final List<FanAd> myAds;
  final bool loading;
  final String? error;

  const FanAdState({
    this.myAds = const [],
    this.loading = false,
    this.error,
  });

  FanAdState copyWith({
    List<FanAd>? myAds,
    bool? loading,
    String? error,
  }) {
    return FanAdState(
      myAds: myAds ?? this.myAds,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

// ── Notifier ──

class FanAdNotifier extends StateNotifier<FanAdState> {
  final Ref _ref;
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  FanAdNotifier(this._ref) : super(const FanAdState());

  bool get _isDemoMode {
    final auth = _ref.read(authProvider);
    return auth is AuthDemoMode;
  }

  /// 입력값이 channel_id면 그대로 사용, 아니면 channels.artist_id로 역조회.
  Future<String?> _resolveArtistChannelId(String input) async {
    final normalized = input.trim();
    if (normalized.isEmpty) return null;
    if (!_uuidRegex.hasMatch(normalized)) {
      AppLogger.warning(
        'FanAdNotifier._resolveArtistChannelId: non-uuid input=$normalized',
        tag: 'FanAd',
      );
      return null;
    }

    final client = SupabaseConfig.client;

    // 1) channel_id direct hit
    final byChannelId = await client
        .from('channels')
        .select('id')
        .eq('id', normalized)
        .maybeSingle();
    if (byChannelId != null) {
      return byChannelId['id'] as String;
    }

    // 2) legacy creator/user id fallback: channels.artist_id -> channels.id
    final byArtistId = await client
        .from('channels')
        .select('id')
        .eq('artist_id', normalized)
        .maybeSingle();
    if (byArtistId != null) {
      return byArtistId['id'] as String;
    }

    return null;
  }

  /// 내 광고 목록 로드
  Future<void> loadMyAds() async {
    if (_isDemoMode) {
      state = state.copyWith(
        myAds: _demoAds(),
        loading: false,
      );
      return;
    }

    state = state.copyWith(loading: true, error: null);
    try {
      final client = SupabaseConfig.client;
      final rows = await client
          .from('fan_ads')
          .select()
          .order('created_at', ascending: false);

      final ads = (rows as List)
          .map((r) => FanAd.fromJson(r as Map<String, dynamic>))
          .toList();
      state = state.copyWith(myAds: ads, loading: false);
    } catch (e) {
      AppLogger.error('FanAdNotifier.loadMyAds: $e', tag: 'FanAd');
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// 광고 신청 생성 — 결제 완료 후 서버에서 payment_status 갱신
  /// 반환: 생성된 fan_ad id (성공), null (실패)
  Future<String?> createAd(FanAdDraft draft) async {
    if (!draft.isValid) return null;

    // 서버 전송 직전 URL 스킴 이중 검증 (defense-in-depth)
    if (draft.linkUrl != null && draft.linkUrl!.isNotEmpty) {
      final uri = Uri.tryParse(draft.linkUrl!);
      if (uri == null ||
          !['http', 'https'].contains(uri.scheme.toLowerCase())) {
        AppLogger.error(
          'FanAdNotifier.createAd: unsafe URL scheme blocked: ${draft.linkUrl}',
          tag: 'FanAd',
        );
        return null;
      }
    }

    if (_isDemoMode) {
      AppLogger.debug('Demo: createAd skipped', tag: 'FanAd');
      return 'demo_ad_${DateTime.now().millisecondsSinceEpoch}';
    }

    try {
      final client = SupabaseConfig.client;
      final fanUserId = client.auth.currentUser?.id;
      final rawArtistId = draft.artistChannelId?.trim() ?? '';
      if (fanUserId == null || rawArtistId.isEmpty) {
        AppLogger.error('FanAdNotifier.createAd: missing user/channel id',
            tag: 'FanAd');
        return null;
      }

      final resolvedChannelId = await _resolveArtistChannelId(rawArtistId);
      if (resolvedChannelId == null) {
        AppLogger.error(
          'FanAdNotifier.createAd: artist channel resolve failed: $rawArtistId',
          tag: 'FanAd',
        );
        return null;
      }

      final row = await client
          .from('fan_ads')
          .insert({
            'fan_user_id': fanUserId,
            'artist_channel_id': resolvedChannelId,
            'title': draft.title.trim(),
            'body': draft.body.trim().isEmpty ? null : draft.body.trim(),
            'image_url': draft.imageUrl,
            'link_url': draft.linkUrl,
            'link_type': draft.linkType,
            'start_at': draft.startAt!.toIso8601String(),
            'end_at': draft.endAt!.toIso8601String(),
            'payment_amount_krw': draft.paymentAmountKrw,
            // RLS가 status='pending_review', payment_status='pending' 강제
          })
          .select()
          .single();

      await loadMyAds();
      return row['id'] as String;
    } catch (e) {
      AppLogger.error('FanAdNotifier.createAd: $e', tag: 'FanAd');
      return null;
    }
  }

  /// 광고 취소 — pending_review 상태에서만 가능 (RLS 강제)
  Future<bool> cancelAd(String adId) async {
    if (_isDemoMode) return true;

    try {
      final client = SupabaseConfig.client;
      final actorId = client.auth.currentUser?.id;
      if (actorId == null) {
        AppLogger.error('FanAdNotifier.cancelAd: user not authenticated',
            tag: 'FanAd');
        return false;
      }

      await client.rpc('cancel_fan_ad_atomic', params: {
        'p_fan_ad_id': adId,
        'p_actor_id': actorId,
      });

      await loadMyAds();
      return true;
    } catch (e) {
      AppLogger.error('FanAdNotifier.cancelAd: $e', tag: 'FanAd');
      return false;
    }
  }

  // ── Demo 데이터 ──

  List<FanAd> _demoAds() {
    final now = DateTime.now();
    return [
      FanAd(
        id: 'demo_ad_1',
        fanUserId: 'demo_user_001',
        artistChannelId: 'channel_1',
        title: '팬클럽 2주년 축하 광고',
        body: '2년간 함께해줘서 고마워요!',
        imageUrl: null,
        linkUrl: null,
        linkType: 'none',
        startAt: now.subtract(const Duration(days: 1)),
        endAt: now.add(const Duration(days: 6)),
        paymentAmountKrw: 9900,
        paymentStatus: 'paid',
        status: 'active',
        impressions: 1240,
        clicks: 38,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      FanAd(
        id: 'demo_ad_2',
        fanUserId: 'demo_user_001',
        artistChannelId: 'channel_1',
        title: '생일 축하 메시지',
        body: null,
        imageUrl: null,
        linkUrl: null,
        linkType: 'none',
        startAt: now.add(const Duration(days: 5)),
        endAt: now.add(const Duration(days: 12)),
        paymentAmountKrw: 4900,
        paymentStatus: 'pending',
        status: 'pending_review',
        impressions: 0,
        clicks: 0,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
    ];
  }
}

// ── Providers ──

final fanAdProvider = StateNotifierProvider<FanAdNotifier, FanAdState>((ref) {
  return FanAdNotifier(ref);
});

/// 상태별 필터링 convenience provider
final myAdsByStatusProvider =
    Provider.family<List<FanAd>, String?>((ref, status) {
  final ads = ref.watch(fanAdProvider).myAds;
  if (status == null) return ads;
  return ads.where((a) => a.status == status).toList();
});
