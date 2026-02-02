import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';

/// 사람 모양 인포그래피 플레이스홀더 위젯
class AvatarPlaceholder extends StatelessWidget {
  final double size;
  final bool isDark;

  const AvatarPlaceholder({
    super.key,
    required this.size,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
        size: size * 0.55,
      ),
    );
  }
}

class AvatarWithBadge extends StatelessWidget {
  final String imageUrl;
  final double size;
  final bool isOnline;
  final bool isVerified;
  final bool showRing;
  final Color? ringColor;

  const AvatarWithBadge({
    super.key,
    required this.imageUrl,
    this.size = 56,
    this.isOnline = false,
    this.isVerified = false,
    this.showRing = false,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool showPlaceholder = imageUrl.isEmpty;

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: showRing
                ? Border.all(
                    color: ringColor ?? AppColors.primary,
                    width: 2,
                  )
                : null,
          ),
          padding: showRing ? const EdgeInsets.all(2) : null,
          child: showPlaceholder
              ? AvatarPlaceholder(
                  size: showRing ? size - 8 : size,
                  isDark: isDark,
                )
              : ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => AvatarPlaceholder(
                      size: showRing ? size - 8 : size,
                      isDark: isDark,
                    ),
                    errorWidget: (context, url, error) => AvatarPlaceholder(
                      size: showRing ? size - 8 : size,
                      isDark: isDark,
                    ),
                  ),
                ),
        ),
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: BoxDecoration(
                color: AppColors.online,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
        if (isVerified)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: AppColors.verified,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: size * 0.16,
              ),
            ),
          ),
      ],
    );
  }
}

class StoryAvatar extends StatelessWidget {
  final String imageUrl;
  final String label;
  final bool hasNewStory;
  final bool isAddStory;
  final VoidCallback? onTap;

  const StoryAvatar({
    super.key,
    required this.imageUrl,
    required this.label,
    this.hasNewStory = false,
    this.isAddStory = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool showPlaceholder = imageUrl.isEmpty;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasNewStory
                      ? AppColors.primary
                      : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  width: 2,
                ),
              ),
              child: isAddStory
                  ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.grey[800] : Colors.grey[50],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.add,
                              color: Colors.grey[400],
                              size: 28,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.backgroundDark
                                      : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : showPlaceholder
                      ? AvatarPlaceholder(size: 58, isDark: isDark)
                      : ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                AvatarPlaceholder(size: 58, isDark: isDark),
                            errorWidget: (context, url, error) =>
                                AvatarPlaceholder(size: 58, isDark: isDark),
                          ),
                        ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: hasNewStory
                    ? (isDark ? AppColors.textMainDark : AppColors.textMainLight)
                    : (isDark ? Colors.grey[400] : Colors.grey[500]),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
