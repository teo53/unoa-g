import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/premium_effects.dart';
import '../../data/mock/mock_data.dart';
import '../../shared/widgets/search_field.dart';
import '../../shared/widgets/section_header.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

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
                '탐색',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
                ),
              ),
              IconButton(
                onPressed: () {
                  // TODO: Show filter bottom sheet
                },
                icon: Icon(
                  Icons.tune,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ],
          ),
        ),

        // Search
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: SearchField(hintText: '아티스트, 그룹 검색...'),
        ),

        const SizedBox(height: 24),

        // Content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Categories
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _CategoryChip(label: '전체', isSelected: true),
                      const SizedBox(width: 8),
                      _CategoryChip(label: '아이돌'),
                      const SizedBox(width: 8),
                      _CategoryChip(label: '배우'),
                      const SizedBox(width: 8),
                      _CategoryChip(label: '가수'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Featured Artist Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _FeaturedBanner(
                    artist: MockData.trendingArtists.first,
                    onTap: () => context.push(
                      '/artist/${MockData.trendingArtists.first.id}',
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Recommended Artists
                const SectionHeader(
                  title: '추천 아티스트',
                  trailing: '더보기',
                ),
                const SizedBox(height: 16),

                // Artists Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: MockData.trendingArtists.length,
                    itemBuilder: (context, index) {
                      final artist = MockData.trendingArtists[index];
                      return _DiscoverArtistCard(
                        name: artist.name,
                        group: artist.group,
                        avatarUrl: artist.avatarUrl,
                        followerCount: artist.formattedFollowers,
                        isVerified: artist.isVerified,
                        onTap: () => context.push('/artist/${artist.id}'),
                      );
                    },
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

/// Category Chip using primary600 for selected state
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _CategoryChip({
    required this.label,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary600
            : (isDark ? AppColors.surfaceDark : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? null
            : Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isSelected
              ? Colors.white
              : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
        ),
      ),
    );
  }
}

/// Featured Banner using unified gradient
class _FeaturedBanner extends StatelessWidget {
  final dynamic artist;
  final VoidCallback? onTap;

  const _FeaturedBanner({
    required this.artist,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.subtleGradient,
          ),
          boxShadow: PremiumEffects.primaryCtaShadows,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: ClipOval(
                child: artist.avatarUrl.isEmpty
                    ? Container(
                        width: 160,
                        height: 160,
                        color: Colors.white.withOpacity(0.2),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 80,
                          color: Colors.white54,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: artist.avatarUrl,
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 160,
                          height: 160,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 160,
                          height: 160,
                          color: Colors.white.withOpacity(0.2),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 80,
                            color: Colors.white54,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'HOT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    artist.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    artist.group ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '프로필 보기',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Discover Artist Card using consistent primary colors
class _DiscoverArtistCard extends StatelessWidget {
  final String name;
  final String? group;
  final String avatarUrl;
  final String followerCount;
  final bool isVerified;
  final VoidCallback? onTap;

  const _DiscoverArtistCard({
    required this.name,
    this.group,
    required this.avatarUrl,
    required this.followerCount,
    this.isVerified = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: avatarUrl.isEmpty
                    ? Container(
                        width: double.infinity,
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: Icon(
                          Icons.person_rounded,
                          size: 48,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: avatarUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(
                            Icons.person_rounded,
                            size: 48,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                      ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified)
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: AppColors.verified,
                        ),
                    ],
                  ),
                  if (group != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      group!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 12,
                        color: AppColors.primary500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        followerCount,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
