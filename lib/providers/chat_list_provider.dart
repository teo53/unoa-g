import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_client.dart';
import '../core/theme/app_colors.dart';
import '../data/models/channel.dart';
import '../data/models/message.dart';
import 'auth_provider.dart';

/// State for the chat list screen
class ChatListState {
  final List<ChatThreadData> threads;
  final bool isLoading;
  final String? error;
  final bool hasLoaded;

  const ChatListState({
    this.threads = const [],
    this.isLoading = false,
    this.error,
    this.hasLoaded = false,
  });

  ChatListState copyWith({
    List<ChatThreadData>? threads,
    bool? isLoading,
    String? error,
    bool? hasLoaded,
  }) {
    return ChatListState(
      threads: threads ?? this.threads,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

/// Data model for chat thread display (combines channel + subscription + messages)
class ChatThreadData {
  final String channelId;
  final String artistId;
  final String artistName;
  final String? artistEnglishName;
  final String? avatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isOnline;
  final bool isVerified;
  final bool isPinned;
  final bool isStar;
  final String tier;
  final int daysSubscribed;

  /// 아티스트 테마 색상 인덱스 (0-5)
  final int themeColorIndex;

  const ChatThreadData({
    required this.channelId,
    required this.artistId,
    required this.artistName,
    this.artistEnglishName,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isVerified = false,
    this.isPinned = false,
    this.isStar = false,
    this.tier = 'STANDARD',
    this.daysSubscribed = 0,
    this.themeColorIndex = 0,
  });

  String get displayName =>
      artistEnglishName != null ? '$artistName ($artistEnglishName)' : artistName;

  String get formattedTime {
    if (lastMessageAt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(lastMessageAt!);

    if (diff.inMinutes < 1) {
      return '방금';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inDays < 1) {
      final hour = lastMessageAt!.hour;
      final minute = lastMessageAt!.minute.toString().padLeft(2, '0');
      final period = hour < 12 ? '오전' : '오후';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$period $displayHour:$minute';
    } else if (diff.inDays == 1) {
      return '어제';
    } else {
      return '${lastMessageAt!.month}/${lastMessageAt!.day}';
    }
  }

  /// Convert to legacy ChatThread for backward compatibility
  ChatThread toChatThread() {
    return ChatThread(
      id: channelId,
      artistId: artistId,
      artistName: artistName,
      artistEnglishName: artistEnglishName,
      artistAvatarUrl: avatarUrl ?? '',
      lastMessage: lastMessage ?? '',
      lastMessageTime: lastMessageAt ?? DateTime.now(),
      unreadCount: unreadCount,
      isOnline: isOnline,
      isVerified: isVerified,
      isPinned: isPinned,
      isStar: isStar,
    );
  }

  factory ChatThreadData.fromJson(Map<String, dynamic> json) {
    return ChatThreadData(
      channelId: json['channel_id'] as String,
      artistId: json['artist_id'] as String,
      artistName: json['artist_name'] as String? ?? 'Unknown',
      artistEnglishName: json['artist_english_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      isOnline: json['is_online'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      isStar: json['is_star'] as bool? ?? false,
      tier: json['tier'] as String? ?? 'STANDARD',
      daysSubscribed: json['days_subscribed'] as int? ?? 0,
      themeColorIndex: json['theme_color_index'] as int? ?? 0,
    );
  }
}

/// Notifier for managing chat list state
class ChatListNotifier extends StateNotifier<ChatListState> {
  final Ref _ref;
  StreamSubscription? _subscriptionsSubscription;
  ProviderSubscription? _authSubscription;

  ChatListNotifier(this._ref) : super(const ChatListState()) {
    _initialize();
  }

  void _initialize() {
    // Listen to auth state changes so that when user enters demo mode,
    // chat list automatically reloads with demo data
    _authSubscription = _ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev.runtimeType != next.runtimeType) {
        // Auth state changed (e.g. unauthenticated → demo mode)
        state = const ChatListState(); // Reset state
        loadChatThreads();
      }
    });
    loadChatThreads();
  }

  /// Load all subscribed channels with latest messages
  Future<void> loadChatThreads() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check if in demo mode
      final authState = _ref.read(authProvider);
      if (authState is AuthDemoMode) {
        _loadDemoThreads();
        return;
      }

      final client = _ref.read(supabaseClientProvider);
      final userId = _ref.read(currentUserProvider)?.id;

      if (userId == null) {
        state = state.copyWith(
          isLoading: false,
          error: '로그인이 필요합니다.',
          hasLoaded: true,
        );
        return;
      }

      // Query subscribed channels with artist info and last message
      final response = await client
          .from('subscriptions')
          .select('''
            id,
            channel_id,
            tier,
            started_at,
            is_pinned,
            channels (
              id,
              artist_id,
              name,
              description,
              avatar_url,
              user_profiles!channels_artist_id_fkey (
                display_name,
                avatar_url,
                is_verified
              )
            )
          ''')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('is_pinned', ascending: false)
          .order('updated_at', ascending: false);

      final threads = <ChatThreadData>[];

      for (final sub in (response as List)) {
        final channel = sub['channels'] as Map<String, dynamic>?;
        if (channel == null) continue;

        final artistProfile = channel['user_profiles'] as Map<String, dynamic>?;
        final startedAt = DateTime.parse(sub['started_at'] as String);
        final daysSubscribed = DateTime.now().difference(startedAt).inDays;

        // Get last message and unread count for this channel
        final messagesResponse = await client
            .from('messages')
            .select('content, created_at')
            .eq('channel_id', channel['id'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        final unreadResponse = await client
            .from('message_delivery')
            .select('id')
            .eq('user_id', userId)
            .eq('is_read', false)
            .count();

        threads.add(ChatThreadData(
          channelId: channel['id'] as String,
          artistId: channel['artist_id'] as String,
          artistName: artistProfile?['display_name'] as String? ?? channel['name'] as String,
          avatarUrl: artistProfile?['avatar_url'] as String? ?? channel['avatar_url'] as String?,
          lastMessage: messagesResponse?['content'] as String?,
          lastMessageAt: messagesResponse?['created_at'] != null
              ? DateTime.parse(messagesResponse!['created_at'] as String)
              : null,
          unreadCount: (unreadResponse.count ?? 0),
          isVerified: artistProfile?['is_verified'] as bool? ?? false,
          isPinned: sub['is_pinned'] as bool? ?? false,
          tier: sub['tier'] as String? ?? 'STANDARD',
          daysSubscribed: daysSubscribed,
        ));
      }

      // Sort: pinned first, then by last message time
      threads.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        final aTime = a.lastMessageAt ?? DateTime(1970);
        final bTime = b.lastMessageAt ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      state = state.copyWith(
        threads: threads,
        isLoading: false,
        hasLoaded: true,
      );

      _subscribeToUpdates();
    } catch (e, stackTrace) {
      debugPrint('[ChatListNotifier] Error loading threads: $e');
      if (kDebugMode) {
        debugPrint(stackTrace.toString());
      }

      state = state.copyWith(
        isLoading: false,
        error: '채팅 목록을 불러오는데 실패했습니다.',
        hasLoaded: true,
      );
    }
  }

  void _subscribeToUpdates() {
    _subscriptionsSubscription?.cancel();

    final client = _ref.read(supabaseClientProvider);
    final userId = _ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    // Listen for new messages to update the list
    _subscriptionsSubscription = client
        .from('messages')
        .stream(primaryKey: ['id'])
        .listen((data) {
      // Refresh the list when new messages arrive
      // In a production app, you'd want to be smarter about this
      // and only update the affected thread
      loadChatThreads();
    });
  }

  /// Refresh the chat list
  Future<void> refresh() async {
    await loadChatThreads();
  }

  /// Toggle pin status for a channel
  Future<void> togglePin(String channelId) async {
    try {
      final client = _ref.read(supabaseClientProvider);
      final userId = _ref.read(currentUserProvider)?.id;
      if (userId == null) return;

      final thread = state.threads.firstWhere(
        (t) => t.channelId == channelId,
        orElse: () => throw Exception('Thread not found'),
      );

      await client
          .from('subscriptions')
          .update({'is_pinned': !thread.isPinned})
          .eq('channel_id', channelId)
          .eq('user_id', userId);

      await loadChatThreads();
    } catch (e) {
      debugPrint('[ChatListNotifier] Error toggling pin: $e');
    }
  }

  /// Load demo data for demo mode
  void _loadDemoThreads() {
    final demoThreads = [
      ChatThreadData(
        channelId: 'demo_channel_1',
        artistId: 'artist_1',
        artistName: '김민지',
        artistEnglishName: 'Minji Kim',
        avatarUrl: null,
        lastMessage: '오늘 공연 와줘서 너무 고마워요!',
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 5)),
        unreadCount: 2,
        isOnline: true,
        isVerified: true,
        isPinned: true,
        tier: 'VIP',
        daysSubscribed: 45,
        themeColorIndex: 1, // 핑크
      ),
      ChatThreadData(
        channelId: 'demo_channel_2',
        artistId: 'artist_2',
        artistName: '이준호',
        artistEnglishName: 'Junho Lee',
        avatarUrl: null,
        lastMessage: '다음 주 일정 공유할게요. 확인해주세요!',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 1,
        isOnline: false,
        isVerified: true,
        isStar: true,
        tier: 'STANDARD',
        daysSubscribed: 30,
        themeColorIndex: 2, // 블루
      ),
      ChatThreadData(
        channelId: 'demo_channel_3',
        artistId: 'artist_3',
        artistName: '박서연',
        avatarUrl: null,
        lastMessage: '사진 보내주셔서 감사합니다 :)',
        lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
        unreadCount: 0,
        isOnline: false,
        tier: 'STANDARD',
        daysSubscribed: 15,
        themeColorIndex: 4, // 틸
      ),
    ];

    state = state.copyWith(
      threads: demoThreads,
      isLoading: false,
      hasLoaded: true,
    );
  }

