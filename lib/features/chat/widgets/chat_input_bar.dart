import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/premium_effects.dart';

/// Chat Input Bar with message sending functionality
///
/// Features:
/// - Text input with send callback
/// - Attachment button (add)
/// - Emoji picker button
/// - Send button with primary600 and glow effect
class ChatInputBar extends StatefulWidget {
  /// Callback when a message is sent
  final Function(String message)? onSendMessage;

  /// Callback when attachment button is pressed
  final VoidCallback? onAttachmentPressed;

  /// Callback when emoji button is pressed
  final VoidCallback? onEmojiPressed;

  /// Hint text for input field
  final String hintText;

  /// Whether send is enabled (for validation purposes)
  final bool sendEnabled;

  const ChatInputBar({
    super.key,
    this.onSendMessage,
    this.onAttachmentPressed,
    this.onEmojiPressed,
    this.hintText = '답장을 입력하세요...',
    this.sendEnabled = true,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && widget.sendEnabled) {
      widget.onSendMessage?.call(text);
      _controller.clear();
      setState(() {
        _hasText = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          // Add/Attachment Button
          IconButton(
            onPressed: widget.onAttachmentPressed ?? () {
              // Default: show attachment options snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('첨부 기능은 준비 중입니다'),
                  backgroundColor: isDark ? AppColors.surfaceDark : AppColors.text,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: Icon(
              Icons.add,
              color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),

          const SizedBox(width: 12),

          // Input Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  suffixIcon: IconButton(
                    onPressed: widget.onEmojiPressed ?? () {
                      // Default: show emoji picker snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('이모지 기능은 준비 중입니다'),
                          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.text,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.sentiment_satisfied_alt,
                      color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
                      size: 20,
                    ),
                  ),
                ),
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Send Button with primary600 and glow
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _hasText && widget.sendEnabled
                  ? AppColors.primary600
                  : (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt),
              shape: BoxShape.circle,
              boxShadow: _hasText && widget.sendEnabled
                  ? [PremiumEffects.subtleGlow]
                  : null,
            ),
            child: IconButton(
              onPressed: _hasText && widget.sendEnabled ? _sendMessage : null,
              icon: Icon(
                Icons.arrow_upward,
                color: _hasText && widget.sendEnabled
                    ? Colors.white
                    : (isDark ? AppColors.iconMutedDark : AppColors.iconMuted),
                size: 20,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
