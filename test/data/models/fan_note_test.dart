import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/fan_note.dart';

void main() {
  group('FanNote', () {
    final now = DateTime.parse('2025-02-01T12:00:00.000Z');

    final sampleJson = {
      'id': 'note_1',
      'creator_id': 'creator_1',
      'fan_id': 'fan_1',
      'content': '팬 메모 테스트',
      'created_at': '2025-02-01T12:00:00.000Z',
      'updated_at': '2025-02-01T12:00:00.000Z',
    };

    final sampleNote = FanNote(
      id: 'note_1',
      creatorId: 'creator_1',
      fanId: 'fan_1',
      content: '팬 메모 테스트',
      createdAt: now,
      updatedAt: now,
    );

    test('fromJson creates correct instance', () {
      final note = FanNote.fromJson(sampleJson);
      expect(note.id, 'note_1');
      expect(note.creatorId, 'creator_1');
      expect(note.fanId, 'fan_1');
      expect(note.content, '팬 메모 테스트');
      expect(note.createdAt, now);
      expect(note.updatedAt, now);
    });

    test('toJson produces correct map', () {
      final json = sampleNote.toJson();
      expect(json['id'], 'note_1');
      expect(json['creator_id'], 'creator_1');
      expect(json['fan_id'], 'fan_1');
      expect(json['content'], '팬 메모 테스트');
      expect(json.containsKey('created_at'), true);
      expect(json.containsKey('updated_at'), true);
    });

    test('fromJson → toJson roundtrip', () {
      final note = FanNote.fromJson(sampleJson);
      final json = note.toJson();
      final restored = FanNote.fromJson(json);
      expect(restored, note);
    });

    test('copyWith creates modified copy', () {
      final modified = sampleNote.copyWith(content: '수정된 메모');
      expect(modified.content, '수정된 메모');
      expect(modified.id, sampleNote.id);
      expect(modified.creatorId, sampleNote.creatorId);
      expect(modified.fanId, sampleNote.fanId);
    });

    test('copyWith with no arguments returns equal object', () {
      final copy = sampleNote.copyWith();
      expect(copy, sampleNote);
    });

    test('equality works correctly', () {
      final other = FanNote(
        id: 'note_1',
        creatorId: 'creator_1',
        fanId: 'fan_1',
        content: '팬 메모 테스트',
        createdAt: now,
        updatedAt: now,
      );
      expect(sampleNote, other);
      expect(sampleNote.hashCode, other.hashCode);
    });

    test('inequality when different id', () {
      final other = sampleNote.copyWith(id: 'note_2');
      expect(sampleNote, isNot(other));
    });

    test('empty factory creates valid empty note', () {
      final empty = FanNote.empty('c1', 'f1');
      expect(empty.isEmpty, true);
      expect(empty.isNotEmpty, false);
      expect(empty.content, '');
      expect(empty.creatorId, 'c1');
      expect(empty.fanId, 'f1');
    });

    test('isEmpty and isNotEmpty work correctly', () {
      expect(sampleNote.isEmpty, false);
      expect(sampleNote.isNotEmpty, true);

      final emptyContent = sampleNote.copyWith(content: '');
      expect(emptyContent.isEmpty, true);
    });
  });
}
