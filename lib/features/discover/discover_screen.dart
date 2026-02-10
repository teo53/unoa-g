import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/premium_effects.dart';
import '../../core/utils/animation_utils.dart';
import '../../data/mock/mock_data.dart';
import '../../shared/widgets/search_field.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/skeleton_loader.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  bool _isLoading = true;
  int _selectedCategory = 0;
  final List<String> _categories = ['전체', '아이돌', '배우', '가수'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showFilterSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '필터',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 20),
              const _FilterOption(title: '카테고리', value: '전체'),
              const _FilterOption(title: '정렬', value: '인기순'),
              const _FilterOption(title: '활동 상태', value: '전체'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '적용하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                '탐색',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              IconButton(
                onPressed: () => _showFilterSheet(context),
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
        // Categories skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: List.generate(
                4,
                (index) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SkeletonLoader(
                        width: 60,
                        height: 32,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    )),
          ),
        ),

        const SizedBox(height: 24),

        // Featured banner skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SkeletonLoader.card(
            width: double.infinity,
            height: 180,
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        const SizedBox(height: 32),

        // Section title skeleton
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader.text(width: 100, height: 18),
              SkeletonLoader.text(width: 40, height: 14),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Grid skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SkeletonLoader.card(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 8),
                const SkeletonLoader.text(width: 80, height: 14),
                const SizedBox(height: 4),
                const SkeletonLoader.text(width: 50, height: 12),
              ],
            ),
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
        // Categories
        SlideFadeAnimation.fromLeft(
          delay: const Duration(milliseconds: 50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: _categories.asMap().entries.map((entry) {
                final index = entry.key;
                final label = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedCategory == index
                            ? AppColors.primary600
                            : (isDark ? AppColors.surfaceDark : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: _selectedCategory == index
                            ? null
                            : Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                              ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _selectedCategory == index
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textSubDark
                                  : AppColors.textSubLight),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Featured Artist Banner
        SlideFadeAnimation.fromBottom(
          delay: const Duration(milliseconds: 100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _FeaturedBanner(
              artist: MockData.trendingArtists.first,
              onTap: () {
                HapticFeedback.selectionClick();
                context.push(
                  '/artist/${MockData.trendingArtists.first.id}',
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Recommended Artists
        const SlideFadeAnimation.fromBottom(
          delay: Duration(milliseconds: 150),
          child: SectionHeader(
            title: '추천 아티스트',
            trailing: '더보기',
          ),
        ),
        const SizedBox(height: 16),

        // Artists Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: MockData.trendingArtists.length,
            itemBuilder: (context, index) {
              final artist = MockData.trendingArtists[index];
              return FadeInAnimation(
                delay: Duration(milliseconds: 200 + (60 * index)),
                child: ScaleOnTap(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.push('/artist/${artist.id}');
                  },
                  child: _DiscoverArtistCard(
                    name: artist.name,
                    group: artist.group,
                    avatarUrl: artist.avatarUrl,
                    followerCount: artist.formattedFollowers,
                    isVerified: artist.isVerified,
                    onTap: () => context.push('/artist/${artist.id}'),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 100),
      ],
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
          gradient: const LinearGradient(
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
                        color: Colors.white.withValues(alpha: 0.2),
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
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 160,
                          height: 160,
                          color: Colors.white.withValues(alpha: 0.2),
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
                      color: Colors.white.withValues(alpha: 0.2),
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
                      color: Colors.white.withValues(alpha: 0.8),
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
                    child: const Text(
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

/// Filter Option Row
class _FilterOption extends StatelessWidget {
  final String title;
  final String value;

  const _FilterOption({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.primary500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ],
          ),
        ],
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
              color: Colors.black.withValues(alpha: 0.03),
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
                        const Icon(
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
                      const Icon(
                        Icons.person,
                        size: 12,
                        color: AppColors.primary500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        followerCount,
                        style: const TextStyle(
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
