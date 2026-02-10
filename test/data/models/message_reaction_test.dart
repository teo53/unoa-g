import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/message_reaction.dart';

void main() {
  group('MessageReaction', () {
    Map<String, dynamic> createReactionJson({
      String id = 'reaction-1',
      String messageId = 'msg-1',
      String userId = 'user-1',
      String? reactionType,
      String createdAt = '2024-01-15T10:30:00.000Z',
    }) {
      return {
        'id': id,
        'message_id': messageId,
        'user_id': userId,
        if (reactionType != null) 'reaction_type': reactionType,
        'created_at': createdAt,
      };
    }

    group('fromJson / toJson', () {
      test('round-trips all fields correctly', () {
        final json = createReactionJson(reactionType: 'heart');
        final reaction = MessageReaction.fromJson(json);
        final restored = MessageReaction.fromJson(reaction.toJson());

        expect(restored.id, equals('reaction-1'));
        expect(restored.messageId, equals('msg-1'));
        expect(restored.userId, equals('user-1'));
        expect(restored.reactionType, equals('heart'));
        expect(restored.createdAt.year, equals(2024));
      });

      test('defaults reactionType to heart when absent', () {
        final json = createReactionJson();
        final reaction = MessageReaction.fromJson(json);
        expect(reaction.reactionType, equals('heart'));
      });
    });

    group('copyWith', () {
      test('preserves unchanged values', () {
        final original = MessageReaction.fromJson(
          createReactionJson(reactionType: 'heart'),
        );
        final copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.messageId, equals(original.messageId));
        expect(copy.reactionType, equals(original.reactionType));
      });

      test('can update reactionType', () {
        final original = MessageReaction.fromJson(
          createReactionJson(reactionType: 'heart'),
        );
        final updated = original.copyWith(reactionType: 'fire');
        expect(updated.reactionType, equals('fire'));
        expect(updated.id, equals(original.id));
      });
    });

    group('equality', () {
      test('reactions with same fields are equal', () {
        final a = MessageReaction.fromJson(
          createReactionJson(reactionType: 'heart'),
        );
        final b = MessageReaction.fromJson(
          createReactionJson(reactionType: 'heart'),
        );
        expect(a, equals(b));
      });

      test('reactions with different ids are not equal', () {
        final a = MessageReaction.fromJson(
          createReactionJson(id: 'r-1', reactionType: 'heart'),
        );
        final b = MessageReaction.fromJson(
          createReactionJson(id: 'r-2', reactionType: 'heart'),
        );
        expect(a, isNot(equals(b)));
      });

      test('identical instances are equal', () {
        final reaction = MessageReaction.fromJson(
          createReactionJson(reactionType: 'heart'),
        );
        expect(identical(reaction, reaction), isTrue);
      });
    });

    group('hashCode', () {
      test('equal reactions produce same hashCode', () {
        final a = MessageReaction.fromJson(
          createReactionJson(reactionType: 'heart'),
        );
        final b = MessageReaction.fromJson(
          createReactionJson(reactionType: 'heart'),
        );
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('toString', () {
      test('includes key fields', () {
        final reaction = MessageReaction.fromJson(
          createReactionJson(reactionType: 'heart'),
        );
        final str = reaction.toString();
        expect(str, contains('reaction-1'));
        expect(str, contains('msg-1'));
        expect(str, contains('heart'));
      });
    });
  });

  group('ReactionInfo', () {
    group('toggle', () {
      test('toggling from not-reacted increments count', () {
        const info = ReactionInfo(count: 5, hasReacted: false);
        final toggled = info.toggle();
        expect(toggled.count, equals(6));
        expect(toggled.hasReacted, isTrue);
      });

      test('toggling from reacted decrements count', () {
        const info = ReactionInfo(count: 5, hasReacted: true);
        final toggled = info.toggle();
        expect(toggled.count, equals(4));
        expect(toggled.hasReacted, isFalse);
      });
    });

    group('empty', () {
      test('has count 0 and hasReacted false', () {
        expect(ReactionInfo.empty.count, equals(0));
        expect(ReactionInfo.empty.hasReacted, isFalse);
      });
    });

    group('fromJson', () {
      test('defaults to 0 count and false hasReacted when null', () {
        final info = ReactionInfo.fromJson({});
        expect(info.count, equals(0));
        expect(info.hasReacted, isFalse);
      });

      test('parses provided values', () {
        final info = ReactionInfo.fromJson({
          'reaction_count': 10,
          'has_reacted': true,
        });
        expect(info.count, equals(10));
        expect(info.hasReacted, isTrue);
      });
    });

    group('copyWith', () {
      test('can update count independently', () {
        const original = ReactionInfo(count: 5, hasReacted: true);
        final updated = original.copyWith(count: 10);
        expect(updated.count, equals(10));
        expect(updated.hasReacted, isTrue);
      });
    });
  });
}
