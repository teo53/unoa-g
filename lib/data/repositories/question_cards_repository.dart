import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/daily_question_set.dart';
import '../models/question_card.dart';

/// Repository for Question Cards system
///
/// Handles daily question set operations:
/// - Get or create today's question set for a channel
/// - Vote for a question card
/// - Mark question as answered (creator only)
/// - Get today's question stats (creator only)
abstract class IQuestionCardsRepository {
  /// Get or create today's daily question set for a channel
  Future<DailyQuestionSet> getOrCreateDailySet(String channelId);

  /// Vote for a question card
  Future<VoteResponse> vote(String setId, String cardId);

  /// Mark question as answered (creator only)
  Future<bool> markAnswered({
    required String channelId,
    required String cardId,
    required String messageId,
    String? setId,
  });

  /// Get today's question stats for creator dashboard
  Future<TodaysQuestionStats> getTodaysStats(String channelId);

  /// Get available decks
  Future<List<QuestionDeck>> getDecks();

  /// Update creator's question preferences
  Future<bool> updateCreatorPrefs({
    required List<String> deckCodes,
    required List<int> levelsEnabled,
    required bool enabled,
  });
}

/// Supabase implementation of Question Cards repository
class SupabaseQuestionCardsRepository implements IQuestionCardsRepository {
  final SupabaseClient _client;

  SupabaseQuestionCardsRepository(this._client);

