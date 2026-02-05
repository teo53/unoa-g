import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/broadcast_message.dart';
import '../data/models/reply_quota.dart';
import '../data/models/channel.dart';
import 'auth_provider.dart';
import 'chat_list_provider.dart';

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
      // Check if in demo mode
      final authState = _ref.read(authProvider);
      if (authState is AuthDemoMode) {
        _loadDemoData();
        return;
      }

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

      final messages = _parseMessages(messagesResponse)
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

  /// Load demo data for demo mode
  void _loadDemoData() {
    // Find matching demo thread data
    final chatListState = _ref.read(chatListProvider);
    final demoThread = chatListState.threads.firstWhere(
      (t) => t.channelId == channelId,
      orElse: () => ChatThreadData(
        channelId: channelId,
        artistId: 'demo_artist',
        artistName: '데모 아티스트',
      ),
    );

    // Create demo channel
    final demoChannel = Channel(
      id: channelId,
      artistId: demoThread.artistId,
      name: demoThread.artistName,
      description: '데모 모드 채팅방입니다.',
      avatarUrl: demoThread.avatarUrl,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );

    // Create demo subscription
    final demoSubscription = Subscription(
      id: 'demo_sub_${channelId}',
      userId: 'demo_user_001',
      channelId: channelId,
      tier: demoThread.tier,
      startedAt: DateTime.now().subtract(Duration(days: demoThread.daysSubscribed)),
      isActive: true,
      createdAt: DateTime.now().subtract(Duration(days: demoThread.daysSubscribed)),
      updatedAt: DateTime.now(),
    );

    // Create demo quota
    final demoQuota = ReplyQuota(
      id: 'demo_quota_${channelId}',
      userId: 'demo_user_001',
      channelId: channelId,
      tokensAvailable: 3,
      tokensUsed: 0,
      fallbackAvailable: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Create demo messages
    final demoMessages = _generateDemoMessages(demoThread);

    state = state.copyWith(
      channel: demoChannel,
      subscription: demoSubscription,
      quota: demoQuota,
      messages: demoMessages,
      isLoading: false,
      hasMoreMessages: false,
      onlineUsers: {demoThread.artistId: demoThread.isOnline},
    );
  }

  /// Generate demo messages based on channel
  List<BroadcastMessage> _generateDemoMessages(ChatThreadData thread) {
    final now = DateTime.now();
    final messages = <BroadcastMessage>[];

    // Get fan's display name for personalization
    final demoProfile = _ref.read(currentProfileProvider);
    final fanName = demoProfile?.displayName ?? '데모 팬';

    // Artist welcome message (with Bubble-style personalization)
    // Template: "{fanName}님, 안녕하세요!" becomes "데모 팬님, 안녕하세요!"
    messages.add(BroadcastMessage(
      id: 'demo_msg_1_${thread.channelId}',
      channelId: thread.channelId,
      senderId: thread.artistId,
      senderType: 'artist',
      deliveryScope: DeliveryScope.broadcast,
      content: '$fanName님, 안녕하세요! ${thread.artistName}입니다. 제 채팅방에 오신 것을 환영해요! 💕',
      templateContent: '{fanName}님, 안녕하세요! ${thread.artistName}입니다. 제 채팅방에 오신 것을 환영해요! 💕',
      createdAt: now.subtract(const Duration(days: 7)),
      senderName: thread.artistName,
      senderAvatarUrl: thread.avatarUrl,
      isRead: true,
    ));

    // Fan reply
    messages.add(BroadcastMessage(
      id: 'demo_msg_2_${thread.channelId}',
      channelId: thread.channelId,
      senderId: 'demo_user_001',
      senderType: 'fan',
      deliveryScope: DeliveryScope.directReply,
      content: '환영해주셔서 감사합니다! 항상 응원해요!',
      createdAt: now.subtract(const Duration(days: 6, hours: 12)),
      senderName: '데모 사용자',
      senderTier: thread.tier,
      senderDaysSubscribed: thread.daysSubscribed,
      isRead: true,
    ));

    // Artist daily message (with personalization)
    messages.add(BroadcastMessage(
      id: 'demo_msg_3_${thread.channelId}',
      channelId: thread.channelId,
      senderId: thread.artistId,
      senderType: 'artist',
      deliveryScope: DeliveryScope.broadcast,
      content: '$fanName님, 오늘 하루도 화이팅! 행복한 하루 보내세요 ☀️',
      templateContent: '{fanName}님, 오늘 하루도 화이팅! 행복한 하루 보내세요 ☀️',
      createdAt: now.subtract(const Duration(days: 3)),
      senderName: thread.artistName,
      senderAvatarUrl: thread.avatarUrl,
      isRead: true,
    ));

    // Artist recent message
    messages.add(BroadcastMessage(
      id: 'demo_msg_4_${thread.channelId}',
      channelId: thread.channelId,
      senderId: thread.artistId,
      senderType: 'artist',
      deliveryScope: DeliveryScope.broadcast,
      content: thread.lastMessage ?? '항상 응원해주셔서 감사합니다!',
      createdAt: thread.lastMessageAt ?? now.subtract(const Duration(hours: 1)),
      senderName: thread.artistName,
      senderAvatarUrl: thread.avatarUrl,
      isRead: thread.unreadCount == 0,
    ));

    // Sort by time
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return messages;
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

    // Note: Supabase stream only supports one eq() filter.
    // We filter channel_id via stream and user_id in the listener.
    _quotaSubscription = client
        .from('reply_quota')
        .stream(primaryKey: ['id'])
        .eq('channel_id', channelId)
        .listen((data) {
      final userQuota = data.where((row) => row['user_id'] == userId).toList();
      if (userQuota.isNotEmpty) {
        state = state.copyWith(quota: ReplyQuota.fromJson(userQuota.first));
      }
    });
  }

  void _subscribeToPresence() {
    // Cancel existing subscription to prevent memory leak
    _presenceSubscription?.cancel();
    _cleanupPresenceChannel();

    // Using Supabase Realtime Presence
    final client = _ref.read(supabaseClientProvider);

    _presenceChannel = client.channel('presence:$channelId');

    // Store the subscription to allow proper cleanup
    // presenceState() returns List<SinglePresenceState>
    // SinglePresenceState has: key (String) and presences (List<Presence>)
    // Each Presence has: presenceRef and payload (Map<String, dynamic>)
    _presenceChannel!.onPresenceSync((_) {
      // Get current state from the channel's presenceState
      final presenceState = _presenceChannel!.presenceState();
      final onlineUsers = <String, bool>{};

      // Iterate through SinglePresenceState list
      for (final singleState in presenceState) {
        // Each singleState has a list of Presence objects
        for (final presence in singleState.presences) {
          final presenceUserId = presence.payload['user_id'] as String?;
          if (presenceUserId != null) {
            onlineUsers[presenceUserId] = true;
          }
        }
      }
      state = state.copyWith(onlineUsers: onlineUsers);
    }).subscribe();
  }

  /// Safely cleanup presence channel to prevent memory leaks
  void _cleanupPresenceChannel() {
    if (_presenceChannel != null) {
      try {
        final client = _ref.read(supabaseClientProvider);
        client.removeChannel(_presenceChannel!);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[ChatNotifier] Presence channel cleanup error: $e');
        }
      }
      _presenceChannel = null;
    }
  }

  // Track the realtime channel for cleanup (typed for safety)
  RealtimeChannel? _presenceChannel;

  // Pagination retry tracking
  int _paginationRetryCount = 0;
  static const int _maxPaginationRetries = 3;

  /// Load more messages (pagination)
  Future<void> loadMoreMessages() async {
    if (!state.hasMoreMessages || state.isLoading) return;

    // Prevent infinite retry loops
    if (_paginationRetryCount >= _maxPaginationRetries) {
      if (kDebugMode) {
        debugPrint('[ChatNotifier] Max pagination retries reached');
      }
      return;
    }

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

      final olderMessages = _parseMessages(response)
          .reversed
          .toList();

      // Reset retry count on success
      _paginationRetryCount = 0;

      state = state.copyWith(
        messages: [...olderMessages, ...state.messages],
        hasMoreMessages: olderMessages.length >= 50,
        error: null,
      );
    } catch (e, stackTrace) {
      _paginationRetryCount++;
      debugPrint('[ChatNotifier] Pagination error (attempt $_paginationRetryCount): $e');
      if (kDebugMode) {
        debugPrint(stackTrace.toString());
      }

      // Show error to user after max retries
      if (_paginationRetryCount >= _maxPaginationRetries) {
        state = state.copyWith(
          error: '이전 메시지를 불러오는데 실패했습니다.',
          hasMoreMessages: false,
        );
      }
    }
  }

  /// Parse messages from API response with type safety
  List<BroadcastMessage> _parseMessages(dynamic response) {
    if (response == null) return [];
    if (response is! List) {
      debugPrint('[ChatNotifier] Unexpected response type: ${response.runtimeType}');
      return [];
    }

    return response
        .whereType<Map<String, dynamic>>()
        .map((json) {
          try {
            return BroadcastMessage.fromJson(json);
          } catch (e) {
            debugPrint('[ChatNotifier] Failed to parse message: $e');
            return null;
          }
        })
        .whereType<BroadcastMessage>()
        .toList();
  }

  /// Send a text reply
  Future<bool> sendReply(String content) async {
    if (!state.canReply) return false;
    if (content.length > state.characterLimit) return false;

    // Handle demo mode
    final authState = _ref.read(authProvider);
    if (authState is AuthDemoMode) {
      return _sendDemoReply(content);
    }

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

  /// Send a demo reply (for demo mode)
  bool _sendDemoReply(String content) {
    final newMessage = BroadcastMessage(
      id: 'demo_msg_${DateTime.now().millisecondsSinceEpoch}',
      channelId: channelId,
      senderId: 'demo_user_001',
      senderType: 'fan',
      deliveryScope: DeliveryScope.directReply,
      content: content,
      createdAt: DateTime.now(),
      senderName: '데모 사용자',
      senderTier: state.subscription?.tier ?? 'STANDARD',
      senderDaysSubscribed: state.subscription?.daysSubscribed ?? 0,
      isRead: true,
    );

    // Update quota
    final newQuota = state.quota?.afterReply();

    state = state.copyWith(
      messages: [...state.messages, newMessage],
      quota: newQuota,
    );

    // Simulate artist reply after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _addDemoArtistReply();
      }
    });

    return true;
  }

  /// Add a demo artist auto-reply
  void _addDemoArtistReply() {
    final demoReplies = [
      '고마워요! 💕',
      '항상 응원해줘서 감사해요~',
      '좋은 하루 보내세요! ☺️',
      '메시지 잘 받았어요!',
      '사랑해요~ 🥰',
    ];

    final randomReply = demoReplies[DateTime.now().millisecond % demoReplies.length];

    final artistReply = BroadcastMessage(
      id: 'demo_msg_artist_${DateTime.now().millisecondsSinceEpoch}',
      channelId: channelId,
      senderId: state.channel?.artistId ?? 'demo_artist',
      senderType: 'artist',
      deliveryScope: DeliveryScope.broadcast,
      content: randomReply,
      createdAt: DateTime.now(),
      senderName: state.channel?.name ?? '아티스트',
      senderAvatarUrl: state.channel?.avatarUrl,
      isRead: false,
    );

    state = state.copyWith(
      messages: [...state.messages, artistReply],
    );
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
    _cleanupPresenceChannel();
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
