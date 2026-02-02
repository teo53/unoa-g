import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock/mock_data.dart';
import '../../shared/widgets/search_field.dart';
import '../../shared/widgets/avatar_with_badge.dart';
import 'widgets/chat_list_tile.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

        // Stories Row
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
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: MockData.chatThreads.length,
            itemBuilder: (context, index) {
              final chat = MockData.chatThreads[index];
              return ChatListTile(
                chat: chat,
                onTap: () => context.push('/chat/${chat.artistId}'),
              );
            },
          ),
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
}
