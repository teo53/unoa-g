import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/broadcast_message.dart';
import '../../../services/media_service.dart';
import 'star_reaction_button.dart';
import 'public_share_badge.dart';

/// Message bubble widget for BroadcastMessage model
/// Supports edited/deleted states, donation messages, and media
class BroadcastMessageBubble extends StatelessWidget {
  /// The message to display
  final BroadcastMessage message;

  /// Whether the current user is the sender (show on right side)
  final bool isOwnMessage;

  /// Callback when message is long-pressed
  final VoidCallback? onLongPress;

  /// Callback when message is tapped
  final VoidCallback? onTap;

  /// Whether to show sender info (avatar, name)
  final bool showSenderInfo;

  /// Callback when reaction button is tapped
  final VoidCallback? onReactionTap;

  /// Whether to show reaction button (for creator view)
  final bool showReactionButton;

  const BroadcastMessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.onLongPress,
    this.onTap,
    this.showSenderInfo = true,
    this.onReactionTap,
    this.showReactionButton = true,
  });

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$period $displayHour:$minute';
  }

  /// Check if message is deleted
  bool get _isDeleted => message.deletedAt != null;

  /// Check if message is edited
  bool get _isEdited => message.isEdited;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Deleted message shows placeholder
    if (_isDeleted) {
      return _DeletedMessageBubble(
        isOwnMessage: isOwnMessage,
        isDark: isDark,
        timestamp: message.createdAt,
      );
    }

    if (isOwnMessage) {
      return _OwnMessageBubble(
        message: message,
        isDark: isDark,
        isEdited: _isEdited,
        onLongPress: onLongPress,
        onTap: onTap,
        formatTime: _formatTime,
        onReactionTap: onReactionTap,
        showReactionButton: showReactionButton,
      );
    } else {
      return _OtherMessageBubble(
        message: message,
        isDark: isDark,
        isEdited: _isEdited,
        showSenderInfo: showSenderInfo,
        onLongPress: onLongPress,
        onTap: onTap,
        formatTime: _formatTime,
        onReactionTap: onReactionTap,
        showReactionButton: showReactionButton,
      );
    }
  }
}

/// Deleted message placeholder
class _DeletedMessageBubble extends StatelessWidget {
  final bool isOwnMessage;
  final bool isDark;
  final DateTime timestamp;

