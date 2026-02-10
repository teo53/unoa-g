import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/broadcast_message.dart';

/// 메시지 반응 이모지 데이터
class ReactionEmoji {
  final IconData icon;
  final Color color;
  final String label;
  final String emoji;

  const ReactionEmoji({
    required this.icon,
    required this.color,
    required this.label,
    required this.emoji,
  });
}

/// 카카오톡 스타일 메시지 액션 시트
/// 상단: 이모지 반응 행 (세련된 아이콘 스타일)
/// 하단: 액션 리스트 (복사, 수정, 삭제, 공지 등)
class MessageActionSheet extends StatelessWidget {
  final BroadcastMessage message;
  final bool isOwnMessage;
  final bool isCreator;
  final bool canEdit;
  final bool canDelete;
  final bool canPin;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final Function(String emoji)? onReact;

  const MessageActionSheet({
    super.key,
    required this.message,
    this.isOwnMessage = false,
    this.isCreator = false,
    this.canEdit = false,
    this.canDelete = false,
    this.canPin = false,
    this.onCopy,
    this.onEdit,
    this.onDelete,
    this.onPin,
    this.onReact,
  });

  static const List<ReactionEmoji> reactions = [
    ReactionEmoji(
      icon: Icons.favorite_rounded,
      color: Color(0xFFFF4B6E),
      label: '좋아요',
      emoji: '❤️',
    ),
    ReactionEmoji(
      icon: Icons.thumb_up_rounded,
      color: Color(0xFF5B8DEF),
      label: '최고',
      emoji: '👍',
    ),
    ReactionEmoji(
      icon: Icons.celebration_rounded,
      color: Color(0xFFFFAB40),
      label: '축하',
      emoji: '🎉',
    ),
    ReactionEmoji(
      icon: Icons.sentiment_very_satisfied_rounded,
      color: Color(0xFFFFCA28),
      label: '웃겨',
      emoji: '😂',
    ),
    ReactionEmoji(
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFAB47BC),
      label: '감동',
      emoji: '✨',
    ),
    ReactionEmoji(
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFF7043),
      label: '불타오르네',
      emoji: '🔥',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Message preview (truncated)
            if (message.content != null && message.content!.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.content!.length > 80
                        ? '${message.content!.substring(0, 80)}...'
                        : message.content!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Emoji reaction row
            _buildReactionRow(context, isDark),

            const SizedBox(height: 8),

            // Divider
            Divider(
              height: 1,
              thickness: 0.5,
              color: isDark ? Colors.grey[800] : Colors.grey[200],
            ),

            // Action list
            _buildActionList(context, isDark),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionRow(BuildContext context, bool isDark) {
    final currentReactions = message.reactions ?? {};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: reactions.map((reaction) {
          final hasReacted =
              currentReactions[reaction.emoji]?.isNotEmpty == true;

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              onReact?.call(reaction.emoji);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: hasReacted
                        ? reaction.color.withValues(alpha: 0.15)
                        : isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF0F0F0),
                    shape: BoxShape.circle,
                    border: hasReacted
                        ? Border.all(
                            color: reaction.color.withValues(alpha: 0.4),
                            width: 1.5)
                        : null,
                  ),
                  child: Icon(
                    reaction.icon,
                    size: 22,
                    color: hasReacted
                        ? reaction.color
                        : isDark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reaction.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: hasReacted
                        ? reaction.color
                        : isDark
                            ? Colors.grey[500]
                            : Colors.grey[500],
                    fontWeight: hasReacted ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionList(BuildContext context, bool isDark) {
    final actions = <_ActionItem>[];

    // Copy (always available for text messages)
    if (message.content != null &&
        message.content!.isNotEmpty &&
        message.deletedAt == null) {
      actions.add(_ActionItem(
        icon: Icons.copy_rounded,
        label: '복사',
        onTap: () {
          Navigator.pop(context);
          onCopy?.call();
        },
      ));
    }

    // Edit (own message, within 24 hours, text only)
    if (canEdit && message.deletedAt == null) {
      actions.add(_ActionItem(
        icon: Icons.edit_rounded,
        label: '수정',
        onTap: () {
          Navigator.pop(context);
          onEdit?.call();
        },
      ));
    }

    // Pin as announcement (creator only)
    if (canPin && message.deletedAt == null) {
      actions.add(_ActionItem(
        icon:
            message.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
        label: message.isPinned ? '공지 해제' : '공지 등록',
        onTap: () {
          Navigator.pop(context);
          onPin?.call();
        },
      ));
    }

    // Delete (own message)
    if (canDelete && message.deletedAt == null) {
      actions.add(_ActionItem(
        icon: Icons.delete_outline_rounded,
        label: '삭제',
        isDestructive: true,
        onTap: () {
          Navigator.pop(context);
          onDelete?.call();
        },
      ));
    }

    return Column(
      children: actions.map((action) {
        return InkWell(
          onTap: action.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(
                  action.icon,
                  size: 22,
                  color: action.isDestructive
                      ? const Color(0xFFEF4444)
                      : isDark
                          ? Colors.grey[300]
                          : Colors.grey[700],
                ),
                const SizedBox(width: 14),
                Text(
                  action.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: action.isDestructive
                        ? const Color(0xFFEF4444)
                        : isDark
                            ? Colors.grey[200]
                            : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    required this.onTap,
  });
}

/// 메시지 하단에 표시되는 이모지 반응 카운트 위젯
class MessageReactionsBar extends StatelessWidget {
  final Map<String, List<String>>? reactions;
  final Function(String emoji)? onTapReaction;

  const MessageReactionsBar({
    super.key,
    this.reactions,
    this.onTapReaction,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions == null || reactions!.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children:
            reactions!.entries.where((e) => e.value.isNotEmpty).map((entry) {
          final emoji = entry.key;
          final count = entry.value.length;
          final matchingReaction = MessageActionSheet.reactions.where(
            (r) => r.emoji == emoji,
          );
          final color = matchingReaction.isNotEmpty
              ? matchingReaction.first.color
              : AppColors.primary;

          return GestureDetector(
            onTap: () => onTapReaction?.call(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (matchingReaction.isNotEmpty)
                    Icon(
                      matchingReaction.first.icon,
                      size: 14,
                      color: color,
                    )
                  else
                    Text(emoji, style: const TextStyle(fontSize: 12)),
                  if (count > 1) ...[
                    const SizedBox(width: 3),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
