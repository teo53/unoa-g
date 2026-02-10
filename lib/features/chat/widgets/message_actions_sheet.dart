import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/broadcast_message.dart';
import 'report_dialog.dart';

/// Bottom sheet for message actions (edit, delete, copy, report, block)
class MessageActionsSheet extends StatelessWidget {
  /// The message to show actions for
  final BroadcastMessage message;

  /// Whether this message belongs to the current user
  final bool isOwnMessage;

  /// Callback when reply is requested
  final VoidCallback? onReply;

  /// Callback when edit is requested
  final VoidCallback? onEdit;

  /// Callback when delete is requested
  final VoidCallback? onDelete;

  /// Callback when report is submitted
  final Future<void> Function(ReportReason reason, String? description)?
      onReport;

  /// Callback when block is requested
  final VoidCallback? onBlock;

  /// Whether the viewer is a creator (for public share option)
  final bool isCreatorView;

  /// Callback when public share is requested
  final VoidCallback? onPublicShare;

  /// Callback when unshare is requested
  final VoidCallback? onUnshare;

  const MessageActionsSheet({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onReport,
    this.onBlock,
    this.isCreatorView = false,
    this.onPublicShare,
    this.onUnshare,
  });

  /// Show the message actions sheet
  static Future<void> show({
    required BuildContext context,
    required BroadcastMessage message,
    required bool isOwnMessage,
    VoidCallback? onReply,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    Future<void> Function(ReportReason reason, String? description)? onReport,
    VoidCallback? onBlock,
    bool isCreatorView = false,
    VoidCallback? onPublicShare,
    VoidCallback? onUnshare,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MessageActionsSheet(
        message: message,
        isOwnMessage: isOwnMessage,
        onReply: onReply,
        onEdit: onEdit,
        onDelete: onDelete,
        onReport: onReport,
        onBlock: onBlock,
        isCreatorView: isCreatorView,
        onPublicShare: onPublicShare,
        onUnshare: onUnshare,
      ),
    );
  }

  /// Check if the message can be edited (within 24 hours)
  bool get _canEdit {
    if (!isOwnMessage) return false;
    if (message.messageType != BroadcastMessageType.text) return false;
    if (message.deletedAt != null) return false;

    final hoursSinceCreation =
        DateTime.now().difference(message.createdAt).inHours;
    return hoursSinceCreation < 24;
  }

  /// Check if the message can be deleted
  bool get _canDelete {
    if (!isOwnMessage) return false;
    return message.deletedAt == null;
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content ?? ''));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('메시지가 복사되었습니다'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    Navigator.pop(context);
    onEdit?.call();
  }

  void _showDeleteConfirmation(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메시지 삭제'),
        content: const Text(
          '이 메시지를 삭제하시겠습니까?\n삭제된 메시지는 상대방에게 "삭제된 메시지"로 표시됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    Navigator.pop(context);
    if (onReport == null) return;

    ReportDialog.show(
      context: context,
      reportedContentId: message.id,
      reportedContentType: 'message',
      onSubmit: onReport!,
    ).then((reported) {
      if (reported == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('신고가 접수되었습니다. 검토 후 조치하겠습니다.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _showBlockConfirmation(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용자 차단'),
        content: const Text(
          '이 사용자를 차단하시겠습니까?\n차단하면 이 사용자의 메시지가 더 이상 표시되지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onBlock?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
            child: const Text('차단'),
          ),
        ],
      ),
    );
  }

  void _showPublicShareConfirmation(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전체공개'),
        content: const Text(
          '이 메시지를 모든 구독자에게 공개하시겠습니까?\n공개된 메시지는 모든 팬들이 볼 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onPublicShare?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary600,
            ),
            child: const Text('공개'),
          ),
        ],
      ),
    );
  }

  void _showUnshareConfirmation(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공개 취소'),
        content: const Text(
          '이 메시지의 전체공개를 취소하시겠습니까?\n취소하면 더 이상 다른 팬들에게 표시되지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onUnshare?.call();
            },
            child: const Text('공개 취소'),
          ),
        ],
      ),
    );
  }

  /// Check if the message can be public shared (fan message, not own, creator view)
  bool get _canPublicShare {
    if (!isCreatorView) return false;
    if (isOwnMessage) return false; // 크리에이터 본인 메시지는 이미 브로드캐스트
    if (message.isFromArtist) return false; // 아티스트 메시지는 이미 브로드캐스트
    if (message.isPublicShared) return false; // 이미 공개된 메시지
    if (message.deletedAt != null) return false; // 삭제된 메시지
    return true;
  }

  /// Check if the message can be unshared (already shared)
  bool get _canUnshare {
    if (!isCreatorView) return false;
    return message.isPublicShared;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Message preview (truncated)
          if (message.content != null && message.content!.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message.content!.length > 100
                    ? '${message.content!.substring(0, 100)}...'
                    : message.content!,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          const SizedBox(height: 8),

          // Action items
          // Reply action (shown for all messages)
          if (onReply != null)
            _ActionTile(
              icon: Icons.reply_rounded,
              label: '답장',
              onTap: () {
                Navigator.pop(context);
                onReply!.call();
              },
            ),

          if (isOwnMessage) ...[
            // Own message actions
            if (_canEdit)
              _ActionTile(
                icon: Icons.edit_outlined,
                label: '편집',
                sublabel: '24시간 이내',
                onTap: () => _showEditDialog(context),
              ),
            if (_canDelete)
              _ActionTile(
                icon: Icons.delete_outline,
                label: '삭제',
                onTap: () => _showDeleteConfirmation(context),
                isDanger: true,
              ),
            _ActionTile(
              icon: Icons.copy_outlined,
              label: '복사',
              onTap: () => _copyToClipboard(context),
            ),
          ] else ...[
            // Other's message actions
            _ActionTile(
              icon: Icons.copy_outlined,
              label: '복사',
              onTap: () => _copyToClipboard(context),
            ),

            // Creator-specific actions for fan messages
            if (_canPublicShare && onPublicShare != null)
              _ActionTile(
                icon: Icons.public,
                label: '전체공개',
                sublabel: '모든 구독자에게 공개',
                onTap: () => _showPublicShareConfirmation(context),
                isPrimary: true,
              ),
            if (_canUnshare && onUnshare != null)
              _ActionTile(
                icon: Icons.public_off,
                label: '공개 취소',
                sublabel: '전체공개 해제',
                onTap: () => _showUnshareConfirmation(context),
              ),

            if (onReport != null)
              _ActionTile(
                icon: Icons.flag_outlined,
                label: '신고',
                onTap: () => _showReportDialog(context),
                isDanger: true,
              ),
            if (onBlock != null)
              _ActionTile(
                icon: Icons.block_outlined,
                label: '차단',
                onTap: () => _showBlockConfirmation(context),
                isDanger: true,
              ),
          ],

          // Cancel button
          const Divider(height: 1),
          _ActionTile(
            icon: Icons.close,
            label: '취소',
            onTap: () => Navigator.pop(context),
            isCancel: true,
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final VoidCallback onTap;
  final bool isDanger;
  final bool isCancel;
  final bool isPrimary;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.sublabel,
    required this.onTap,
    this.isDanger = false,
    this.isCancel = false,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color = isDanger
        ? AppColors.danger
        : isPrimary
            ? AppColors.primary500
            : isCancel
                ? (isDark ? AppColors.textSubDark : AppColors.textSubLight)
                : (isDark ? AppColors.textMainDark : AppColors.textMainLight);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  if (sublabel != null)
                    Text(
                      sublabel!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
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