  const _DeletedMessageBubble({
    required this.isOwnMessage,
    required this.isDark,
    required this.timestamp,
  });

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$period $displayHour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isOwnMessage) ...[
            Text(
              _formatTime(timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: const BoxConstraints(maxWidth: 240),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[850]?.withValues(alpha: 0.5)
                  : Colors.grey[200]?.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.grey[700]!.withValues(alpha: 0.3)
                    : Colors.grey[300]!.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.block,
                  size: 16,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '삭제된 메시지입니다',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (!isOwnMessage) ...[
            const SizedBox(width: 8),
            Text(
              _formatTime(timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Own message bubble (right-aligned)
class _OwnMessageBubble extends StatelessWidget {
  final BroadcastMessage message;
  final bool isDark;
  final bool isEdited;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final String Function(DateTime) formatTime;
  final VoidCallback? onReactionTap;
  final bool showReactionButton;

  const _OwnMessageBubble({
    required this.message,
    required this.isDark,
    required this.isEdited,
    this.onLongPress,
    this.onTap,
    required this.formatTime,
    this.onReactionTap,
    this.showReactionButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDonation = message.isDonation;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Reaction button (left of time)
          if (showReactionButton &&
              (message.reactionCount > 0 || message.hasReacted))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: StarReactionButton(
                count: message.reactionCount,
                hasReacted: message.hasReacted,
                onTap: onReactionTap,
                compact: true,
              ),
            ),

          // Time and edit/read status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isEdited)
                Text(
                  '편집됨',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              if (message.isRead == true)
                const Text(
                  '읽음',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary500,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                formatTime(message.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),

          // Bubble
          GestureDetector(
            onLongPress: onLongPress,
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Donation amount badge
                if (isDonation && message.donationAmount != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.star.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.star.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 12,
                          color: AppColors.star,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${message.donationAmount} DT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.star : Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                // Media content
                if (message.messageType == BroadcastMessageType.image &&
                    message.mediaUrl != null)
                  _MediaBubble(
                    mediaUrl: MediaUrlResolver.instance.resolve(message.mediaUrl!),
                    isOwnMessage: true,
                    isDark: isDark,
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxWidth: 240),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.bubbleFanDark
                          : AppColors.bubbleFanLight,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      boxShadow: isDonation
                          ? [
                              BoxShadow(
                                color: AppColors.star.withValues(alpha: 0.15),
                                blurRadius: 8,
                                spreadRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                      border: isDonation
                          ? Border.all(
                              color: AppColors.star.withValues(alpha: 0.3),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Text(
                      message.content ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: isDark
                            ? const Color(0xFFFFCDD2)
                            : AppColors.textMainLight,
                      ),
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

/// Other user's message bubble (left-aligned)
class _OtherMessageBubble extends StatelessWidget {
  final BroadcastMessage message;
  final bool isDark;
  final bool isEdited;
  final bool showSenderInfo;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final String Function(DateTime) formatTime;
  final VoidCallback? onReactionTap;
  final bool showReactionButton;

  const _OtherMessageBubble({
    required this.message,
    required this.isDark,
    required this.isEdited,
    required this.showSenderInfo,
    this.onLongPress,
    this.onTap,
    required this.formatTime,
    this.onReactionTap,
    this.showReactionButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDonation = message.isDonation;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          if (showSenderInfo)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: message.senderAvatarUrl == null ||
                        message.senderAvatarUrl!.isEmpty
                    ? Container(
                        width: 34,
                        height: 34,
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: Icon(
                          Icons.person_rounded,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                          size: 18,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: message.senderAvatarUrl!,
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(
                            Icons.person_rounded,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                            size: 18,
                          ),
                        ),
                      ),
              ),
            )
          else
            const SizedBox(width: 36),

          const SizedBox(width: 10),

          // Bubble content
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender info
                  if (showSenderInfo) ...[
                    Row(
                      children: [
                        Text(
                          message.senderName ?? '알 수 없음',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSubDark
                                : AppColors.textSubLight,
                          ),
                        ),
                        // Tier badge
                        if (message.senderTier != null) ...[
                          const SizedBox(width: 6),
                          _TierBadge(tier: message.senderTier!, isDark: isDark),
                        ],
                        // Donation badge
                        if (isDonation && message.donationAmount != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.star.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  size: 10,
                                  color: AppColors.star,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${message.donationAmount} DT',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.star,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Public share badge
                        if (message.isPublicShare) ...[
                          const SizedBox(width: 6),
                          const PublicShareBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Media or text content
                  if (message.messageType == BroadcastMessageType.image &&
                      message.mediaUrl != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _MediaBubble(
                          mediaUrl: MediaUrlResolver.instance.resolve(message.mediaUrl!),
                          isOwnMessage: false,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatTime(message.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.textSubDark
                                    : AppColors.textSubLight,
                              ),
                            ),
                            if (showReactionButton) ...[
                              const SizedBox(height: 4),
                              StarReactionButton(
                                count: message.reactionCount,
                                hasReacted: message.hasReacted,
                                onTap: onReactionTap,
                                compact: true,
                              ),
                            ],
                          ],
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 240),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.bubbleArtistDark
                                : AppColors.bubbleArtistLight,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(18),
                              bottomLeft: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                            ),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            message.content ?? '',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: isDark
                                  ? AppColors.textMainDark
                                  : AppColors.textMainLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isEdited)
                              Text(
                                '편집됨',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: isDark
                                      ? AppColors.textSubDark
                                      : AppColors.textSubLight,
                                ),
                              ),
                            Text(
                              formatTime(message.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.textSubDark
                                    : AppColors.textSubLight,
                              ),
                            ),
                            // Reaction button
                            if (showReactionButton) ...[
                              const SizedBox(height: 4),
                              StarReactionButton(
                                count: message.reactionCount,
                                hasReacted: message.hasReacted,
                                onTap: onReactionTap,
                                compact: true,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Media content bubble (image/video)
class _MediaBubble extends StatelessWidget {
  final String mediaUrl;
  final bool isOwnMessage;
  final bool isDark;

  const _MediaBubble({
    required this.mediaUrl,
    required this.isOwnMessage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(isOwnMessage ? 18 : 4),
        topRight: Radius.circular(isOwnMessage ? 4 : 18),
        bottomLeft: const Radius.circular(18),
        bottomRight: const Radius.circular(18),
      ),
      child: CachedNetworkImage(
        imageUrl: mediaUrl,
        width: 220,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 220,
          height: 160,
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 220,
          height: 160,
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                '이미지를 불러올 수 없습니다',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subscription tier badge
class _TierBadge extends StatelessWidget {
  final String tier;
  final bool isDark;

  const _TierBadge({
    required this.tier,
    required this.isDark,
  });

  Color get _tierColor {
    switch (tier.toUpperCase()) {
      case 'VIP':
        return AppColors.vip;
      case 'STANDARD':
        return AppColors.standard;
      case 'BASIC':
      default:
        return isDark ? Colors.grey[500]! : Colors.grey[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _tierColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _tierColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        tier,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: _tierColor,
        ),
      ),
    );
  }
}

/// Date separator for chat timeline
class BroadcastDateSeparator extends StatelessWidget {
  final DateTime date;

  const BroadcastDateSeparator({
    super.key,
    required this.date,
  });

  String _formatDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return '오늘';
    } else if (messageDate == yesterday) {
      return '어제';
    } else if (date.year == now.year) {
      return '${date.month}월 ${date.day}일';
    } else {
      return '${date.year}년 ${date.month}월 ${date.day}일';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDate(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
        ],
      ),
    );
  }
}
