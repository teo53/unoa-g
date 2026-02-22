import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';

/// Repository for creator-side chat operations:
/// channel lookup, broadcasting, polls, AI suggestions,
/// user consents, subscription pricing, private cards, IAP
class SupabaseCreatorChatRepository {
  final SupabaseClient _supabase;

  SupabaseCreatorChatRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseConfig.client;

  String get _currentUserId => _supabase.currentUserId;

  // ============================================
  // Channel Lookup
  // ============================================

  /// Get creator's channel ID
  Future<String?> getCreatorChannelId() async {
    final result = await _supabase
        .from('channels')
        .select('id')
        .eq('artist_id', _currentUserId)
        .maybeSingle();
    return result?['id'] as String?;
  }

  // ============================================
  // Messages
  // ============================================

  /// Send creator broadcast or direct reply message
  Future<Map<String, dynamic>> sendMessage({
    required String channelId,
    required String content,
    required String deliveryScope,
    String? targetUserId,
    String? messageType,
    Map<String, dynamic>? metadata,
  }) async {
    final insertData = <String, dynamic>{
      'channel_id': channelId,
      'sender_id': _currentUserId,
      'sender_type': 'artist',
      'content': content,
      'delivery_scope': deliveryScope,
    };

    if (targetUserId != null) {
      insertData['target_user_id'] = targetUserId;
    }
    if (messageType != null) {
      insertData['message_type'] = messageType;
    }
    if (metadata != null) {
      insertData.addAll(metadata);
    }

    return await _supabase
        .from('messages')
        .insert(insertData)
        .select()
        .single();
  }

  // ============================================
  // Polls
  // ============================================

  /// Create poll message via RPC
  Future<void> createPollMessage({
    required String channelId,
    required String question,
    required List<Map<String, dynamic>> options,
    String? comment,
    String? draftId,
  }) async {
    await _supabase.rpc(
      'create_poll_message',
      params: {
        'p_channel_id': channelId,
        'p_question': question,
        'p_options': options,
        'p_comment': comment,
        'p_draft_id': draftId,
      },
    );
  }

  /// Generate AI poll suggestions via Edge Function
  Future<Map<String, dynamic>> generatePollSuggestions(
    String channelId, {
    int count = 5,
  }) async {
    final response = await _supabase.functions.invoke(
      'ai-poll-suggest',
      body: {
        'channel_id': channelId,
        'count': count,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ============================================
  // User Consents
  // ============================================

  /// Update user consent record
  Future<void> updateUserConsent({
    required String consentType,
    required bool agreed,
    required String version,
  }) async {
    await _supabase.from('user_consents').upsert(
      {
        'user_id': _currentUserId,
        'consent_type': consentType,
        'version': version,
        'agreed': agreed,
        'agreed_at': agreed ? DateTime.now().toIso8601String() : null,
        'revoked_at': !agreed ? DateTime.now().toIso8601String() : null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,consent_type,version',
    );
  }

  // ============================================
  // Subscription Pricing
  // ============================================

  /// Get subscription pricing policy for a channel
  Future<Map<String, dynamic>?> getSubscriptionPricingPolicy(
      String channelId) async {
    return await _supabase
        .from('policy_config')
        .select('value')
        .eq('key', 'subscription_pricing:$channelId')
        .maybeSingle();
  }

  // ============================================
  // Private Cards
  // ============================================

  /// Mark a fan as favorite
  Future<void> markFanAsFavorite(String fanId) async {
    await _supabase.from('fan_favorites').upsert({
      'creator_id': _currentUserId,
      'fan_id': fanId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Remove fan from favorites
  Future<void> removeFanFromFavorites(String fanId) async {
    await _supabase
        .from('fan_favorites')
        .delete()
        .eq('creator_id', _currentUserId)
        .eq('fan_id', fanId);
  }

  /// Send private card via Edge Function
  Future<Map<String, dynamic>> sendPrivateCard({
    required String templateId,
    required String cardText,
    required List<String> attachedMediaUrls,
    required List<String> recipientIds,
    String? filterUsed,
  }) async {
    final response = await _supabase.functions.invoke(
      'send-private-card',
      body: {
        'creatorId': _currentUserId,
        'templateId': templateId,
        'cardText': cardText,
        'attachedMediaUrls': attachedMediaUrls,
        'recipientIds': recipientIds,
        'filterUsed': filterUsed,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get private card history
  Future<List<Map<String, dynamic>>> getPrivateCardHistory(
      {int limit = 50}) async {
    final response = await _supabase
        .from('private_cards')
        .select()
        .eq('artist_id', _currentUserId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // ============================================
  // Creator Content
  // ============================================

  /// Save creator social links
  Future<void> saveSocialLinks(Map<String, String?> socialLinks) async {
    await _supabase.from('creator_profiles').upsert({
      'user_id': _currentUserId,
      'social_links': socialLinks,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Save creator drops
  Future<void> saveCreatorDrops(
      List<Map<String, dynamic>> drops, String channelId) async {
    await _supabase.from('creator_drops').upsert(drops);
  }

  /// Save creator events
  Future<void> saveCreatorEvents(
      List<Map<String, dynamic>> events, String channelId) async {
    await _supabase.from('creator_events').upsert(events);
  }

  // ============================================
  // IAP Verification
  // ============================================

  /// Verify IAP purchase and credit DT via Edge Function
  Future<Map<String, dynamic>> verifyIAPPurchase({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionReceipt,
    String? transactionId,
  }) async {
    final body = <String, dynamic>{
      'platform': platform,
      'productId': productId,
      'purchaseToken': purchaseToken,
    };

    if (transactionReceipt != null) {
      body['transactionReceipt'] = transactionReceipt;
    }
    if (transactionId != null) {
      body['transactionId'] = transactionId;
    }

    final response = await _supabase.functions.invoke(
      'iap-verify',
      body: body,
    );
    return response.data as Map<String, dynamic>;
  }
}
