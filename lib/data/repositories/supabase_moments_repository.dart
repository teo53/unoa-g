/// Supabase Moments Repository
/// fan_moments 테이블 실 Supabase 구현
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fan_moment.dart';
import 'moments_repository.dart';

class SupabaseMomentsRepository implements IMomentsRepository {
  final _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;

  @override
  Future<List<FanMoment>> getMoments({
    String? channelId,
    MomentSourceType? sourceType,
    bool? favoritesOnly,
    int limit = 20,
    int offset = 0,
  }) async {
    // Apply all .eq() filters before .order() and .range()
    // because .order()/.range() return PostgrestTransformBuilder
    // which does not support .eq()
    var query = _supabase.from('fan_moments').select().eq('fan_id', _userId);

    if (channelId != null) {
      query = query.eq('channel_id', channelId);
    }

    if (sourceType != null) {
      query = query.eq('source_type', _sourceTypeToDb(sourceType));
    }

    if (favoritesOnly == true) {
      query = query.eq('is_favorite', true);
    }

    final data = await query
        .order('collected_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (data as List)
        .map((e) => FanMoment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FanMoment> getMoment(String momentId) async {
    final data = await _supabase
        .from('fan_moments')
        .select()
        .eq('id', momentId)
        .eq('fan_id', _userId)
        .single();
    return FanMoment.fromJson(data);
  }

  @override
  Future<FanMoment> saveMessageAsMoment({
    required String channelId,
    required String messageId,
    required String content,
    String? mediaUrl,
    String? mediaType,
    String? artistName,
    String? artistAvatarUrl,
  }) async {
    final data = await _supabase
        .from('fan_moments')
        .insert({
          'fan_id': _userId,
          'channel_id': channelId,
          'source_type': 'manual',
          'source_message_id': messageId,
          'title': '저장한 메시지',
          'content': content,
          'media_url': mediaUrl,
          'media_type': mediaType,
          'artist_name': artistName,
          'artist_avatar_url': artistAvatarUrl,
        })
        .select()
        .single();

    return FanMoment.fromJson(data);
  }

  @override
  Future<FanMoment> toggleFavorite(String momentId) async {
    // 현재 상태 조회
    final current = await getMoment(momentId);
    final newFav = !current.isFavorite;

    final data = await _supabase
        .from('fan_moments')
        .update({'is_favorite': newFav})
        .eq('id', momentId)
        .eq('fan_id', _userId)
        .select()
        .single();

    return FanMoment.fromJson(data);
  }

  @override
  Future<void> deleteMoment(String momentId) async {
    await _supabase
        .from('fan_moments')
        .delete()
        .eq('id', momentId)
        .eq('fan_id', _userId);
  }

  @override
  Future<int> getMomentCount({String? channelId}) async {
    var query = _supabase.from('fan_moments').select().eq('fan_id', _userId);

    if (channelId != null) {
      query = query.eq('channel_id', channelId);
    }

    final data = await query;
    return (data as List).length;
  }

  String _sourceTypeToDb(MomentSourceType type) {
    switch (type) {
      case MomentSourceType.privateCard:
        return 'private_card';
      case MomentSourceType.highlight:
        return 'highlight';
      case MomentSourceType.mediaMessage:
        return 'media_message';
      case MomentSourceType.donationReply:
        return 'donation_reply';
      case MomentSourceType.welcome:
        return 'welcome';
      case MomentSourceType.manual:
        return 'manual';
    }
  }
}
