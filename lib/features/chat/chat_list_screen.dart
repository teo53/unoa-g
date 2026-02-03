import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock/mock_data.dart';
import '../../providers/chat_list_provider.dart';
import '../../shared/widgets/search_field.dart';
import '../../shared/widgets/avatar_with_badge.dart';
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
                  color: isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('새 메시지 기능 준비 중')),
                    );
                  },
                  icon: Icon(
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

        const SizedBox(height: 16),

        // Stories Row (still using mock data for now)
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: MockData.storyUsers.length,
            itemBuilder: (context, index) {
              final story = MockData.storyUsers[index];
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
          ),
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

        // FAB
        Padding(
          padding: const EdgeInsets.only(right: 20, bottom: 20),
          child: Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('새 대화 시작 기능 준비 중')),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.edit, color: Colors.white),
            ),
          ),
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
    // Show loading indicator
    if (state.isLoading && !state.hasLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error state
    if (state.error != null && state.threads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: TextStyle(
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(chatListProvider.notifier).refresh();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (state.threads.isEmpty && state.hasLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
            const SizedBox(height: 16),
            Text(
              '아직 구독 중인 채널이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '아티스트를 검색하고 구독해보세요!',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ],
        ),
      );
    }

    // Show chat list with pull-to-refresh
    return RefreshIndicator(
      onRefresh: () => ref.read(chatListProvider.notifier).refresh(),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: state.threads.length,
        itemBuilder: (context, index) {
          final thread = state.threads[index];
          return ChatListTile(
            chat: thread.toChatThread(),
            onTap: () => context.push('/chat/${thread.channelId}'),
          );
        },
      ),
    );
  }
}
