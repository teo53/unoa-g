import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/artist.dart';
import '../../data/models/creator_content.dart';
import '../../providers/discover_provider.dart';
import '../../shared/widgets/app_scaffold.dart';

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
    final feedsAsync = ref.read(artistContentFeedsProvider(widget.artistId));
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
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('YouTube를 열 수 없습니다')),
        );
      }
    }
  }

  Future<void> _openSocialLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다')),
        );
      }
    }
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
                  return _FancamListItem(
                    fancam: fancam,
                    onTap: () {
                      Navigator.pop(context);
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
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('공유 기능 준비 중')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('알림 설정'),
              onTap: () {
                Navigator.pop(context);
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
                Navigator.pop(context);
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
                              _StatBadge(
                                icon: Icons.trending_up,
                                label: '주간랭킹: ${artist.rank}위',
                                change: '+2',
                              ),
                              const SizedBox(width: 12),
                              _StatBadge(
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
                            _HighlightItem(
                              icon: Icons.checkroom,
                              label: 'Today\'s OOTD',
                              hasRing: true,
                            ),
                            SizedBox(width: 16),
                            _HighlightItem(
                              icon: Icons.music_note,
                              label: 'Rehearsal',
                            ),
                            SizedBox(width: 16),
                            _HighlightItem(
                              icon: Icons.camera_alt,
                              label: 'Q&A',
                            ),
                            SizedBox(width: 16),
                            _HighlightItem(
                              icon: Icons.videocam,
                              label: 'V-log',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Social Links (좌측 정렬)
                      if (_socialLinks.hasAnyLink)
                        _SocialLinksSection(
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
                            _ActionButton(
                              icon: Icons.chat_bubble_outline,
                              label: 'DM',
                              themeColor: _artistThemeColor,
                              onTap: () =>
                                  context.push('/chat/${widget.artistId}'),
                            ),
                            _ActionButton(
                              icon: Icons.card_giftcard,
                              label: '드롭',
                              themeColor: _artistThemeColor,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('드롭 스토어 준비 중')),
                                );
                              },
                            ),
                            _ActionButton(
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
                        _SectionHeader(
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
                              return _FancamCard(
                                fancam: fancam,
                                onTap: () => _openYouTubeVideo(fancam.videoUrl),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Drops Section
                      _SectionHeader(
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
                            _DropItem(
                              name: '1st Anniversary T-shirt',
                              price: '35,000 KRW',
                              isSoldOut: true,
                            ),
                            SizedBox(width: 12),
                            _DropItem(
                              name: 'Winter Photo Set A',
                              price: '12,000 KRW',
                              isNew: true,
                            ),
                            SizedBox(width: 12),
                            _DropItem(
                              name: 'Gold Member Kit',
                              price: '5,000 KRW',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Upcoming Events
                      _SectionHeader(
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
                        child: _EventCard(
                          title: 'Starlight Christmas Live',
                          location: '홍대 롤링홀',
                          date: '12월 24일 (토)',
                          isOffline: true,
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
                          return _AnnouncementPost(
                            artistName: artist.name,
                            artistAvatarUrl: artist.avatarUrl,
                            content: feed['content'] as String,
                            time: feed['time'] as String,
                            likes: feed['likes'] as int,
                            comments: feed['comments'] as int,
                          );
                        } else if (_tabController.index == 2) {
                          // 오타 레터 탭 - 편지 스타일
                          return _OtaLetterPost(
                            artistName: artist.name,
                            artistAvatarUrl: artist.avatarUrl,
                            content: feed['content'] as String,
                            time: feed['time'] as String,
                            likes: feed['likes'] as int,
                            comments: feed['comments'] as int,
                          );
                        } else {
                          // 하이라이트 탭 - 기존 피드 스타일
                          return _FeedPost(
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
                      _FeedComposeSheet(artistName: artist.name),
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

/// Stat Badge Widget - Uses primary600 for WCAG compliance
class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? change;

  const _StatBadge({
    required this.icon,
    required this.label,
    this.change,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary600,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (change != null) ...[
            const SizedBox(width: 4),
            Text(
              change!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Highlight Item Widget - Uses primary500 for active ring
class _HighlightItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasRing;

  const _HighlightItem({
    required this.icon,
    required this.label,
    this.hasRing = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.surfaceDark : Colors.grey[100],
            border: hasRing
                ? Border.all(color: AppColors.primary500, width: 2)
                : Border.all(
                    color: isDark ? AppColors.borderDark : Colors.grey[300]!,
                  ),
          ),
          child: Icon(
            icon,
            size: 24,
            color: isDark ? AppColors.textSubDark : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
        ),
      ],
    );
  }
}

/// Action Button Widget - Uses artist theme color for filled state
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final Color? themeColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.themeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveThemeColor = themeColor ?? AppColors.primary600;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isPrimary
                  ? effectiveThemeColor
                  : (isDark ? AppColors.surfaceDark : Colors.grey[100]),
              borderRadius: BorderRadius.circular(16),
              border: isPrimary
                  ? null
                  : Border.all(
                      color: isDark ? AppColors.borderDark : Colors.grey[300]!,
                    ),
            ),
            child: Icon(
              icon,
              color: isPrimary
                  ? Colors.white
                  : (isDark ? AppColors.textSubDark : Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section Header Widget - Uses primary500 for trailing link
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  const _SectionHeader({
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailingTap,
              child: Text(
                trailing!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Drop Item Widget - Uses primary500 for price, primary100 for NEW badge
class _DropItem extends StatelessWidget {
  final String name;
  final String price;
  final bool isNew;
  final bool isSoldOut;

  const _DropItem({
    required this.name,
    required this.price,
    this.isNew = false,
    this.isSoldOut = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image Placeholder
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Icon(
                    Icons.checkroom,
                    size: 40,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
                if (isSoldOut)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'SOLD OUT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (isNew)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Product Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                    decoration: isSoldOut ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSoldOut
                        ? (isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight)
                        : AppColors.primary500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Event Card Widget - Uses primary colors consistently
class _EventCard extends StatelessWidget {
  final String title;
  final String location;
  final String date;
  final bool isOffline;

  const _EventCard({
    required this.title,
    required this.location,
    required this.date,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          // Event Image Placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event,
              color: AppColors.primary600,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isOffline ? Colors.grey[600] : AppColors.primary600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOffline ? 'OFFLINE' : 'ONLINE',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Feed Post Widget - Uses primary500 for like icon and avatar border
class _FeedPost extends StatelessWidget {
  final String artistName;
  final String artistAvatarUrl;
  final String content;
  final String? imageUrl;
  final String time;
  final int likes;
  final int comments;
  final bool isPinned;

  const _FeedPost({
    required this.artistName,
    required this.artistAvatarUrl,
    required this.content,
    this.imageUrl,
    required this.time,
    required this.likes,
    required this.comments,
    this.isPinned = false,
  });

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : Colors.grey[200]!,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pinned indicator
          if (isPinned) ...[
            const Row(
              children: [
                Icon(
                  Icons.push_pin,
                  size: 14,
                  color: AppColors.primary500,
                ),
                SizedBox(width: 4),
                Text(
                  '고정된 게시물',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          // Header
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  border: Border.all(
                    color: AppColors.primary500,
                    width: 2,
                  ),
                ),
                child: artistAvatarUrl.isEmpty
                    ? Icon(
                        Icons.person_rounded,
                        size: 20,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      )
                    : ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: artistAvatarUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Icon(
                            Icons.person_rounded,
                            size: 20,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.person_rounded,
                            size: 20,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$artistName ($artistName)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                    Text(
                      time,
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
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.more_horiz,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Content
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),

          // Image
          if (imageUrl != null && imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: const Icon(Icons.image, size: 40),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              const Icon(
                Icons.favorite,
                size: 18,
                color: AppColors.primary500,
              ),
              const SizedBox(width: 4),
              Text(
                _formatCount(likes),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
              const SizedBox(width: 20),
              Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
              const SizedBox(width: 4),
              Text(
                _formatCount(comments),
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Feed Compose Bottom Sheet - Uses primary600 for CTA
class _FeedComposeSheet extends StatefulWidget {
  final String artistName;

  const _FeedComposeSheet({required this.artistName});

  @override
  State<_FeedComposeSheet> createState() => _FeedComposeSheetState();
}

class _FeedComposeSheetState extends State<_FeedComposeSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasContent = _controller.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '피드 작성',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Text Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '팬들에게 전하고 싶은 이야기를 작성해주세요...',
                  hintStyle: TextStyle(
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Attachment Options
            Row(
              children: [
                _AttachmentButton(
                  icon: Icons.image_outlined,
                  label: '사진',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('사진 첨부 기능 준비 중')),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _AttachmentButton(
                  icon: Icons.videocam_outlined,
                  label: '영상',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('영상 첨부 기능 준비 중')),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _AttachmentButton(
                  icon: Icons.poll_outlined,
                  label: '투표',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('투표 기능 준비 중')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Post Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _hasContent
                    ? () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('피드가 작성되었습니다'),
                            backgroundColor: AppColors.primary600,
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  disabledBackgroundColor:
                      isDark ? Colors.grey[800] : Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '게시하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _hasContent
                        ? Colors.white
                        : (isDark ? Colors.grey[600] : Colors.grey[500]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Announcement Post Widget - 공지사항 스타일
class _AnnouncementPost extends StatelessWidget {
  final String artistName;
  final String artistAvatarUrl;
  final String content;
  final String time;
  final int likes;
  final int comments;

  const _AnnouncementPost({
    required this.artistName,
    required this.artistAvatarUrl,
    required this.content,
    required this.time,
    required this.likes,
    required this.comments,
  });

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.primary500.withValues(alpha: 0.3)
              : AppColors.primary100,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Official badge header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.campaign_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      '공식 공지',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.push_pin,
                size: 16,
                color: AppColors.primary500,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Content
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),

          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              const Icon(
                Icons.favorite,
                size: 18,
                color: AppColors.primary500,
              ),
              const SizedBox(width: 4),
              Text(
                _formatCount(likes),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
              const SizedBox(width: 20),
              Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
              const SizedBox(width: 4),
              Text(
                _formatCount(comments),
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.bookmark_border,
                size: 20,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ota Letter Post Widget - 편지/일기 스타일
class _OtaLetterPost extends StatelessWidget {
  final String artistName;
  final String artistAvatarUrl;
  final String content;
  final String time;
  final int likes;
  final int comments;

  const _OtaLetterPost({
    required this.artistName,
    required this.artistAvatarUrl,
    required this.content,
    required this.time,
    required this.likes,
    required this.comments,
  });

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : const Color(0xFFFFFDF5), // 따뜻한 편지 톤
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.amber.withValues(alpha: 0.2)
              : const Color(0xFFE8DCC8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Letter header - 편지 스타일 아이콘
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: artistAvatarUrl.isEmpty
                    ? Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      )
                    : ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: artistAvatarUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$artistName의 편지',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.mail_outline_rounded,
                          size: 16,
                          color: Colors.amber[700],
                        ),
                      ],
                    ),
                    Text(
                      time,
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
            ],
          ),

          const SizedBox(height: 16),

          // Decorative line
          Container(
            width: 40,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(1),
            ),
          ),

          const SizedBox(height: 16),

          // Letter content
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.8,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              const Icon(
                Icons.favorite,
                size: 18,
                color: AppColors.primary500,
              ),
              const SizedBox(width: 4),
              Text(
                _formatCount(likes),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
              const SizedBox(width: 20),
              Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
              const SizedBox(width: 4),
              Text(
                _formatCount(comments),
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.bookmark_border,
                size: 20,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Attachment Button Widget
class _AttachmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// YouTube Fancam Card Widget - Horizontal scroll item
class _FancamCard extends StatelessWidget {
  final YouTubeFancam fancam;
  final VoidCallback onTap;

  const _FancamCard({
    required this.fancam,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with play button overlay
            Expanded(
              child: Stack(
                children: [
                  // YouTube Thumbnail
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: fancam.thumbnailUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            size: 40,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.videocam_off,
                            size: 40,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Play button
                  Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  // Pinned badge
                  if (fancam.isPinned)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.push_pin, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              '고정됨',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // YouTube logo
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  ),
                  // View count
                  if (fancam.viewCount != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          fancam.formattedViewCount,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                fancam.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// YouTube Fancam List Item - For bottom sheet full list view
class _FancamListItem extends StatelessWidget {
  final YouTubeFancam fancam;
  final VoidCallback onTap;

  const _FancamListItem({
    required this.fancam,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: fancam.thumbnailUrlMQ,
                    width: 140,
                    height: 90,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 140,
                      height: 90,
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 140,
                      height: 90,
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      child: const Icon(Icons.videocam_off),
                    ),
                  ),
                ),
                // Play overlay
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Pinned badge
                if (fancam.isPinned)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '고정',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fancam.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 14,
                          color: isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fancam.formattedViewCount,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSubDark
                                : AppColors.textSubLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Social Links Section Widget - 좌측 정렬 소셜 링크 아이콘
class _SocialLinksSection extends StatelessWidget {
  final SocialLinks socialLinks;
  final Color themeColor;
  final Function(String) onLinkTap;

  const _SocialLinksSection({
    required this.socialLinks,
    required this.themeColor,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // 좌측 정렬
        children: [
          if (socialLinks.instagram != null &&
              socialLinks.instagram!.isNotEmpty)
            _SocialIconButton(
              label: 'IG',
              color: themeColor,
              onTap: () => onLinkTap(socialLinks.instagram!),
            ),
          if (socialLinks.youtube != null && socialLinks.youtube!.isNotEmpty)
            _SocialIconButton(
              icon: Icons.play_circle_outline,
              color: themeColor,
              onTap: () => onLinkTap(socialLinks.youtube!),
            ),
          if (socialLinks.tiktok != null && socialLinks.tiktok!.isNotEmpty)
            _SocialIconButton(
              label: 'TT',
              color: themeColor,
              onTap: () => onLinkTap(socialLinks.tiktok!),
            ),
          if (socialLinks.twitter != null && socialLinks.twitter!.isNotEmpty)
            _SocialIconButton(
              label: 'X',
              color: themeColor,
              onTap: () => onLinkTap(socialLinks.twitter!),
            ),
          // Custom links
          ...socialLinks.customLinks.map((link) => _SocialIconButton(
                icon: Icons.link,
                color: themeColor,
                onTap: () => onLinkTap(link.url),
              )),
        ],
      ),
    );
  }
}

/// Social Icon Button Widget
class _SocialIconButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final Color color;
  final VoidCallback onTap;

  const _SocialIconButton({
    this.icon,
    this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: icon != null
                ? Icon(
                    icon,
                    size: 18,
                    color: color,
                  )
                : Text(
                    label ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
