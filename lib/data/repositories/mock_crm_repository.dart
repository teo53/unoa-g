import 'package:uuid/uuid.dart';
import '../../core/config/demo_config.dart';
import '../models/fan_note.dart';
import '../models/fan_tag.dart';
import '../models/fan_profile_summary.dart';
import 'crm_repository.dart';

/// Mock implementation of ICrmRepository for demo mode
/// 데모 모드용 CRM 레포지토리 (인메모리)
class MockCrmRepository implements ICrmRepository {
  static const _uuid = Uuid();

  // 인메모리 저장소
  final Map<String, FanNote> _notes = {};
  final Map<String, FanTag> _tags = {};
  final Map<String, Set<String>> _assignments = {}; // fanId → Set<tagId>

  // 목 팬 프로필 데이터 (creator_chat_tab_screen.dart의 fan_1/2/3 매칭)
  static final Map<String, _MockFanData> _fanData = {
    'fan_1': const _MockFanData(
      name: '하늘덕후',
      tier: 'VIP',
      subscribedDays: 245,
      totalDtSpent: 125000,
    ),
    'fan_2': const _MockFanData(
      name: '별빛팬',
      tier: 'STANDARD',
      subscribedDays: 89,
      totalDtSpent: 34500,
    ),
    'fan_3': const _MockFanData(
      name: '달빛소녀',
      tier: 'VIP',
      subscribedDays: 312,
      totalDtSpent: 287000,
    ),
  };

  MockCrmRepository() {
    _initDefaultTags();
  }

  void _initDefaultTags() {
    const creatorId = DemoConfig.demoCreatorId;
    final now = DateTime.now();

    final defaultTags = [
      FanTag(
        id: 'tag_1',
        creatorId: creatorId,
        tagName: '열정팬',
        tagColor: '#FF6B6B',
        description: '적극적으로 활동하는 팬',
        fanCount: 2,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      FanTag(
        id: 'tag_2',
        creatorId: creatorId,
        tagName: '아트팬',
        tagColor: '#7C4DFF',
        description: '팬아트를 자주 공유하는 팬',
        fanCount: 1,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      FanTag(
        id: 'tag_3',
        creatorId: creatorId,
        tagName: '초기멤버',
        tagColor: '#FFC107',
        description: '초기부터 함께한 팬',
        fanCount: 1,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
    ];

    for (final tag in defaultTags) {
      _tags[tag.id] = tag;
    }

    // 기본 태그 할당
    _assignments['fan_1'] = {'tag_1', 'tag_3'};
    _assignments['fan_3'] = {'tag_1', 'tag_2'};

    // 기본 메모
    _notes['${creatorId}_fan_1'] = FanNote(
      id: 'note_1',
      creatorId: creatorId,
      fanId: 'fan_1',
      content: '매번 공연 후기를 상세하게 남겨줌. 생일: 3/15',
      createdAt: now.subtract(const Duration(days: 10)),
      updatedAt: now.subtract(const Duration(days: 2)),
    );
  }

  String _noteKey(String creatorId, String fanId) => '${creatorId}_$fanId';

  // ============================================
  // Fan Profile
  // ============================================

  @override
  Future<FanProfileSummary> getFanProfile(
      String creatorId, String fanId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final data = _fanData[fanId];
    final note = _notes[_noteKey(creatorId, fanId)];
    final assignedTagIds = _assignments[fanId] ?? {};
    final tags = assignedTagIds
        .where((id) => _tags.containsKey(id))
        .map((id) => _tags[id]!)
        .toList();

    return FanProfileSummary(
      fanId: fanId,
      displayName: data?.name ?? '팬',
      avatarUrl: DemoConfig.avatarUrl(fanId),
      tier: data?.tier ?? 'BASIC',
      subscribedDays: data?.subscribedDays ?? 0,
      totalDtSpent: data?.totalDtSpent ?? 0,
      note: note,
      tags: tags,
    );
  }

  // ============================================
  // Notes
  // ============================================

  @override
  Future<FanNote?> getNote(String creatorId, String fanId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _notes[_noteKey(creatorId, fanId)];
  }

  @override
  Future<FanNote> upsertNote(
      String creatorId, String fanId, String content) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final key = _noteKey(creatorId, fanId);
    final existing = _notes[key];
    final now = DateTime.now();

    final note = FanNote(
      id: existing?.id ?? _uuid.v4(),
      creatorId: creatorId,
      fanId: fanId,
      content: content,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    _notes[key] = note;
    return note;
  }

  // ============================================
  // Tags
  // ============================================

  @override
  Future<List<FanTag>> getCreatorTags(String creatorId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _tags.values.where((tag) => tag.creatorId == creatorId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<FanTag> createTag(String creatorId, String name, String color) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final tag = FanTag(
      id: _uuid.v4(),
      creatorId: creatorId,
      tagName: name,
      tagColor: color,
      fanCount: 0,
      createdAt: DateTime.now(),
    );

    _tags[tag.id] = tag;
    return tag;
  }

  @override
  Future<void> deleteTag(String tagId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _tags.remove(tagId);
    // 모든 할당도 제거
    for (final entry in _assignments.entries) {
      entry.value.remove(tagId);
    }
  }

  @override
  Future<void> assignTag(String fanId, String tagId, String assignedBy) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _assignments.putIfAbsent(fanId, () => {});
    _assignments[fanId]!.add(tagId);

    // fan_count 업데이트
    final tag = _tags[tagId];
    if (tag != null) {
      _tags[tagId] = tag.copyWith(fanCount: tag.fanCount + 1);
    }
  }

  @override
  Future<void> removeTagAssignment(String fanId, String tagId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _assignments[fanId]?.remove(tagId);

    // fan_count 업데이트
    final tag = _tags[tagId];
    if (tag != null && tag.fanCount > 0) {
      _tags[tagId] = tag.copyWith(fanCount: tag.fanCount - 1);
    }
  }

  @override
  Future<List<FanTag>> getFanTags(String creatorId, String fanId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final assignedTagIds = _assignments[fanId] ?? {};
    return assignedTagIds
        .where((id) => _tags.containsKey(id))
        .map((id) => _tags[id]!)
        .where((tag) => tag.creatorId == creatorId)
        .toList();
  }
}

class _MockFanData {
  final String name;
  final String tier;
  final int subscribedDays;
  final int totalDtSpent;

  const _MockFanData({
    required this.name,
    required this.tier,
    required this.subscribedDays,
    required this.totalDtSpent,
  });
}
