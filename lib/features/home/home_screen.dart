import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock/mock_data.dart';
import '../../shared/widgets/search_field.dart';
import '../../shared/widgets/section_header.dart';
import 'widgets/trending_artist_card.dart';
import 'widgets/subscription_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                    onPressed: () => context.push('/notifications'),
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trending Artists Section
                const SectionHeader(
                  title: '인기 캐스트',
                  trailing: '더보기',
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
                        child: TrendingArtistCard(
                          artist: artist,
                          onTap: () => context.push('/artist/${artist.id}'),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // My Subscriptions Section
                const SectionHeader(
                  title: '내 구독',
                ),
                const SizedBox(height: 16),

                // Subscription List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: MockData.subscribedArtists.map((artist) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SubscriptionTile(
                          artist: artist,
                          hasNewMessage: artist.id == 'artist_1',
                          isLive: artist.id == 'artist_4',
                          onTap: () => context.push('/chat/${artist.id}'),
                          onMessageTap: () => context.push('/chat/${artist.id}'),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
