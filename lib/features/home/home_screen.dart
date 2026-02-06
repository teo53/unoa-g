import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/animation_utils.dart';
import '../../data/mock/mock_data.dart';
import '../../shared/widgets/search_field.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/error_boundary.dart';
import 'widgets/trending_artist_card.dart';
import 'widgets/subscription_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    // Simulate loading delay for skeleton demo
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UNO A',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
                  letterSpacing: -0.5,
                ),
              ),
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      context.push('/notifications');
                    },
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Search
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: SearchField(),
        ),

        const SizedBox(height: 24),

        // Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              await _loadData();
            },
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: _isLoading
                  ? _buildSkeletonContent(isDark)
                  : _hasError
                      ? ErrorDisplay(
                          error: '데이터 로드 실패',
                          onRetry: _loadData,
                        )
                      : _buildContent(context, isDark),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonLoader.text(width: 80, height: 18),
              SkeletonLoader.text(width: 40, height: 14),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Trending artists skeleton (horizontal)
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: 3,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SkeletonCard(
                width: 160,
                height: 180,
                showTitle: true,
                showSubtitle: true,
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // My subscriptions skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const SkeletonLoader.text(width: 60, height: 18),
        ),
        const SizedBox(height: 16),

        // Subscription list skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: List.generate(3, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SkeletonListTile(
                showAvatar: true,
                showSubtitle: true,
                showTrailing: true,
                avatarSize: 48,
              ),
            )),
          ),
        ),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trending Artists Section
        SlideFadeAnimation.fromBottom(
          delay: const Duration(milliseconds: 50),
          child: const SectionHeader(
            title: '인기 캐스트',
            trailing: '더보기',
          ),
        ),
        const SizedBox(height: 16),

        // Horizontal Scroll of Artists
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: MockData.trendingArtists.length,
            itemBuilder: (context, index) {
              final artist = MockData.trendingArtists[index];
              return Padding(
                padding: EdgeInsets.only(
                  right:
                      index < MockData.trendingArtists.length - 1 ? 16 : 0,
                ),
                child: FadeInAnimation(
                  delay: Duration(milliseconds: 80 + (50 * index)),
                  child: ScaleOnTap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/artist/${artist.id}');
                    },
                    child: TrendingArtistCard(
                      artist: artist,
                      onTap: () => context.push('/artist/${artist.id}'),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 32),

        // My Subscriptions Section
        SlideFadeAnimation.fromBottom(
          delay: const Duration(milliseconds: 150),
          child: const SectionHeader(
            title: '내 구독',
          ),
        ),
        const SizedBox(height: 16),

        // Subscription List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: MockData.subscribedArtists.asMap().entries.map((entry) {
              final index = entry.key;
              final artist = entry.value;
              return SlideFadeAnimation.fromBottom(
                delay: Duration(milliseconds: 200 + (50 * index)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SubscriptionTile(
                    artist: artist,
                    hasNewMessage: artist.id == 'artist_1',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/chat/${artist.id}');
                    },
                    onMessageTap: () => context.push('/chat/${artist.id}'),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 100),
      ],
    );
  }
}
