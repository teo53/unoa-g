import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock/mock_data.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_input_bar.dart';

/// Chat thread screen showing 1:1 conversation with an artist
/// Implements Fromm/Bubble style broadcast chat UX
class ChatThreadScreen extends StatefulWidget {
  final String artistId;

  const ChatThreadScreen({
    super.key,
    required this.artistId,
  });

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  _ChatData? _chatData;

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

    _loadChatData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _loadChatData() {
    // Cache the expensive lookup once
    final chat = MockData.chatThreads.firstWhere(
      (c) => c.artistId == widget.artistId,
      orElse: () => MockData.chatThreads.first,
    );

    setState(() {
      _chatData = _ChatData(chat: chat);
    });

    // Start fade animation after data is ready
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show skeleton while loading
    if (_chatData == null) {
      return AppScaffold(
        showStatusBar: true,
        child: _ChatSkeleton(isDark: isDark),
      );
    }

    final chat = _chatData!.chat;

    return AppScaffold(
      showStatusBar: true,
      child: Column(
        children: [
          // Header
          Container(
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
                    color:
                        isDark ? AppColors.textMainDark : AppColors.textMainLight,
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
                            child: CachedNetworkImage(
                              imageUrl: chat.artistAvatarUrl,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (chat.isOnline)
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
                        chat.artistName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (chat.isVerified)
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: AppColors.verified,
                        ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFEF08A), Color(0xFFFCD34D)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'VIP',
                          style: TextStyle(
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
                Container(
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
                        '120',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Date Separator
                Center(
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
                      '오늘 10월 24일',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                    ),
                  ),
                ),

                // Messages
                ...MockData.sampleMessages.map((message) {
                  return MessageBubble(
                    message: message,
                    isArtist: message.senderId != 'user_1',
                    artistAvatarUrl: chat.artistAvatarUrl,
                    artistName: chat.artistName,
                  );
                }),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // Input Bar
          ChatInputBar(artistId: widget.artistId),
        ],
      ),
    );
  }
}

/// Cached chat data to avoid expensive lookups in build
class _ChatData {
  final dynamic chat;

  const _ChatData({required this.chat});
}

/// Skeleton loading state for chat thread
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
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 48), // Back button space
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
              // Date separator skeleton
              Center(
                child: _SkeletonBox(width: 100, height: 28, isDark: isDark),
              ),
              const SizedBox(height: 20),

              // Artist message skeleton
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(width: 60, height: 12, isDark: isDark),
                        const SizedBox(height: 6),
                        _SkeletonBox(
                          width: double.infinity,
                          height: 60,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 16),

              // User message skeleton
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

              // Another artist message
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(width: 60, height: 12, isDark: isDark),
                        const SizedBox(height: 6),
                        _SkeletonBox(
                          width: double.infinity,
                          height: 80,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ),
        ),

        // Input bar skeleton
        Container(
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

/// Skeleton placeholder box with shimmer effect
class _SkeletonBox extends StatefulWidget {
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
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.grey[800]!.withValues(alpha: _animation.value)
                : Colors.grey[300]!.withValues(alpha: _animation.value),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.isCircle ? null : BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}
