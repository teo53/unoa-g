import 'question_card.dart';

/// Daily Question Set model for UNO A
///
/// Represents a set of 3 question cards shown to fans each day.
/// Fans can vote for one card per day per channel.
class DailyQuestionSet {
  /// Unique set identifier
  final String setId;

  /// KST date for this set (YYYY-MM-DD)
  final DateTime kstDate;

  /// Deck code used for this set
  final String deckCode;

  /// The 3 question cards for today
  final List<QuestionCard> cards;

  /// Card ID the current user voted for (null if not voted)
  final String? userVote;

  /// Total number of votes across all cards
  final int totalVotes;

  const DailyQuestionSet({
    required this.setId,
    required this.kstDate,
    required this.deckCode,
    required this.cards,
    this.userVote,
    this.totalVotes = 0,
  });

  /// Whether the current user has voted
  bool get hasVoted => userVote != null;

  /// Get the card the user voted for
  QuestionCard? get votedCard {
    if (userVote == null) return null;
    try {
      return cards.firstWhere((c) => c.id == userVote);
    } catch (_) {
      return null;
    }
  }

  /// Get the winning card (most votes)
  QuestionCard? get winningCard {
    if (cards.isEmpty) return null;
    return cards.reduce((a, b) => a.voteCount >= b.voteCount ? a : b);
  }

  /// Get vote percentage for a card
  double getVotePercentage(String cardId) {
    if (totalVotes == 0) return 0.0;
    final card = cards.firstWhere(
      (c) => c.id == cardId,
      orElse: () => cards.first,
    );
    return (card.voteCount / totalVotes) * 100;
  }

  /// Create from JSON (Supabase RPC response)
  factory DailyQuestionSet.fromJson(Map<String, dynamic> json) {
    final cardsJson = json['cards'] as List<dynamic>? ?? [];
    final cards = cardsJson
        .map((c) => QuestionCard.fromJson(c as Map<String, dynamic>))
        .toList();

    // Parse kst_date - can be String or DateTime
    DateTime kstDate;
    final kstDateValue = json['kst_date'];
    if (kstDateValue is DateTime) {
      kstDate = kstDateValue;
    } else if (kstDateValue is String) {
      kstDate = DateTime.parse(kstDateValue);
    } else {
      kstDate = DateTime.now();
    }

    return DailyQuestionSet(
      setId: json['set_id'] as String,
      kstDate: kstDate,
      deckCode: json['deck_code'] as String? ?? 'ex_idol',
      cards: cards,
      userVote: json['user_vote'] as String?,
      totalVotes: json['total_votes'] as int? ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'set_id': setId,
      'kst_date': kstDate.toIso8601String().split('T').first,
      'deck_code': deckCode,
      'cards': cards.map((c) => c.toJson()).toList(),
      'user_vote': userVote,
      'total_votes': totalVotes,
    };
  }

  /// Copy with modified fields
  DailyQuestionSet copyWith({
    String? setId,
    DateTime? kstDate,
    String? deckCode,
    List<QuestionCard>? cards,
    String? userVote,
    int? totalVotes,
  }) {
    return DailyQuestionSet(
      setId: setId ?? this.setId,
      kstDate: kstDate ?? this.kstDate,
      deckCode: deckCode ?? this.deckCode,
      cards: cards ?? this.cards,
      userVote: userVote ?? this.userVote,
      totalVotes: totalVotes ?? this.totalVotes,
    );
  }

  /// Update vote counts from vote response
  DailyQuestionSet updateVoteCounts(
      Map<String, int> voteCounts, String? newUserVote, int newTotalVotes) {
    final updatedCards = cards.map((card) {
      final newCount = voteCounts[card.id] ?? card.voteCount;
      return card.copyWith(voteCount: newCount);
    }).toList();

    return copyWith(
      cards: updatedCards,
      userVote: newUserVote ?? userVote,
      totalVotes: newTotalVotes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyQuestionSet &&
          runtimeType == other.runtimeType &&
          setId == other.setId;

  @override
  int get hashCode => setId.hashCode;

  @override
  String toString() =>
      'DailyQuestionSet(id: $setId, date: ${kstDate.toIso8601String().split('T').first}, cards: ${cards.length}, voted: $hasVoted)';
}

/// Response model for vote action
class VoteResponse {
  final bool success;
  final String? error;
  final String? userVote;
  final Map<String, int> voteCounts;
  final int totalVotes;

  const VoteResponse({
    required this.success,
    this.error,
    this.userVote,
    this.voteCounts = const {},
    this.totalVotes = 0,
  });

  factory VoteResponse.fromJson(Map<String, dynamic> json) {
    final success = json['success'] as bool? ?? false;

    Map<String, int> voteCounts = {};
    if (json['vote_counts'] != null) {
      final counts = json['vote_counts'] as Map<String, dynamic>;
      voteCounts = counts.map((k, v) => MapEntry(k, v as int));
    }

    return VoteResponse(
      success: success,
      error: json['error'] as String?,
      userVote: json['user_vote'] as String?,
      voteCounts: voteCounts,
      totalVotes: json['total_votes'] as int? ?? 0,
    );
  }
}

/// Stats model for creator dashboard (today's question stats)
class TodaysQuestionStats {
  final bool hasSet;
  final String? setId;
  final DateTime? kstDate;
  final String? deckCode;
  final int totalVotes;
  final List<QuestionCardStat> cards;

  const TodaysQuestionStats({
    required this.hasSet,
    this.setId,
    this.kstDate,
    this.deckCode,
    this.totalVotes = 0,
    this.cards = const [],
  });

  factory TodaysQuestionStats.fromJson(Map<String, dynamic> json) {
    if (json['error'] != null) {
      return const TodaysQuestionStats(hasSet: false);
    }

    final hasSet = json['has_set'] as bool? ?? false;
    if (!hasSet) {
      return const TodaysQuestionStats(hasSet: false);
    }

    final cardsJson = json['cards'] as List<dynamic>? ?? [];
    final cards = cardsJson
        .map((c) => QuestionCardStat.fromJson(c as Map<String, dynamic>))
        .toList();

    // Parse kst_date
    DateTime? kstDate;
    final kstDateValue = json['kst_date'];
    if (kstDateValue is DateTime) {
      kstDate = kstDateValue;
    } else if (kstDateValue is String) {
      kstDate = DateTime.parse(kstDateValue);
    }

    return TodaysQuestionStats(
      hasSet: true,
      setId: json['set_id'] as String?,
      kstDate: kstDate,
      deckCode: json['deck_code'] as String?,
      totalVotes: json['total_votes'] as int? ?? 0,
      cards: cards,
    );
  }

  /// Get winning card (most votes)
  QuestionCardStat? get winningCard {
    if (cards.isEmpty) return null;
    return cards.reduce((a, b) => a.voteCount >= b.voteCount ? a : b);
  }
}

/// Question card stat for creator view
class QuestionCardStat {
  final String id;
  final String cardText;
  final int level;
  final String subdeck;
  final int voteCount;
  final bool isAnswered;

  const QuestionCardStat({
    required this.id,
    required this.cardText,
    required this.level,
    required this.subdeck,
    this.voteCount = 0,
    this.isAnswered = false,
  });

  factory QuestionCardStat.fromJson(Map<String, dynamic> json) {
    return QuestionCardStat(
      id: json['id'] as String,
      cardText: json['card_text'] as String,
      level: json['level'] as int,
      subdeck: json['subdeck'] as String,
      voteCount: json['vote_count'] as int? ?? 0,
      isAnswered: json['is_answered'] as bool? ?? false,
    );
  }
}