  @override
  Future<DailyQuestionSet> getOrCreateDailySet(String channelId) async {
    try {
      final response = await _client.rpc(
        'get_or_create_daily_question_set',
        params: {'p_channel_id': channelId},
      );

      if (response == null) {
        throw Exception('Failed to get daily question set');
      }

      final data = response as Map<String, dynamic>;

      // Check for error response
      if (data['error'] != null) {
        throw Exception(data['message'] ?? data['error']);
      }

      return DailyQuestionSet.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<VoteResponse> vote(String setId, String cardId) async {
    try {
      final response = await _client.rpc(
        'vote_daily_question',
        params: {
          'p_set_id': setId,
          'p_card_id': cardId,
        },
      );

      if (response == null) {
        return const VoteResponse(success: false, error: 'No response');
      }

      return VoteResponse.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return VoteResponse(success: false, error: e.toString());
    }
  }

  @override
  Future<bool> markAnswered({
    required String channelId,
    required String cardId,
    required String messageId,
    String? setId,
  }) async {
    try {
      final response = await _client.rpc(
        'mark_question_answered',
        params: {
          'p_channel_id': channelId,
          'p_card_id': cardId,
          'p_message_id': messageId,
          if (setId != null) 'p_set_id': setId,
        },
      );

      if (response == null) return false;

      final data = response as Map<String, dynamic>;
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<TodaysQuestionStats> getTodaysStats(String channelId) async {
    try {
      final response = await _client.rpc(
        'get_todays_question_stats',
        params: {'p_channel_id': channelId},
      );

      if (response == null) {
        return const TodaysQuestionStats(hasSet: false);
      }

      return TodaysQuestionStats.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return const TodaysQuestionStats(hasSet: false);
    }
  }

  @override
  Future<List<QuestionDeck>> getDecks() async {
    try {
      final response = await _client
          .from('question_decks')
          .select('id, code, title, description, is_active')
          .eq('is_active', true)
          .order('code');

      return (response as List<dynamic>)
          .map((d) => QuestionDeck.fromJson(d as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> updateCreatorPrefs({
    required List<String> deckCodes,
    required List<int> levelsEnabled,
    required bool enabled,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      await _client.from('creator_question_prefs').upsert({
        'creator_id': userId,
        'deck_codes': deckCodes,
        'levels_enabled': levelsEnabled,
        'enabled': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Mock implementation for demo mode
class MockQuestionCardsRepository implements IQuestionCardsRepository {
  final List<QuestionCard> _mockCards = [
    const QuestionCard(
      id: 'mock_card_1',
      cardText: '오늘 기분을 날씨로 표현하면?',
      level: 1,
      subdeck: 'icebreaker',
      tags: ['기분', '날씨', '가벼운'],
      voteCount: 42,
    ),
    const QuestionCard(
      id: 'mock_card_2',
      cardText: '지금 마시고 싶은 음료 하나만!',
      level: 1,
      subdeck: 'icebreaker',
      tags: ['음료', '취향', '선택'],
      voteCount: 38,
    ),
    const QuestionCard(
      id: 'mock_card_3',
      cardText: '메이드 일을 시작하게 된 계기가 뭐야?',
      level: 2,
      subdeck: 'behind_story',
      tags: ['계기', '시작', '스토리'],
      voteCount: 55,
    ),
  ];

  String? _userVote;

  @override
  Future<DailyQuestionSet> getOrCreateDailySet(String channelId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return DailyQuestionSet(
      setId: 'mock_set_${DateTime.now().toIso8601String().split('T').first}',
      kstDate: DateTime.now(),
      deckCode: 'maid',
      cards: _mockCards,
      userVote: _userVote,
      totalVotes: 135,
    );
  }

  @override
  Future<VoteResponse> vote(String setId, String cardId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_userVote != null) {
      return const VoteResponse(success: false, error: 'already_voted');
    }

    _userVote = cardId;

    return VoteResponse(
      success: true,
      userVote: cardId,
      voteCounts: {
        'mock_card_1': 42,
        'mock_card_2': 38,
        'mock_card_3': 56, // Incremented the voted card
      },
      totalVotes: 136,
    );
  }

  @override
  Future<bool> markAnswered({
    required String channelId,
    required String cardId,
    required String messageId,
    String? setId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  @override
  Future<TodaysQuestionStats> getTodaysStats(String channelId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return TodaysQuestionStats(
      hasSet: true,
      setId: 'mock_set_${DateTime.now().toIso8601String().split('T').first}',
      kstDate: DateTime.now(),
      deckCode: 'maid',
      totalVotes: 135,
      cards: [
        const QuestionCardStat(
          id: 'mock_card_3',
          cardText: '메이드 일을 시작하게 된 계기가 뭐야?',
          level: 2,
          subdeck: 'behind_story',
          voteCount: 55,
          isAnswered: false,
        ),
        const QuestionCardStat(
          id: 'mock_card_1',
          cardText: '오늘 기분을 날씨로 표현하면?',
          level: 1,
          subdeck: 'icebreaker',
          voteCount: 42,
          isAnswered: true,
        ),
        const QuestionCardStat(
          id: 'mock_card_2',
          cardText: '지금 마시고 싶은 음료 하나만!',
          level: 1,
          subdeck: 'icebreaker',
          voteCount: 38,
          isAnswered: false,
        ),
      ],
    );
  }

  @override
  Future<List<QuestionDeck>> getDecks() async {
    await Future.delayed(const Duration(milliseconds: 200));

    return [
      const QuestionDeck(
        id: 'deck_maid',
        code: 'maid',
        title: '메이드',
        description: '메이드 컨셉 크리에이터용 질문 덱',
      ),
      const QuestionDeck(
        id: 'deck_ex_idol',
        code: 'ex_idol',
        title: '전 아이돌',
        description: '전 아이돌/연습생 크리에이터용 질문 덱',
      ),
    ];
  }

  @override
  Future<bool> updateCreatorPrefs({
    required List<String> deckCodes,
    required List<int> levelsEnabled,
    required bool enabled,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }
}

/// Question deck model
class QuestionDeck {
  final String id;
  final String code;
  final String title;
  final String? description;
  final bool isActive;

  const QuestionDeck({
    required this.id,
    required this.code,
    required this.title,
    this.description,
    this.isActive = true,
  });

  factory QuestionDeck.fromJson(Map<String, dynamic> json) {
    return QuestionDeck(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
