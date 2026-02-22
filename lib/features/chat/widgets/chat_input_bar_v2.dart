import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_gate.dart';
import '../../../data/models/broadcast_message.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../services/media_service.dart';
import '../../../services/voice_service.dart';

/// Chat input bar with Riverpod state management
class ChatInputBarV2 extends ConsumerStatefulWidget {
  final String channelId;
  final VoidCallback? onMessageSent;
  final Color? accentColor;

  const ChatInputBarV2({
    super.key,
    required this.channelId,
    this.onMessageSent,
    this.accentColor,
  });

  @override
  ConsumerState<ChatInputBarV2> createState() => _ChatInputBarV2State();
}

class _ChatInputBarV2State extends ConsumerState<ChatInputBarV2> {
  late final TextEditingController _controller;
  final MediaService _mediaService = MediaService();
  final VoiceRecordingService _voiceService = VoiceRecordingService();
  bool _isComposing = false;
  bool _isSending = false;
  bool _isMediaMenuOpen = false;
  bool _isRecording = false;
  String? _failedMessageText;
  int _recordingDuration = 0;
  StreamSubscription<int>? _durationSub;
  StreamSubscription<VoiceRecordingState>? _stateSub;
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
    _durationSub?.cancel();
    _stateSub?.cancel();
    _voiceService.dispose();
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

