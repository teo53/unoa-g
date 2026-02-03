import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_client.dart';
import '../data/models/broadcast_message.dart';
import '../data/models/reply_quota.dart';
import '../data/models/channel.dart';
import 'auth_provider.dart';

/// Chat state for a specific channel
class ChatState {
  final String channelId;
  final Channel? channel;
  final List<BroadcastMessage> messages;
  final ReplyQuota? quota;
  final Subscription? subscription;
  final bool isLoading;
  final String? error;
  final bool hasMoreMessages;
  final Map<String, bool> onlineUsers; // userId -> isOnline
  final Set<String> typingUsers;

  const ChatState({
    required this.channelId,
    this.channel,
    this.messages = const [],
    this.quota,
    this.subscription,
    this.isLoading = false,
    this.error,
    this.hasMoreMessages = true,
    this.onlineUsers = const {},
    this.typingUsers = const {},
  });

  ChatState copyWith({
    Channel? channel,
    List<BroadcastMessage>? messages,
    ReplyQuota? quota,
    Subscription? subscription,
    bool? isLoading,
    String? error,
    bool? hasMoreMessages,
    Map<String, bool>? onlineUsers,
    Set<String>? typingUsers,
  }) {
    return ChatState(
      channelId: channelId,
      channel: channel ?? this.channel,
      messages: messages ?? this.messages,
      quota: quota ?? this.quota,
      subscription: subscription ?? this.subscription,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      onlineUsers: onlineUsers ?? this.onlineUsers,
      typingUsers: typingUsers ?? this.typingUsers,
    );
  }

  bool get canReply {
    if (quota == null) return false;
    return quota!.canReply;
  }

  int get characterLimit {
    if (subscription == null) return 50;
    return ReplyQuota.getCharacterLimitForDays(subscription!.daysSubscribed);
  }
}

/// Chat notifier for managing chat state
class ChatNotifier extends StateNotifier<ChatState> {
  final String channelId;
  final Ref _ref;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _quotaSubscription;
  StreamSubscription? _presenceSubscription;

  ChatNotifier(this.channelId, this._ref) : super(ChatState(channelId: channelId)) {
    _initialize();
  }

  void _initialize() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final client = _ref.read(supabaseClientProvider);
      final userId = _ref.read(currentUserProvider)?.id;

      if (userId == null) {
        state = state.copyWith(isLoading: false, error: '로그인이 필요합니다.');
        return;
      }

      // Load channel info
      final channelResponse = await client
          .from('channels')
          .select()
          .eq('id', channelId)
          .single();
      final channel = Channel.fromJson(channelResponse);

      // Load subscription
      final subResponse = await client
          .from('subscriptions')
          .select()
          .eq('channel_id', channelId)
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      Subscription? subscription;
      if (subResponse != null) {
        subscription = Subscription.fromJson(subResponse);
      }

      // Load quota
      final quotaResponse = await client
          .from('reply_quota')
          .select()
          .eq('channel_id', channelId)
          .eq('user_id', userId)
          .maybeSingle();

      ReplyQuota? quota;
      if (quotaResponse != null) {
        quota = ReplyQuota.fromJson(quotaResponse);
      }

      // Load initial messages
      final messagesResponse = await client
          .rpc('get_user_chat_thread', params: {
            'p_channel_id': channelId,
            'p_limit': 50,
          });

      final messages = (messagesResponse as List)
          .map((json) => BroadcastMessage.fromJson(json))
          .toList()
          .reversed
          .toList(); // Reverse to get chronological order

      state = state.copyWith(
        channel: channel,
        subscription: subscription,
        quota: quota,
        messages: messages,
        isLoading: false,
        hasMoreMessages: messages.length >= 50,
      );

