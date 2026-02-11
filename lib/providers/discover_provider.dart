import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock/mock_data.dart';
import '../data/models/artist.dart';
import 'auth_provider.dart';

/// Discover / trending artists state
sealed class DiscoverState {
  const DiscoverState();
}

class DiscoverInitial extends DiscoverState {
  const DiscoverInitial();
}

class DiscoverLoading extends DiscoverState {
  const DiscoverLoading();
}

class DiscoverLoaded extends DiscoverState {
  final List<Artist> trendingArtists;
  final List<Artist> recommendedArtists;

  const DiscoverLoaded({
    required this.trendingArtists,
    this.recommendedArtists = const [],
  });
}

class DiscoverError extends DiscoverState {
  final String message;
  final Object? error;

  const DiscoverError(this.message, [this.error]);
}

/// Discover notifier — loads trending / recommended artists
class DiscoverNotifier extends StateNotifier<DiscoverState> {
  final Ref _ref;

  DiscoverNotifier(this._ref) : super(const DiscoverInitial()) {
    _initialize();
  }

  void _initialize() {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated || next is AuthDemoMode) {
        loadArtists();
      } else if (next is AuthUnauthenticated) {
        state = const DiscoverInitial();
      }
    });

    // Initial load if already authenticated or in demo mode
    final authState = _ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      loadArtists();
    } else if (authState is AuthDemoMode) {
      _loadDemoArtists();
    }
  }

  /// Load artists (Supabase)
  Future<void> loadArtists() async {
    final authState = _ref.read(authProvider);

    // Demo fallback
    if (authState is AuthDemoMode) {
      _loadDemoArtists();
      return;
    }

    state = const DiscoverLoading();

    try {
      final client = _ref.read(supabaseClientProvider);

      // Trending: ordered by subscriber count
      final trendingResponse = await client
          .from('channels')
          .select('*, user_profiles!creator_id(*)')
          .order('subscriber_count', ascending: false)
          .limit(20);

      final trending = (trendingResponse as List).map((json) {
        return Artist(
          id: json['creator_id'] as String? ?? json['id'] as String,
          name: json['name'] as String? ?? '',
          avatarUrl: json['avatar_url'] as String? ?? '',
          followerCount: json['subscriber_count'] as int? ?? 0,
          isVerified: json['is_verified'] as bool? ?? false,
          isOnline: false,
        );
      }).toList();

      // Recommended: separate query or subset
      final recommended = trending.length > 4 ? trending.sublist(4) : trending;

      state = DiscoverLoaded(
        trendingArtists: trending,
        recommendedArtists: recommended,
      );
    } catch (e) {
      state = DiscoverError('아티스트를 불러오는데 실패했습니다.', e);
    }
  }

  /// Demo mode fallback
  void _loadDemoArtists() {
    state = DiscoverLoaded(
      trendingArtists: MockData.trendingArtists,
      recommendedArtists: MockData.trendingArtists,
    );
  }

  /// Refresh
  Future<void> refresh() async {
    await loadArtists();
  }
}

/// Main discover provider
final discoverProvider =
    StateNotifierProvider<DiscoverNotifier, DiscoverState>((ref) {
  return DiscoverNotifier(ref);
});

/// Trending artists convenience provider
final trendingArtistsProvider = Provider<List<Artist>>((ref) {
  final state = ref.watch(discoverProvider);
  if (state is DiscoverLoaded) {
    return state.trendingArtists;
  }
  return const [];
});

/// Recommended artists convenience provider
final recommendedArtistsProvider = Provider<List<Artist>>((ref) {
  final state = ref.watch(discoverProvider);
  if (state is DiscoverLoaded) {
    return state.recommendedArtists;
  }
  return const [];
});

/// Artist by ID — lookup from trending artists or Supabase
final artistByIdProvider = Provider.family<Artist?, String>((ref, artistId) {
  final artists = ref.watch(trendingArtistsProvider);
  final match = artists.where((a) => a.id == artistId);
  if (match.isNotEmpty) return match.first;
  return null;
});

/// Artist content feeds provider (highlight / announcement / letter)
/// In demo mode returns mock data; in production queries the content table
final artistContentFeedsProvider =
    FutureProvider.family<Map<String, List<Map<String, dynamic>>>, String>(
        (ref, artistId) async {
  final authState = ref.read(authProvider);

  // Demo / unauthenticated → return mock feeds
  if (authState is AuthDemoMode || authState is! AuthAuthenticated) {
    return {
      'highlight': MockData.highlightFeeds,
      'announcement': MockData.announcementFeeds,
      'letter': MockData.otaLetterFeeds,
    };
  }

  try {
    final client = ref.read(supabaseClientProvider);

    final highlightResp = await client
        .from('creator_content')
        .select('*')
        .eq('artist_id', artistId)
        .eq('content_type', 'highlight')
        .order('created_at', ascending: false)
        .limit(10);

    final announcementResp = await client
        .from('creator_content')
        .select('*')
        .eq('artist_id', artistId)
        .eq('content_type', 'announcement')
        .order('created_at', ascending: false)
        .limit(10);

    final letterResp = await client
        .from('creator_content')
        .select('*')
        .eq('artist_id', artistId)
        .eq('content_type', 'letter')
        .order('created_at', ascending: false)
        .limit(10);

    return {
      'highlight': _mapContentRows(highlightResp as List),
      'announcement': _mapContentRows(announcementResp as List),
      'letter': _mapContentRows(letterResp as List),
    };
  } catch (_) {
    // Fallback to demo data on error
    return {
      'highlight': MockData.highlightFeeds,
      'announcement': MockData.announcementFeeds,
      'letter': MockData.otaLetterFeeds,
    };
  }
});

List<Map<String, dynamic>> _mapContentRows(List<dynamic> rows) {
  return rows.map<Map<String, dynamic>>((row) {
    final r = row as Map<String, dynamic>;
    return {
      'content': r['body'] as String? ?? '',
      'imageUrl': r['image_url'] as String?,
      'time': _formatRelativeTime(r['created_at'] as String?),
      'likes': r['like_count'] as int? ?? 0,
      'comments': r['comment_count'] as int? ?? 0,
      'isPinned': r['is_pinned'] as bool? ?? false,
      'isOfficial': r['content_type'] == 'announcement',
      'isLetter': r['content_type'] == 'letter',
    };
  }).toList();
}

String _formatRelativeTime(String? isoString) {
  if (isoString == null) return '';
  final dt = DateTime.tryParse(isoString);
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  if (diff.inDays == 1) return '어제';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  return '${dt.month}/${dt.day}';
}
