import 'dart:async';
import '../models/broadcast_message.dart';
import '../models/reply_quota.dart';
import '../models/channel.dart';
import 'chat_repository.dart';

/// Mock implementation of IChatRepository for demo/testing
class MockChatRepository implements IChatRepository {
  // Simulated current user
  static const String _currentUserId = 'user_1';

  // In-memory storage
  final Map<String, List<BroadcastMessage>> _messages = {};
  final Map<String, ReplyQuota> _quotas = {};
  final Map<String, Subscription> _subscriptions = {};
  final Map<String, Channel> _channels = {};

  // Stream controllers for real-time updates
  final Map<String, StreamController<List<BroadcastMessage>>> _messageStreams =
      {};
  final Map<String, StreamController<ReplyQuota?>> _quotaStreams = {};

  MockChatRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    final now = DateTime.now();

    // Create mock channels (one per artist)
    _channels['channel_1'] = Channel(
      id: 'channel_1',
      artistId: 'artist_1',
      name: '아이유',
      description: '아이유의 프라이빗 메시지',
      avatarUrl: 'https://picsum.photos/seed/iu/200',
      createdAt: now.subtract(const Duration(days: 365)),
      updatedAt: now,
    );

    _channels['channel_2'] = Channel(
      id: 'channel_2',
      artistId: 'artist_2',
      name: '뉴진스',
      description: '뉴진스의 프라이빗 메시지',
      avatarUrl: 'https://picsum.photos/seed/nj/200',
      createdAt: now.subtract(const Duration(days: 180)),
      updatedAt: now,
    );

    // Create mock subscriptions (user subscribed for different periods)
    _subscriptions['channel_1'] = Subscription(
      id: 'sub_1',
      userId: _currentUserId,
      channelId: 'channel_1',
      tier: 'STANDARD',
      startedAt: now.subtract(const Duration(days: 85)), // 85일 구독
      isActive: true,
      autoRenew: true,
      createdAt: now.subtract(const Duration(days: 85)),
      updatedAt: now,
    );

    _subscriptions['channel_2'] = Subscription(
      id: 'sub_2',
      userId: _currentUserId,
      channelId: 'channel_2',
      tier: 'STANDARD',
      startedAt: now.subtract(const Duration(days: 30)), // 30일 구독
      isActive: true,
      autoRenew: true,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
    );

    // Create mock quotas (3 tokens per broadcast)
    _quotas['channel_1'] = ReplyQuota(
      id: 'quota_1',
      userId: _currentUserId,
      channelId: 'channel_1',
      tokensAvailable: 2, // 1개 사용함
      tokensUsed: 1,
      lastBroadcastId: 'msg_broadcast_1',
      lastBroadcastAt: now.subtract(const Duration(hours: 2)),
      createdAt: now.subtract(const Duration(days: 85)),
      updatedAt: now,
    );

    _quotas['channel_2'] = ReplyQuota(
      id: 'quota_2',
      userId: _currentUserId,
      channelId: 'channel_2',
      tokensAvailable: 0, // 토큰 소진
      tokensUsed: 3,
      lastBroadcastId: 'msg_broadcast_2',
      lastBroadcastAt: now.subtract(const Duration(days: 3)),
      fallbackAvailable: false,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
    );

