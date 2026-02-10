import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/broadcast_message.dart';

/// Dialog for editing a message
/// Only text messages can be edited, within 24 hours of sending
class MessageEditDialog extends StatefulWidget {
  /// The message to edit
  final BroadcastMessage message;

  /// Callback when edit is confirmed
  final Future<void> Function(String newContent) onEdit;

  /// Maximum character limit for the message
  final int? maxCharacters;

  const MessageEditDialog({
    super.key,
    required this.message,
    required this.onEdit,
    this.maxCharacters,
  });

  /// Show the edit dialog
  static Future<bool?> show({
    required BuildContext context,
    required BroadcastMessage message,
    required Future<void> Function(String newContent) onEdit,
    int? maxCharacters,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => MessageEditDialog(
        message: message,
        onEdit: onEdit,
        maxCharacters: maxCharacters,
      ),
    );
  }

  @override
  State<MessageEditDialog> createState() => _MessageEditDialogState();
}

class _MessageEditDialogState extends State<MessageEditDialog> {
  late TextEditingController _controller;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.message.content ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canEdit {
    // Check if message is within 24 hours
    final hoursSinceCreation =
        DateTime.now().difference(widget.message.createdAt).inHours;
    return hoursSinceCreation < 24;
  }

  bool get _hasChanges {
    return _controller.text.trim() != (widget.message.content ?? '').trim();
  }

  bool get _isValid {
    final text = _controller.text.trim();
    if (text.isEmpty) return false;
    if (widget.maxCharacters != null && text.length > widget.maxCharacters!) {
      return false;
    }
    return true;
  }

  String get _remainingTimeText {
    final hoursSinceCreation =
        DateTime.now().difference(widget.message.createdAt).inHours;
    final remainingHours = 24 - hoursSinceCreation;

    if (remainingHours <= 0) {
      return '편집 가능 시간이 만료되었습니다';
    } else if (remainingHours == 1) {
      return '편집 가능 시간: 1시간 미만';
    } else {
      return '편집 가능 시간: $remainingHours시간';
    }
  }

  Future<void> _handleEdit() async {
    if (!_canEdit || !_hasChanges || !_isValid || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.onEdit(_controller.text.trim());
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '메시지 편집에 실패했습니다. 다시 시도해주세요.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final characterCount = _controller.text.length;
    final isOverLimit = widget.maxCharacters != null &&
        characterCount > widget.maxCharacters!;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      title: Row(
        children: [
          Icon(
            Icons.edit_outlined,
            size: 24,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
          const SizedBox(width: 8),
          const Text('메시지 편집'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time remaining notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _canEdit
                    ? (isDark
                        ? AppColors.primary500.withValues(alpha: 0.15)
                        : AppColors.primary500.withValues(alpha: 0.1))
                    : (isDark
                        ? AppColors.danger.withValues(alpha: 0.15)
                        : AppColors.danger.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _canEdit ? Icons.access_time : Icons.timer_off,
                    size: 18,
                    color: _canEdit ? AppColors.primary500 : AppColors.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _remainingTimeText,
                      style: TextStyle(
                        fontSize: 13,
                        color: _canEdit ? AppColors.primary500 : AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Text field
            TextField(
              controller: _controller,
              enabled: _canEdit && !_isLoading,
              maxLines: 5,
              minLines: 3,
              decoration: InputDecoration(
                hintText: '메시지를 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isOverLimit ? AppColors.danger : AppColors.primary500,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 8),

            // Character count
            if (widget.maxCharacters != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$characterCount / ${widget.maxCharacters}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverLimit
                          ? AppColors.danger
                          : (isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight),
                    ),
                  ),
                ],
              ),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Info about edit
            const SizedBox(height: 12),
            Text(
              '편집된 메시지에는 "편집됨" 표시가 추가됩니다.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: (_canEdit && _hasChanges && _isValid && !_isLoading)
              ? _handleEdit
              : null,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary500,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('편집'),
        ),
      ],
    );
  }
}
