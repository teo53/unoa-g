import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/question_card.dart';
import 'package:uno_a_flutter/data/models/daily_question_set.dart';
import 'package:uno_a_flutter/data/models/poll_draft.dart';

void main() {
  group('QuestionCard', () {
    Map<String, dynamic> createCardJson({
      String id = 'qc-1',
      String cardText = '오늘 기분이 어떤가요?',
      int level = 1,
      String subdeck = 'icebreaker',
      List<String>? tags,
      int voteCount = 0,
      String? answerHint,
    }) {
      return {
        'id': id,
        'card_text': cardText,
        'level': level,
        'subdeck': subdeck,
        if (tags != null) 'tags': tags,
        'vote_count': voteCount,
        if (answerHint != null) 'answer_hint': answerHint,
      };
    }

    group('fromJson / toJson', () {
      test('round-trips all fields correctly', () {
        final json = createCardJson(
          tags: ['일상', '감정'],
          voteCount: 5,
          answerHint: '솔직하게!',
        );
        final card = QuestionCard.fromJson(json);
        final restored = QuestionCard.fromJson(card.toJson());

        expect(restored.id, equals('qc-1'));
        expect(restored.cardText, equals('오늘 기분이 어떤가요?'));
        expect(restored.level, equals(1));
        expect(restored.subdeck, equals('icebreaker'));
        expect(restored.tags, equals(['일상', '감정']));
        expect(restored.voteCount, equals(5));
        expect(restored.answerHint, equals('솔직하게!'));
      });

      test('handles null tags and answerHint', () {
        final json = createCardJson();
        final card = QuestionCard.fromJson(json);
        expect(card.tags, isEmpty);
        expect(card.answerHint, isNull);
      });
    });

    group('levelDisplayName', () {
      test('returns 가벼운 for level 1', () {
        final card = QuestionCard.fromJson(createCardJson(level: 1));
        expect(card.levelDisplayName, equals('가벼운'));
      });

      test('returns 보통 for level 2', () {
        final card = QuestionCard.fromJson(createCardJson(level: 2));
        expect(card.levelDisplayName, equals('보통'));
      });

      test('returns 깊은 for level 3', () {
        final card = QuestionCard.fromJson(createCardJson(level: 3));
        expect(card.levelDisplayName, equals('깊은'));
      });

      test('returns empty string for unknown level', () {
        final card = QuestionCard.fromJson(createCardJson(level: 99));
        expect(card.levelDisplayName, equals(''));
      });
    });

    group('subdeckDisplayName', () {
      test('returns 아이스브레이커 for icebreaker', () {
        final card =
            QuestionCard.fromJson(createCardJson(subdeck: 'icebreaker'));
        expect(card.subdeckDisplayName, equals('아이스브레이커'));
      });

      test('returns 일상 for daily_scene', () {
        final card =
            QuestionCard.fromJson(createCardJson(subdeck: 'daily_scene'));
        expect(card.subdeckDisplayName, equals('일상'));
      });

      test('returns 깊은 대화 for deep_but_safe', () {
        final card =
            QuestionCard.fromJson(createCardJson(subdeck: 'deep_but_safe'));
        expect(card.subdeckDisplayName, equals('깊은 대화'));
      });

      test('returns raw value for unknown subdeck', () {
        final card =
            QuestionCard.fromJson(createCardJson(subdeck: 'custom'));
        expect(card.subdeckDisplayName, equals('custom'));
      });
    });

    group('equality', () {
      test('cards with same id are equal', () {
        final a = QuestionCard.fromJson(createCardJson(id: 'qc-1'));
        final b = QuestionCard.fromJson(
            createCardJson(id: 'qc-1', cardText: '다른 질문'));
        expect(a, equals(b));
      });

      test('cards with different id are not equal', () {
        final a = QuestionCard.fromJson(createCardJson(id: 'qc-1'));
        final b = QuestionCard.fromJson(createCardJson(id: 'qc-2'));
        expect(a, isNot(equals(b)));
      });
    });
  });

  group('DailyQuestionSet', () {
    QuestionCard card0(String id, {int voteCount = 0}) {
      return QuestionCard(
        id: id,
        cardText: 'Question $id',
        level: 1,
        subdeck: 'icebreaker',
        voteCount: voteCount,
      );
    }

    group('fromJson / toJson', () {
      test('round-trips correctly', () {
        final json = {
          'set_id': 'set-1',
          'kst_date': '2024-06-15',
          'deck_code': 'ex_idol',
          'cards': [
            {
              'id': 'qc-1',
              'card_text': 'Q1',
              'level': 1,
              'subdeck': 'icebreaker'
            },
            {
              'id': 'qc-2',
              'card_text': 'Q2',
              'level': 2,
              'subdeck': 'daily_scene'
            },
          ],
          'user_vote': 'qc-1',
          'total_votes': 10,
        };
        final set = DailyQuestionSet.fromJson(json);

        expect(set.setId, equals('set-1'));
        expect(set.deckCode, equals('ex_idol'));
        expect(set.cards.length, equals(2));
        expect(set.userVote, equals('qc-1'));
        expect(set.totalVotes, equals(10));
      });

      test('handles kst_date as String', () {
        final set = DailyQuestionSet.fromJson({
          'set_id': 'set-1',
          'kst_date': '2024-06-15',
          'cards': [],
        });
        expect(set.kstDate.year, equals(2024));
        expect(set.kstDate.month, equals(6));
        expect(set.kstDate.day, equals(15));
      });
    });

    group('hasVoted', () {
      test('returns true when userVote is set', () {
        final set = DailyQuestionSet(
          setId: 'set-1',
          kstDate: DateTime(2024, 6, 15),
          deckCode: 'ex_idol',
          cards: [card0('qc-1')],
          userVote: 'qc-1',
        );
        expect(set.hasVoted, isTrue);
      });

      test('returns false when userVote is null', () {
        final set = DailyQuestionSet(
          setId: 'set-1',
          kstDate: DateTime(2024, 6, 15),
          deckCode: 'ex_idol',
          cards: [card0('qc-1')],
        );
        expect(set.hasVoted, isFalse);
      });
    });

    group('votedCard', () {
      test('returns matching card', () {
        final set = DailyQuestionSet(
          setId: 'set-1',
          kstDate: DateTime(2024, 6, 15),
          deckCode: 'ex_idol',
          cards: [card0('qc-1'), card0('qc-2')],
          userVote: 'qc-2',
        );
        expect(set.votedCard?.id, equals('qc-2'));
      });

      test('returns null when no vote', () {
        final set = DailyQuestionSet(
          setId: 'set-1',
          kstDate: DateTime(2024, 6, 15),
          deckCode: 'ex_idol',
          cards: [card0('qc-1')],
        );
        expect(set.votedCard, isNull);
      });
    });

    group('winningCard', () {
      test('returns card with highest voteCount', () {
        final set = DailyQuestionSet(
          setId: 'set-1',
          kstDate: DateTime(2024, 6, 15),
          deckCode: 'ex_idol',
          cards: [
            card0('qc-1', voteCount: 3),
            card0('qc-2', voteCount: 7),
            card0('qc-3', voteCount: 5),
          ],
          totalVotes: 15,
        );
        expect(set.winningCard?.id, equals('qc-2'));
      });

      test('returns null for empty cards', () {
        final set = DailyQuestionSet(
          setId: 'set-1',
          kstDate: DateTime(2024, 6, 15),
          deckCode: 'ex_idol',
          cards: [],
        );
        expect(set.winningCard, isNull);
      });
    });

    group('updateVoteCounts', () {
      test('updates card vote counts and sets new userVote', () {
        final set = DailyQuestionSet(
          setId: 'set-1',
          kstDate: DateTime(2024, 6, 15),
          deckCode: 'ex_idol',
          cards: [
            card0('qc-1', voteCount: 0),
            card0('qc-2', voteCount: 0),
          ],
        );

        final updated = set.updateVoteCounts(
          {'qc-1': 5, 'qc-2': 3},
          'qc-1',
          8,
        );

        expect(updated.cards[0].voteCount, equals(5));
        expect(updated.cards[1].voteCount, equals(3));
        expect(updated.userVote, equals('qc-1'));
        expect(updated.totalVotes, equals(8));
      });
    });

    group('getVotePercentage', () {
      test('returns correct percentage', () {
        final set = DailyQuestionSet(
          setId: 'set-1',
          kstDate: DateTime(2024, 6, 15),
          deckCode: 'ex_idol',
          cards: [
            card0('qc-1', voteCount: 3),
            card0('qc-2', voteCount: 7),
          ],
          totalVotes: 10,
        );
        expect(set.getVotePercentage('qc-1'), closeTo(30.0, 0.1));
        expect(set.getVotePercentage('qc-2'), closeTo(70.0, 0.1));
      });

      test('returns 0.0 when totalVotes is 0', () {
        final set = DailyQuestionSet(
          setId: 'set-1',
          kstDate: DateTime(2024, 6, 15),
          deckCode: 'ex_idol',
          cards: [card0('qc-1')],
          totalVotes: 0,
        );
        expect(set.getVotePercentage('qc-1'), equals(0.0));
      });
    });
  });

  group('PollDraft', () {
    group('categoryLabel', () {
      test('returns 취향 VS for preference_vs', () {
        final draft = PollDraft.fromJson({
          'id': 'pd-1',
          'channel_id': 'ch-1',
          'category': 'preference_vs',
          'question': 'Q?',
          'options': [
            {'id': 'o1', 'text': 'A'},
            {'id': 'o2', 'text': 'B'},
          ],
          'created_at': '2024-01-01T00:00:00.000Z',
        });
        expect(draft.categoryLabel, equals('취향 VS'));
      });

      test('returns 콘텐츠 선택 for content_choice', () {
        final draft = PollDraft.fromJson({
          'id': 'pd-2',
          'channel_id': 'ch-1',
          'category': 'content_choice',
          'question': 'Q?',
          'options': [
            {'id': 'o1', 'text': 'A'},
          ],
          'created_at': '2024-01-01T00:00:00.000Z',
        });
        expect(draft.categoryLabel, equals('콘텐츠 선택'));
      });

      test('returns raw category for unknown value', () {
        final draft = PollDraft.fromJson({
          'id': 'pd-3',
          'channel_id': 'ch-1',
          'category': 'custom_cat',
          'question': 'Q?',
          'options': [
            {'id': 'o1', 'text': 'A'},
          ],
          'created_at': '2024-01-01T00:00:00.000Z',
        });
        expect(draft.categoryLabel, equals('custom_cat'));
      });
    });
  });
}
