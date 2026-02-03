import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';
import '../models/broadcast_message.dart';
import '../models/channel.dart';
import '../models/reply_quota.dart';
import 'chat_repository.dart';

/// Supabase implementation of IChatRepository
/// Handles fan-side chat operations with real-time subscriptions
class SupabaseChatRepository implements IChatRepository {
  final SupabaseClient _supabase;

  // Cache for policy configs
  CharacterLimits? _characterLimits;

  SupabaseChatRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseConfig.client;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    return user.id;
  }

  // ============================================
  // Messages
  // ============================================

  @override
  Stream<List<BroadcastMessage>> watchMessages(String channelId) {
    // Use the user_chat_thread_view which handles visibility rules
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('channel_id', channelId)
        .order('created_at', ascending: true)
        .map((rows) {
          // Filter messages based on visibility rules in Dart
          // (In production, use database view for better performance)
          return rows
              .where((row) => _isMessageVisibleToFan(row))
              .map((row) => BroadcastMessage.fromJson(row))
              .toList();
        });
  }

  /// Check if a message should be visible to the current fan
  bool _isMessageVisibleToFan(Map<String, dynamic> row) {
    final deliveryScope = row['delivery_scope'] as String?;
    final senderId = row['sender_id'] as String?;
    final targetUserId = row['target_user_id'] as String?;
    final deletedAt = row['deleted_at'];

    // Skip deleted messages
    if (deletedAt != null) return false;

    switch (deliveryScope) {
      case 'broadcast':
        // Broadcasts are visible to all subscribers
        return true;
      case 'direct_reply':
      case 'donation_message':
        // Fan's own replies are visible
        return senderId == _currentUserId;
      case 'donation_reply':
        // Artist's reply to donation is only visible to target fan
        return targetUserId == _currentUserId;
      default:
        return false;
    }
  }

  @override
  Future<List<BroadcastMessage>> getMessages(
    String channelId, {
    int limit = 50,
    String? beforeId,
  }) async {
    var query = _supabase
        .from('messages')
        .select('''
          *,
          user_profiles!sender_id (
            display_name,
            avatar_url
          ),
          subscriptions!inner (
            tier,
            started_at
          )
        ''')
        .eq('channel_id', channelId)
        .order('created_at', ascending: false)
        .limit(limit);

    if (beforeId != null) {
      // Get the timestamp of the before message for cursor pagination
      final beforeMsg = await _supabase
          .from('messages')
          .select('created_at')
          .eq('id', beforeId)
          .single();

      query = query.lt('created_at', beforeMsg['created_at']);
    }

    final response = await query;

    return response
        .where((row) => _isMessageVisibleToFan(row))
        .map((row) => _mapMessageWithSenderInfo(row))
        .toList()
        .reversed
        .toList(); // Reverse to get chronological order
  }

  BroadcastMessage _mapMessageWithSenderInfo(Map<String, dynamic> row) {
    final userProfile = row['user_profiles'] as Map<String, dynamic>?;
    final subscription = row['subscriptions'] as Map<String, dynamic>?;

    final startedAt = subscription?['started_at'] != null
        ? DateTime.parse(subscription!['started_at'] as String)
        : null;

    final daysSubscribed = startedAt != null
        ? DateTime.now().difference(startedAt).inDays
        : null;

    return BroadcastMessage.fromJson({
      ...row,
      'sender_name': userProfile?['display_name'],
      'sender_avatar_url': userProfile?['avatar_url'],
      'sender_tier': subscription?['tier'],
      'sender_days_subscribed': daysSubscribed,
    });
  }

  @override
  Future<BroadcastMessage> sendReply(
    String channelId,
    String content,
  ) async {
    // Check quota first
    final quota = await getQuota(channelId);
    if (quota == null || !quota.canReply) {
      throw StateError('No reply tokens available');
    }

    // Check character limit
    final charLimit = await getCharacterLimit(channelId);
    if (content.length > charLimit) {
      throw StateError('Message exceeds character limit ($charLimit)');
    }

    // Start a pseudo-transaction
    // 1. Insert message
    final response = await _supabase.from('messages').insert({
      'channel_id': channelId,
      'sender_id': _currentUserId,
      'sender_type': 'fan',
      'delivery_scope': 'direct_reply',
      'content': content,
      'message_type': 'text',
    }).select().single();

    // 2. Decrement quota
    if (quota.tokensAvailable > 0) {
      await _supabase.from('reply_quota').update({
        'tokens_available': quota.tokensAvailable - 1,
        'tokens_used': quota.tokensUsed + 1,
        'last_reply_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', quota.id);
    } else if (quota.fallbackAvailable) {
      await _supabase.from('reply_quota').update({
        'fallback_available': false,
        'fallback_used_at': DateTime.now().toIso8601String(),
        'last_reply_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', quota.id);
    }

    return BroadcastMessage.fromJson(response);
  }

  @override
  Future<BroadcastMessage> sendDonationMessage(
    String channelId,
    String content,
    int donationAmount,
    String donationId,
  ) async {
    // Donation messages have 100 char limit
    const donationCharLimit = 100;
    if (content.length > donationCharLimit) {
      throw StateError('Donation message exceeds $donationCharLimit characters');
    }

    // Get channel to find creator
    final channel = await getChannel(channelId);
    if (channel == null) throw StateError('Channel not found');

    final response = await _supabase.from('messages').insert({
      'channel_id': channelId,
      'sender_id': _currentUserId,
      'sender_type': 'fan',
      'delivery_scope': 'donation_message',
      'content': content,
      'message_type': 'text',
      'donation_id': donationId,
      'donation_amount': donationAmount,
      'target_user_id': channel.artistId, // Target is the artist
    }).select().single();

    return BroadcastMessage.fromJson(response);
  }

  // ============================================
  // Quota
  // ============================================

  @override
  Future<ReplyQuota?> getQuota(String channelId) async {
    final response = await _supabase
        .from('reply_quota')
        .select()
        .eq('user_id', _currentUserId)
        .eq('channel_id', channelId)
        .maybeSingle();

    if (response == null) {
      // Create empty quota if doesn't exist
      return ReplyQuota.empty(_currentUserId, channelId);
    }

    return ReplyQuota.fromJson(response);
  }

  @override
  Stream<ReplyQuota?> watchQuota(String channelId) {
    return _supabase
        .from('reply_quota')
        .stream(primaryKey: ['id'])
        .eq('user_id', _currentUserId)
        .eq('channel_id', channelId)
        .map((rows) {
          if (rows.isEmpty) {
            return ReplyQuota.empty(_currentUserId, channelId);
          }
          return ReplyQuota.fromJson(rows.first);
        });
  }

  @override
  Future<int> getCharacterLimit(String channelId) async {
    // Load character limits from policy_config if not cached
    _characterLimits ??= await _loadCharacterLimits();

    // Get subscription days
    final daysSubscribed = await getDaysSubscribed(channelId);

    return _characterLimits!.getLimitForDays(daysSubscribed);
  }

  Future<CharacterLimits> _loadCharacterLimits() async {
    final response = await _supabase
        .from('policy_config')
        .select('value')
        .eq('key', 'character_limits')
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) {
      return CharacterLimits.defaultLimits;
    }

    return CharacterLimits.fromJson(response['value'] as Map<String, dynamic>);
  }

  // ============================================
  // Subscription
  // ============================================

  @override
  Future<Subscription?> getSubscription(String channelId) async {
    final response = await _supabase
        .from('subscriptions')
        .select()
        .eq('user_id', _currentUserId)
        .eq('channel_id', channelId)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return Subscription.fromJson(response);
  }

  @override
  Future<int> getDaysSubscribed(String channelId) async {
    final subscription = await getSubscription(channelId);
    return subscription?.daysSubscribed ?? 0;
  }

  // ============================================
  // Channel
  // ============================================

  @override
  Future<Channel?> getChannel(String channelId) async {
    final response = await _supabase
        .from('channels')
        .select('''
          *,
          subscriptions!left (
            id
          )
        ''')
        .eq('id', channelId)
        .maybeSingle();

    if (response == null) return null;

    // Count subscribers
    final subs = response['subscriptions'] as List?;
    final subscriberCount = subs?.length ?? 0;

    return Channel.fromJson({
      ...response,
      'subscriber_count': subscriberCount,
    });
  }

  @override
  Future<List<Channel>> getSubscribedChannels() async {
    final response = await _supabase
        .from('subscriptions')
        .select('''
          channel_id,
          channels!inner (
            *
          )
        ''')
        .eq('user_id', _currentUserId)
        .eq('is_active', true);

    return response.map((row) {
      final channelData = row['channels'] as Map<String, dynamic>;
      return Channel.fromJson(channelData);
    }).toList();
  }

  // ============================================
  // Read Receipts
  // ============================================

  /// Mark a message as read
  Future<void> markAsRead(String messageId) async {
    await _supabase.from('message_delivery').upsert({
      'message_id': messageId,
      'user_id': _currentUserId,
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }, onConflict: 'message_id,user_id');
  }

  /// Mark all messages in a channel as read
  Future<void> markChannelAsRead(String channelId) async {
    // Get all unread message IDs for this channel
    final unreadMessages = await _supabase
        .from('messages')
        .select('id')
        .eq('channel_id', channelId)
        .not('id', 'in',
          _supabase
              .from('message_delivery')
              .select('message_id')
              .eq('user_id', _currentUserId)
              .eq('is_read', true)
        );

    if (unreadMessages.isEmpty) return;

    // Create read receipts for all unread messages
    final now = DateTime.now().toIso8601String();
    final deliveries = unreadMessages.map((msg) => {
      'message_id': msg['id'],
      'user_id': _currentUserId,
      'is_read': true,
      'read_at': now,
    }).toList();

    await _supabase.from('message_delivery').upsert(
      deliveries,
      onConflict: 'message_id,user_id',
    );
  }

  /// Get unread count for a channel
  Future<int> getUnreadCount(String channelId) async {
    final response = await _supabase
        .from('messages')
        .select('id')
        .eq('channel_id', channelId)
        .eq('delivery_scope', 'broadcast')
        .isFilter('deleted_at', null);

    final readMessages = await _supabase
        .from('message_delivery')
        .select('message_id')
        .eq('user_id', _currentUserId)
        .eq('is_read', true)
        .inFilter('message_id', response.map((r) => r['id']).toList());

    return response.length - readMessages.length;
  }
}