    // Create mock messages for channel_1
    _messages['channel_1'] = [
      // Artist broadcast
      BroadcastMessage(
        id: 'msg_broadcast_1',
        channelId: 'channel_1',
        senderId: 'artist_1',
        senderType: 'artist',
        deliveryScope: DeliveryScope.broadcast,
        content: '오늘 날씨가 너무 좋아서 공원에서 산책했어요 🌸',
        createdAt: now.subtract(const Duration(hours: 2)),
        senderName: '아이유',
        senderAvatarUrl: 'https://picsum.photos/seed/iu/200',
      ),
      // Fan reply
      BroadcastMessage(
        id: 'msg_reply_1',
        channelId: 'channel_1',
        senderId: _currentUserId,
        senderType: 'fan',
        deliveryScope: DeliveryScope.directReply,
        content: '언니 저도 산책 좋아해요! 어디 공원이에요?',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 30)),
      ),
      // Another artist broadcast
      BroadcastMessage(
        id: 'msg_broadcast_0',
        channelId: 'channel_1',
        senderId: 'artist_1',
        senderType: 'artist',
        deliveryScope: DeliveryScope.broadcast,
        content: '다들 뭐하고 있어요? 저는 녹음 중이에요 🎤',
        createdAt: now.subtract(const Duration(days: 1)),
        senderName: '아이유',
        senderAvatarUrl: 'https://picsum.photos/seed/iu/200',
      ),
    ];

    _messages['channel_2'] = [
      // Artist broadcast
      BroadcastMessage(
        id: 'msg_broadcast_2',
        channelId: 'channel_2',
        senderId: 'artist_2',
        senderType: 'artist',
        deliveryScope: DeliveryScope.broadcast,
        content: '오늘 연습 끝! 다들 굿나잇 🌙',
        createdAt: now.subtract(const Duration(days: 3)),
        senderName: '뉴진스',
        senderAvatarUrl: 'https://picsum.photos/seed/nj/200',
      ),
      // Fan's donation message
      BroadcastMessage(
        id: 'msg_donation_1',
        channelId: 'channel_2',
        senderId: _currentUserId,
        senderType: 'fan',
        deliveryScope: DeliveryScope.donationMessage,
        content: '항상 응원합니다! 화이팅!',
        donationAmount: 100,
        donationId: 'donation_1',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      // Artist's donation reply
      BroadcastMessage(
        id: 'msg_donation_reply_1',
        channelId: 'channel_2',
        senderId: 'artist_2',
        senderType: 'artist',
        deliveryScope: DeliveryScope.donationReply,
        targetUserId: _currentUserId,
        replyToMessageId: 'msg_donation_1',
        content: '고마워요!! 💕 덕분에 힘이 나요',
        createdAt: now.subtract(const Duration(days: 1, hours: 12)),
        senderName: '뉴진스',
        senderAvatarUrl: 'https://picsum.photos/seed/nj/200',
      ),
    ];
  }

  @override
  Stream<List<BroadcastMessage>> watchMessages(String channelId) {
    if (!_messageStreams.containsKey(channelId)) {
      _messageStreams[channelId] =
          StreamController<List<BroadcastMessage>>.broadcast();
    }

    // Emit current messages immediately
    Future.microtask(() {
      _messageStreams[channelId]?.add(_messages[channelId] ?? []);
    });

    return _messageStreams[channelId]!.stream;
  }

  @override
  Future<List<BroadcastMessage>> getMessages(
    String channelId, {
    int limit = 50,
    String? beforeId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate network

    final messages = _messages[channelId] ?? [];

    if (beforeId != null) {
      final index = messages.indexWhere((m) => m.id == beforeId);
      if (index > 0) {
        return messages.sublist(0, index).take(limit).toList();
      }
    }

    return messages.take(limit).toList();
  }

  @override
  Future<BroadcastMessage> sendReply(String channelId, String content) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Check quota
    final quota = _quotas[channelId];
    if (quota == null || !quota.canReply) {
      throw Exception('No reply tokens available');
    }

    // Check character limit
    final charLimit = await getCharacterLimit(channelId);
    if (content.length > charLimit) {
      throw Exception('Message too long. Maximum $charLimit characters allowed.');
    }

    // Create message
    final message = BroadcastMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      channelId: channelId,
      senderId: _currentUserId,
      senderType: 'fan',
      deliveryScope: DeliveryScope.directReply,
      content: content,
      createdAt: DateTime.now(),
    );

    // Add to messages
    _messages[channelId] = [...(_messages[channelId] ?? []), message];

    // Decrement quota
    _quotas[channelId] = quota.afterReply();

    // Notify streams
    _messageStreams[channelId]?.add(_messages[channelId]!);
    _quotaStreams[channelId]?.add(_quotas[channelId]);

    return message;
  }

  @override
  Future<BroadcastMessage> sendDonationMessage(
    String channelId,
    String content,
    int donationAmount,
    String donationId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Donation messages have 100 char limit
    if (content.length > 100) {
      throw Exception('Donation message too long. Maximum 100 characters allowed.');
    }

    final message = BroadcastMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      channelId: channelId,
      senderId: _currentUserId,
      senderType: 'fan',
      deliveryScope: DeliveryScope.donationMessage,
      content: content,
      donationAmount: donationAmount,
      donationId: donationId,
      createdAt: DateTime.now(),
    );

    _messages[channelId] = [...(_messages[channelId] ?? []), message];
    _messageStreams[channelId]?.add(_messages[channelId]!);

    return message;
  }

  @override
  Future<ReplyQuota?> getQuota(String channelId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _quotas[channelId];
  }

  @override
  Stream<ReplyQuota?> watchQuota(String channelId) {
    if (!_quotaStreams.containsKey(channelId)) {
      _quotaStreams[channelId] = StreamController<ReplyQuota?>.broadcast();
    }

    Future.microtask(() {
      _quotaStreams[channelId]?.add(_quotas[channelId]);
    });

    return _quotaStreams[channelId]!.stream;
  }

  @override
  Future<int> getCharacterLimit(String channelId) async {
    final subscription = _subscriptions[channelId];
    if (subscription == null) return 50;

    final daysSubscribed = subscription.daysSubscribed;
    return CharacterLimits.defaultLimits.getLimitForDays(daysSubscribed);
  }

  @override
  Future<Subscription?> getSubscription(String channelId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _subscriptions[channelId];
  }

  @override
  Future<int> getDaysSubscribed(String channelId) async {
    final subscription = _subscriptions[channelId];
    return subscription?.daysSubscribed ?? 0;
  }

  @override
  Future<Channel?> getChannel(String channelId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _channels[channelId];
  }

  @override
  Future<List<Channel>> getSubscribedChannels() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final activeSubChannelIds = _subscriptions.entries
        .where((e) => e.value.isActive)
        .map((e) => e.key)
        .toList();

    return _channels.values
        .where((c) => activeSubChannelIds.contains(c.id))
        .toList();
  }

  /// Dispose all stream controllers
  void dispose() {
    for (final controller in _messageStreams.values) {
      controller.close();
    }
    for (final controller in _quotaStreams.values) {
      controller.close();
    }
  }
}

