import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/artist.dart';
import '../../../shared/widgets/primary_button.dart';

class TrendingArtistCard extends StatelessWidget {
  final Artist artist;
  final VoidCallback? onTap;

  const TrendingArtistCard({
    super.key,
    required this.artist,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 144,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          // uno-a (2) soft shadow style
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image with 4:5 aspect ratio
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: artist.avatarUrl.isEmpty
                          ? Container(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              child: Center(
                                child: Icon(
                                  Icons.person_rounded,
                                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                                  size: 48,
                                ),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: artist.avatarUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: isDark ? Colors.grey[800] : Colors.grey[200],
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: isDark ? Colors.grey[800] : Colors.grey[200],
                                child: Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    // Gradient overlay at bottom
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Rank Badge with glassmorphism
                    if (artist.rank != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: BadgeChip(
                          label: 'TOP ${artist.rank}',
                          type: BadgeType.top,
                        ),
                      ),
                    // Name overlay at bottom
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artist.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black38,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (artist.group != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              artist.group!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.8),
                                shadows: const [
                                  Shadow(
                                    color: Colors.black38,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom section with follower count
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          artist.formattedFollowers,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
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
