import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/chat_provider.dart';
import '../../providers/daily_question_set_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../data/models/broadcast_message.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/message_action_sheet.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/error_boundary.dart';
import 'widgets/daily_question_cards_panel.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_input_bar_v2.dart';
import 'widgets/voice_message_widget.dart';

/// Chat thread screen showing 1:1 conversation with an artist
/// Uses Riverpod for state management with Supabase backend
class ChatThreadScreenV2 extends ConsumerStatefulWidget {
  final String channelId;

  const ChatThreadScreenV2({
    super.key,
    required this.channelId,
  });

  @override
  ConsumerState<ChatThreadScreenV2> createState() => _ChatThreadScreenV2State();
}

class _ChatThreadScreenV2State extends ConsumerState<ChatThreadScreenV2>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Setup fade animation for smooth content appearance
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Add scroll listener for pagination and scroll-to-bottom FAB
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more messages when scrolled near the top (with tolerance for floating point)
    final position = _scrollController.position;
    final threshold = 100.0; // pixels from end to trigger load

    if (position.pixels >= position.maxScrollExtent - threshold) {
      ref.read(chatProvider(widget.channelId).notifier).loadMoreMessages();
    }

    // Show/hide scroll-to-bottom button
    final showButton = position.pixels > 300;
    if (showButton != _showScrollToBottom) {
      setState(() => _showScrollToBottom = showButton);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      HapticFeedback.lightImpact();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Message action handlers
  // ═══════════════════════════════════════════════════════════

  void _showMessageActionSheet(BuildContext context, BroadcastMessage message) {
    if (message.deletedAt != null) return; // Can't act on deleted messages

    final isOwnMessage = message.isFromFan;
    final canEdit = isOwnMessage &&
        message.messageType == BroadcastMessageType.text &&
        DateTime.now().difference(message.createdAt).inHours < 24;

    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MessageActionSheet(
        message: message,
        isOwnMessage: isOwnMessage,
        canEdit: canEdit,
        canDelete: isOwnMessage,
        onCopy: () => _copyMessage(message),
        onEdit: canEdit ? () => _showEditDialog(message) : null,
        onDelete: isOwnMessage ? () => _showDeleteConfirmation(message) : null,
        onReact: (emoji) => _reactToMessage(message.id, emoji),
      ),
    );
  }

  void _copyMessage(BroadcastMessage message) {
    if (message.content != null && message.content!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: message.content!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('메시지가 복사되었습니다'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(BroadcastMessage message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('메시지 삭제'),
        content: const Text('이 메시지를 삭제하시겠습니까?\n삭제된 메시지는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '취소',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(chatProvider(widget.channelId).notifier)
                  .deleteMessage(message.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('메시지가 삭제되었습니다'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BroadcastMessage message) {
    final controller = TextEditingController(text: message.content);
    final chatState = ref.read(chatProvider(widget.channelId));
    final characterLimit = chatState.characterLimit;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('메시지 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLength: characterLimit,
                maxLines: 5,
                minLines: 1,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(
                  hintText: '메시지를 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                '취소',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: controller.text.trim().isEmpty ||
                      controller.text.trim() == message.content
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final success = await ref
                          .read(chatProvider(widget.channelId).notifier)
                          .editMessage(message.id, controller.text.trim());
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('메시지가 수정되었습니다'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
              child: const Text('수정'),
            ),
          ],
        ),
      ),
    );
  }

  void _reactToMessage(String messageId, String emoji) {
    ref.read(chatProvider(widget.channelId).notifier).reactToMessage(messageId, emoji);
  }

  Widget _buildPinnedBanner(BuildContext context, ChatState chatState, bool isDark) {
    final pinnedMessages = chatState.messages
        .where((m) => m.isPinned && m.deletedAt == null)
        .toList();

    if (pinnedMessages.isEmpty) return const SizedBox.shrink();

    final latest = pinnedMessages.last;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.06),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.push_pin_rounded,
            size: 16,
            color: AppColors.primary.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '공지',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  latest.content ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (pinnedMessages.length > 1)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${pinnedMessages.length - 1}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatState = ref.watch(chatProvider(widget.channelId));
    final walletState = ref.watch(walletProvider);

    // Start fade animation when data is loaded
    if (!chatState.isLoading && _fadeController.value == 0) {
      _fadeController.forward();
    }

    // Show loading skeleton
    if (chatState.isLoading && chatState.messages.isEmpty) {
      return AppScaffold(
        showStatusBar: true,
        child: _ChatSkeleton(isDark: isDark),
      );
    }

    // Show error state with enterprise ErrorDisplay
    if (chatState.error != null && chatState.messages.isEmpty) {
      return AppScaffold(
        showStatusBar: true,
        child: Column(
          children: [
            // Show header even in error state for navigation
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ErrorDisplay(
                error: chatState.error!,
                title: '메시지를 불러올 수 없습니다',
                icon: Icons.chat_bubble_outline_rounded,
                onRetry: () {
                  HapticFeedback.mediumImpact();
                  ref.read(chatProvider(widget.channelId).notifier).loadInitialData();
                },
              ),
            ),
          ],
        ),
      );
    }

    final channel = chatState.channel;

    return AppScaffold(
      showStatusBar: true,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Header
            _buildHeader(context, chatState, walletState, isDark),

            // Pinned message banner
            _buildPinnedBanner(context, chatState, isDark),

            // Messages list with floating question banner & scroll FAB
            Expanded(
              child: Stack(
                children: [
                  _buildMessagesList(context, chatState, isDark),

                  // Floating question banner (top)
                  Positioned(
                    top: 8,
                    left: 12,
                    right: 12,
                    child: _QuestionBannerV2(
                      channelId: widget.channelId,
                    ),
                  ),

                  // Scroll to bottom FAB
                  if (_showScrollToBottom)
                    Positioned(
                      right: 16,
                      bottom: 12,
                      child: AnimatedOpacity(
                        opacity: _showScrollToBottom ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: GestureDetector(
                          onTap: _scrollToBottom,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDark.withValues(alpha: 0.95)
                                  : Colors.white.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                width: 0.5,
                              ),
                            ),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Input bar
            ChatInputBarV2(
              channelId: widget.channelId,
              onMessageSent: _scrollToBottom,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ChatState chatState,
    WalletState walletState,
    bool isDark,
  ) {
    final channel = chatState.channel;

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
          // Back Button
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              size: 20,
            ),
          ),

          // Artist Info
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    ClipOval(
                      child: channel?.avatarUrl != null
                          ? CachedNetworkImage(
                              imageUrl: channel!.avatarUrl!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                width: 32,
                                height: 32,
                                color: isDark ? Colors.grey[700] : Colors.grey[300],
                              ),
                            )
                          : Container(
                              width: 32,
                              height: 32,
                              color: isDark ? Colors.grey[700] : Colors.grey[300],
                              child: const Icon(Icons.person, size: 20),
                            ),
                    ),
                    // Online indicator
                    if (chatState.onlineUsers.containsKey(channel?.artistId))
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.online,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.backgroundDark
                                  : Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  channel?.name ?? '채널',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(width: 4),
                // Subscription tier badge
                if (chatState.subscription != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getTierColors(chatState.subscription!.tier),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      chatState.subscription!.tier,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // DT Balance
          GestureDetector(
            onTap: () => context.push('/wallet'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.diamond,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    walletState.wallet?.formattedBalance ?? '0',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(
    BuildContext context,
    ChatState chatState,
    bool isDark,
  ) {
    final messages = chatState.messages;

    if (messages.isEmpty) {
      return EmptyState(
        title: '아직 메시지가 없습니다',
        message: '아티스트의 첫 메시지를 기다려보세요!',
        icon: Icons.chat_bubble_outline_rounded,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Newest messages at bottom
      padding: const EdgeInsets.fromLTRB(16, 70, 16, 16),
      itemCount: messages.length + (chatState.hasMoreMessages ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading skeleton at top when loading more
        if (chatState.hasMoreMessages && index == messages.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: const [
                SkeletonMessageBubble(isFromArtist: true, width: 180),
                SizedBox(height: 12),
                SkeletonMessageBubble(isFromArtist: false, width: 140),
              ],
            ),
          );
        }

        final message = messages[messages.length - 1 - index];
        final previousMessage = index < messages.length - 1
            ? messages[messages.length - 2 - index]
            : null;

        // Date separator
        Widget? dateSeparator;
        if (_shouldShowDateSeparator(message, previousMessage)) {
          dateSeparator = _buildDateSeparator(message.createdAt, isDark);
        }

        return Column(
          children: [
            if (dateSeparator != null) dateSeparator,
            MessageBubbleV2(
              message: message,
              isArtist: message.isFromArtist,
              artistAvatarUrl: chatState.channel?.avatarUrl,
              artistName: chatState.channel?.name ?? '',
              showAvatar: _shouldShowAvatar(message, previousMessage),
              onLongPress: () => _showMessageActionSheet(context, message),
              onReact: (emoji) => _reactToMessage(message.id, emoji),
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowDateSeparator(
    BroadcastMessage current,
    BroadcastMessage? previous,
  ) {
    if (previous == null) return true;

    final currentDate = DateTime(
      current.createdAt.year,
      current.createdAt.month,
      current.createdAt.day,
    );
    final previousDate = DateTime(
      previous.createdAt.year,
      previous.createdAt.month,
      previous.createdAt.day,
    );

    return currentDate != previousDate;
  }

  bool _shouldShowAvatar(
    BroadcastMessage current,
    BroadcastMessage? previous,
  ) {
    if (!current.isFromArtist) return false;
    if (previous == null) return true;
    if (!previous.isFromArtist) return true;

    // Don't show avatar if same sender within 1 minute
    final timeDiff = current.createdAt.difference(previous.createdAt).inMinutes;
    return timeDiff > 1;
  }

  Widget _buildDateSeparator(DateTime date, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = '오늘';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateText = '어제';
    } else {
      dateText = '${date.month}월 ${date.day}일';
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          dateText,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
        ),
      ),
    );
  }

  List<Color> _getTierColors(String tier) {
    switch (tier.toUpperCase()) {
      case 'VIP':
        return [const Color(0xFFFEF08A), const Color(0xFFFCD34D)];
      case 'STANDARD':
        return [const Color(0xFFD1FAE5), const Color(0xFF6EE7B7)];
      case 'BASIC':
        return [const Color(0xFFE0E7FF), const Color(0xFFA5B4FC)];
      default:
        return [Colors.grey[300]!, Colors.grey[400]!];
    }
  }
}

/// Updated message bubble supporting new message model
class MessageBubbleV2 extends StatelessWidget {
  final BroadcastMessage message;
  final bool isArtist;
  final String? artistAvatarUrl;
  final String artistName;
  final bool showAvatar;
  final VoidCallback? onLongPress;
  final Function(String emoji)? onReact;

  const MessageBubbleV2({
    super.key,
    required this.message,
    required this.isArtist,
    this.artistAvatarUrl,
    required this.artistName,
    this.showAvatar = true,
    this.onLongPress,
    this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Deleted message placeholder
    if (message.deletedAt != null) {
      return _buildDeletedBubble(context, isDark);
    }

    // Donation message styling
    if (message.isDonation) {
      return _buildDonationBubble(context, isDark);
    }

    if (isArtist) {
      return _buildArtistBubble(context, isDark);
    } else {
      return _buildUserBubble(context, isDark);
    }
  }

  Widget _buildDeletedBubble(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isArtist ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isArtist) const SizedBox(width: 44),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.block_rounded,
                  size: 14,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                const SizedBox(width: 6),
                Text(
                  '삭제된 메시지입니다',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          if (!isArtist) const SizedBox(width: 0),
        ],
      ),
    );
  }

  Widget _buildArtistBubble(BuildContext context, bool isDark) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAvatar)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipOval(
                  child: artistAvatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: artistAvatarUrl!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 36,
                          height: 36,
                          color: Colors.grey,
                          child: const Icon(Icons.person, size: 20),
                        ),
                ),
              )
            else
              const SizedBox(width: 44),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showAvatar)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        artistName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2D2D2D) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _buildContent(context, isDark),
                  ),
                  // Reactions bar
                  if (message.reactions != null && message.reactions!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: MessageReactionsBar(
                        reactions: message.reactions,
                        onTapReaction: onReact,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.textSubDark
                                : AppColors.textSubLight,
                          ),
                        ),
                        if (message.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(수정됨)',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ),
                        ],
                        if (message.isPinned || message.isHighlighted) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.push_pin_rounded,
                            size: 10,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 60), // Space for alignment
          ],
        ),
      ),
    );
  }

  Widget _buildUserBubble(BuildContext context, bool isDark) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(width: 60), // Space for alignment
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message.content ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Reactions bar
                  if (message.reactions != null && message.reactions!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: MessageReactionsBar(
                        reactions: message.reactions,
                        onTapReaction: onReact,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.isEdited) ...[
                          Text(
                            '(수정됨)',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (message.isRead == true) ...[
                          const Icon(
                            Icons.done_all,
                            size: 12,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
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
          ],
        ),
      ),
    );
  }

  Widget _buildDonationBubble(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFEE2E2).withValues(alpha: 0.5),
            const Color(0xFFFCE7F3).withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF9A8D4).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.favorite,
                color: Color(0xFFEC4899),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${message.senderName ?? '팬'}님이 ${message.donationAmount} DT 후원',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFBE185D),
                ),
              ),
            ],
          ),
          if (message.content != null && message.content!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message.content!,
              style: TextStyle(
                color: isDark ? Colors.grey[200] : Colors.grey[800],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    switch (message.messageType) {
      case BroadcastMessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: message.mediaUrl!,
            width: 200,
            fit: BoxFit.cover,
          ),
        );
      case BroadcastMessageType.video:
        // 동영상 썸네일 + 재생 버튼 오버레이
        final thumbnailUrl = message.mediaMetadata?['thumbnail_url'] as String?;
        return GestureDetector(
          onTap: () => _playVideo(context, message.mediaUrl!),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (thumbnailUrl != null)
                  CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    width: 200,
                    height: 150,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    width: 200,
                    height: 150,
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                    child: Icon(
                      Icons.videocam,
                      size: 48,
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                    ),
                  ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                // 동영상 길이 표시 (있는 경우)
                if (message.mediaMetadata?['duration'] != null)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(message.mediaMetadata!['duration'] as int),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      case BroadcastMessageType.voice:
        return VoiceMessageWidget(
          voiceUrl: message.mediaUrl!,
          durationSeconds: message.mediaMetadata?['duration'] as int?,
          isFromArtist: message.isFromArtist,
        );
      default:
        return Text(
          message.content ?? '',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        );
    }
  }

  void _playVideo(BuildContext context, String videoUrl) {
    // TODO: 전체화면 비디오 플레이어로 이동
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('동영상 재생'),
        content: const Text('동영상 플레이어 구현 예정'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? '오후' : '오전';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period $hour:$minute';
  }
}

