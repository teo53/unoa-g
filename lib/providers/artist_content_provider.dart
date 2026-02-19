import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/creator_content.dart';
import '../core/config/demo_config.dart';
import 'auth_provider.dart';

/// Data class for artist's public content
class ArtistContent {
  final List<CreatorDrop> drops;
  final List<CreatorEvent> events;
  final List<CreatorFancam> fancams;

  const ArtistContent({
    this.drops = const [],
    this.events = const [],
    this.fancams = const [],
  });
}

/// Provider to fetch artist's public content (drops, events, fancams)
final artistContentProvider =
    FutureProvider.family<ArtistContent, String>((ref, artistId) async {
  final isDemoMode = ref.read(isDemoModeProvider);

  if (isDemoMode) {
    return _getDemoContent(artistId);
  }

  // TODO: Fetch from Supabase creator_drops, creator_events, creator_fancams
  // For now, return demo data
  return _getDemoContent(artistId);
});

ArtistContent _getDemoContent(String artistId) {
  return ArtistContent(
    drops: [
      CreatorDrop(
        id: 'drop_1',
        name: '1st Anniversary T-shirt',
        description: '데뷔 1주년 기념 한정 티셔츠',
        imageUrl: DemoConfig.avatarUrl('tshirt1'),
        priceKrw: 35000,
        isSoldOut: true,
        releaseDate: DateTime(2025, 12, 1),
      ),
      CreatorDrop(
        id: 'drop_2',
        name: 'Winter Photo Set A',
        description: '겨울 시즌 포토 세트',
        imageUrl: DemoConfig.avatarUrl('photo_set'),
        priceKrw: 12000,
        isNew: true,
        releaseDate: DateTime(2026, 1, 15),
      ),
      CreatorDrop(
        id: 'drop_3',
        name: 'Gold Member Kit',
        description: 'VIP 골드 멤버 키트',
        imageUrl: DemoConfig.avatarUrl('gold_kit'),
        priceKrw: 5000,
      ),
    ],
    events: [
      CreatorEvent(
        id: 'event_1',
        title: 'Starlight Christmas Live',
        location: '홍대 롤링홀',
        date: DateTime(2026, 3, 24),
        isOffline: true,
        description: '크리스마스 특별 라이브 공연',
      ),
      CreatorEvent(
        id: 'event_2',
        title: 'Online Fan Meeting',
        location: 'ZOOM',
        date: DateTime(2026, 4, 5),
        isOffline: false,
        description: '온라인 팬미팅',
      ),
    ],
    fancams: [
      const CreatorFancam(
        id: 'fancam_1',
        videoId: 'dQw4w9WgXcQ',
        title: '직캠) 하늘달 - Starlight Dance Practice',
        viewCount: 125000,
        isPinned: true,
      ),
      const CreatorFancam(
        id: 'fancam_2',
        videoId: 'jNQXAC9IVRw',
        title: '직캠) 하늘달 콘서트 하이라이트',
        viewCount: 89000,
      ),
    ],
  );
}
