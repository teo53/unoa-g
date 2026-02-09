import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/mock/mock_data.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/animation_utils.dart';
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

    if (isGuest) {
      return _GuestHomeScreen(isDark: isDark);
    }

    return _LoggedInHomeScreen(isDark: isDark);
  }
}

/// Logged-in user home screen (기존 로직 유지)
class _LoggedInHomeScreen extends StatelessWidget {
  final bool isDark;

  const _LoggedInHomeScreen({required this.isDark});

  @override
  Widget build(BuildContext context) {
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
                      return SlideFadeAnimation.fromLeft(
                        delay: Duration(milliseconds: 50 * index),
                        child: Padding(
                          padding: EdgeInsets.only(
                            right:
                                index < MockData.trendingArtists.length - 1 ? 16 : 0,
                          ),
                          child: TrendingArtistCard(
                            artist: artist,
                            onTap: () => context.push('/artist/${artist.id}'),
                          ),
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
                    children: MockData.subscribedArtists.asMap().entries.map((entry) {
                      final index = entry.key;
                      final artist = entry.value;
                      return FadeInAnimation(
                        delay: Duration(milliseconds: 80 * index),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SubscriptionTile(
                            artist: artist,
                            hasNewMessage: artist.id == 'artist_1',
                            onTap: () => context.push('/chat/${artist.id}'),
                            onMessageTap: () => context.push('/chat/${artist.id}'),
                          ),
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

/// Guest home screen - 비로그인 사용자 전용 랜딩 페이지
class _GuestHomeScreen extends StatelessWidget {
  final bool isDark;

  const _GuestHomeScreen({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Minimal Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
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
              TextButton(
                onPressed: () => context.push('/login'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary600,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('로그인'),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Hero Section
                FadeInAnimation(
                  child: _GuestHeroSection(isDark: isDark),
                ),

                const SizedBox(height: 36),

                // Trending Artists
                const SectionHeader(
                  title: '지금 인기 있는 아티스트',
                  trailing: '전체보기',
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: MockData.trendingArtists.length,
                    itemBuilder: (context, index) {
                      final artist = MockData.trendingArtists[index];
                      return SlideFadeAnimation.fromLeft(
                        delay: Duration(milliseconds: 50 * index),
                        child: Padding(
                          padding: EdgeInsets.only(
                            right:
                                index < MockData.trendingArtists.length - 1 ? 16 : 0,
                          ),
                          child: TrendingArtistCard(
                            artist: artist,
                            onTap: () => context.push('/artist/${artist.id}'),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 36),

                // Feature Cards Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UNO A에서 할 수 있는 것들',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SlideFadeAnimation.fromBottom(
                        delay: const Duration(milliseconds: 100),
                        child: _FeatureCard(
                          isDark: isDark,
                          icon: Icons.chat_bubble_rounded,
                          iconColor: AppColors.primary,
                          title: '1:1 메시지',
                          description: '아티스트의 일상 메시지를 받고, 직접 답장을 보내세요',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SlideFadeAnimation.fromBottom(
                        delay: const Duration(milliseconds: 200),
                        child: _FeatureCard(
                          isDark: isDark,
                          icon: Icons.card_giftcard_rounded,
                          iconColor: Colors.purple,
                          title: '프라이빗 카드',
                          description: '나만을 위한 특별한 포토카드와 메시지를 받아보세요',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SlideFadeAnimation.fromBottom(
                        delay: const Duration(milliseconds: 300),
                        child: _FeatureCard(
                          isDark: isDark,
                          icon: Icons.how_to_vote_rounded,
                          iconColor: Colors.blue,
                          title: '투표 참여',
                          description: '아티스트의 다음 콘텐츠와 활동을 함께 결정하세요',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Bottom CTA
                FadeInAnimation(
                  delay: const Duration(milliseconds: 400),
                  child: _GuestBottomCTA(isDark: isDark),
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

/// Hero section for guest home screen
class _GuestHeroSection extends StatelessWidget {
  final bool isDark;

  const _GuestHeroSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.10),
            AppColors.primary.withValues(alpha: 0.04),
            isDark
                ? AppColors.surfaceDark
                : AppColors.surfaceLight,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          // Decorative icon row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FloatingIcon(
                icon: Icons.favorite_rounded,
                color: Colors.pink.shade300,
                size: 20,
              ),
              const SizedBox(width: 8),
              _FloatingIcon(
                icon: Icons.chat_bubble_rounded,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              _FloatingIcon(
                icon: Icons.star_rounded,
                color: Colors.amber.shade400,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main title
          Text(
            '아티스트와\n가까워지는 순간',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.3,
              color: isDark
                  ? AppColors.textMainDark
                  : AppColors.textMainLight,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle
          Text(
            '좋아하는 아티스트의 일상 메시지를 받고\n직접 대화를 나눠보세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark
                  ? AppColors.textSubDark
                  : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 24),

          // CTA Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/discover'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('둘러보기'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () => context.push('/login'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('시작하기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Floating decorative icon used in hero section
class _FloatingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _FloatingIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size * 0.4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}

/// Feature card for app introduction
class _FeatureCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _FeatureCard({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSubDark
                        : AppColors.textSubLight,
                    height: 1.4,
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

/// Bottom CTA section for guest
class _GuestBottomCTA extends StatelessWidget {
  final bool isDark;

  const _GuestBottomCTA({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Text(
            '지금 바로 시작해보세요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textMainDark
                  : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '가입하고 좋아하는 아티스트를 구독하세요',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSubDark
                  : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.push('/login'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('무료로 시작하기'),
            ),
          ),
        ],
      ),
    );
  }
}
