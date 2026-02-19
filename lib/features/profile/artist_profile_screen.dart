import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/utils/safe_url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/artist.dart';
import '../../data/models/creator_content.dart';
import '../../providers/discover_provider.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/utils/share_utils.dart';
import 'widgets/artist_profile_feed_widgets.dart';
import 'widgets/artist_profile_fancam_widgets.dart';
import 'widgets/artist_profile_info_widgets.dart';

class ArtistProfileScreen extends ConsumerStatefulWidget {
  final String artistId;

  const ArtistProfileScreen({
    super.key,
    required this.artistId,
  });

  @override
  ConsumerState<ArtistProfileScreen> createState() =>
      _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends ConsumerState<ArtistProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock social links data (실제로는 아티스트 데이터에서 가져와야 함)
  final SocialLinks _socialLinks = const SocialLinks(
    instagram: 'https://instagram.com/starlight_official',
    youtube: 'https://youtube.com/@starlight_music',
    tiktok: 'https://tiktok.com/@starlight_dance',
    twitter: 'https://twitter.com/starlight_twt',
  );

  // Mock theme color (실제로는 아티스트 데이터에서 가져와야 함)
  Color get _artistThemeColor => AppColors.primary500;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _currentTabFeeds {
    final feedsAsync = ref.watch(artistContentFeedsProvider(widget.artistId));
    final feeds = feedsAsync.valueOrNull ?? {};
    switch (_tabController.index) {
      case 0:
        return feeds['highlight'] ?? [];
      case 1:
        return feeds['announcement'] ?? [];
      case 2:
        return feeds['letter'] ?? [];
      default:
        return feeds['highlight'] ?? [];
    }
  }

  Future<void> _openYouTubeVideo(String url) async {
    await SafeUrlLauncher.launch(url, context: context);
  }

  Future<void> _openSocialLink(String url) async {
    await SafeUrlLauncher.launch(url, context: context);
  }

