import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/artist.dart';

/// Stat Badge Widget - Uses primary600 for WCAG compliance
class ProfileStatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? change;

  const ProfileStatBadge({
    super.key,
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
class ProfileHighlightItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasRing;

  const ProfileHighlightItem({
    super.key,
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
class ProfileActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final Color? themeColor;
  final VoidCallback? onTap;

  const ProfileActionButton({
    super.key,
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
class ProfileSectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  const ProfileSectionHeader({
    super.key,
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
class ProfileDropItem extends StatelessWidget {
  final String name;
  final String price;
  final bool isNew;
  final bool isSoldOut;

  const ProfileDropItem({
    super.key,
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
class ProfileEventCard extends StatelessWidget {
  final String title;
  final String location;
  final String date;
  final bool isOffline;

  const ProfileEventCard({
    super.key,
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

/// Social Links Section Widget - 좌측 정렬 소셜 링크 아이콘
class SocialLinksSection extends StatelessWidget {
  final SocialLinks socialLinks;
  final Color themeColor;
  final Function(String) onLinkTap;

  const SocialLinksSection({
    super.key,
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
            SocialIconButton(
              label: 'IG',
              color: themeColor,
              onTap: () => onLinkTap(socialLinks.instagram!),
            ),
          if (socialLinks.youtube != null && socialLinks.youtube!.isNotEmpty)
            SocialIconButton(
              icon: Icons.play_circle_outline,
              color: themeColor,
              onTap: () => onLinkTap(socialLinks.youtube!),
            ),
          if (socialLinks.tiktok != null && socialLinks.tiktok!.isNotEmpty)
            SocialIconButton(
              label: 'TT',
              color: themeColor,
              onTap: () => onLinkTap(socialLinks.tiktok!),
            ),
          if (socialLinks.twitter != null && socialLinks.twitter!.isNotEmpty)
            SocialIconButton(
              label: 'X',
              color: themeColor,
              onTap: () => onLinkTap(socialLinks.twitter!),
            ),
          // Custom links
          ...socialLinks.customLinks.map((link) => SocialIconButton(
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
class SocialIconButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final Color color;
  final VoidCallback onTap;

  const SocialIconButton({
    super.key,
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
