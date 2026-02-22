import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/app_logger.dart';
import '../data/models/creator_content.dart';
import 'auth_provider.dart';
import 'repository_providers.dart';

/// 크리에이터 콘텐츠 상태 (드롭, 이벤트, 직캠, 하이라이트, 소셜링크)
class CreatorContentState {
  final List<CreatorDrop> drops;
  final List<CreatorEvent> events;
  final List<CreatorFancam> fancams;
  final List<CreatorHighlight> highlights;
  final SocialLinks socialLinks;
  final bool isLoading;
  final bool hasChanges;

  const CreatorContentState({
    this.drops = const [],
    this.events = const [],
    this.fancams = const [],
    this.highlights = const [],
    this.socialLinks = const SocialLinks(),
    this.isLoading = false,
    this.hasChanges = false,
  });

  CreatorContentState copyWith({
    List<CreatorDrop>? drops,
    List<CreatorEvent>? events,
    List<CreatorFancam>? fancams,
    List<CreatorHighlight>? highlights,
    SocialLinks? socialLinks,
    bool? isLoading,
    bool? hasChanges,
  }) {
    return CreatorContentState(
      drops: drops ?? this.drops,
      events: events ?? this.events,
      fancams: fancams ?? this.fancams,
      highlights: highlights ?? this.highlights,
      socialLinks: socialLinks ?? this.socialLinks,
      isLoading: isLoading ?? this.isLoading,
      hasChanges: hasChanges ?? this.hasChanges,
    );
  }
}

/// 크리에이터 콘텐츠 관리 Notifier
class CreatorContentNotifier extends StateNotifier<CreatorContentState> {
  final Ref _ref;

  CreatorContentNotifier(this._ref) : super(const CreatorContentState()) {
    loadContent();
  }

  /// 콘텐츠 로드 (현재 목 데이터, 추후 Supabase 연동)
  void loadContent() {
    state = state.copyWith(isLoading: true);

    // Mock 데이터
    final drops = [
      const CreatorDrop(
        id: '1',
        name: '시즌 포토카드 세트',
        priceKrw: 15000,
        isNew: true,
      ),
      const CreatorDrop(
        id: '2',
        name: '한정판 굿즈 박스',
        priceKrw: 45000,
        isSoldOut: true,
      ),
    ];

    final events = [
      CreatorEvent(
        id: '1',
        title: '팬미팅 2024',
        location: '서울 올림픽공원',
        date: DateTime(2024, 6, 15),
        isOffline: true,
      ),
    ];

    final fancams = [
      const CreatorFancam(
        id: '1',
        videoId: 'dQw4w9WgXcQ',
        title: '직캠 - 신곡 무대',
        viewCount: 125000,
        isPinned: true,
      ),
    ];

    const highlights = [
      CreatorHighlight(
        id: '1',
        label: "Today's OOTD",
        icon: Icons.checkroom,
        hasRing: true,
      ),
      CreatorHighlight(
        id: '2',
        label: 'Rehearsal',
        icon: Icons.music_note,
      ),
      CreatorHighlight(
        id: '3',
        label: 'Q&A',
        icon: Icons.camera_alt,
      ),
      CreatorHighlight(
        id: '4',
        label: 'V-log',
        icon: Icons.videocam,
      ),
    ];

    const socialLinks = SocialLinks(
      instagram: 'https://instagram.com/starlight_official',
      youtube: 'https://youtube.com/@starlight_music',
      tiktok: 'https://tiktok.com/@starlight_dance',
      twitter: 'https://twitter.com/starlight_twt',
    );

    state = CreatorContentState(
      drops: drops,
      events: events,
      fancams: fancams,
      highlights: highlights,
      socialLinks: socialLinks,
      isLoading: false,
      hasChanges: false,
    );
  }

  // ===== Drops CRUD =====

  void addDrop(CreatorDrop drop) {
    state = state.copyWith(
      drops: [...state.drops, drop],
      hasChanges: true,
    );
  }

  void updateDrop(CreatorDrop drop) {
    final updated = state.drops.map((d) => d.id == drop.id ? drop : d).toList();
    state = state.copyWith(drops: updated, hasChanges: true);
  }

  void deleteDrop(String id) {
    state = state.copyWith(
      drops: state.drops.where((d) => d.id != id).toList(),
      hasChanges: true,
    );
  }

