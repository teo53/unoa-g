import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_list_provider.dart';
import '../../data/models/broadcast_message.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/push_permission_prompt.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_input_bar_v2.dart';
import 'widgets/voice_message_widget.dart';
import 'widgets/message_actions_sheet.dart';
import 'widgets/message_edit_dialog.dart';
import 'widgets/report_dialog.dart';
import 'widgets/daily_question_cards_panel.dart';
import 'widgets/chat_search_bar.dart';
import 'widgets/highlighted_text.dart';
import 'widgets/media_gallery_sheet.dart';
import 'widgets/full_screen_image_viewer.dart';
import '../private_card/widgets/private_card_bubble.dart';

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

  // Search state
  bool _isSearchActive = false;
  String _searchQuery = '';
  List<int> _searchMatchIndices = [];
  int _currentSearchMatchIndex = -1;

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

    // Show push notification prompt on first chat entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPushPermissionPrompt();
    });
  }

  Future<void> _checkPushPermissionPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasShown = prefs.getBool('push_prompt_shown') ?? false;
      if (!hasShown && mounted) {
        await prefs.setBool('push_prompt_shown', true);
        if (mounted) {
          PushPermissionPrompt.show(context);
        }
      }
    } catch (_) {
      // SharedPreferences may not be available
    }
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
    final isCreator = ref.watch(isCreatorProvider);
    final accentColor = ref.watch(
        artistThemeColorByChannelProvider(widget.channelId));

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
            // Header or Search Bar
            _isSearchActive
                ? ChatSearchBar(
                    matchCount: _searchMatchIndices.length,
                    currentMatch: _currentSearchMatchIndex,
                    onQueryChanged: _onSearchQueryChanged,
                    onNavigate: _onSearchNavigate,
                    onClose: _onSearchClose,
                  )
                : _buildHeader(context, chatState, isDark),

            // Daily question cards panel (fan only)
            if (!isCreator)
              DailyQuestionCardsPanel(
                channelId: widget.channelId,
                compact: true,
                accentColor: accentColor,
              ),

            // Messages list
            Expanded(
              child: _buildMessagesList(context, chatState, isDark, accentColor: accentColor),
            ),

            // Input bar
            ChatInputBarV2(
              channelId: widget.channelId,
              onMessageSent: _scrollToBottom,
              accentColor: accentColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ChatState chatState,
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

          // Artist Info (tappable → artist profile)
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/artist/${channel?.artistId ?? widget.channelId}'),
              behavior: HitTestBehavior.opaque,
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
          ),

          // Search button
          IconButton(
            onPressed: () => setState(() { _isSearchActive = true; }),
            icon: Icon(
              Icons.search,
              size: 22,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
            tooltip: '메시지 검색',
          ),

          // Media gallery / hamburger menu button
          IconButton(
            onPressed: () => MediaGallerySheet.show(
              context: context,
              channelId: widget.channelId,
            ),
            icon: Icon(
              Icons.menu,
              size: 22,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
            tooltip: '미디어 모아보기',
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(
    BuildContext context,
    ChatState chatState,
    bool isDark, {
    Color accentColor = AppColors.primary,
  }) {
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

        // Check if this message belongs to the current user
        final authState = ref.read(authProvider);
        String? currentUserId;
        if (authState is AuthAuthenticated) {
          currentUserId = authState.user.id;
        } else if (authState is AuthDemoMode) {
          currentUserId = authState.demoProfile.id;
        }
        final isOwnMessage = message.senderId == currentUserId;

        // Private card messages get special bubble
        final isPrivateCard = message.deliveryScope == DeliveryScope.privateCard;

        return Column(
          children: [
            if (dateSeparator != null) dateSeparator,
            if (isPrivateCard)
              PrivateCardBubble(
                message: message,
              )
            else
              MessageBubbleV2(
                message: message,
                isArtist: message.isFromArtist,
                artistAvatarUrl: chatState.channel?.avatarUrl,
                artistName: chatState.channel?.name ?? '',
                showAvatar: _shouldShowAvatar(message, previousMessage),
                isOwnMessage: isOwnMessage,
                searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
                allMessages: messages,
                accentColor: accentColor,
                onLongPress: () => _showMessageActions(
                  context,
                  message,
                  isOwnMessage,
                ),
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

  // ── Search Methods ──────────────────────────────────────

  void _onSearchQueryChanged(String query) {
    setState(() {
      _searchQuery = query;
      _searchMatchIndices = [];
      _currentSearchMatchIndex = -1;
      if (query.isNotEmpty) {
        final messages = ref.read(chatProvider(widget.channelId)).messages;
        for (int i = 0; i < messages.length; i++) {
          if (messages[i].content?.toLowerCase().contains(query.toLowerCase()) ?? false) {
            _searchMatchIndices.add(i);
          }
        }
        if (_searchMatchIndices.isNotEmpty) {
          _currentSearchMatchIndex = 0;
        }
      }
    });
    if (_searchMatchIndices.isNotEmpty) {
      _scrollToCurrentMatch();
    }
  }

  void _onSearchNavigate(int direction) {
    if (_searchMatchIndices.isEmpty) return;
    setState(() {
      _currentSearchMatchIndex = (_currentSearchMatchIndex + direction)
          .clamp(0, _searchMatchIndices.length - 1);
    });
    _scrollToCurrentMatch();
  }

  void _scrollToCurrentMatch() {
    if (_currentSearchMatchIndex < 0 || _searchMatchIndices.isEmpty) return;
    final msgIndex = _searchMatchIndices[_currentSearchMatchIndex];
    // ListView is reverse:true, so index 0 = newest at bottom
    // Estimate offset based on message position
    final estimatedOffset = msgIndex * 80.0;
    _scrollController.animateTo(
      estimatedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onSearchClose() {
    setState(() {
      _isSearchActive = false;
      _searchQuery = '';
      _searchMatchIndices = [];
      _currentSearchMatchIndex = -1;
    });
  }

  /// Show message actions sheet (reply, edit, delete, report, block)
  void _showMessageActions(
    BuildContext context,
    BroadcastMessage message,
    bool isOwnMessage,
  ) {
    // Don't show actions for deleted messages
    if (message.deletedAt != null) return;

    MessageActionsSheet.show(
      context: context,
      message: message,
      isOwnMessage: isOwnMessage,
      onReply: () => _handleReplyToMessage(message),
      onEdit: isOwnMessage ? () => _handleEditMessage(context, message) : null,
      onDelete: isOwnMessage ? () => _handleDeleteMessage(message) : null,
      onReport: !isOwnMessage ? _handleReportMessage : null,
      onBlock: !isOwnMessage ? () => _handleBlockUser(message.senderId) : null,
    );
  }

  /// Handle reply to message
  void _handleReplyToMessage(BroadcastMessage message) {
    ref.read(chatProvider(widget.channelId).notifier).setReplyTo(message);
  }

  /// Handle edit message
  void _handleEditMessage(BuildContext context, BroadcastMessage message) {
    MessageEditDialog.show(
      context: context,
      message: message,
      maxCharacters: 300, // Based on subscription, can be dynamic
      onEdit: (newContent) async {
        // TODO: Call repository to update message
        await ref.read(chatProvider(widget.channelId).notifier)
            .editMessage(message.id, newContent);
      },
    );
  }

  /// Handle delete message
  void _handleDeleteMessage(BroadcastMessage message) {
    // The delete confirmation is already shown in MessageActionsSheet
    ref.read(chatProvider(widget.channelId).notifier)
        .deleteMessage(message.id);
  }

  /// Handle report message
  Future<void> _handleReportMessage(
    ReportReason reason,
    String? description,
  ) async {
    // TODO: Call repository to submit report
    debugPrint('Report submitted: $reason - $description');
  }

  /// Handle block user
  void _handleBlockUser(String userId) {
    // TODO: Call repository to block user
    debugPrint('Blocking user: $userId');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('사용자를 차단했습니다'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Updated message bubble supporting new message model
class MessageBubbleV2 extends StatelessWidget {
  final BroadcastMessage message;
  final bool isArtist;
  final String? artistAvatarUrl;
  final String artistName;
  final bool showAvatar;
  final bool isOwnMessage;
  final VoidCallback? onLongPress;
  final String? searchQuery;
  final List<BroadcastMessage> allMessages;
  final Color accentColor;

  const MessageBubbleV2({
    super.key,
    required this.message,
    required this.isArtist,
    this.artistAvatarUrl,
    required this.artistName,
    this.showAvatar = true,
    this.isOwnMessage = false,
    this.onLongPress,
    this.searchQuery,
    this.allMessages = const [],
    this.accentColor = AppColors.primary,
  });

  /// Find the replied-to message from allMessages
  BroadcastMessage? get _repliedToMessage {
    if (message.replyToMessageId == null) return null;
    try {
      return allMessages.firstWhere((m) => m.id == message.replyToMessageId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Deleted message shows placeholder
    if (message.deletedAt != null) {
      return _buildDeletedBubble(context, isDark);
    }

    // Donation message styling
    if (message.isDonation) {
      return GestureDetector(
        onLongPress: onLongPress,
        child: _buildDonationBubble(context, isDark),
      );
    }

    if (isArtist) {
      return GestureDetector(
        onLongPress: onLongPress,
        child: _buildArtistBubble(context, isDark),
      );
    } else {
      return GestureDetector(
        onLongPress: onLongPress,
        child: _buildUserBubble(context, isDark),
      );
    }
  }

  Widget _buildDeletedBubble(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isOwnMessage) ...[
            if (showAvatar)
              const SizedBox(width: 44)
            else
              const SizedBox(width: 44),
          ],
          Container(
            constraints: const BoxConstraints(maxWidth: 240),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[850]?.withValues(alpha: 0.5)
                  : Colors.grey[200]?.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.grey[700]!.withValues(alpha: 0.3)
                    : Colors.grey[300]!.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.block,
                  size: 16,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '삭제된 메시지입니다',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isOwnMessage)
            const SizedBox(width: 60),
        ],
      ),
    );
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_repliedToMessage != null)
                        _ReplyQuoteBubble(
                          repliedTo: _repliedToMessage!,
                          isDark: isDark,
                          isOwnBubble: false,
                          accentColor: accentColor,
                        ),
                      _buildContent(context, isDark),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.isEdited) ...[
                        Text(
                          '편집됨',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? AppColors.textSubDark
                                : AppColors.textSubLight,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.textSubDark
                                : AppColors.textSubLight,
                          ),
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
                      if (message.isHighlighted) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.push_pin,
                          size: 10,
                          color: accentColor,
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
                    color: accentColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_repliedToMessage != null)
                        _ReplyQuoteBubble(
                          repliedTo: _repliedToMessage!,
                          isDark: isDark,
                          isOwnBubble: true,
                          accentColor: accentColor,
                        ),
                      HighlightedText(
                        text: message.content ?? '',
                        query: searchQuery,
                        baseStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
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
                      if (message.isEdited) ...[
                        Text(
                          '편집됨',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? AppColors.textSubDark
                                : AppColors.textSubLight,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.textSubDark
                                : AppColors.textSubLight,
                          ),
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
            HighlightedText(
              text: message.content!,
              query: searchQuery,
              baseStyle: TextStyle(
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
        return GestureDetector(
          onTap: () => FullScreenImageViewer.show(
            context,
            imageUrl: message.mediaUrl!,
            senderName: message.isFromArtist ? artistName : message.senderName,
            date: message.createdAt,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: message.mediaUrl!,
              width: 200,
              fit: BoxFit.cover,
            ),
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
        return HighlightedText(
          text: message.content ?? '',
          query: searchQuery,
          baseStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        );
    }
  }

  void _playVideo(BuildContext context, String videoUrl) {
    // TODO: 전체화면 비디오 플레이어 구현 (video_player 패키지 필요)
    // 현재는 외부 브라우저에서 재생
    final uri = Uri.tryParse(videoUrl);
    if (uri != null) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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

/// Reply quote bubble shown inside a message when replying to another message
class _ReplyQuoteBubble extends StatelessWidget {
  final BroadcastMessage repliedTo;
  final bool isDark;
  final bool isOwnBubble;
  final Color accentColor;

  const _ReplyQuoteBubble({
    required this.repliedTo,
    required this.isDark,
    required this.isOwnBubble,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final senderName = repliedTo.isFromArtist
        ? (repliedTo.senderName ?? '아티스트')
        : (repliedTo.senderName ?? '나');

    final previewText = repliedTo.deletedAt != null
        ? '삭제된 메시지'
        : repliedTo.content ?? (repliedTo.messageType == BroadcastMessageType.image
            ? '📷 사진'
            : repliedTo.messageType == BroadcastMessageType.video
                ? '🎬 동영상'
                : repliedTo.messageType == BroadcastMessageType.voice
                    ? '🎤 음성 메시지'
                    : '메시지');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: isOwnBubble
            ? Colors.white.withValues(alpha: 0.15)
            : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isOwnBubble
                ? Colors.white.withValues(alpha: 0.5)
                : accentColor.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            senderName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isOwnBubble
                  ? Colors.white.withValues(alpha: 0.8)
                  : accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            previewText.length > 40
                ? '${previewText.substring(0, 40)}...'
                : previewText,
            style: TextStyle(
              fontSize: 12,
              color: isOwnBubble
                  ? Colors.white.withValues(alpha: 0.6)
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