    AuthGate.guardAction(
      context,
      reason: '메시지를 보내려면 로그인이 필요해요',
      onAuthenticated: () => _doSendMessage(text),
    );
  }

  Future<void> _doSendMessage(String text) async {
    // Validate character limit before sending
    final chatState = ref.read(chatProvider(widget.channelId));
    if (text.length > chatState.characterLimit) {
      _showError('글자 수 제한(${chatState.characterLimit}자)을 초과했습니다.');
      return;
    }

    setState(() {
      _isSending = true;
      _failedMessageText = null;
    });

    // Check connectivity first
    final connectivities = await Connectivity().checkConnectivity();
    if (connectivities.contains(ConnectivityResult.none)) {
      setState(() {
        _isSending = false;
        _failedMessageText = text;
      });
      _showOfflineWarning();
      return;
    }

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
        setState(() => _failedMessageText = text);
        _showRetrySnackbar(text, '메시지 전송에 실패했습니다.');
      }
    } catch (e) {
      setState(() => _failedMessageText = text);
      _showRetrySnackbar(text, '메시지 전송 중 오류가 발생했습니다.');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _toggleMediaMenu() {
    setState(() {
      _isMediaMenuOpen = !_isMediaMenuOpen;
    });
  }

  // ── Voice recording ──

  Future<void> _startVoiceRecording() async {
    setState(() {
      _isMediaMenuOpen = false;
    });

    if (kIsWeb) {
      _showError('웹에서는 음성 녹음이 지원되지 않습니다.');
      return;
    }

    final hasPermission = await _voiceService.hasPermission();
    if (!hasPermission) {
      _showError('마이크 권한이 필요합니다.');
      return;
    }

    final started = await _voiceService.startRecording();
    if (!started) {
      _showError('녹음을 시작할 수 없습니다.');
      return;
    }

    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });

    _durationSub = _voiceService.durationStream.listen((seconds) {
      if (mounted) {
        setState(() {
          _recordingDuration = seconds;
        });
      }
    });

    _stateSub = _voiceService.stateStream.listen((state) {
      if (state == VoiceRecordingState.idle && mounted) {
        setState(() {
          _isRecording = false;
        });
      }
    });
  }

  Future<void> _stopAndSendVoice() async {
    final result = await _voiceService.stopRecording();
    _durationSub?.cancel();
    _stateSub?.cancel();
    setState(() {
      _isRecording = false;
    });

    if (result == null) {
      _showError('녹음에 실패했습니다.');
      return;
    }

    setState(() {
      _isSending = true;
    });
    try {
      final userId =
          ref.read(chatProvider(widget.channelId)).subscription?.userId ?? '';
      if (userId.isEmpty) {
        _showError('로그인이 필요합니다.');
        return;
      }

      final uploaded = await _mediaService.uploadVoice(
        result.toXFile(),
        channelId: widget.channelId,
        userId: userId,
        durationSeconds: result.durationSeconds,
      );

      if (uploaded != null) {
        await ref
            .read(chatProvider(widget.channelId).notifier)
            .sendMediaMessage(
              mediaUrl: uploaded.mainUrl,
              messageType: 'voice',
              mediaMetadata: uploaded.metadata,
            );
        widget.onMessageSent?.call();
      }
    } catch (e) {
      _showError('음성 메시지 전송에 실패했습니다.');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _cancelVoiceRecording() async {
    await _voiceService.cancelRecording();
    _durationSub?.cancel();
    _stateSub?.cancel();
    setState(() {
      _isRecording = false;
    });
  }

  // ── Video pick & send ──

  Future<void> _pickAndSendVideo(
      {ImageSource source = ImageSource.gallery}) async {
    setState(() {
      _isMediaMenuOpen = false;
    });

    final video = await _mediaService.pickVideo(source: source);
    if (video == null) return;

    // Validate
    final validation = await _mediaService.validateVideo(video);
    if (!validation.isValid) {
      _showError(validation.errorMessage ?? '동영상 검증 실패');
      return;
    }

    setState(() {
      _isSending = true;
    });
    try {
      final userId =
          ref.read(chatProvider(widget.channelId)).subscription?.userId ?? '';
      if (userId.isEmpty) {
        _showError('로그인이 필요합니다.');
        return;
      }

      final uploaded = await _mediaService.uploadVideo(
        video,
        channelId: widget.channelId,
        userId: userId,
      );

      if (uploaded != null) {
        await ref
            .read(chatProvider(widget.channelId).notifier)
            .sendMediaMessage(
              mediaUrl: uploaded.mainUrl,
              messageType: 'video',
              mediaMetadata: uploaded.metadata,
            );
        widget.onMessageSent?.call();
      }
    } catch (e) {
      _showError('동영상 전송에 실패했습니다.');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _pickAndSendImage() async {
    setState(() {
      _isMediaMenuOpen = false;
    });
    final image = await _mediaService.pickImage();
    if (image == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      final userId =
          ref.read(chatProvider(widget.channelId)).subscription?.userId ?? '';
      if (userId.isEmpty) {
        _showError('로그인이 필요합니다.');
        return;
      }

      // Upload image
      final result = await _mediaService.uploadMedia(
        image,
        channelId: widget.channelId,
        userId: userId,
      );

      if (result != null) {
        await ref
            .read(chatProvider(widget.channelId).notifier)
            .sendMediaMessage(
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

  Widget _buildVoiceRecordingBar(bool isDark) {
    final minutes = _recordingDuration ~/ 60;
    final seconds = _recordingDuration % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Row(
      children: [
        // Cancel button
        IconButton(
          onPressed: _cancelVoiceRecording,
          icon: Icon(
            Icons.delete_outline,
            color: Colors.red[400],
            size: 24,
          ),
          tooltip: '취소',
        ),

        // Recording indicator + timer
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing red dot
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (_, value, child) => Opacity(
                    opacity: value,
                    child: child,
                  ),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '녹음 중  $timeStr',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.red[300] : Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Send button
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: widget.accentColor ?? AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _stopAndSendVoice,
            icon: const Icon(
              Icons.send,
              color: Colors.white,
              size: 20,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
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

  void _showOfflineWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('네트워크 연결을 확인해 주세요'),
          ],
        ),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: '재시도',
          textColor: Colors.white,
          onPressed: () {
            if (_failedMessageText != null) {
              _doSendMessage(_failedMessageText!);
            }
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showRetrySnackbar(String text, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: '재시도',
          textColor: Colors.white,
          onPressed: () => _doSendMessage(text),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accentColor ?? AppColors.primary;
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
          // Reply-to preview bar (KakaoTalk style)
          if (chatState.replyingToMessage != null)
            _ReplyPreviewBar(
              message: chatState.replyingToMessage!,
              isDark: isDark,
              accentColor: accent,
              onCancel: () {
                ref
                    .read(chatProvider(widget.channelId).notifier)
                    .clearReplyTo();
              },
            ),

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
                        color: accent,
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
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+1 대기',
                            style: TextStyle(
                              fontSize: 10,
                              color: accent,
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

          // Expandable media menu
          if (_isMediaMenuOpen)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MediaMenuButton(
                    icon: Icons.photo_library_outlined,
                    label: '사진',
                    color: AppColors.success,
                    isDark: isDark,
                    onTap: _isSending ? null : _pickAndSendImage,
                  ),
                  _MediaMenuButton(
                    icon: Icons.videocam_outlined,
                    label: '동영상',
                    color: AppColors.verified,
                    isDark: isDark,
                    onTap: _isSending ? null : _pickAndSendVideo,
                  ),
                  _MediaMenuButton(
                    icon: Icons.mic_outlined,
                    label: '음성',
                    color: AppColors.warning,
                    isDark: isDark,
                    onTap: _isSending ? null : _startVoiceRecording,
                  ),
                  _MediaMenuButton(
                    icon: Icons.favorite_border,
                    label: '후원',
                    color: AppColors.primary,
                    isDark: isDark,
                    onTap: _showDonationSheet,
                  ),
                ],
              ),
            ),

          // Input row (or voice recording bar)
          if (_isRecording)
            _buildVoiceRecordingBar(isDark)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // + / X toggle button
                IconButton(
                  onPressed: _toggleMediaMenu,
                  icon: AnimatedRotation(
                    turns: _isMediaMenuOpen ? 0.125 : 0, // 45도 회전 → X 모양
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.add,
                      color: _isMediaMenuOpen
                          ? accent
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      size: 26,
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
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
                      buildCounter: (_,
                              {required currentLength,
                              required isFocused,
                              maxLength}) =>
                          null,
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
                                ? accent
                                : isDark
                                    ? Colors.grey[700]
                                    : Colors.grey[300],
                            shape: const CircleBorder(),
                          ),
                          icon: Icon(
                            Icons.send,
                            color:
                                _isComposing ? Colors.white : Colors.grey[500],
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
        const SnackBar(
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
      if (!mounted) return;
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
                final isSelected =
                    !_isCustomAmount && _selectedAmount == amount;
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
              decoration: const InputDecoration(
                labelText: '후원 금액 (DT)',
                hintText: '10 ~ 1,000,000',
                suffixText: 'DT',
                border: OutlineInputBorder(),
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
            onPressed:
                (_isSending || _effectiveAmount < 10) ? null : _sendDonation,
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

/// Media menu button (used in expandable + menu)
class _MediaMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const _MediaMenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reply preview bar shown above input when replying to a message
class _ReplyPreviewBar extends StatelessWidget {
  final BroadcastMessage message;
  final bool isDark;
  final Color accentColor;
  final VoidCallback onCancel;

  const _ReplyPreviewBar({
    required this.message,
    required this.isDark,
    required this.accentColor,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final senderName = message.isFromArtist
        ? (message.senderName ?? '아티스트')
        : (message.senderName ?? '나');
    final previewText = message.content ??
        (message.messageType == BroadcastMessageType.image
            ? '사진'
            : message.messageType == BroadcastMessageType.video
                ? '동영상'
                : message.messageType == BroadcastMessageType.voice
                    ? '음성 메시지'
                    : '메시지');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark
            ? accentColor.withValues(alpha: 0.08)
            : accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: accentColor,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply_rounded,
            size: 16,
            color: accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  previewText.length > 50
                      ? '${previewText.substring(0, 50)}...'
                      : previewText,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
