import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/premium_effects.dart';
import '../../../data/models/reply_quota.dart';
import 'token_counter.dart';

/// Chat Input Bar with message sending functionality
///
/// Features:
/// - Text input with send callback
/// - Attachment button (add)
/// - DT Gift/Donation button
/// - Emoji picker button
/// - Send button with primary600 and glow effect
/// - Token gating (Fromm/Bubble style)
/// - Character limit based on subscription age
class ChatInputBar extends StatefulWidget {
  /// Callback when a message is sent
  final Function(String message)? onSendMessage;

  /// Callback when attachment button is pressed
  final VoidCallback? onAttachmentPressed;

  /// Callback when emoji button is pressed
  final VoidCallback? onEmojiPressed;

  /// Callback when DT gift button is pressed
  final VoidCallback? onDtGiftPressed;

  /// Artist ID for donation context
  final String? artistId;

  /// Hint text for input field
  final String hintText;

  /// Whether send is enabled (for validation purposes)
  final bool sendEnabled;

  /// Reply quota (for token gating)
  final ReplyQuota? quota;

  /// Character limit based on subscription age
  final int characterLimit;

  /// Days subscribed (for character limit display)
  final int daysSubscribed;

  const ChatInputBar({
    super.key,
    this.onSendMessage,
    this.onAttachmentPressed,
    this.onEmojiPressed,
    this.onDtGiftPressed,
    this.artistId,
    this.hintText = '답장을 입력하세요...',
    this.sendEnabled = true,
    this.quota,
    this.characterLimit = 50,
    this.daysSubscribed = 0,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  int _currentLength = 0;

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
    final text = _controller.text.trim();
    final hasText = text.isNotEmpty;
    final newLength = text.length;

    if (hasText != _hasText || newLength != _currentLength) {
      setState(() {
        _hasText = hasText;
        _currentLength = newLength;
      });
    }
  }

  bool get _canSend {
    final hasQuota = widget.quota?.canReply ?? true;
    final withinLimit = _currentLength <= widget.characterLimit;
    return _hasText && widget.sendEnabled && hasQuota && withinLimit;
  }

  bool get _isOverLimit => _currentLength > widget.characterLimit;

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && _canSend) {
      widget.onSendMessage?.call(text);
      _controller.clear();
      setState(() {
        _hasText = false;
        _currentLength = 0;
      });
    }
  }

  void _showDtGiftSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DtGiftSheet(artistId: widget.artistId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Character limit and token counter row
          if (_hasText || widget.quota != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Token counter (compact)
                  if (widget.quota != null)
                    TokenCounter(quota: widget.quota, compact: true)
                  else
                    const SizedBox.shrink(),

                  // Character limit indicator
                  if (_hasText)
                    CharacterLimitIndicator(
                      currentLength: _currentLength,
                      maxLength: widget.characterLimit,
                    ),
                ],
              ),
            ),

          // Input row
          Row(
            children: [
              // Add/Attachment Button
              IconButton(
                onPressed: widget.onAttachmentPressed ?? () {
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

              const SizedBox(width: 8),

              // DT Gift/Donation Button
              IconButton(
                onPressed: widget.onDtGiftPressed ?? () {
                  _showDtGiftSheet(context, isDark);
                },
                icon: Icon(
                  Icons.diamond,
                  color: AppColors.primary500,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              const SizedBox(width: 8),

              // Input Field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(24),
                    border: _isOverLimit
                        ? Border.all(color: AppColors.error, width: 1.5)
                        : null,
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
                      color: _isOverLimit
                          ? AppColors.error
                          : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
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
                  color: _canSend
                      ? AppColors.primary600
                      : (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt),
                  shape: BoxShape.circle,
                  boxShadow: _canSend ? [PremiumEffects.subtleGlow] : null,
                ),
                child: IconButton(
                  onPressed: _canSend ? _sendMessage : null,
                  icon: Icon(
                    Icons.arrow_upward,
                    color: _canSend
                        ? Colors.white
                        : (isDark ? AppColors.iconMutedDark : AppColors.iconMuted),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// DT Gift/Donation Bottom Sheet
class _DtGiftSheet extends StatefulWidget {
  final String? artistId;

  const _DtGiftSheet({this.artistId});

  @override
  State<_DtGiftSheet> createState() => _DtGiftSheetState();
}

class _DtGiftSheetState extends State<_DtGiftSheet> {
  int _selectedAmount = 10;
  final TextEditingController _messageController = TextEditingController();
  bool _isAnonymous = false;
  bool _isSending = false;

  final List<int> _dtAmounts = [10, 50, 100, 500, 1000];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.diamond,
                      color: AppColors.primary500,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'DT 후원하기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Balance display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '내 잔액: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                    ),
                  ),
                  Icon(Icons.diamond, size: 14, color: AppColors.primary500),
                  const SizedBox(width: 4),
                  Text(
                    '1,250 DT',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Amount Selection
            Text(
              '후원 금액',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _dtAmounts.map((amount) {
                final isSelected = _selectedAmount == amount;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAmount = amount;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary100
                          : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary500
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.diamond,
                          size: 16,
                          color: isSelected
                              ? AppColors.primary600
                              : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$amount',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary600
                                : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Message Input
            Text(
              '응원 메시지 (선택)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 2,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: '아티스트에게 전할 메시지를 입력하세요',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  counterStyle: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Anonymous toggle
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _isAnonymous,
                    onChanged: (value) {
                      setState(() {
                        _isAnonymous = value ?? false;
                      });
                    },
                    activeColor: AppColors.primary500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '익명으로 후원하기',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Send Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendDonation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  disabledBackgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.diamond, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '$_selectedAmount DT 후원하기',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 8),

            // Policy notice
            Center(
              child: Text(
                '후원한 DT는 환불되지 않습니다',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendDonation() async {
    setState(() {
      _isSending = true;
    });

    // Simulate donation processing
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isSending = false;
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('$_selectedAmount DT를 후원했습니다! 💎'),
            ],
          ),
          backgroundColor: AppColors.primary600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
