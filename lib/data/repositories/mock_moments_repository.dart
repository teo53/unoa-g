/// Mock Moments Repository
/// 데모 모드용 모먼트 목업 데이터
library;

import 'package:uuid/uuid.dart';
import '../../core/config/demo_config.dart';
import '../models/fan_moment.dart';
import 'moments_repository.dart';

class MockMomentsRepository implements IMomentsRepository {
  final _uuid = const Uuid();
  late final List<FanMoment> _moments;

  MockMomentsRepository() {
    _moments = _generateMockMoments();
  }

  List<FanMoment> _generateMockMoments() {
    final now = DateTime.now();
    return [
      FanMoment(
        id: _uuid.v4(),
        fanId: DemoConfig.demoFanId,
        channelId: 'channel_demo_001',
        sourceType: MomentSourceType.privateCard,
        sourceMessageId: 'msg_pc_001',
        title: '프라이빗 카드',
        content: '항상 응원해줘서 고마워요 💕 앞으로도 함께해요!',
        mediaUrl: DemoConfig.avatarUrl('card1', size: 400),
        mediaType: 'image',
        thumbnailUrl: DemoConfig.avatarUrl('card1', size: 200),
        artistName: DemoConfig.demoCreatorName,
        artistAvatarUrl: DemoConfig.avatarUrl('vtuber1'),
        isFavorite: true,
        createdAt: now.subtract(const Duration(days: 3)),
        collectedAt: now.subtract(const Duration(days: 3)),
      ),
      FanMoment(
        id: _uuid.v4(),
        fanId: DemoConfig.demoFanId,
        channelId: 'channel_demo_001',
        sourceType: MomentSourceType.highlight,
        sourceMessageId: 'msg_hl_001',
        title: '하이라이트된 메시지',
        content: '오늘 라이브 너무 좋았어요! 최고의 무대였습니다 🎵',
        artistName: DemoConfig.demoCreatorName,
        artistAvatarUrl: DemoConfig.avatarUrl('vtuber1'),
        isFavorite: false,
        createdAt: now.subtract(const Duration(days: 5)),
        collectedAt: now.subtract(const Duration(days: 5)),
      ),
      FanMoment(
        id: _uuid.v4(),
        fanId: DemoConfig.demoFanId,
        channelId: 'channel_demo_001',
        sourceType: MomentSourceType.mediaMessage,
        sourceMessageId: 'msg_media_001',
        title: '미디어',
        content: '오늘 연습실 셀카 📸',
        mediaUrl: DemoConfig.avatarUrl('selfie1', size: 400),
        mediaType: 'image',
        thumbnailUrl: DemoConfig.avatarUrl('selfie1', size: 200),
        artistName: DemoConfig.demoCreatorName,
        artistAvatarUrl: DemoConfig.avatarUrl('vtuber1'),
        isFavorite: true,
        createdAt: now.subtract(const Duration(days: 7)),
        collectedAt: now.subtract(const Duration(days: 7)),
      ),
      FanMoment(
        id: _uuid.v4(),
        fanId: DemoConfig.demoFanId,
        channelId: 'channel_demo_001',
        sourceType: MomentSourceType.donationReply,
        sourceMessageId: 'msg_dr_001',
        title: '후원 답장',
        content: '후원 감사합니다! 다음에 이름 불러줄게요 😊',
        artistName: DemoConfig.demoCreatorName,
        artistAvatarUrl: DemoConfig.avatarUrl('vtuber1'),
        isFavorite: false,
        createdAt: now.subtract(const Duration(days: 10)),
        collectedAt: now.subtract(const Duration(days: 10)),
      ),
      FanMoment(
        id: _uuid.v4(),
        fanId: DemoConfig.demoFanId,
        channelId: 'channel_demo_001',
        sourceType: MomentSourceType.welcome,
        sourceMessageId: 'msg_wl_001',
        title: '웰컴 메시지',
        content: '환영해요! 앞으로 재밌는 이야기 많이 할게요 🎉',
        artistName: DemoConfig.demoCreatorName,
        artistAvatarUrl: DemoConfig.avatarUrl('vtuber1'),
        isFavorite: false,
        createdAt: now.subtract(const Duration(days: 30)),
        collectedAt: now.subtract(const Duration(days: 30)),
      ),
      FanMoment(
        id: _uuid.v4(),
        fanId: DemoConfig.demoFanId,
        channelId: 'channel_demo_001',
        sourceType: MomentSourceType.manual,
        sourceMessageId: 'msg_saved_001',
        title: '저장한 메시지',
        content: '여러분 모두 사랑해요! 이번 주말 브이로그 기대해주세요 💖',
        artistName: DemoConfig.demoCreatorName,
        artistAvatarUrl: DemoConfig.avatarUrl('vtuber1'),
        isFavorite: false,
        createdAt: now.subtract(const Duration(days: 14)),
        collectedAt: now.subtract(const Duration(days: 14)),
      ),
    ];
  }

  @override
  Future<List<FanMoment>> getMoments({
    String? channelId,
    MomentSourceType? sourceType,
    bool? favoritesOnly,
    int limit = 20,
    int offset = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    var filtered = List<FanMoment>.from(_moments);

    if (channelId != null) {
      filtered = filtered.where((m) => m.channelId == channelId).toList();
    }
    if (sourceType != null) {
      filtered = filtered.where((m) => m.sourceType == sourceType).toList();
    }
    if (favoritesOnly == true) {
      filtered = filtered.where((m) => m.isFavorite).toList();
    }

    filtered.sort((a, b) => b.collectedAt.compareTo(a.collectedAt));

    final end = (offset + limit).clamp(0, filtered.length);
    if (offset >= filtered.length) return [];
    return filtered.sublist(offset, end);
  }

  @override
  Future<FanMoment> getMoment(String momentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _moments.firstWhere((m) => m.id == momentId);
  }

  @override
  Future<FanMoment> saveMessageAsMoment({
    required String channelId,
    required String messageId,
    required String content,
    String? mediaUrl,
    String? mediaType,
    String? artistName,
    String? artistAvatarUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final moment = FanMoment(
      id: _uuid.v4(),
      fanId: DemoConfig.demoFanId,
      channelId: channelId,
      sourceType: MomentSourceType.manual,
      sourceMessageId: messageId,
      title: '저장한 메시지',
      content: content,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      artistName: artistName,
      artistAvatarUrl: artistAvatarUrl,
      createdAt: DateTime.now(),
      collectedAt: DateTime.now(),
    );

    _moments.insert(0, moment);
    return moment;
  }

  @override
  Future<FanMoment> toggleFavorite(String momentId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _moments.indexWhere((m) => m.id == momentId);
    if (index == -1) throw Exception('Moment not found');

    final updated = _moments[index].copyWith(
      isFavorite: !_moments[index].isFavorite,
    );
    _moments[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteMoment(String momentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _moments.removeWhere((m) => m.id == momentId);
  }

  @override
  Future<int> getMomentCount({String? channelId}) async {
    if (channelId != null) {
      return _moments.where((m) => m.channelId == channelId).length;
    }
    return _moments.length;
  }
}