  @override
  void dispose() {
    _subscriptionsSubscription?.cancel();
    _authSubscription?.close();
    super.dispose();
  }
}

/// Provider for chat list state
final chatListProvider =
    StateNotifierProvider<ChatListNotifier, ChatListState>((ref) {
  return ChatListNotifier(ref);
});

/// Convenience provider for chat threads
final chatThreadsProvider = Provider<List<ChatThreadData>>((ref) {
  return ref.watch(chatListProvider).threads;
});

/// Convenience provider for loading state
final chatListLoadingProvider = Provider<bool>((ref) {
  return ref.watch(chatListProvider).isLoading;
});

/// artistId → 테마 Color 변환 provider
final artistThemeColorByIdProvider =
    Provider.family<Color, String>((ref, artistId) {
  final threads = ref.watch(chatThreadsProvider);
  final thread = threads.where((t) => t.artistId == artistId).firstOrNull;
  return ArtistThemeColors.fromIndex(thread?.themeColorIndex ?? 0);
});

/// channelId → 테마 Color 변환 provider
final artistThemeColorByChannelProvider =
    Provider.family<Color, String>((ref, channelId) {
  final threads = ref.watch(chatThreadsProvider);
  final thread = threads.where((t) => t.channelId == channelId).firstOrNull;
  return ArtistThemeColors.fromIndex(thread?.themeColorIndex ?? 0);
});
