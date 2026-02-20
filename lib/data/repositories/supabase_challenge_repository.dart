/// Supabase Challenge Repository
/// challenges 테이블 실 Supabase 구현
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/challenge.dart';
import 'challenge_repository.dart';

class SupabaseChallengeRepository implements IChallengeRepository {
  final _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;

  @override
  Future<List<Challenge>> getChallenges({
    required String channelId,
    ChallengeStatus? status,
    int limit = 20,
    int offset = 0,
  }) async {
    var query =
        _supabase.from('challenges').select().eq('channel_id', channelId);

    if (status != null) {
      query = query.eq('status', status.name);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List)
        .map((e) => Challenge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Challenge> getChallenge(String challengeId) async {
    final data = await _supabase
        .from('challenges')
        .select()
        .eq('id', challengeId)
        .single();
    return Challenge.fromJson(data);
  }

  @override
  Future<Challenge> createChallenge({
    required String channelId,
    required String title,
    String? description,
    String? rules,
    required ChallengeType challengeType,
    required RewardType rewardType,
    int rewardAmountDt = 0,
    String? rewardDescription,
    int maxSubmissions = 0,
    int maxWinners = 1,
    required DateTime startAt,
    required DateTime endAt,
    DateTime? votingEndAt,
    String? thumbnailUrl,
  }) async {
    final data = await _supabase
        .from('challenges')
        .insert({
          'channel_id': channelId,
          'creator_id': _userId,
          'title': title,
          'description': description,
          'rules': rules,
          'challenge_type': challengeType.name,
          'reward_type': rewardType.name,
          'reward_amount_dt': rewardAmountDt,
          'reward_description': rewardDescription,
          'max_submissions': maxSubmissions,
          'max_winners': maxWinners,
          'start_at': startAt.toIso8601String(),
          'end_at': endAt.toIso8601String(),
          'voting_end_at': votingEndAt?.toIso8601String(),
          'thumbnail_url': thumbnailUrl,
        })
        .select()
        .single();
    return Challenge.fromJson(data);
  }

  @override
  Future<Challenge> updateChallengeStatus(
    String challengeId,
    ChallengeStatus status,
  ) async {
    final data = await _supabase
        .from('challenges')
        .update({
          'status': status.name,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', challengeId)
        .eq('creator_id', _userId)
        .select()
        .single();
    return Challenge.fromJson(data);
  }

  @override
  Future<List<ChallengeSubmission>> getSubmissions({
    required String challengeId,
    SubmissionStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _supabase
        .from('challenge_submissions')
        .select()
        .eq('challenge_id', challengeId);

    if (status != null) {
      query = query.eq('status', status.name);
    }

    final data = await query
        .order('vote_count', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List)
        .map((e) => ChallengeSubmission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ChallengeSubmission> submitEntry({
    required String challengeId,
    String? content,
    String? mediaUrl,
    String? mediaType,
  }) async {
    final data = await _supabase
        .from('challenge_submissions')
        .insert({
          'challenge_id': challengeId,
          'fan_id': _userId,
          'content': content,
          'media_url': mediaUrl,
          'media_type': mediaType,
        })
        .select()
        .single();
    return ChallengeSubmission.fromJson(data);
  }

  @override
  Future<ChallengeSubmission> reviewSubmission({
    required String submissionId,
    required SubmissionStatus status,
    String? comment,
  }) async {
    final data = await _supabase
        .from('challenge_submissions')
        .update({
          'status': status.name,
          'creator_comment': comment,
          'reviewed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', submissionId)
        .select()
        .single();
    return ChallengeSubmission.fromJson(data);
  }

  @override
  Future<void> vote(String submissionId) async {
    await _supabase.from('challenge_votes').insert({
      'submission_id': submissionId,
      'voter_id': _userId,
    });
  }

  @override
  Future<ChallengeSubmission?> getMySubmission(String challengeId) async {
    final data = await _supabase
        .from('challenge_submissions')
        .select()
        .eq('challenge_id', challengeId)
        .eq('fan_id', _userId)
        .maybeSingle();
    if (data == null) return null;
    return ChallengeSubmission.fromJson(data);
  }

  @override
  Future<bool> hasVoted(String submissionId) async {
    final data = await _supabase
        .from('challenge_votes')
        .select('id')
        .eq('submission_id', submissionId)
        .eq('voter_id', _userId)
        .maybeSingle();
    return data != null;
  }
}