  void _showAllFancams(BuildContext context, List<YouTubeFancam> fancams) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '아티스트 직캠',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  Text(
                    '${fancams.length}개',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Fancam list
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: fancams.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final fancam = fancams[index];
                  return FancamListItem(
                    fancam: fancam,
                    onTap: () {
                      context.pop();
                      _openYouTubeVideo(fancam.videoUrl);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('프로필 공유'),
              onTap: () {
                context.pop();
                final artists = ref.read(trendingArtistsProvider);
                final artist = artists.isNotEmpty
                    ? artists.firstWhere(
                        (a) => a.id == widget.artistId,
                        orElse: () => artists.first,
                      )
                    : null;
                shareArtistProfile(
                  artistId: widget.artistId,
                  artistName: artist?.name ?? '아티스트',
                  context: context,
                  ref: ref,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('알림 설정'),
              onTap: () {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('알림 설정 준비 중')),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.report_outlined, color: AppColors.danger),
              title:
                  const Text('신고하기', style: TextStyle(color: AppColors.danger)),
              onTap: () {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('신고 기능 준비 중')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final artists = ref.watch(trendingArtistsProvider);
    final artist = artists.isNotEmpty
        ? artists.firstWhere(
            (a) => a.id == widget.artistId,
            orElse: () => artists.first,
          )
        : Artist(
            id: widget.artistId,
            name: '아티스트',
            avatarUrl: '',
            followerCount: 0,
          );

    return AppScaffold(
      showStatusBar: true,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Cover Image with Profile Info Overlay
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Cover Image with Primary Gradient
                    Container(
                      height: 280,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary600.withValues(alpha: 0.8),
                            AppColors.primary500,
                          ],
                        ),
                      ),
                      child: artist.avatarUrl.isEmpty
                          ? Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 120,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: artist.avatarUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.primary500,
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 120,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                    ),
                    // Gradient Overlay
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Header Buttons
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('검색 기능 준비 중')),
                                  );
                                },
                                icon: const Icon(
                                  Icons.search,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  _showMoreOptions(context);
                                },
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Name & Group Overlay
                    Positioned(
                      left: 20,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                artist.displayName,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (artist.isVerified)
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: AppColors.verified,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            artist.group != null
                                ? 'Underground Idol Group \'${artist.group}\''
                                : 'Solo Artist',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Rank & Fan Badges
                          Row(
                            children: [
                              ProfileStatBadge(
                                icon: Icons.trending_up,
                                label: '주간랭킹: ${artist.rank}위',
                                change: '+2',
                              ),
                              const SizedBox(width: 12),
                              ProfileStatBadge(
                                icon: Icons.people,
                                label: '팬 ${artist.formattedFollowers}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 0),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.backgroundDark : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Highlights Row
                      SizedBox(
                        height: 90,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: const [
                            ProfileHighlightItem(
                              icon: Icons.checkroom,
                              label: 'Today\'s OOTD',
                              hasRing: true,
                            ),
                            SizedBox(width: 16),
                            ProfileHighlightItem(
                              icon: Icons.music_note,
                              label: 'Rehearsal',
                            ),
                            SizedBox(width: 16),
                            ProfileHighlightItem(
                              icon: Icons.camera_alt,
                              label: 'Q&A',
                            ),
                            SizedBox(width: 16),
                            ProfileHighlightItem(
                              icon: Icons.videocam,
                              label: 'V-log',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Social Links (좌측 정렬)
                      if (_socialLinks.hasAnyLink)
                        SocialLinksSection(
                          socialLinks: _socialLinks,
                          themeColor: _artistThemeColor,
                          onLinkTap: _openSocialLink,
                        ),

                      const SizedBox(height: 20),

                      // Action Buttons Grid
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ProfileActionButton(
                              icon: Icons.chat_bubble_outline,
                              label: 'DM',
                              themeColor: _artistThemeColor,
                              onTap: () =>
                                  context.push('/chat/${widget.artistId}'),
                            ),
                            ProfileActionButton(
                              icon: Icons.card_giftcard,
                              label: '드롭',
                              themeColor: _artistThemeColor,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('드롭 스토어 준비 중')),
                                );
                              },
                            ),
                            ProfileActionButton(
                              icon: Icons.groups,
                              label: '이벤트',
                              isPrimary: true,
                              themeColor: _artistThemeColor,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('이벤트 페이지 준비 중')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Supporter Ranking Banner
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : Colors.grey[200]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.emoji_events_outlined,
                                  color: AppColors.primary600,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '내 서포터 랭킹: 12위',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.textMainDark
                                            : AppColors.textMainLight,
                                      ),
                                    ),
                                    Text(
                                      'Gold Member • 상위 5%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textSubDark
                                            : AppColors.textSubLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: true,
                                onChanged: (v) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('랭킹 알림 설정 준비 중')),
                                  );
                                },
                                activeThumbColor: AppColors.primary500,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // YouTube Fancam Section
                      if (artist.fancams.isNotEmpty) ...[
                        ProfileSectionHeader(
                          title: '아티스트 직캠',
                          trailing: artist.fancams.length > 1 ? '전체보기' : null,
                          onTrailingTap: artist.fancams.length > 1
                              ? () {
                                  _showAllFancams(context, artist.fancams);
                                }
                              : null,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 180,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: artist.fancams.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final fancam = artist.fancams[index];
                              return FancamCard(
                                fancam: fancam,
                                onTap: () => _openYouTubeVideo(fancam.videoUrl),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Drops Section
                      ProfileSectionHeader(
                        title: '최신 드롭 (Drops)',
                        trailing: '전체보기',
                        onTrailingTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('드롭 전체보기 준비 중')),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: const [
                            ProfileDropItem(
                              name: '1st Anniversary T-shirt',
                              price: '35,000 KRW',
                              isSoldOut: true,
                            ),
                            SizedBox(width: 12),
                            ProfileDropItem(
                              name: 'Winter Photo Set A',
                              price: '12,000 KRW',
                              isNew: true,
                            ),
                            SizedBox(width: 12),
                            ProfileDropItem(
                              name: 'Gold Member Kit',
                              price: '5,000 KRW',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Upcoming Events
                      ProfileSectionHeader(
                        title: '다가오는 이벤트',
                        trailing: '더보기',
                        onTrailingTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('이벤트 전체보기 준비 중')),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: ProfileEventCard(
                          title: 'Starlight Christmas Live',
                          location: '홍대 롤링홀',
                          date: '12월 24일 (토)',
                          isOffline: true,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Fan Ad - Support This Artist
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.push('/fan-ads/purchase?artistId=${widget.artistId}');
                          },
                          icon: const Icon(Icons.campaign_outlined, size: 18),
                          label: const Text('이 아티스트 응원 광고하기'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary600,
                            side: BorderSide(
                              color: AppColors.primary500.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: const Size(double.infinity, 44),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tab Bar
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? AppColors.borderDark
                                  : Colors.grey[200]!,
                            ),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: AppColors.primary500,
                          unselectedLabelColor: isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight,
                          indicatorColor: AppColors.primary500,
                          indicatorWeight: 3,
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          tabs: const [
                            Tab(text: '하이라이트'),
                            Tab(text: '공지사항'),
                            Tab(text: '오타 레터'),
                          ],
                        ),
                      ),

                      // Tab Content - different for each tab
                      ..._currentTabFeeds.map((feed) {
                        if (_tabController.index == 1) {
                          // 공지사항 탭 - 공식 공지 스타일
                          return AnnouncementPost(
                            artistName: artist.name,
                            artistAvatarUrl: artist.avatarUrl,
                            content: feed['content'] as String,
                            time: feed['time'] as String,
                            likes: feed['likes'] as int,
                            comments: feed['comments'] as int,
                          );
                        } else if (_tabController.index == 2) {
                          // 오타 레터 탭 - 편지 스타일
                          return OtaLetterPost(
                            artistName: artist.name,
                            artistAvatarUrl: artist.avatarUrl,
                            content: feed['content'] as String,
                            time: feed['time'] as String,
                            likes: feed['likes'] as int,
                            comments: feed['comments'] as int,
                          );
                        } else {
                          // 하이라이트 탭 - 기존 피드 스타일
                          return ArtistFeedPost(
                            artistName: artist.name,
                            artistAvatarUrl: artist.avatarUrl,
                            content: feed['content'] as String,
                            imageUrl: feed['imageUrl'] as String?,
                            time: feed['time'] as String,
                            likes: feed['likes'] as int,
                            comments: feed['comments'] as int,
                            isPinned: feed['isPinned'] as bool? ?? false,
                          );
                        }
                      }),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // FAB - Feed Compose
          Positioned(
            right: 20,
            bottom: 100,
            child: FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      FeedComposeSheet(artistName: artist.name),
                );
              },
              backgroundColor: AppColors.primary600,
              child: const Icon(Icons.edit, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Note: Widget classes (ProfileStatBadge, ProfileHighlightItem, ProfileActionButton,
// ProfileSectionHeader, ProfileDropItem, ProfileEventCard, ArtistFeedPost,
// AnnouncementPost, OtaLetterPost, FeedComposeSheet, FancamCard, FancamListItem,
// SocialLinksSection) are defined in:
//   - widgets/artist_profile_info_widgets.dart
//   - widgets/artist_profile_feed_widgets.dart
//   - widgets/artist_profile_fancam_widgets.dart
//
// The following duplicate definitions from a merge conflict have been removed.
// DO NOT add private widget classes here — use the widget files above.

// --- Duplicate classes removed (merge conflict cleanup) ---
