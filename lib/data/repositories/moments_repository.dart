/// Moments Repository Interface
/// 팬 모먼트 데이터 접근 추상 인터페이스
library;

import '../models/fan_moment.dart';

abstract class IMomentsRepository {
  /// 팬의 모먼트 목록 조회 (페이지네이션)
  Future<List<FanMoment>> getMoments({
    String? channelId,
    MomentSourceType? sourceType,
    bool? favoritesOnly,
    int limit = 20,
    int offset = 0,
  });

  /// 모먼트 상세 조회
  Future<FanMoment> getMoment(String momentId);

  /// 수동 모먼트 저장 (메시지 → 모먼트)
  Future<FanMoment> saveMessageAsMoment({
    required String channelId,
    required String messageId,
    required String content,
    String? mediaUrl,
    String? mediaType,
    String? artistName,
    String? artistAvatarUrl,
  });

  /// 모먼트 즐겨찾기 토글
  Future<FanMoment> toggleFavorite(String momentId);

  /// 모먼트 삭제
  Future<void> deleteMoment(String momentId);

  /// 모먼트 총 개수
  Future<int> getMomentCount({String? channelId});
}
