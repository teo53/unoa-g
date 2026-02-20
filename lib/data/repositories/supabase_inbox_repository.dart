import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';
import '../models/broadcast_message.dart';
import 'chat_repository.dart';

/// Supabase implementation of IArtistInboxRepository
/// Handles artist-side inbox operations (viewing fan messages, sending broadcasts)
class SupabaseInboxRepository implements IArtistInboxRepository {
  final SupabaseClient _supabase;

  SupabaseInboxRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseConfig.client;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    return user.id;
  }

  // ============================================
  // Fan Messages (Artist Inbox)
  // ============================================

  @override
  Future<List<BroadcastMessage>> getFanMessages(
    String channelId, {
    String filterType = 'all',
    int limit = 50,
    int offset = 0,
  }) async {
    // Verify the artist owns this channel
    await _verifyChannelOwnership(channelId);

    var query = _supabase
        .from('messages')
        .select('''
          *,
          user_profiles!sender_id (
            display_name,
            avatar_url
          ),
          subscriptions!left (
            tier,
            started_at
          )
        ''')
        .eq('channel_id', channelId)
        .inFilter('delivery_scope', ['direct_reply', 'donation_message'])
        .isFilter('deleted_at', null);

    // Apply filter
    switch (filterType) {
      case 'donation':
        query = query.eq('delivery_scope', 'donation_message');
        break;
      case 'regular':
        query = query.eq('delivery_scope', 'direct_reply');
        break;
      case 'highlighted':
        query = query.eq('is_highlighted', true);
        break;
      case 'all':
      default:
        // No additional filter
        break;
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return response.map((row) => _mapMessageWithSenderInfo(row)).toList();
  }

  @override
  Stream<List<BroadcastMessage>> watchFanMessages(String channelId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('channel_id', channelId)
        .order('created_at', ascending: false)
        .map((rows) {
          return rows
              .where((row) =>
                  (row['delivery_scope'] == 'direct_reply' ||
                      row['delivery_scope'] == 'donation_message') &&
                  row['deleted_at'] == null)
              .map((row) => BroadcastMessage.fromJson(row))
              .toList();
        });
  }

  BroadcastMessage _mapMessageWithSenderInfo(Map<String, dynamic> row) {
    final userProfile = row['user_profiles'] as Map<String, dynamic>?;
    final subscription = row['subscriptions'] as Map<String, dynamic>?;

    final startedAt = subscription?['started_at'] != null
        ? DateTime.parse(subscription!['started_at'] as String)
        : null;

    final daysSubscribed =
        startedAt != null ? DateTime.now().difference(startedAt).inDays : null;

    return BroadcastMessage.fromJson({
      ...row,
      'sender_name': userProfile?['display_name'],
      'sender_avatar_url': userProfile?['avatar_url'],
      'sender_tier': subscription?['tier'],
      'sender_days_subscribed': daysSubscribed,
    });
  }

  // ============================================
  // Sending Messages
  // ============================================

  @override
  Future<BroadcastMessage> sendBroadcast(
    String channelId,
    String content, {
    BroadcastMessageType messageType = BroadcastMessageType.text,
    String? mediaUrl,
    String? minTierRequired,
  }) async {
    // Verify the artist owns this channel
    await _verifyChannelOwnership(channelId);

    // Insert broadcast message
    final insertData = <String, dynamic>{
      'channel_id': channelId,
      'sender_id': _currentUserId,
      'sender_type': 'artist',
      'delivery_scope': 'broadcast',
      'content': content,
      'message_type': _messageTypeToString(messageType),
      'media_url': mediaUrl,
    };

    // Add tier gating if specified
    if (minTierRequired != null) {
      insertData['min_tier_required'] = minTierRequired;
    }

    final response =
        await _supabase.from('messages').insert(insertData).select().single();

    final message = BroadcastMessage.fromJson(response);

    // Create delivery records (filtered by tier if tier-gated)
    await _createDeliveryRecords(channelId, message.id,
        minTier: minTierRequired);

    // Update quotas for eligible subscribers (grant 3 tokens)
    await _refreshSubscriberQuotas(channelId, message.id);

    return message;
  }

  Future<void> _createDeliveryRecords(
    String channelId,
    String messageId, {
    String? minTier,
  }) async {
    // Get active subscribers, optionally filtered by tier
    var query = _supabase
        .from('subscriptions')
        .select('user_id, tier')
        .eq('channel_id', channelId)
        .eq('is_active', true);

    final subscribers = await query;
    if (subscribers.isEmpty) return;

    // Filter by tier if tier-gated
    // SECURITY: Unknown tiers are excluded (fail-closed) to prevent bypass
    const tierOrder = ['BASIC', 'STANDARD', 'VIP'];
    final minTierIndex = minTier != null ? tierOrder.indexOf(minTier) : -1;
    final eligible = minTier != null
        ? subscribers.where((s) {
            final subTier = s['tier'] as String? ?? '';
            final subIndex = tierOrder.indexOf(subTier);
            // Unknown tier → exclude (fail-closed)
            return minTierIndex >= 0 &&
                subIndex >= 0 &&
                subIndex >= minTierIndex;
          }).toList()
        : subscribers;

    if (eligible.isEmpty) return;

    // Create delivery records
    final deliveries = eligible
        .map((s) => {
              'message_id': messageId,
              'user_id': s['user_id'],
              'is_read': false,
            })
        .toList();

    await _supabase.from('message_delivery').insert(deliveries);
  }

  Future<void> _refreshSubscriberQuotas(
      String channelId, String messageId) async {
    // Get all active subscribers
    final subscribers = await _supabase
        .from('subscriptions')
        .select('user_id')
        .eq('channel_id', channelId)
        .eq('is_active', true);

    if (subscribers.isEmpty) return;

    final now = DateTime.now().toIso8601String();

    // Upsert quota records with 3 tokens
    for (final sub in subscribers) {
      await _supabase.from('reply_quota').upsert(
        {
          'user_id': sub['user_id'],
          'channel_id': channelId,
          'tokens_available': 3,
          'tokens_used': 0,
          'last_broadcast_id': messageId,
          'last_broadcast_at': now,
          'fallback_available': false,
          'updated_at': now,
        },
        onConflict: 'user_id,channel_id',
      );
    }
  }

  @override
  Future<BroadcastMessage> replyToDonation(
    String channelId,
    String donationMessageId,
    String content,
  ) async {
    // Verify the artist owns this channel
    await _verifyChannelOwnership(channelId);

    // Get the donation message to find the sender
    final donationMessage = await _supabase
        .from('messages')
        .select()
        .eq('id', donationMessageId)
        .eq('delivery_scope', 'donation_message')
        .single();

    final fanUserId = donationMessage['sender_id'] as String;

    // Check reply window (7 days)
    final donationTime =
        DateTime.parse(donationMessage['created_at'] as String);
    const replyWindowHours = 168; // 7 days
    if (DateTime.now().difference(donationTime).inHours > replyWindowHours) {
      throw StateError('Reply window expired (7 days)');
    }

    // Insert donation reply
    final response = await _supabase
        .from('messages')
        .insert({
          'channel_id': channelId,
          'sender_id': _currentUserId,
          'sender_type': 'artist',
          'delivery_scope': 'donation_reply',
          'content': content,
          'message_type': 'text',
          'reply_to_message_id': donationMessageId,
          'target_user_id': fanUserId,
        })
        .select()
        .single();

    return BroadcastMessage.fromJson(response);
  }

  // ============================================
  // Message Management
  // ============================================

  @override
  Future<void> toggleHighlight(String messageId) async {
    // Get current highlight status
    final message = await _supabase
        .from('messages')
        .select('is_highlighted, channel_id')
        .eq('id', messageId)
        .single();

    // Verify ownership
    await _verifyChannelOwnership(message['channel_id'] as String);

    final isCurrentlyHighlighted = message['is_highlighted'] as bool? ?? false;

    await _supabase.from('messages').update({
      'is_highlighted': !isCurrentlyHighlighted,
      'highlighted_at':
          isCurrentlyHighlighted ? null : DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId);
  }

  /// Edit a broadcast message (within 24 hours)
  Future<void> editMessage(String messageId, String newContent) async {
    final message =
        await _supabase.from('messages').select().eq('id', messageId).single();

    // Verify ownership
    await _verifyChannelOwnership(message['channel_id'] as String);

    // Check edit window (24 hours)
    final createdAt = DateTime.parse(message['created_at'] as String);
    if (DateTime.now().difference(createdAt).inHours > 24) {
      throw StateError('Edit window expired (24 hours)');
    }

    // Update edit history
    final editHistory =
        List<Map<String, dynamic>>.from(message['edit_history'] ?? []);
    editHistory.add({
      'previous_content': message['content'],
      'edited_at': DateTime.now().toIso8601String(),
    });

    await _supabase.from('messages').update({
      'content': newContent,
      'is_edited': true,
      'edit_history': editHistory,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId);
  }

  /// Delete a message for everyone (soft delete)
  Future<void> deleteForEveryone(String messageId) async {
    final message = await _supabase
        .from('messages')
        .select('channel_id')
        .eq('id', messageId)
        .single();

    // Verify ownership
    await _verifyChannelOwnership(message['channel_id'] as String);

    await _supabase.from('messages').update({
      'deleted_at': DateTime.now().toIso8601String(),
      'content': null,
      'media_url': null,
    }).eq('id', messageId);
  }

  /// Pin a message (max 3 pinned per channel)
  Future<void> pinMessage(String messageId) async {
    final message = await _supabase
        .from('messages')
        .select('channel_id')
        .eq('id', messageId)
        .single();

    final channelId = message['channel_id'] as String;

    // Verify ownership
    await _verifyChannelOwnership(channelId);

    // Check pin count
    final pinnedCount = await _supabase
        .from('messages')
        .select('id')
        .eq('channel_id', channelId)
        .eq('is_pinned', true);

    if (pinnedCount.length >= 3) {
      throw StateError('Maximum 3 pinned messages allowed');
    }

    await _supabase.from('messages').update({
      'is_pinned': true,
      'pinned_at': DateTime.now().toIso8601String(),
      'pinned_by': _currentUserId,
    }).eq('id', messageId);
  }

  /// Unpin a message
  Future<void> unpinMessage(String messageId) async {
    final message = await _supabase
        .from('messages')
        .select('channel_id')
        .eq('id', messageId)
        .single();

    // Verify ownership
    await _verifyChannelOwnership(message['channel_id'] as String);

    await _supabase.from('messages').update({
      'is_pinned': false,
      'pinned_at': null,
      'pinned_by': null,
    }).eq('id', messageId);
  }

  /// Get pinned messages for a channel
  Future<List<BroadcastMessage>> getPinnedMessages(String channelId) async {
    final response = await _supabase
        .from('messages')
        .select()
        .eq('channel_id', channelId)
        .eq('is_pinned', true)
        .order('pinned_at', ascending: false);

    return response.map((row) => BroadcastMessage.fromJson(row)).toList();
  }

  // ============================================
  // Statistics
  // ============================================

  @override
  Future<InboxStats> getInboxStats(String channelId) async {
    // Verify ownership
    await _verifyChannelOwnership(channelId);

    // Get all fan messages
    final messages = await _supabase
        .from('messages')
        .select('id, delivery_scope, is_highlighted')
        .eq('channel_id', channelId)
        .inFilter('delivery_scope',
            ['direct_reply', 'donation_message']).isFilter('deleted_at', null);

    // Get subscriber count
    final subscribers = await _supabase
        .from('subscriptions')
        .select('id')
        .eq('channel_id', channelId)
        .eq('is_active', true);

    final totalMessages = messages.length;
    final donationMessages =
        messages.where((m) => m['delivery_scope'] == 'donation_message').length;
    final highlightedMessages =
        messages.where((m) => m['is_highlighted'] == true).length;

    // Count unread fan messages via server-side RPC
    int unreadMessages = 0;
    try {
      final unreadResult = await _supabase.rpc(
        'count_unread_inbox_messages',
        params: {
          'p_channel_id': channelId,
          'p_artist_user_id': _currentUserId,
        },
      );
      unreadMessages = (unreadResult as int?) ?? 0;
    } catch (_) {
      // Graceful fallback - don't block stats loading if RPC not yet deployed
      unreadMessages = 0;
    }

    return InboxStats(
      totalMessages: totalMessages,
      unreadMessages: unreadMessages,
      donationMessages: donationMessages,
      highlightedMessages: highlightedMessages,
      subscriberCount: subscribers.length,
    );
  }

  // ============================================
  // Scheduled Messages
  // ============================================

  /// Schedule a broadcast for later
  Future<BroadcastMessage> scheduleBroadcast(
    String channelId,
    String content,
    DateTime scheduledAt, {
    BroadcastMessageType messageType = BroadcastMessageType.text,
    String? mediaUrl,
  }) async {
    // Verify ownership
    await _verifyChannelOwnership(channelId);

    if (scheduledAt.isBefore(DateTime.now())) {
      throw StateError('Scheduled time must be in the future');
    }

    final response = await _supabase
        .from('messages')
        .insert({
          'channel_id': channelId,
          'sender_id': _currentUserId,
          'sender_type': 'artist',
          'delivery_scope': 'broadcast',
          'content': content,
          'message_type': _messageTypeToString(messageType),
          'media_url': mediaUrl,
          'scheduled_at': scheduledAt.toIso8601String(),
          'scheduled_status': 'pending',
        })
        .select()
        .single();

    return BroadcastMessage.fromJson(response);
  }

  /// Get scheduled messages for a channel
  Future<List<BroadcastMessage>> getScheduledMessages(String channelId) async {
    // Verify ownership
    await _verifyChannelOwnership(channelId);

    final response = await _supabase
        .from('messages')
        .select()
        .eq('channel_id', channelId)
        .eq('scheduled_status', 'pending')
        .order('scheduled_at', ascending: true);

    return response.map((row) => BroadcastMessage.fromJson(row)).toList();
  }

  /// Cancel a scheduled message
  Future<void> cancelScheduledMessage(String messageId) async {
    final message = await _supabase
        .from('messages')
        .select('channel_id, scheduled_status')
        .eq('id', messageId)
        .single();

    // Verify ownership
    await _verifyChannelOwnership(message['channel_id'] as String);

    if (message['scheduled_status'] != 'pending') {
      throw StateError('Can only cancel pending scheduled messages');
    }

    await _supabase.from('messages').update({
      'scheduled_status': 'cancelled',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId);
  }

  // ============================================
  // Helpers
  // ============================================

  Future<void> _verifyChannelOwnership(String channelId) async {
    final channel = await _supabase
        .from('channels')
        .select('artist_id')
        .eq('id', channelId)
        .single();

    if (channel['artist_id'] != _currentUserId) {
      throw StateError('Not authorized to access this channel');
    }
  }

  String _messageTypeToString(BroadcastMessageType type) {
    switch (type) {
      case BroadcastMessageType.text:
        return 'text';
      case BroadcastMessageType.image:
        return 'image';
      case BroadcastMessageType.emoji:
        return 'emoji';
      case BroadcastMessageType.voice:
        return 'voice';
      case BroadcastMessageType.video:
        return 'video';
      case BroadcastMessageType.sticker:
        return 'sticker';
    }
  }
}
