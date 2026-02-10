/// AI-generated poll draft candidate.
class PollDraft {
  final String id;
  final String channelId;
  final String category;
  final String question;
  final List<PollOption> options;
  final String status; // suggested, selected, sent, expired, rejected
  final DateTime createdAt;

  const PollDraft({
    required this.id,
    required this.channelId,
    required this.category,
    required this.question,
    required this.options,
    this.status = 'suggested',
    required this.createdAt,
  });

  factory PollDraft.fromJson(Map<String, dynamic> json) {
    return PollDraft(
      id: json['id'] as String,
      channelId: json['channel_id'] as String? ?? '',
      category: json['category'] as String,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((o) => PollOption.fromJson(o as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String? ?? 'suggested',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'channel_id': channelId,
        'category': category,
        'question': question,
        'options': options.map((o) => o.toJson()).toList(),
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  /// Korean label for the category.
  String get categoryLabel {
    switch (category) {
      case 'preference_vs':
        return '취향 VS';
      case 'content_choice':
        return '콘텐츠 선택';
      case 'light_tmi':
        return '가벼운 TMI';
      case 'schedule_choice':
        return '일정 선택';
      case 'mini_mission':
        return '미니 미션';
      default:
        return category;
    }
  }
}

/// A single poll option.
class PollOption {
  final String id;
  final String text;

  const PollOption({required this.id, required this.text});

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] as String,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'text': text};
}
