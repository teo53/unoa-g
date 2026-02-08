import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/mock/mock_data.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/search_field.dart';
import '../../shared/widgets/section_header.dart';
import 'widgets/trending_artist_card.dart';
import 'widgets/subscription_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(currentProfileProvider);
    final isGuest = profile == null;

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
                  if (!isGuest)
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
                // Guest Welcome Banner
                if (isGuest) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _GuestWelcomeBanner(isDark: isDark),
                  ),
                  const SizedBox(height: 24),
                ],

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

                // My Subscriptions Section (only for logged-in users)
                if (!isGuest) ...[
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
                            onTap: () => context.push('/chat/${artist.id}'),
                            onMessageTap: () => context.push('/chat/${artist.id}'),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Guest welcome banner with value proposition and CTAs
class _GuestWelcomeBanner extends StatelessWidget {
  final bool isDark;

  const _GuestWelcomeBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.lgBR,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Text(
            '좋아하는 아티스트의 메시지를 받아보세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '구독하고 1:1 채팅을 시작하세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/discover'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('아티스트 둘러보기'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => context.push('/login'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                  ),
                  child: const Text('로그인하기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