/// Mock implementation of IArtistInboxRepository
class MockArtistInboxRepository implements IArtistInboxRepository {
  final Map<String, List<BroadcastMessage>> _fanMessages = {};
  final Map<String, StreamController<List<BroadcastMessage>>> _inboxStreams =
      {};

  MockArtistInboxRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    final now = DateTime.now();

    // Mock fan messages for artist inbox
    _fanMessages['channel_1'] = [
      BroadcastMessage(
        id: 'fan_msg_1',
        channelId: 'channel_1',
        senderId: 'fan_1',
        senderType: 'fan',
        deliveryScope: DeliveryScope.directReply,
        content: '언니 노래 너무 좋아요!',
        createdAt: now.subtract(const Duration(hours: 1)),
        senderName: '팬1',
        senderTier: 'STANDARD',
        senderDaysSubscribed: 45,
      ),
      BroadcastMessage(
        id: 'fan_msg_2',
        channelId: 'channel_1',
        senderId: 'fan_2',
        senderType: 'fan',
        deliveryScope: DeliveryScope.donationMessage,
        content: '항상 응원해요! 💕',
        donationAmount: 500,
        donationId: 'donation_2',
        createdAt: now.subtract(const Duration(hours: 2)),
        senderName: '팬2',
        senderTier: 'VIP',
        senderDaysSubscribed: 200,
        isHighlighted: true,
      ),
      BroadcastMessage(
        id: 'fan_msg_3',
        channelId: 'channel_1',
        senderId: 'fan_3',
        senderType: 'fan',
        deliveryScope: DeliveryScope.directReply,
        content: '오늘 공연 너무 기대돼요',
        createdAt: now.subtract(const Duration(hours: 5)),
        senderName: '팬3',
        senderTier: 'STANDARD',
        senderDaysSubscribed: 30,
      ),
    ];
  }

  @override
  Future<List<BroadcastMessage>> getFanMessages(
    String channelId, {
    String filterType = 'all',
    int limit = 50,
    int offset = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    var messages = _fanMessages[channelId] ?? [];

    switch (filterType) {
      case 'donation':
        messages = messages
            .where((m) => m.deliveryScope == DeliveryScope.donationMessage)
            .toList();
        break;
      case 'regular':
        messages = messages
            .where((m) => m.deliveryScope == DeliveryScope.directReply)
            .toList();
        break;
      case 'highlighted':
        messages = messages.where((m) => m.isHighlighted).toList();
        break;
    }

    return messages.skip(offset).take(limit).toList();
  }

  @override
  Stream<List<BroadcastMessage>> watchFanMessages(String channelId) {
    if (!_inboxStreams.containsKey(channelId)) {
      _inboxStreams[channelId] =
          StreamController<List<BroadcastMessage>>.broadcast();
    }

    Future.microtask(() {
      _inboxStreams[channelId]?.add(_fanMessages[channelId] ?? []);
    });

    return _inboxStreams[channelId]!.stream;
  }

  @override
  Future<BroadcastMessage> sendBroadcast(
    String channelId,
    String content, {
    BroadcastMessageType messageType = BroadcastMessageType.text,
    String? mediaUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return BroadcastMessage(
      id: 'broadcast_${DateTime.now().millisecondsSinceEpoch}',
      channelId: channelId,
      senderId: 'artist_1', // Would be current artist
      senderType: 'artist',
      deliveryScope: DeliveryScope.broadcast,
      content: content,
      messageType: messageType,
      mediaUrl: mediaUrl,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<BroadcastMessage> replyToDonation(
    String channelId,
    String donationMessageId,
    String content,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Find original donation message
    final originalMsg = _fanMessages[channelId]?.firstWhere(
      (m) => m.id == donationMessageId,
      orElse: () => throw Exception('Donation message not found'),
    );

    if (originalMsg?.deliveryScope != DeliveryScope.donationMessage) {
      throw Exception('Can only reply to donation messages');
    }

    return BroadcastMessage(
      id: 'donation_reply_${DateTime.now().millisecondsSinceEpoch}',
      channelId: channelId,
      senderId: 'artist_1',
      senderType: 'artist',
      deliveryScope: DeliveryScope.donationReply,
      targetUserId: originalMsg?.senderId,
      replyToMessageId: donationMessageId,
      content: content,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> toggleHighlight(String messageId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    for (final channelId in _fanMessages.keys) {
      final messages = _fanMessages[channelId]!;
      final index = messages.indexWhere((m) => m.id == messageId);
      if (index >= 0) {
        _fanMessages[channelId]![index] = messages[index].copyWith(
          isHighlighted: !messages[index].isHighlighted,
          highlightedAt: DateTime.now(),
        );
        _inboxStreams[channelId]?.add(_fanMessages[channelId]!);
        break;
      }
    }
  }

  @override
  Future<InboxStats> getInboxStats(String channelId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final messages = _fanMessages[channelId] ?? [];

    return InboxStats(
      totalMessages: messages.length,
      unreadMessages: messages.where((m) => m.isRead != true).length,
      donationMessages: messages
          .where((m) => m.deliveryScope == DeliveryScope.donationMessage)
          .length,
      highlightedMessages: messages.where((m) => m.isHighlighted).length,
      subscriberCount: 1250, // Mock value
    );
  }

  void dispose() {
    for (final controller in _inboxStreams.values) {
      controller.close();
    }
  }
}
