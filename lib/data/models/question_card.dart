/// Question Card model for UNO A
///
/// Represents a pre-generated question card from the question bank.
/// Cards are organized by deck, subdeck, and level.
class QuestionCard {
  /// Unique identifier
  final String id;

  /// Question text to display
  final String cardText;

  /// Difficulty/intimacy level (1: light, 2: medium, 3: deep)
  final int level;

  /// Subdeck category (icebreaker, daily_scene, behind_story, roleplay_flavor, deep_but_safe)
  final String subdeck;

  /// Tags for categorization
  final List<String> tags;

  /// Vote count for this card in the current set
  final int voteCount;

  /// Optional answer hint for the artist
  final String? answerHint;

  const QuestionCard({
    required this.id,
    required this.cardText,
    required this.level,
    required this.subdeck,
    this.tags = const [],
    this.voteCount = 0,
    this.answerHint,
  });

  /// Create from JSON (Supabase response)
  factory QuestionCard.fromJson(Map<String, dynamic> json) {
    return QuestionCard(
      id: json['id'] as String,
      cardText: json['card_text'] as String,
      level: json['level'] as int,
      subdeck: json['subdeck'] as String,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      voteCount: json['vote_count'] as int? ?? 0,
      answerHint: json['answer_hint'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'card_text': cardText,
      'level': level,
      'subdeck': subdeck,
      'tags': tags,
      'vote_count': voteCount,
      if (answerHint != null) 'answer_hint': answerHint,
    };
  }

  /// Copy with modified fields
  QuestionCard copyWith({
    String? id,
    String? cardText,
    int? level,
    String? subdeck,
    List<String>? tags,
    int? voteCount,
    String? answerHint,
  }) {
    return QuestionCard(
      id: id ?? this.id,
      cardText: cardText ?? this.cardText,
      level: level ?? this.level,
      subdeck: subdeck ?? this.subdeck,
      tags: tags ?? this.tags,
      voteCount: voteCount ?? this.voteCount,
      answerHint: answerHint ?? this.answerHint,
    );
  }

  /// Get level display name in Korean
  String get levelDisplayName {
    switch (level) {
      case 1:
        return '가벼운';
      case 2:
        return '보통';
      case 3:
        return '깊은';
      default:
        return '';
    }
  }

  /// Get subdeck display name in Korean
  String get subdeckDisplayName {
    switch (subdeck) {
      case 'icebreaker':
        return '아이스브레이커';
      case 'daily_scene':
        return '일상';
      case 'behind_story':
        return '비하인드';
      case 'roleplay_flavor':
        return '롤플레이';
      case 'deep_but_safe':
        return '깊은 대화';
      default:
        return subdeck;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionCard &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'QuestionCard(id: $id, level: $level, subdeck: $subdeck, text: ${cardText.substring(0, cardText.length > 20 ? 20 : cardText.length)}...)';
}
