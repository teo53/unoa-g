import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';

/// Supabase Funding Repository
///
/// Real Supabase implementation for funding system operations:
/// - Reward tiers, backers, stats, pledges, FAQ, updates
class SupabaseFundingRepository {
  SupabaseClient get _client => SupabaseConfig.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ============================================
  // Reward Tiers
  // ============================================

  /// Get reward tiers for a campaign
  Future<List<Map<String, dynamic>>> getTiersForCampaign(
      String campaignId) async {
    final response = await _client
        .from('funding_reward_tiers')
        .select()
        .eq('campaign_id', campaignId)
        .eq('is_active', true)
        .order('display_order', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Create a reward tier
  Future<Map<String, dynamic>> createTier({
    required String campaignId,
    required String title,
    String? description,
    required int priceKrw,
    int? totalQuantity,
    int displayOrder = 0,
    bool isFeatured = false,
  }) async {
    final response = await _client
        .from('funding_reward_tiers')
        .insert({
          'campaign_id': campaignId,
          'title': title,
          'description': description,
          'price_krw': priceKrw,
          'total_quantity': totalQuantity,
          'remaining_quantity': totalQuantity,
          'display_order': displayOrder,
          'is_featured': isFeatured,
        })
        .select()
        .single();

    return response;
  }

  /// Update a reward tier
  Future<void> updateTier(
    String tierId, {
    String? title,
    String? description,
    int? priceKrw,
    int? totalQuantity,
    int? displayOrder,
    bool? isFeatured,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (priceKrw != null) updates['price_krw'] = priceKrw;
    if (totalQuantity != null) {
      updates['total_quantity'] = totalQuantity;
      updates['remaining_quantity'] = totalQuantity;
    }
    if (displayOrder != null) updates['display_order'] = displayOrder;
    if (isFeatured != null) updates['is_featured'] = isFeatured;
    if (isActive != null) updates['is_active'] = isActive;

    if (updates.isNotEmpty) {
      await _client
          .from('funding_reward_tiers')
          .update(updates)
          .eq('id', tierId);
    }
  }

  /// Delete a reward tier
  Future<void> deleteTier(String tierId) async {
    await _client.from('funding_reward_tiers').delete().eq('id', tierId);
  }

  // ============================================
  // Backers (Pledges with user info)
  // ============================================

  /// Get backers for a campaign (pledges joined with user profiles)
  Future<List<Map<String, dynamic>>> getBackersForCampaign(
    String campaignId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _client
        .from('funding_pledges')
        .select('''
          id,
          user_id,
          tier_id,
          amount_krw,
          extra_support_krw,
          is_anonymous,
          support_message,
          status,
          created_at,
          paid_at,
          funding_reward_tiers!tier_id (title),
          user_profiles!user_id (display_name, avatar_url)
        ''')
        .eq('campaign_id', campaignId)
        .eq('status', 'paid')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get backer count for a campaign
  Future<int> getBackerCount(String campaignId) async {
    final response = await _client
        .from('funding_pledges')
        .select('id')
        .eq('campaign_id', campaignId)
        .eq('status', 'paid');

    return (response as List).length;
  }

  // ============================================
  // Campaign Stats
  // ============================================

  /// Get aggregated stats for a campaign
  Future<Map<String, dynamic>> getStatsForCampaign(
      String campaignId) async {
    // Get tier distribution
    final tierStats = await _client
        .from('funding_reward_tiers')
        .select('title, pledge_count')
        .eq('campaign_id', campaignId)
        .eq('is_active', true)
        .order('display_order', ascending: true);

    // Get daily funding data (last 14 days)
    final fourteenDaysAgo =
        DateTime.now().subtract(const Duration(days: 14)).toIso8601String();

    final dailyData = await _client.rpc('get_daily_funding_data', params: {
      'p_campaign_id': campaignId,
      'p_since': fourteenDaysAgo,
    }).catchError((_) {
      // If RPC doesn't exist, fall back to manual aggregation
      return <dynamic>[];
    });

    return {
      'tier_stats': tierStats,
      'daily_data': dailyData,
    };
  }

  // ============================================
  // Pledges (My pledges as a fan)
  // ============================================

  /// Get current user's pledges
  Future<List<Map<String, dynamic>>> getMyPledges({
    int limit = 50,
    int offset = 0,
  }) async {
    if (_userId == null) return [];

    final response = await _client
        .from('funding_pledges')
        .select('''
          id,
          campaign_id,
          user_id,
          tier_id,
          amount_krw,
          extra_support_krw,
          is_anonymous,
          support_message,
          status,
          payment_order_id,
          payment_method,
          created_at,
          paid_at,
          funding_reward_tiers!tier_id (title),
          funding_campaigns!campaign_id (title, cover_image_url, status, end_at)
        ''')
        .eq('user_id', _userId!)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Check if user already pledged to a campaign
  Future<bool> hasUserPledged(String campaignId) async {
    if (_userId == null) return false;

    final response = await _client
        .from('funding_pledges')
        .select('id')
        .eq('campaign_id', campaignId)
        .eq('user_id', _userId!)
        .inFilter('status', ['paid', 'pending']);

    return (response as List).isNotEmpty;
  }

  // ============================================
  // Submit Pledge (via atomic RPC)
  // ============================================

  /// Submit a pledge using the atomic DB function
  /// This calls process_funding_pledge_krw() which handles:
  /// - Campaign/tier validation
  /// - Tier quantity decrement
  /// - Pledge record creation
  /// - Campaign stats update
  Future<Map<String, dynamic>> submitPledge({
    required String campaignId,
    required String tierId,
    required int amountKrw,
    int extraSupportKrw = 0,
    String? paymentOrderId,
    String? paymentMethod,
    String? pgTransactionId,
    String? idempotencyKey,
    bool isAnonymous = false,
    String? supportMessage,
  }) async {
    if (_userId == null) throw Exception('Not authenticated');

    final result =
        await _client.rpc('process_funding_pledge_krw', params: {
      'p_campaign_id': campaignId,
      'p_tier_id': tierId,
      'p_user_id': _userId,
      'p_amount_krw': amountKrw,
      'p_extra_support_krw': extraSupportKrw,
      'p_payment_order_id': paymentOrderId,
      'p_payment_method': paymentMethod,
      'p_pg_transaction_id': pgTransactionId,
      'p_idempotency_key':
          idempotencyKey ?? 'pledge_${DateTime.now().millisecondsSinceEpoch}',
      'p_is_anonymous': isAnonymous,
      'p_support_message': supportMessage,
    });

    if (result is Map<String, dynamic>) {
      return result;
    }

    return {'pledge_id': null, 'error': 'Unexpected response'};
  }

  // ============================================
  // FAQ Items
  // ============================================

  /// Get FAQ items for a campaign
  Future<List<Map<String, dynamic>>> getFaqItems(String campaignId) async {
    final response = await _client
        .from('funding_faq_items')
        .select()
        .eq('campaign_id', campaignId)
        .order('display_order', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Create a FAQ item
  Future<Map<String, dynamic>> createFaqItem({
    required String campaignId,
    required String question,
    required String answer,
    int displayOrder = 0,
  }) async {
    final response = await _client
        .from('funding_faq_items')
        .insert({
          'campaign_id': campaignId,
          'question': question,
          'answer': answer,
          'display_order': displayOrder,
        })
        .select()
        .single();

    return response;
  }

  /// Update a FAQ item
  Future<void> updateFaqItem(
    String faqId, {
    String? question,
    String? answer,
    int? displayOrder,
  }) async {
    final updates = <String, dynamic>{};
    if (question != null) updates['question'] = question;
    if (answer != null) updates['answer'] = answer;
    if (displayOrder != null) updates['display_order'] = displayOrder;

    if (updates.isNotEmpty) {
      await _client.from('funding_faq_items').update(updates).eq('id', faqId);
    }
  }

  /// Delete a FAQ item
  Future<void> deleteFaqItem(String faqId) async {
    await _client.from('funding_faq_items').delete().eq('id', faqId);
  }

  // ============================================
  // Campaign Updates (News/Announcements)
  // ============================================

  /// Get updates for a campaign
  Future<List<Map<String, dynamic>>> getCampaignUpdates(
    String campaignId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client
        .from('funding_updates')
        .select()
        .eq('campaign_id', campaignId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Create a campaign update
  Future<Map<String, dynamic>> createCampaignUpdate({
    required String campaignId,
    required String title,
    required String contentMd,
    bool isPublic = true,
  }) async {
    final response = await _client
        .from('funding_updates')
        .insert({
          'campaign_id': campaignId,
          'title': title,
          'content_md': contentMd,
          'is_public': isPublic,
        })
        .select()
        .single();

    return response;
  }

  // ============================================
  // Prelaunch Signups
  // ============================================

  /// Sign up for prelaunch notification
  Future<void> signupForPrelaunch(String campaignId) async {
    if (_userId == null) throw Exception('Not authenticated');

    await _client.from('funding_prelaunch_signups').upsert(
      {
        'campaign_id': campaignId,
        'user_id': _userId,
        'notify_on_launch': true,
      },
      onConflict: 'campaign_id,user_id,email',
    );
  }

  /// Check if user is signed up for prelaunch
  Future<bool> isSignedUpForPrelaunch(String campaignId) async {
    if (_userId == null) return false;

    final response = await _client
        .from('funding_prelaunch_signups')
        .select('id')
        .eq('campaign_id', campaignId)
        .eq('user_id', _userId!);

    return (response as List).isNotEmpty;
  }

  /// Get prelaunch signup count for a campaign
  Future<int> getPrelaunchSignupCount(String campaignId) async {
    final response = await _client
        .from('funding_prelaunch_signups')
        .select('id')
        .eq('campaign_id', campaignId);

    return (response as List).length;
  }

}
