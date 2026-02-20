import '../models/broadcast_message.dart';
import '../models/reply_quota.dart';
import '../models/channel.dart';

/// Abstract interface for chat operations
/// Allows swapping between Mock and Supabase implementations
abstract class IChatRepository {
  // ============================================
  // Messages
  // ============================================

  /// Watch messages for a channel (fan view - broadcasts + own replies + artist replies to self)
  Stream<List<BroadcastMessage>> watchMessages(String channelId);

  /// Get paginated messages
  Future<List<BroadcastMessage>> getMessages(
    String channelId, {
    int limit = 50,
    String? beforeId,
  });

  /// Send a reply (decrements quota)
  Future<BroadcastMessage> sendReply(
    String channelId,
    String content,
  );

  /// Send a donation message (100 char limit, no quota needed)
  Future<BroadcastMessage> sendDonationMessage(
    String channelId,
    String content,
    int donationAmount,
    String donationId,
  );

  // ============================================
  // Quota
  // ============================================

  /// Get current quota for a channel
  Future<ReplyQuota?> getQuota(String channelId);

  /// Watch quota changes in real-time
  Stream<ReplyQuota?> watchQuota(String channelId);

  /// Get character limit based on subscription age
  Future<int> getCharacterLimit(String channelId);

  // ============================================
  // Subscription
  // ============================================

  /// Get subscription info for a channel
  Future<Subscription?> getSubscription(String channelId);

  /// Get days subscribed to a channel
  Future<int> getDaysSubscribed(String channelId);

  // ============================================
  // Channel
  // ============================================

  /// Get channel info
  Future<Channel?> getChannel(String channelId);

  /// Get all subscribed channels
  Future<List<Channel>> getSubscribedChannels();
}

/// Abstract interface for artist inbox operations
abstract class IArtistInboxRepository {
  /// Get all fan messages (for artist inbox)
  Future<List<BroadcastMessage>> getFanMessages(
    String channelId, {
    String filterType = 'all', // 'all', 'donation', 'regular', 'highlighted'
    int limit = 50,
    int offset = 0,
  });

  /// Watch fan messages in real-time
  Stream<List<BroadcastMessage>> watchFanMessages(String channelId);

  /// Send a broadcast to all subscribers (optionally tier-gated)
  Future<BroadcastMessage> sendBroadcast(
    String channelId,
    String content, {
    BroadcastMessageType messageType = BroadcastMessageType.text,
    String? mediaUrl,
    String? minTierRequired,
  });

  /// Reply to a donation message (1:1)
  Future<BroadcastMessage> replyToDonation(
    String channelId,
    String donationMessageId,
    String content,
  );

  /// Highlight/unhighlight a fan message
  Future<void> toggleHighlight(String messageId);

  /// Get inbox statistics
  Future<InboxStats> getInboxStats(String channelId);
}

/// Inbox statistics for artist dashboard
class InboxStats {
  final int totalMessages;
  final int unreadMessages;
  final int donationMessages;
  final int highlightedMessages;
  final int subscriberCount;

  const InboxStats({
    required this.totalMessages,
    required this.unreadMessages,
    required this.donationMessages,
    required this.highlightedMessages,
    required this.subscriberCount,
  });
}
