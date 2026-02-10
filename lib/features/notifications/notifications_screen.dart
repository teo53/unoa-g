import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      showStatusBar: true,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const Expanded(
                  child: Text(
                    '알림',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('모든 알림을 읽음 처리했습니다')),
                    );
                  },
                  child: const Text(
                    '모두 읽음',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                const _DateHeader(title: '오늘'),
                _NotificationItem(
                  avatarUrl:
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
                  title: 'IU',
                  message: '새로운 메시지를 보냈습니다',
                  time: '5분 전',
                  isUnread: true,
                  type: NotificationType.message,
                  onTap: () => context.push('/chat/1'),
                ),
                _NotificationItem(
                  avatarUrl:
                      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
                  title: '카리나',
                  message: '새 게시물을 올렸습니다',
                  time: '1시간 전',
                  isUnread: true,
                  type: NotificationType.post,
                  onTap: () => context.push('/artist/2'),
                ),
                _NotificationItem(
                  avatarUrl: '',
                  title: 'DT 충전 완료',
                  message: '1,000 DT가 충전되었습니다',
                  time: '3시간 전',
                  isUnread: false,
                  type: NotificationType.system,
                  onTap: () => context.push('/wallet'),
                ),
                const _DateHeader(title: '어제'),
                _NotificationItem(
                  avatarUrl:
                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
                  title: '정국',
                  message: '라이브 방송을 시작했습니다',
                  time: '어제 오후 8:00',
                  isUnread: false,
                  type: NotificationType.live,
                  onTap: () => context.push('/artist/3'),
                ),
                _NotificationItem(
                  avatarUrl:
                      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=100',
                  title: '지수',
                  message: '새 게시물을 올렸습니다',
                  time: '어제 오후 2:30',
                  isUnread: false,
                  type: NotificationType.post,
                  onTap: () => context.push('/artist/4'),
                ),
                const _DateHeader(title: '이번 주'),
                _NotificationItem(
                  avatarUrl: '',
                  title: '구독 갱신 알림',
                  message: 'IU 구독이 3일 후 만료됩니다',
                  time: '2일 전',
                  isUnread: false,
                  type: NotificationType.subscription,
                  onTap: () => context.push('/subscriptions'),
                ),
                _NotificationItem(
                  avatarUrl: '',
                  title: '이벤트 알림',
                  message: '신규 가입 보너스 500 DT를 받았습니다',
                  time: '3일 전',
                  isUnread: false,
                  type: NotificationType.system,
                  onTap: () => context.push('/wallet'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum NotificationType {
  message,
  post,
  live,
  subscription,
  system,
}

class _DateHeader extends StatelessWidget {
  final String title;

  const _DateHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String avatarUrl;
  final String title;
  final String message;
  final String time;
  final bool isUnread;
  final NotificationType type;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.avatarUrl,
    required this.title,
    required this.message,
    required this.time,
    required this.isUnread,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        color: isUnread
            ? (isDark
                ? AppColors.primary600.withValues(alpha: 0.1)
                : AppColors.primary100.withValues(alpha: 0.5))
            : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar or Icon
            _buildAvatar(isDark),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w500,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary500,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
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
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    if (avatarUrl.isEmpty) {
      // System notification icon
      IconData iconData;
      Color iconColor;
      Color bgColor;

      switch (type) {
        case NotificationType.subscription:
          iconData = Icons.card_membership;
          iconColor = AppColors.primary500;
          bgColor = AppColors.primary100;
          break;
        case NotificationType.system:
          iconData = Icons.diamond;
          iconColor = AppColors.primary500;
          bgColor = AppColors.primary100;
          break;
        default:
          iconData = Icons.notifications;
          iconColor = isDark ? AppColors.textSubDark : AppColors.textSubLight;
          bgColor = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt;
      }

      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(iconData, color: iconColor, size: 24),
      );
    }

    // User avatar
    return Stack(
      children: [
        ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 48,
              height: 48,
              color: isDark ? Colors.grey[800] : Colors.grey[200],
            ),
            errorWidget: (context, url, error) => Container(
              width: 48,
              height: 48,
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              child: Icon(
                Icons.person,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
          ),
        ),
        if (type == NotificationType.live)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary600,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