/// Skeleton loading state using enterprise SkeletonLoader components
class _ChatSkeleton extends StatelessWidget {
  final bool isDark;

  const _ChatSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header skeleton
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          ),
          child: Row(
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SkeletonLoader.circle(size: 32),
                    SizedBox(width: 8),
                    SkeletonLoader.text(width: 80, height: 16),
                  ],
                ),
              ),
              const SkeletonLoader(width: 50, height: 24),
            ],
          ),
        ),

        // Messages skeleton
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              SkeletonMessageBubble(isFromArtist: true, width: 220),
              SizedBox(height: 16),
              SkeletonMessageBubble(isFromArtist: false, width: 160),
              SizedBox(height: 16),
              SkeletonMessageBubble(isFromArtist: true, width: 180),
              SizedBox(height: 16),
              SkeletonMessageBubble(isFromArtist: false, width: 140),
              SizedBox(height: 16),
              SkeletonMessageBubble(isFromArtist: true, width: 200),
            ],
          ),
        ),

        // Input bar skeleton
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Row(
            children: const [
              SkeletonLoader.circle(size: 24),
              SizedBox(width: 12),
              Expanded(
                child: SkeletonLoader(width: double.infinity, height: 44),
              ),
              SizedBox(width: 12),
              SkeletonLoader.circle(size: 40),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Daily Question Mini Banner
// ═══════════════════════════════════════════════════════════

/// Mini banner for daily question cards - tappable to expand
class _QuestionBannerV2 extends ConsumerStatefulWidget {
  final String channelId;

  const _QuestionBannerV2({required this.channelId});

  @override
  ConsumerState<_QuestionBannerV2> createState() => _QuestionBannerV2State();
}

class _QuestionBannerV2State extends ConsumerState<_QuestionBannerV2> {
  bool _loadAttempted = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestions();
    });
  }

  void _loadQuestions() {
    if (!mounted) return;
    _loadAttempted = true;
    ref.read(dailyQuestionSetProvider(widget.channelId).notifier).load();
  }

  void _showQuestionSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Question cards panel (full version)
            DailyQuestionCardsPanel(
              channelId: widget.channelId,
              compact: false,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyQuestionSetProvider(widget.channelId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dismissed by user
    if (_dismissed) return const SizedBox.shrink();

    // Loading & initial: hide (loading is very brief ~300ms)
    if (state is DailyQuestionSetLoading || state is DailyQuestionSetInitial) {
      if (state is DailyQuestionSetInitial && !_loadAttempted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadQuestions();
        });
      }
      return const SizedBox.shrink();
    }

    // Error state - hide (don't clutter UI)
    if (state is DailyQuestionSetError) {
      return const SizedBox.shrink();
    }

    // Get the set data
    final set = switch (state) {
      DailyQuestionSetLoaded(set: final s) => s,
      DailyQuestionSetVoting(set: final s) => s,
      _ => null,
    };

    if (set == null) return const SizedBox.shrink();

    final hasVoted = set.hasVoted;
    final winningCard = set.winningCard;

    return GestureDetector(
      onTap: _showQuestionSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: hasVoted
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: isDark
                      ? [const Color(0xFF2A1515), const Color(0xFF1E1212)]
                      : [const Color(0xFFFFF0F0), const Color(0xFFFFE8E8)],
                )
              : LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: isDark
                      ? [
                          AppColors.primary500.withValues(alpha: 0.22),
                          AppColors.primary500.withValues(alpha: 0.12),
                        ]
                      : [
                          AppColors.primary500.withValues(alpha: 0.10),
                          AppColors.primary500.withValues(alpha: 0.05),
                        ],
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary500.withValues(alpha: isDark ? 0.45 : 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary500.withValues(alpha: isDark ? 0.25 : 0.10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji icon with colored background
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: hasVoted
                    ? AppColors.primary500.withValues(alpha: 0.2)
                    : AppColors.primary500.withValues(alpha: isDark ? 0.25 : 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  hasVoted ? '✅' : '🗳️',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasVoted ? '투표 완료!' : '오늘의 질문 투표하기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: hasVoted
                          ? AppColors.primary500
                          : (isDark ? Colors.white : AppColors.textMainLight),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasVoted
                        ? '1위: ${winningCard?.cardText ?? ''}'
                        : '마음에 드는 질문에 투표해 주세요',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasVoted
                          ? AppColors.primary500.withValues(alpha: 0.7)
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Right side badge - prominent
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary500,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${set.totalVotes}명',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),

            // Dismiss (X) button
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  _dismissed = true;
                });
              },
              behavior: HitTestBehavior.opaque,
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
      ),
    );
  }
}