  // ===== Events CRUD =====

  void addEvent(CreatorEvent event) {
    state = state.copyWith(
      events: [...state.events, event],
      hasChanges: true,
    );
  }

  void updateEvent(CreatorEvent event) {
    final updated =
        state.events.map((e) => e.id == event.id ? event : e).toList();
    state = state.copyWith(events: updated, hasChanges: true);
  }

  void deleteEvent(String id) {
    state = state.copyWith(
      events: state.events.where((e) => e.id != id).toList(),
      hasChanges: true,
    );
  }

  // ===== Fancams CRUD =====

  void addFancam(CreatorFancam fancam) {
    state = state.copyWith(
      fancams: [...state.fancams, fancam],
      hasChanges: true,
    );
  }

  void updateFancam(CreatorFancam fancam) {
    final updated =
        state.fancams.map((f) => f.id == fancam.id ? fancam : f).toList();
    state = state.copyWith(fancams: updated, hasChanges: true);
  }

  void deleteFancam(String id) {
    state = state.copyWith(
      fancams: state.fancams.where((f) => f.id != id).toList(),
      hasChanges: true,
    );
  }

  void toggleFancamPin(String id) {
    final updated = state.fancams.map((f) {
      if (f.id == id) return f.copyWith(isPinned: !f.isPinned);
      return f;
    }).toList();
    state = state.copyWith(fancams: updated, hasChanges: true);
  }

  // ===== Highlights CRUD =====

  void addHighlight(CreatorHighlight highlight) {
    state = state.copyWith(
      highlights: [...state.highlights, highlight],
      hasChanges: true,
    );
  }

  void updateHighlight(CreatorHighlight highlight) {
    final updated = state.highlights
        .map((h) => h.id == highlight.id ? highlight : h)
        .toList();
    state = state.copyWith(highlights: updated, hasChanges: true);
  }

  void deleteHighlight(String id) {
    state = state.copyWith(
      highlights: state.highlights.where((h) => h.id != id).toList(),
      hasChanges: true,
    );
  }

  void toggleHighlightRing(String id) {
    final updated = state.highlights.map((h) {
      if (h.id == id) return h.copyWith(hasRing: !h.hasRing);
      return h;
    }).toList();
    state = state.copyWith(highlights: updated, hasChanges: true);
  }

  // ===== Social Links =====

  void updateSocialLinks(SocialLinks links) {
    state = state.copyWith(socialLinks: links, hasChanges: true);
  }

  /// 변경사항 저장
  Future<void> saveAll() async {
    final authState = _ref.read(authProvider);
    final isDemoMode = authState is AuthDemoMode;

    if (isDemoMode) {
      // 데모 모드: 저장 시뮬레이션
      await Future.delayed(const Duration(milliseconds: 500));
      AppLogger.debug('Demo: Content saved locally', tag: 'CreatorContent');
    } else {
      try {
        final repo = _ref.read(creatorChatRepositoryProvider);

        // 소셜 링크 저장
        await repo.saveSocialLinks({
          'instagram': state.socialLinks.instagram,
          'youtube': state.socialLinks.youtube,
          'tiktok': state.socialLinks.tiktok,
          'twitter': state.socialLinks.twitter,
        });

        // 드롭 저장 — channelId is empty string since no channel scoping needed here
        await repo.saveCreatorDrops(
          state.drops
              .map((d) => {
                    'id': d.id,
                    'name': d.name,
                    'price_krw': d.priceKrw,
                    'is_new': d.isNew,
                    'is_sold_out': d.isSoldOut,
                  })
              .toList(),
          '',
        );

        // 이벤트 저장
        await repo.saveCreatorEvents(
          state.events
              .map((e) => {
                    'id': e.id,
                    'title': e.title,
                    'location': e.location,
                    'date': e.date.toIso8601String(),
                    'is_offline': e.isOffline,
                  })
              .toList(),
          '',
        );
      } catch (e) {
        AppLogger.error(e,
            tag: 'CreatorContent', message: 'Content save failed');
        rethrow;
      }
    }

    state = state.copyWith(hasChanges: false);
  }
}

/// Provider
final creatorContentProvider =
    StateNotifierProvider<CreatorContentNotifier, CreatorContentState>((ref) {
  return CreatorContentNotifier(ref);
});
