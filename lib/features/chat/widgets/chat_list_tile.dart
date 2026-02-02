import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/message.dart';

class ChatListTile extends StatelessWidget {
  final ChatThread chat;
  final VoidCallback? onTap;

  const ChatListTile({
    super.key,
    required this.chat,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPinned = chat.isPinned;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          // uno-a (2) style: bg-red-50/50 dark:bg-[#2C1515] for pinned
          color: isPinned
              ? (isDark ? AppColors.pinnedDark : AppColors.pinnedLight)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isPinned
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: ClipOval(
                    child: chat.artistAvatarUrl.isEmpty
                        ? Container(
                            width: 52,
                            height: 52,
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: Icon(
                              Icons.person_rounded,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                              size: 28,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: chat.artistAvatarUrl,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 52,
                              height: 52,
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 52,
                              height: 52,
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              child: Icon(
                                Icons.person_rounded,
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                                size: 28,
                              ),
                            ),
                          ),
                  ),
                ),
                // Online indicator - positioned at bottom right
                if (chat.isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Name Row with badges
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                chat.artistDisplayName,
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
                            if (chat.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                size: 14,
                                color: AppColors.verified,
                              ),
                            ],
                            if (chat.isStar) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: AppColors.star,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Time
                      Text(
                        chat.formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: isPinned
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.textSubDark
                                  : AppColors.textSubLight),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Message Preview
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: chat.unreadCount > 0
                                ? (isDark
                                    ? AppColors.textMainDark
                                    : AppColors.textMainLight)
                                : (isDark
                                    ? AppColors.textSubDark
                                    : AppColors.textSubLight),
                            fontWeight: chat.unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Unread Badge - red circle
                      if (chat.unreadCount > 0)
                        Container(
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Center(
                            child: Text(
                              chat.unreadCount > 99
                                  ? '99+'
                                  : chat.unreadCount.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      else if (isPinned)
                        Icon(
                          Icons.push_pin,
                          size: 14,
                          color: AppColors.primary.withOpacity(0.5),
                        )
                      else
                        Icon(
                          Icons.done_all,
                          size: 16,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
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