      // Subscribe to real-time updates
      _subscribeToMessages();
      _subscribeToQuota();
      _subscribeToPresence();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '채팅을 불러오는데 실패했습니다.',
      );
    }
  }

  void _subscribeToMessages() {
    _messagesSubscription?.cancel();

    final client = _ref.read(supabaseClientProvider);

    _messagesSubscription = client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('channel_id', channelId)
        .order('created_at')
        .listen((data) {
      // Filter and transform messages
      // Note: In production, use the view or RPC for proper filtering
      final newMessages = data
          .map((json) => BroadcastMessage.fromJson(json))
          .where((msg) => msg.deletedAt == null)
          .toList();

      state = state.copyWith(messages: newMessages);
    });
  }

  void _subscribeToQuota() {
    _quotaSubscription?.cancel();

    final client = _ref.read(supabaseClientProvider);
    final userId = _ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    _quotaSubscription = client
        .from('reply_quota')
        .stream(primaryKey: ['id'])
        .eq('channel_id', channelId)
        .eq('user_id', userId)
        .listen((data) {
      if (data.isNotEmpty) {
        state = state.copyWith(quota: ReplyQuota.fromJson(data.first));
      }
    });
  }

  void _subscribeToPresence() {
    // Cancel existing subscription to prevent memory leak
    _presenceSubscription?.cancel();

    // Using Supabase Realtime Presence
    final client = _ref.read(supabaseClientProvider);

    final channel = client.channel('presence:$channelId');

    // Store the subscription to allow proper cleanup
    final realtimeChannel = channel.onPresenceSync((payload) {
      final presences = payload.currentPresences;
      final onlineUsers = <String, bool>{};
      for (final presence in presences) {
        final oduserId = presence.payload['user_id'] as String?;
        if (oduserId != null) {
          onlineUsers[oduserId] = true;
        }
      }
      state = state.copyWith(onlineUsers: onlineUsers);
    }).subscribe();

    // Store subscription for cleanup - wrap in StreamSubscription-like behavior
    // Note: RealtimeChannel doesn't return StreamSubscription directly,
    // but we can track the channel for unsubscribe in dispose
    _presenceChannel = realtimeChannel;
  }

  // Track the realtime channel for cleanup
  dynamic _presenceChannel;

  /// Load more messages (pagination)
  Future<void> loadMoreMessages() async {
    if (!state.hasMoreMessages || state.isLoading) return;

    final oldestMessage =
        state.messages.isNotEmpty ? state.messages.first : null;
    if (oldestMessage == null) return;

    try {
      final client = _ref.read(supabaseClientProvider);

      final response = await client.rpc('get_user_chat_thread', params: {
        'p_channel_id': channelId,
        'p_limit': 50,
        'p_before_id': oldestMessage.id,
      });

      final olderMessages = (response as List)
          .map((json) => BroadcastMessage.fromJson(json))
          .toList()
          .reversed
          .toList();

      state = state.copyWith(
        messages: [...olderMessages, ...state.messages],
        hasMoreMessages: olderMessages.length >= 50,
      );
    } catch (e, stackTrace) {
      // Log pagination errors but don't fail the UI
      debugPrint('[ChatNotifier] Pagination error: $e');
      if (kDebugMode) {
        debugPrint(stackTrace.toString());
      }
    }
  }

  /// Send a text reply
  Future<bool> sendReply(String content) async {
    if (!state.canReply) return false;
    if (content.length > state.characterLimit) return false;

    try {
      final client = _ref.read(supabaseClientProvider);
      final userId = _ref.read(currentUserProvider)?.id;
      if (userId == null) return false;

      await client.from('messages').insert({
        'channel_id': channelId,
        'sender_id': userId,
        'sender_type': 'fan',
        'delivery_scope': 'direct_reply',
        'content': content,
        'message_type': 'text',
      });

      return true;
    } catch (e, stackTrace) {
      debugPrint('[ChatNotifier] sendReply error: $e');
      if (kDebugMode) {
        debugPrint(stackTrace.toString());
      }
      return false;
    }
  }

  /// Send a donation message
  Future<bool> sendDonationMessage({
    required String content,
    required int amountDt,
    required String donationId,
  }) async {
    if (content.length > 100) return false; // Donation message limit

    try {
      final client = _ref.read(supabaseClientProvider);
      final userId = _ref.read(currentUserProvider)?.id;
      if (userId == null) return false;

      await client.from('messages').insert({
        'channel_id': channelId,
        'sender_id': userId,
        'sender_type': 'fan',
        'delivery_scope': 'donation_message',
        'content': content,
        'message_type': 'text',
        'donation_id': donationId,
        'donation_amount': amountDt,
      });

      return true;
    } catch (e, stackTrace) {
      debugPrint('[ChatNotifier] sendDonationMessage error: $e');
      if (kDebugMode) {
        debugPrint(stackTrace.toString());
      }
      return false;
    }
  }

  /// Send media message
  Future<bool> sendMediaMessage({
    required String mediaUrl,
    required String messageType, // 'image', 'video', 'voice'
    Map<String, dynamic>? mediaMetadata,
  }) async {
    if (!state.canReply) return false;

    try {
      final client = _ref.read(supabaseClientProvider);
      final userId = _ref.read(currentUserProvider)?.id;
      if (userId == null) return false;

      await client.from('messages').insert({
        'channel_id': channelId,
        'sender_id': userId,
        'sender_type': 'fan',
        'delivery_scope': 'direct_reply',
        'message_type': messageType,
        'media_url': mediaUrl,
        'media_metadata': mediaMetadata,
      });

      return true;
    } catch (e, stackTrace) {
      debugPrint('[ChatNotifier] sendMediaMessage error: $e');
      if (kDebugMode) {
        debugPrint(stackTrace.toString());
      }
      return false;
    }
  }

  /// Update typing indicator
  Future<void> updateTyping(bool isTyping) async {
    try {
      final client = _ref.read(supabaseClientProvider);
      final userId = _ref.read(currentUserProvider)?.id;
      if (userId == null) return;

      final channel = client.channel('typing:$channelId');
      await channel.sendBroadcastMessage(
        event: 'typing',
        payload: {
          'user_id': userId,
          'is_typing': isTyping,
        },
      );
    } catch (e) {
      // Typing indicator errors are non-critical, don't log in release
      if (kDebugMode) {
        debugPrint('[ChatNotifier] updateTyping error: $e');
      }
    }
  }

  /// Mark messages as read
  Future<void> markAsRead() async {
    try {
      final client = _ref.read(supabaseClientProvider);
      final userId = _ref.read(currentUserProvider)?.id;
      if (userId == null) return;

      // Get unread message IDs
      final unreadIds = state.messages
          .where((m) => m.isRead != true && m.senderId != userId)
          .map((m) => m.id)
          .toList();

      if (unreadIds.isEmpty) return;

      await client
          .from('message_delivery')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .inFilter('message_id', unreadIds);
    } catch (e) {
      // Read receipt errors are non-critical, don't log in release
      if (kDebugMode) {
        debugPrint('[ChatNotifier] markAsRead error: $e');
      }
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _quotaSubscription?.cancel();
    _presenceSubscription?.cancel();

    // Unsubscribe from presence channel to prevent memory leak
    try {
      if (_presenceChannel != null) {
        final client = _ref.read(supabaseClientProvider);
        client.removeChannel(_presenceChannel);
      }
    } catch (e) {
      // Ignore cleanup errors
      if (kDebugMode) {
        debugPrint('[ChatNotifier] Presence channel cleanup error: $e');
      }
    }

    super.dispose();
  }
}

