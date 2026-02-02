import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/premium_effects.dart';
import '../../data/models/broadcast_message.dart';
import '../../data/repositories/mock_chat_repository.dart';
import '../../shared/widgets/app_scaffold.dart';

/// Broadcast Compose Screen
/// Artist uses this to send messages to all subscribers
class BroadcastComposeScreen extends StatefulWidget {
  final String? channelId;

  const BroadcastComposeScreen({
    super.key,
    this.channelId,
  });

  @override
  State<BroadcastComposeScreen> createState() => _BroadcastComposeScreenState();
}

class _BroadcastComposeScreenState extends State<BroadcastComposeScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final MockArtistInboxRepository _repository = MockArtistInboxRepository();

  bool _isSending = false;
  BroadcastMessageType _messageType = BroadcastMessageType.text;
  String? _mediaUrl;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _canSend => _controller.text.trim().isNotEmpty && !_isSending;

  Future<void> _sendBroadcast() async {
    if (!_canSend) return;

    setState(() => _isSending = true);

    try {
      await _repository.sendBroadcast(
        widget.channelId ?? 'channel_1',
        _controller.text.trim(),
        messageType: _messageType,
        mediaUrl: _mediaUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('메시지가 전송되었습니다'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('전송 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      showStatusBar: true,
      child: Column(
        children: [
          // Header
          _buildHeader(context, isDark),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  _buildInfoCard(isDark),
                  const SizedBox(height: 24),

                  // Message type selector
                  _buildMessageTypeSelector(isDark),
                  const SizedBox(height: 16),

                  // Text input
                  _buildTextInput(isDark),
                ],
              ),
            ),
          ),

          // Bottom CTA
          _buildBottomCTA(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark.withValues(alpha: 0.95)
            : AppColors.backgroundLight.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.close,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          Expanded(
            child: Text(
              '메시지 보내기',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary500.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.campaign_outlined,
            color: AppColors.primary600,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '모든 구독자에게 전송됩니다',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '메시지를 보내면 구독자들에게 답장 토큰 3개가 지급됩니다',
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
    );
  }

  Widget _buildMessageTypeSelector(bool isDark) {
    return Row(
      children: [
        _TypeChip(
          icon: Icons.text_fields,
          label: '텍스트',
          isSelected: _messageType == BroadcastMessageType.text,
          onTap: () => setState(() => _messageType = BroadcastMessageType.text),
        ),
        const SizedBox(width: 8),
        _TypeChip(
          icon: Icons.image,
          label: '사진',
          isSelected: _messageType == BroadcastMessageType.image,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('사진 첨부 기능은 준비 중입니다')),
            );
          },
        ),
        const SizedBox(width: 8),
        _TypeChip(
          icon: Icons.mic,
          label: '음성',
          isSelected: _messageType == BroadcastMessageType.voice,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('음성 메시지 기능은 준비 중입니다')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTextInput(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: 10,
        minLines: 5,
        decoration: InputDecoration(
          hintText: '팬들에게 전할 메시지를 입력하세요...',
          hintStyle: TextStyle(
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
        ),
      ),
    );
  }

  Widget _buildBottomCTA(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Character count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_controller.text.length}자',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 14,
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '1,250명에게 전송',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Send button
            SizedBox(
              width: double.infinity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  boxShadow: _canSend ? [PremiumEffects.subtleGlow] : null,
                ),
                child: ElevatedButton(
                  onPressed: _canSend ? _sendBroadcast : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    disabledBackgroundColor:
                        isDark ? Colors.grey[800] : Colors.grey[300],
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '메시지 보내기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary500
              : (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
