import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/chat_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../data/models/broadcast_message.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_input_bar_v2.dart';

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

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more messages when scrolled to top
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      ref.read(chatProvider(widget.channelId).notifier).loadMoreMessages();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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

    // Show error state
    if (chatState.error != null && chatState.messages.isEmpty) {
      return AppScaffold(
        showStatusBar: true,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                chatState.error!,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  ref.read(chatProvider(widget.channelId).notifier).loadInitialData();
                },
                child: const Text('다시 시도'),
              ),
            ],
          ),
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

            // Messages list
            Expanded(
              child: _buildMessagesList(context, chatState, isDark),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              '아직 메시지가 없습니다',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Newest messages at bottom
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (chatState.hasMoreMessages ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at top
        if (chatState.hasMoreMessages && index == messages.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
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

  const MessageBubbleV2({
    super.key,
    required this.message,
    required this.isArtist,
    this.artistAvatarUrl,
    required this.artistName,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

  Widget _buildArtistBubble(BuildContext context, bool isDark) {
    return Padding(
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
                      if (message.isHighlighted) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.push_pin,
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
    );
  }

  Widget _buildUserBubble(BuildContext context, bool isDark) {
    return Padding(
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
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
      case BroadcastMessageType.voice:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_circle_fill,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            const Text('음성 메시지'),
          ],
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

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? '오후' : '오전';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period $hour:$minute';
  }
}

/// Skeleton loading state
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
                  children: [
                    _SkeletonBox(
                      width: 32,
                      height: 32,
                      isCircle: true,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _SkeletonBox(width: 80, height: 16, isDark: isDark),
                  ],
                ),
              ),
              _SkeletonBox(width: 50, height: 24, isDark: isDark),
            ],
          ),
        ),

        // Messages skeleton
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (int i = 0; i < 5; i++) ...[
                if (i % 2 == 0)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(
                        width: 36,
                        height: 36,
                        isCircle: true,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: _SkeletonBox(
                          width: double.infinity,
                          height: 60,
                          isDark: isDark,
                        ),
                      ),
                      const Spacer(),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Spacer(),
                      Expanded(
                        flex: 2,
                        child: _SkeletonBox(
                          width: double.infinity,
                          height: 40,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),

        // Input bar skeleton
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Row(
            children: [
              _SkeletonBox(width: 24, height: 24, isCircle: true, isDark: isDark),
              const SizedBox(width: 12),
              Expanded(
                child: _SkeletonBox(
                  width: double.infinity,
                  height: 44,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              _SkeletonBox(width: 40, height: 40, isCircle: true, isDark: isDark),
            ],
          ),
        ),
      ],
    );
  }
}

/// Simple skeleton box widget
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final bool isCircle;
  final bool isDark;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.isCircle = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[300],
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(8),
      ),
    );
  }
}