/// Chat provider family (one per channel)
final chatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, channelId) => ChatNotifier(channelId, ref),
);

/// Convenience provider for messages
final messagesProvider = Provider.family<List<BroadcastMessage>, String>(
  (ref, channelId) => ref.watch(chatProvider(channelId)).messages,
);

/// Convenience provider for quota
final quotaProvider = Provider.family<ReplyQuota?, String>(
  (ref, channelId) => ref.watch(chatProvider(channelId)).quota,
);

/// Convenience provider for subscription
final subscriptionProvider = Provider.family<Subscription?, String>(
  (ref, channelId) => ref.watch(chatProvider(channelId)).subscription,
);

/// Convenience provider for character limit
final characterLimitProvider = Provider.family<int, String>(
  (ref, channelId) => ref.watch(chatProvider(channelId)).characterLimit,
);

/// Convenience provider for can reply
final canReplyProvider = Provider.family<bool, String>(
  (ref, channelId) => ref.watch(chatProvider(channelId)).canReply,
);

/// Provider for subscribed channels list
final subscribedChannelsProvider = FutureProvider<List<Channel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];

  final response = await client
      .from('subscriptions')
      .select('channel_id, channels(*)')
      .eq('user_id', userId)
      .eq('is_active', true);

  return (response as List)
      .map((json) => Channel.fromJson(json['channels']))
      .toList();
});
