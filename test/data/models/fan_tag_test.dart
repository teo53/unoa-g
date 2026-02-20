import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/fan_tag.dart';

void main() {
  group('FanTag', () {
    final now = DateTime.parse('2025-02-01T12:00:00.000Z');

    final sampleJson = {
      'id': 'tag_1',
      'creator_id': 'creator_1',
      'tag_name': '열정팬',
      'tag_color': '#FF6B6B',
      'description': '적극적인 팬',
      'fan_count': 5,
      'created_at': '2025-02-01T12:00:00.000Z',
    };

    final sampleTag = FanTag(
      id: 'tag_1',
      creatorId: 'creator_1',
      tagName: '열정팬',
      tagColor: '#FF6B6B',
      description: '적극적인 팬',
      fanCount: 5,
      createdAt: now,
    );

    test('fromJson creates correct instance', () {
      final tag = FanTag.fromJson(sampleJson);
      expect(tag.id, 'tag_1');
      expect(tag.creatorId, 'creator_1');
      expect(tag.tagName, '열정팬');
      expect(tag.tagColor, '#FF6B6B');
      expect(tag.description, '적극적인 팬');
      expect(tag.fanCount, 5);
      expect(tag.createdAt, now);
    });

    test('fromJson handles null description', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json.remove('description');
      final tag = FanTag.fromJson(json);
      expect(tag.description, isNull);
    });

    test('fromJson defaults fan_count to 0', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json.remove('fan_count');
      final tag = FanTag.fromJson(json);
      expect(tag.fanCount, 0);
    });

    test('toJson produces correct map', () {
      final json = sampleTag.toJson();
      expect(json['id'], 'tag_1');
      expect(json['creator_id'], 'creator_1');
      expect(json['tag_name'], '열정팬');
      expect(json['tag_color'], '#FF6B6B');
      expect(json['description'], '적극적인 팬');
      expect(json['fan_count'], 5);
      expect(json.containsKey('created_at'), true);
    });

    test('fromJson → toJson roundtrip', () {
      final tag = FanTag.fromJson(sampleJson);
      final json = tag.toJson();
      final restored = FanTag.fromJson(json);
      expect(restored, tag);
    });

    test('copyWith creates modified copy', () {
      final modified = sampleTag.copyWith(tagName: '수정팬', fanCount: 10);
      expect(modified.tagName, '수정팬');
      expect(modified.fanCount, 10);
      expect(modified.id, sampleTag.id);
      expect(modified.tagColor, sampleTag.tagColor);
    });

    test('copyWith with no arguments returns equal object', () {
      final copy = sampleTag.copyWith();
      expect(copy, sampleTag);
    });

    test('equality works correctly', () {
      final other = FanTag(
        id: 'tag_1',
        creatorId: 'creator_1',
        tagName: '열정팬',
        tagColor: '#FF6B6B',
        description: '적극적인 팬',
        fanCount: 5,
        createdAt: now,
      );
      expect(sampleTag, other);
      expect(sampleTag.hashCode, other.hashCode);
    });

    test('inequality when different id', () {
      final other = sampleTag.copyWith(id: 'tag_2');
      expect(sampleTag, isNot(other));
    });

    test('colorPalette has 8 colors', () {
      expect(FanTag.colorPalette.length, 8);
      // All should be valid hex colors
      for (final hex in FanTag.colorPalette) {
        expect(hex.startsWith('#'), true);
        expect(hex.length, 7); // #RRGGBB
      }
    });
  });

  group('FanTagAssignment', () {
    final now = DateTime.parse('2025-02-01T12:00:00.000Z');

    final sampleJson = {
      'fan_id': 'fan_1',
      'tag_id': 'tag_1',
      'assigned_by': 'creator_1',
      'assigned_at': '2025-02-01T12:00:00.000Z',
    };

    test('fromJson creates correct instance', () {
      final assignment = FanTagAssignment.fromJson(sampleJson);
      expect(assignment.fanId, 'fan_1');
      expect(assignment.tagId, 'tag_1');
      expect(assignment.assignedBy, 'creator_1');
      expect(assignment.assignedAt, now);
    });

    test('toJson produces correct map', () {
      final assignment = FanTagAssignment(
        fanId: 'fan_1',
        tagId: 'tag_1',
        assignedBy: 'creator_1',
        assignedAt: now,
      );
      final json = assignment.toJson();
      expect(json['fan_id'], 'fan_1');
      expect(json['tag_id'], 'tag_1');
      expect(json['assigned_by'], 'creator_1');
      expect(json.containsKey('assigned_at'), true);
    });

    test('fromJson → toJson roundtrip', () {
      final assignment = FanTagAssignment.fromJson(sampleJson);
      final json = assignment.toJson();
      final restored = FanTagAssignment.fromJson(json);
      expect(restored.fanId, assignment.fanId);
      expect(restored.tagId, assignment.tagId);
    });
  });
}
