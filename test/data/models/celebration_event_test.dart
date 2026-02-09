import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/celebration_event.dart';
import 'package:uno_a_flutter/data/models/fan_celebration.dart';

void main() {
  group('CelebrationEvent', () {
    Map<String, dynamic> _createEventJson({
      String id = 'event-1',
      String channelId = 'ch-1',
      String fanCelebrationId = 'fc-1',
      String eventType = 'birthday',
      String? status,
      String? messageId,
    }) {
      return {
        'id': id,
        'channel_id': channelId,
        'fan_celebration_id': fanCelebrationId,
        'event_type': eventType,
        'due_date': '2024-03-15',
        if (status != null) 'status': status,
        'payload': {
          'nickname': '하늘덕후',
          'day_count': 100,
          'tier': 'VIP',
        },
        if (messageId != null) 'message_id': messageId,
        'created_at': '2024-03-10T00:00:00.000Z',
      };
    }

    group('fromJson / toJson', () {
      test('round-trips core fields correctly', () {
        final json = _createEventJson(status: 'sent', messageId: 'msg-1');
        final event = CelebrationEvent.fromJson(json);

        expect(event.id, equals('event-1'));
        expect(event.channelId, equals('ch-1'));
        expect(event.eventType, equals('birthday'));
        expect(event.status, equals('sent'));
        expect(event.messageId, equals('msg-1'));
        expect(event.payload.nickname, equals('하늘덕후'));
        expect(event.payload.dayCount, equals(100));
        expect(event.payload.tier, equals('VIP'));
      });

      test('handles inline payload (no nested payload key)', () {
        final json = {
          'id': 'event-2',
          'channel_id': 'ch-1',
          'fan_celebration_id': 'fc-1',
          'event_type': 'milestone_100',
          'due_date': '2024-05-01',
          'nickname': '별빛팬',
          'day_count': 100,
          'tier': 'STANDARD',
          'created_at': '2024-04-25T00:00:00.000Z',
        };
        final event = CelebrationEvent.fromJson(json);
        expect(event.payload.nickname, equals('별빛팬'));
        expect(event.payload.dayCount, equals(100));
      });

      test('defaults status to pending', () {
        final json = _createEventJson();
        final event = CelebrationEvent.fromJson(json);
        expect(event.status, equals('pending'));
      });
    });

    group('isBirthday', () {
      test('returns true for birthday eventType', () {
        final event =
            CelebrationEvent.fromJson(_createEventJson(eventType: 'birthday'));
        expect(event.isBirthday, isTrue);
      });

      test('returns false for milestone', () {
        final event = CelebrationEvent.fromJson(
          _createEventJson(eventType: 'milestone_100'),
        );
        expect(event.isBirthday, isFalse);
      });
    });

    group('isMilestone', () {
      test('returns true for milestone_100', () {
        final event = CelebrationEvent.fromJson(
          _createEventJson(eventType: 'milestone_100'),
        );
        expect(event.isMilestone, isTrue);
      });

      test('returns true for milestone_365', () {
        final event = CelebrationEvent.fromJson(
          _createEventJson(eventType: 'milestone_365'),
        );
        expect(event.isMilestone, isTrue);
      });

      test('returns false for birthday', () {
        final event =
            CelebrationEvent.fromJson(_createEventJson(eventType: 'birthday'));
        expect(event.isMilestone, isFalse);
      });
    });

    group('eventTypeLabel', () {
      test('returns 생일 for birthday', () {
        final event =
            CelebrationEvent.fromJson(_createEventJson(eventType: 'birthday'));
        expect(event.eventTypeLabel, equals('생일'));
      });

      test('returns 100일 for milestone_100', () {
        final event = CelebrationEvent.fromJson(
          _createEventJson(eventType: 'milestone_100'),
        );
        expect(event.eventTypeLabel, equals('100일'));
      });

      test('returns 1주년 for milestone_365', () {
        final event = CelebrationEvent.fromJson(
          _createEventJson(eventType: 'milestone_365'),
        );
        expect(event.eventTypeLabel, equals('1주년'));
      });

      test('returns raw value for unknown type', () {
        final event = CelebrationEvent.fromJson(
          _createEventJson(eventType: 'custom_type'),
        );
        expect(event.eventTypeLabel, equals('custom_type'));
      });
    });

    group('eventTypeEmoji', () {
      test('returns cake for birthday', () {
        final event =
            CelebrationEvent.fromJson(_createEventJson(eventType: 'birthday'));
        expect(event.eventTypeEmoji, equals('🎂'));
      });

      test('returns party for milestone_100', () {
        final event = CelebrationEvent.fromJson(
          _createEventJson(eventType: 'milestone_100'),
        );
        expect(event.eventTypeEmoji, equals('🎊'));
      });

      test('returns default for unknown type', () {
        final event = CelebrationEvent.fromJson(
          _createEventJson(eventType: 'unknown'),
        );
        expect(event.eventTypeEmoji, equals('🎉'));
      });
    });
  });

  group('CelebrationPayload', () {
    group('fromJson', () {
      test('defaults nickname to 팬 when null', () {
        final payload = CelebrationPayload.fromJson({});
        expect(payload.nickname, equals('팬'));
      });

      test('parses all fields', () {
        final payload = CelebrationPayload.fromJson({
          'nickname': '테스트팬',
          'user_id': 'u-1',
          'day_count': 50,
          'tier': 'VIP',
        });
        expect(payload.nickname, equals('테스트팬'));
        expect(payload.userId, equals('u-1'));
        expect(payload.dayCount, equals(50));
        expect(payload.tier, equals('VIP'));
      });
    });
  });

  group('FanCelebration', () {
    Map<String, dynamic> _createFanCelebrationJson({
      String id = 'fc-1',
      String userId = 'user-1',
      String channelId = 'ch-1',
      int? birthMonth,
      int? birthDay,
      bool birthdayVisible = false,
    }) {
      return {
        'id': id,
        'user_id': userId,
        'channel_id': channelId,
        if (birthMonth != null) 'birth_month': birthMonth,
        if (birthDay != null) 'birth_day': birthDay,
        'birthday_visible': birthdayVisible,
        'subscription_started_at': '2024-01-01T00:00:00.000Z',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-15T00:00:00.000Z',
      };
    }

    group('fromJson / toJson', () {
      test('round-trips core fields', () {
        final json = _createFanCelebrationJson(
          birthMonth: 3,
          birthDay: 15,
          birthdayVisible: true,
        );
        final fc = FanCelebration.fromJson(json);

        expect(fc.id, equals('fc-1'));
        expect(fc.userId, equals('user-1'));
        expect(fc.birthMonth, equals(3));
        expect(fc.birthDay, equals(15));
        expect(fc.birthdayVisible, isTrue);
      });
    });

    group('hasBirthday', () {
      test('returns true when both month and day are set', () {
        final fc = FanCelebration.fromJson(
          _createFanCelebrationJson(birthMonth: 7, birthDay: 20),
        );
        expect(fc.hasBirthday, isTrue);
      });

      test('returns false when month is null', () {
        final fc = FanCelebration.fromJson(
          _createFanCelebrationJson(birthDay: 20),
        );
        expect(fc.hasBirthday, isFalse);
      });

      test('returns false when day is null', () {
        final fc = FanCelebration.fromJson(
          _createFanCelebrationJson(birthMonth: 7),
        );
        expect(fc.hasBirthday, isFalse);
      });
    });

    group('birthdayLabel', () {
      test('returns M월 D일 format when birthday is set', () {
        final fc = FanCelebration.fromJson(
          _createFanCelebrationJson(birthMonth: 3, birthDay: 15),
        );
        expect(fc.birthdayLabel, equals('3월 15일'));
      });

      test('returns 미등록 when no birthday', () {
        final fc = FanCelebration.fromJson(
          _createFanCelebrationJson(),
        );
        expect(fc.birthdayLabel, equals('미등록'));
      });
    });

    group('copyWith', () {
      test('can update birthday fields', () {
        final fc = FanCelebration.fromJson(
          _createFanCelebrationJson(),
        );
        final updated = fc.copyWith(birthMonth: 12, birthDay: 25);

        expect(updated.birthMonth, equals(12));
        expect(updated.birthDay, equals(25));
        expect(updated.id, equals(fc.id));
      });
    });
  });
}
