/// CRM Repository Interface
/// 크리에이터-팬 관계 관리(메모, 태그) 추상 인터페이스
library;

import '../models/fan_note.dart';
import '../models/fan_tag.dart';
import '../models/fan_profile_summary.dart';

abstract class ICrmRepository {
  /// 팬 프로필 요약 조회 (메모 + 태그 + 구독정보 + DT 사용액)
  Future<FanProfileSummary> getFanProfile(String creatorId, String fanId);

  /// 팬 메모 조회
  Future<FanNote?> getNote(String creatorId, String fanId);

  /// 팬 메모 UPSERT (생성 or 수정)
  Future<FanNote> upsertNote(String creatorId, String fanId, String content);

  /// 크리에이터의 전체 태그 목록 조회
  Future<List<FanTag>> getCreatorTags(String creatorId);

  /// 태그 생성
  Future<FanTag> createTag(String creatorId, String name, String color);

  /// 태그 삭제
  Future<void> deleteTag(String tagId);

  /// 팬에 태그 할당
  Future<void> assignTag(String fanId, String tagId, String assignedBy);

  /// 팬에서 태그 제거
  Future<void> removeTagAssignment(String fanId, String tagId);

  /// 특정 팬에 할당된 태그 목록
  Future<List<FanTag>> getFanTags(String creatorId, String fanId);
}
