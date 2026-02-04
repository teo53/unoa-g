import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/artist.dart';
import '../../../shared/widgets/avatar_with_badge.dart';
import '../../../shared/widgets/primary_button.dart';

class SubscriptionTile extends StatelessWidget {
  final Artist artist;
  final bool hasNewMessage;
  final VoidCallback? onTap;
  final VoidCallback? onMessageTap;

  const SubscriptionTile({
    super.key,
    required this.artist,
    this.hasNewMessage = false,
    this.onTap,
    this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : Colors.grey[100]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            AvatarWithBadge(
              imageUrl: artist.avatarUrl,
              size: 56,
              isOnline: artist.isOnline,
              showRing: hasNewMessage,
              ringColor: AppColors.primary,
            ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          artist.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (artist.isVerified)
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: AppColors.verified,
                        ),
                      if (artist.tier == 'VIP') ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.star,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  BadgeChip(
                    label: artist.tier,
                    type: artist.tier == 'VIP'
                        ? BadgeType.vip
                        : BadgeType.standard,
                  ),
                ],
              ),
            ),

            // Action Button
            if (hasNewMessage)
              PrimaryButton(
                label: '메시지 확인',
                showPulse: true,
                onPressed: onMessageTap,
              )
            else
              SecondaryButton(
                label: '최근 활동',
                onPressed: onMessageTap,
              ),
          ],
        ),
      ),
    );
  }
}
