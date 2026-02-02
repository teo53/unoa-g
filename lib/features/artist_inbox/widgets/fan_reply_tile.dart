import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/broadcast_message.dart';

/// Fan Reply Tile for Artist Inbox
/// Shows fan message with sender info, content, and actions
class FanReplyTile extends StatelessWidget {
  final BroadcastMessage message;
  final VoidCallback? onTap;
  final VoidCallback? onHighlightTap;
  final VoidCallback? onReplyTap;

  const FanReplyTile({
    super.key,
    required this.message,
    this.onTap,
    this.onHighlightTap,
    this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDonation = message.deliveryScope == DeliveryScope.donationMessage;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDonation
                ? AppColors.primary500.withValues(alpha: 0.3)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isDonation ? 1.5 : 1,
          ),
          boxShadow: message.isHighlighted
              ? [
                  BoxShadow(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + Name + Badges + Time
            Row(
              children: [
                // Avatar
                _buildAvatar(isDark),
                const SizedBox(width: 12),

                // Name + Tier + Days
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            message.senderName ?? '팬',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textMainDark
                                  : AppColors.textMainLight,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildTierBadge(isDark),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${message.senderDaysSubscribed ?? 0}일째 구독 중',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Donation amount
                if (isDonation && message.donationAmount != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary500,
                          AppColors.primary600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.diamond,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${message.donationAmount}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Time
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isDark ? AppColors.textMutedDark : AppColors.textMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Content
            Text(
              message.content ?? '',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),

            const SizedBox(height: 12),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Highlight button
                _ActionButton(
                  icon: message.isHighlighted
                      ? Icons.star
                      : Icons.star_outline,
                  label: message.isHighlighted ? '하이라이트 해제' : '하이라이트',
                  isActive: message.isHighlighted,
                  activeColor: AppColors.warning,
                  onTap: onHighlightTap,
                ),

                // Reply button (only for donation messages)
                if (isDonation && onReplyTap != null) ...[
                  const SizedBox(width: 12),
                  _ActionButton(
                    icon: Icons.reply,
                    label: '답장하기',
                    isActive: false,
                    activeColor: AppColors.primary500,
                    onTap: onReplyTap,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _getTierColor().withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: message.senderAvatarUrl != null
            ? CachedNetworkImage(
                imageUrl: message.senderAvatarUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: Icon(
                    Icons.person,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              )
            : Container(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                child: Icon(
                  Icons.person,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
      ),
    );
  }

  Widget _buildTierBadge(bool isDark) {
    final tier = message.senderTier ?? 'STANDARD';
    final color = _getTierColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tier,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _getTierColor() {
    switch (message.senderTier) {
      case 'VIP':
        return const Color(0xFFD4A574); // Gold
      case 'STANDARD':
        return AppColors.primary500;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays == 1) return '어제';
    if (diff.inDays < 7) return '${diff.inDays}일 전';

    return '${time.month}/${time.day}';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.1)
              : (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.3)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive
                  ? activeColor
                  : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? activeColor
                    : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
