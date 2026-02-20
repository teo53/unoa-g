import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/animation_utils.dart';
import '../../providers/chat_list_provider.dart';
import '../../shared/widgets/search_field.dart';
import '../../shared/widgets/avatar_with_badge.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/error_boundary.dart';
import '../../shared/widgets/native_ad_card.dart';
import '../../providers/ops_config_provider.dart';
import 'widgets/chat_list_tile.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatListState = ref.watch(chatListProvider);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '메시지',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('새 메시지 기능 준비 중'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.edit_square,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: SearchField(),
        ),

        // Chat List Native Ad Slot
        Builder(builder: (ctx) {
          final banners = ref.watch(opsBannersProvider('chat_list'));
          if (banners.isEmpty) return const SizedBox(height: 8);
          return NativeAdCard(banner: banners.first);
        }),

        // Stories Row
        SizedBox(
          height: 90,
          child: Builder(builder: (context) {
            final storyUsers = ref.watch(storyUsersProvider);
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: storyUsers.length,
              itemBuilder: (context, index) {
                final story = storyUsers[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: StoryAvatar(
                    imageUrl: story['avatarUrl'] as String,
                    label: story['name'] as String,
                    isAddStory: story['isAddStory'] as bool,
                    hasNewStory: story['hasNewStory'] as bool,
                  ),
                );
              },
            );
          }),
        ),

        // Divider
        Divider(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          height: 1,
        ),

        // Chat List
        Expanded(
          child: _buildChatList(context, ref, chatListState, isDark),
        ),
      ],
    );
  }

  Widget _buildChatList(
    BuildContext context,
    WidgetRef ref,
    ChatListState state,
    bool isDark,
  ) {
    // Show skeleton loading
    if (state.isLoading && !state.hasLoaded) {
      return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: 6,
        itemBuilder: (context, index) => const SkeletonListTile(
          showAvatar: true,
          showSubtitle: true,
          showTrailing: true,
          avatarSize: 52,
        ),
      );
    }

    // Show error state with enterprise ErrorDisplay
    if (state.error != null && state.threads.isEmpty) {
      return ErrorDisplay(
        error: state.error!,
        icon: Icons.wifi_off_rounded,
        title: '연결 오류',
        message: state.error,
        onRetry: () {
          HapticFeedback.mediumImpact();
          ref.read(chatListProvider.notifier).refresh();
        },
      );
    }

    // Show empty state with enterprise EmptyState
    if (state.threads.isEmpty && state.hasLoaded) {
      return EmptyState(
        title: '아직 구독 중인 채널이 없습니다',
        message: '아티스트를 검색하고 구독해보세요!',
        icon: Icons.chat_bubble_outline_rounded,
        action: FilledButton.icon(
          onPressed: () => context.go('/discover'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary600,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.search, size: 18),
          label: const Text('아티스트 둘러보기'),
        ),
      );
    }

    // Show chat list with pull-to-refresh
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await ref.read(chatListProvider.notifier).refresh();
      },
      color: AppColors.primary,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: state.threads.length,
        itemBuilder: (context, index) {
          final thread = state.threads[index];
          return FadeInAnimation(
            delay: Duration(milliseconds: 30 * index),
            child: ChatListTile(
              chat: thread.toChatThread(),
              onTap: () {
                HapticFeedback.selectionClick();
                context.push('/chat/${thread.channelId}');
              },
            ),
          );
        },
      ),
    );
  }
}
