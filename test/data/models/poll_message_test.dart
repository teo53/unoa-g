import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/poll_message.dart';
import 'package:uno_a_flutter/data/models/poll_draft.dart';

void main() {
  group('PollMessage', () {
    Map<String, dynamic> _createPollJson({
      String id = 'poll-1',
      String messageId = 'msg-1',
      String question = '좋아하는 색은?',
      bool? allowMultiple,
      bool? isAnonymous,
      bool showResultsBeforeEnd = true,
      String? endsAt,
      List<String>? myVoteOptionIds,
      Map<String, int>? voteCounts,
      int totalVotes = 0,
    }) {
      return {
        'id': id,
        'message_id': messageId,
        'question': question,
        'options': [
          {'id': 'opt-1', 'text': '빨강', 'sort_order': 0},
          {'id': 'opt-2', 'text': '파랑', 'sort_order': 1},
        ],
        if (allowMultiple != null) 'allow_multiple': allowMultiple,
        if (isAnonymous != null) 'is_anonymous': isAnonymous,
        'show_results_before_end': showResultsBeforeEnd,
        if (endsAt != null) 'ends_at': endsAt,
        'created_at': '2024-01-15T10:00:00.000Z',
      };
    }

    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = _createPollJson(
          allowMultiple: true,
          isAnonymous: true,
          endsAt: '2025-12-31T23:59:59.000Z',
        );
        final poll = PollMessage.fromJson(json);

        expect(poll.id, equals('poll-1'));
        expect(poll.messageId, equals('msg-1'));
        expect(poll.question, equals('좋아하는 색은?'));
        expect(poll.options.length, equals(2));
        expect(poll.allowMultiple, isTrue);
        expect(poll.isAnonymous, isTrue);
        expect(poll.endsAt, isNotNull);
      });

      test('defaults allowMultiple and isAnonymous to false', () {
        final json = _createPollJson();
        final poll = PollMessage.fromJson(json);

        expect(poll.allowMultiple, isFalse);
        expect(poll.isAnonymous, isFalse);
      });

      test('handles null endsAt', () {
        final json = _createPollJson();
        final poll = PollMessage.fromJson(json);

        expect(poll.endsAt, isNull);
      });
    });

    group('isEnded', () {
      test('returns true when endsAt is in the past', () {
        final json = _createPollJson(
          endsAt: '2020-01-01T00:00:00.000Z',
        );
        final poll = PollMessage.fromJson(json);
        expect(poll.isEnded, isTrue);
      });

      test('returns false when endsAt is in the future', () {
        final json = _createPollJson(
          endsAt: '2099-12-31T23:59:59.000Z',
        );
        final poll = PollMessage.fromJson(json);
        expect(poll.isEnded, isFalse);
      });

      test('returns false when endsAt is null', () {
        final json = _createPollJson();
        final poll = PollMessage.fromJson(json);
        expect(poll.isEnded, isFalse);
      });
    });

    group('hasVoted', () {
      test('returns true when myVoteOptionIds is non-empty', () {
        final poll = PollMessage(
          id: 'p-1',
          messageId: 'msg-1',
          question: '?',
          options: [],
          createdAt: DateTime.now(),
          myVoteOptionIds: ['opt-1'],
        );
        expect(poll.hasVoted, isTrue);
      });

      test('returns false when myVoteOptionIds is null', () {
        final poll = PollMessage(
          id: 'p-1',
          messageId: 'msg-1',
          question: '?',
          options: [],
          createdAt: DateTime.now(),
        );
        expect(poll.hasVoted, isFalse);
      });

      test('returns false when myVoteOptionIds is empty', () {
        final poll = PollMessage(
          id: 'p-1',
          messageId: 'msg-1',
          question: '?',
          options: [],
          createdAt: DateTime.now(),
          myVoteOptionIds: [],
        );
        expect(poll.hasVoted, isFalse);
      });
    });

    group('voteCountFor', () {
      test('returns count for existing option', () {
        final poll = PollMessage(
          id: 'p-1',
          messageId: 'msg-1',
          question: '?',
          options: [],
          createdAt: DateTime.now(),
          voteCounts: {'opt-1': 10, 'opt-2': 5},
          totalVotes: 15,
        );
        expect(poll.voteCountFor('opt-1'), equals(10));
      });

      test('returns 0 for unknown option', () {
        final poll = PollMessage(
          id: 'p-1',
          messageId: 'msg-1',
          question: '?',
          options: [],
          createdAt: DateTime.now(),
          voteCounts: {'opt-1': 10},
          totalVotes: 10,
        );
        expect(poll.voteCountFor('opt-999'), equals(0));
      });
    });

    group('percentageFor', () {
      test('returns correct fraction', () {
        final poll = PollMessage(
          id: 'p-1',
          messageId: 'msg-1',
          question: '?',
          options: [],
          createdAt: DateTime.now(),
          voteCounts: {'opt-1': 3, 'opt-2': 7},
          totalVotes: 10,
        );
        expect(poll.percentageFor('opt-1'), closeTo(0.3, 0.001));
        expect(poll.percentageFor('opt-2'), closeTo(0.7, 0.001));
      });

      test('returns 0.0 when totalVotes is 0', () {
        final poll = PollMessage(
          id: 'p-1',
          messageId: 'msg-1',
          question: '?',
          options: [],
          createdAt: DateTime.now(),
          totalVotes: 0,
        );
        expect(poll.percentageFor('opt-1'), equals(0.0));
      });
    });

    group('copyWith', () {
      test('preserves unchanged values', () {
        final poll = PollMessage(
          id: 'p-1',
          messageId: 'msg-1',
          question: 'Q?',
          options: [],
          createdAt: DateTime(2024, 1, 15),
          totalVotes: 5,
        );
        final copy = poll.copyWith(totalVotes: 10);

        expect(copy.id, equals('p-1'));
        expect(copy.question, equals('Q?'));
        expect(copy.totalVotes, equals(10));
      });
    });
  });
}
