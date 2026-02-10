import 'poll_draft.dart';

/// A poll attached to a chat message.
class PollMessage {
  final String id;
  final String messageId;
  final String question;
  final List<PollOption> options;
  final bool allowMultiple;
  final bool isAnonymous;
  final bool showResultsBeforeEnd;
  final DateTime? endsAt;
  final DateTime createdAt;

  // Vote state (per-user, loaded separately)
  final List<String>? myVoteOptionIds;

  // Aggregated results
  final Map<String, int>? voteCounts;
  final int totalVotes;

  const PollMessage({
    required this.id,
    required this.messageId,
    required this.question,
    required this.options,
    this.allowMultiple = false,
    this.isAnonymous = false,
    this.showResultsBeforeEnd = true,
    this.endsAt,
    required this.createdAt,
    this.myVoteOptionIds,
    this.voteCounts,
    this.totalVotes = 0,
  });

  factory PollMessage.fromJson(Map<String, dynamic> json) {
    return PollMessage(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((o) => PollOption.fromJson(o as Map<String, dynamic>))
          .toList(),
      allowMultiple: json['allow_multiple'] as bool? ?? false,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      showResultsBeforeEnd: json['show_results_before_end'] as bool? ?? true,
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  bool get isEnded => endsAt != null && DateTime.now().isAfter(endsAt!);

  bool get hasVoted => myVoteOptionIds != null && myVoteOptionIds!.isNotEmpty;

  bool get canShowResults => showResultsBeforeEnd || isEnded || hasVoted;

  /// Get vote count for a specific option.
  int voteCountFor(String optionId) => voteCounts?[optionId] ?? 0;

  /// Get percentage for a specific option (0.0-1.0).
  double percentageFor(String optionId) {
    if (totalVotes == 0) return 0.0;
    return voteCountFor(optionId) / totalVotes;
  }

  PollMessage copyWith({
    List<String>? myVoteOptionIds,
    Map<String, int>? voteCounts,
    int? totalVotes,
  }) {
    return PollMessage(
      id: id,
      messageId: messageId,
      question: question,
      options: options,
      allowMultiple: allowMultiple,
      isAnonymous: isAnonymous,
      showResultsBeforeEnd: showResultsBeforeEnd,
      endsAt: endsAt,
      createdAt: createdAt,
      myVoteOptionIds: myVoteOptionIds ?? this.myVoteOptionIds,
      voteCounts: voteCounts ?? this.voteCounts,
      totalVotes: totalVotes ?? this.totalVotes,
    );
  }
}
