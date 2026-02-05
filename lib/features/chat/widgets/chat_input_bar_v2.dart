import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../services/media_service.dart';

/// Chat input bar with Riverpod state management
class ChatInputBarV2 extends ConsumerStatefulWidget {
  final String channelId;
  final VoidCallback? onMessageSent;

  const ChatInputBarV2({
    super.key,
    required this.channelId,
    this.onMessageSent,
  });

  @override
  ConsumerState<ChatInputBarV2> createState() => _ChatInputBarV2State();
}

class _ChatInputBarV2State extends ConsumerState<ChatInputBarV2> {
  late final TextEditingController _controller;
  final MediaService _mediaService = MediaService();
  bool _isComposing = false;
  bool _isSending = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String text) {
    final wasComposing = _isComposing;
    setState(() {
      _isComposing = text.trim().isNotEmpty;
    });

    // Send typing indicator
    if (_isComposing && !wasComposing) {
      ref.read(chatProvider(widget.channelId).notifier).updateTyping(true);
    }

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      ref.read(chatProvider(widget.channelId).notifier).updateTyping(false);
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final success = await ref
          .read(chatProvider(widget.channelId).notifier)
          .sendReply(text);

      if (success) {
        _controller.clear();
        setState(() {
          _isComposing = false;
        });
        widget.onMessageSent?.call();
      } else {
        _showError('메시지 전송에 실패했습니다.');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _pickAndSendImage() async {
    final image = await _mediaService.pickImage();
    if (image == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Upload image
      final result = await _mediaService.uploadMedia(
        image,
        channelId: widget.channelId,
        userId: ref.read(chatProvider(widget.channelId)).subscription?.userId ?? '',
      );

      if (result != null) {
        await ref.read(chatProvider(widget.channelId).notifier).sendMediaMessage(
          mediaUrl: result.url,
          messageType: 'image',
          mediaMetadata: result.metadata,
        );
        widget.onMessageSent?.call();
      }
    } catch (e) {
      _showError('이미지 전송에 실패했습니다.');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showDonationSheet() {
    final walletState = ref.read(walletProvider);
    final balance = walletState.wallet?.balanceDt ?? 0;

    showModalBottomSheet(
      context: context,
      builder: (context) => _DonationSheet(
        channelId: widget.channelId,
        balance: balance,
        onDonationSent: widget.onMessageSent,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatState = ref.watch(chatProvider(widget.channelId));
    final canReply = chatState.canReply;
    final characterLimit = chatState.characterLimit;
    final quota = chatState.quota;

    // Show disabled state if no reply tokens
    if (!canReply) {
      return _DisabledInput(
        isDark: isDark,
        reason: '답장 토큰이 없습니다. 아티스트의 새 메시지를 기다려주세요.',
        onDonationTap: _showDonationSheet,
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
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
          // Token and character info
          if (quota != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Token count
                  Row(
                    children: [
                      Icon(
                        Icons.token,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${quota.tokensAvailable}/3',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight,
                        ),
                      ),
                      if (quota.fallbackAvailable) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+1 대기',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Character count
                  Text(
                    '${_controller.text.length}/$characterLimit',
                    style: TextStyle(
                      fontSize: 12,
                      color: _controller.text.length > characterLimit
                          ? Colors.red
                          : isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight,
                    ),
                  ),
                ],
              ),
            ),

          // Input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Media button
              IconButton(
                onPressed: _isSending ? null : _pickAndSendImage,
                icon: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),

              // Donation button
              IconButton(
                onPressed: _showDonationSheet,
                icon: Icon(
                  Icons.favorite_border,
                  color: const Color(0xFFEC4899),
                ),
              ),

              // Text input
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _controller,
                    onChanged: _onTextChanged,
                    maxLines: null,
                    maxLength: characterLimit,
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                child: _isSending
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        onPressed: _isComposing &&
                                _controller.text.length <= characterLimit
                            ? _sendMessage
                            : null,
                        style: IconButton.styleFrom(
                          backgroundColor: _isComposing
                              ? AppColors.primary
                              : isDark
                                  ? Colors.grey[700]
                                  : Colors.grey[300],
                          shape: const CircleBorder(),
                        ),
                        icon: Icon(
                          Icons.send,
                          color: _isComposing ? Colors.white : Colors.grey[500],
                          size: 20,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Disabled input state when no tokens available
class _DisabledInput extends StatelessWidget {
  final bool isDark;
  final String reason;
  final VoidCallback? onDonationTap;

  const _DisabledInput({
    required this.isDark,
    required this.reason,
    this.onDonationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
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
          // Disabled message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[800]!.withValues(alpha: 0.5)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reason,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Donation option
          FilledButton.icon(
            onPressed: onDonationTap,
            icon: const Icon(Icons.favorite, size: 18),
            label: const Text('후원 메시지 보내기'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
      ),
    );
  }
}

/// Donation amount selection sheet
class _DonationSheet extends ConsumerStatefulWidget {
  final String channelId;
  final int balance;
  final VoidCallback? onDonationSent;

  const _DonationSheet({
    required this.channelId,
    required this.balance,
    this.onDonationSent,
  });

  @override
  ConsumerState<_DonationSheet> createState() => _DonationSheetState();
}

class _DonationSheetState extends ConsumerState<_DonationSheet> {
  final _messageController = TextEditingController();
  final _customAmountController = TextEditingController();
  int _selectedAmount = 100;
  bool _isAnonymous = false;
  bool _isSending = false;
  bool _isCustomAmount = false;

  static const List<int> _presetAmounts = [100, 500, 1000, 5000, 10000, 50000];
  static const int _maxAmount = 1000000; // 최대 100만 DT

  @override
  void dispose() {
    _messageController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  int get _effectiveAmount {
    if (_isCustomAmount) {
      final customValue = int.tryParse(_customAmountController.text) ?? 0;
      return customValue.clamp(0, _maxAmount);
    }
    return _selectedAmount;
  }

  Future<void> _sendDonation() async {
    final amount = _effectiveAmount;

    if (amount < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 10 DT 이상 후원할 수 있습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amount > _maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('최대 $_maxAmount DT까지 후원할 수 있습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('잔액이 부족합니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // Get channel info for creator ID
      final chatState = ref.read(chatProvider(widget.channelId));
      final creatorId = chatState.channel?.artistId ?? '';

      // Send donation via wallet provider
      final donation = await ref.read(walletProvider.notifier).sendDonation(
        channelId: widget.channelId,
        creatorId: creatorId,
        amountDt: amount,
        isAnonymous: _isAnonymous,
      );

      // Send donation message if text provided
      if (_messageController.text.trim().isNotEmpty && donation != null) {
        await ref
            .read(chatProvider(widget.channelId).notifier)
            .sendDonationMessage(
          content: _messageController.text.trim(),
          amountDt: amount,
          donationId: donation['id'] as String,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onDonationSent?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_formatNumber(amount)} DT 후원 완료!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('후원에 실패했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '후원하기',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Row(
                children: [
                  const Icon(Icons.diamond, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.balance} DT',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Amount selection
          Text(
            '금액 선택',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._presetAmounts.map((amount) {
                final isSelected = !_isCustomAmount && _selectedAmount == amount;
                return ChoiceChip(
                  label: Text(_formatNumber(amount)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _isCustomAmount = false;
                        _selectedAmount = amount;
                      });
                    }
                  },
                );
              }),
              // Custom amount chip
              ChoiceChip(
                label: const Text('직접 입력'),
                selected: _isCustomAmount,
                onSelected: (selected) {
                  setState(() {
                    _isCustomAmount = selected;
                  });
                },
              ),
            ],
          ),

          // Custom amount input
          if (_isCustomAmount) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _customAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '후원 금액 (DT)',
                hintText: '10 ~ 1,000,000',
                suffixText: 'DT',
                border: const OutlineInputBorder(),
                helperText: '최소 10 DT, 최대 1,000,000 DT',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 24),

          // Message input
          TextField(
            controller: _messageController,
            maxLength: 100,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: '메시지 (선택)',
              hintText: '아티스트에게 전하고 싶은 말을 적어주세요',
              border: const OutlineInputBorder(),
              counterText: '${_messageController.text.length}/100',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Anonymous option
          CheckboxListTile(
            value: _isAnonymous,
            onChanged: (value) {
              setState(() {
                _isAnonymous = value ?? false;
              });
            },
            title: const Text('익명으로 후원'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),

          // Send button
          FilledButton(
            onPressed: (_isSending || _effectiveAmount < 10) ? null : _sendDonation,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
              minimumSize: const Size.fromHeight(48),
            ),
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('${_formatNumber(_effectiveAmount)} DT 후원하기'),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
