import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/demo_config.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/blocked_users_provider.dart';
import '../../shared/widgets/app_scaffold.dart';

/// 차단된 사용자 관리 화면
///
/// 차단한 사용자 목록을 표시하고 해제할 수 있음
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blockedUsersAsync = ref.watch(blockedUsersProvider);

    return AppScaffold(
      showStatusBar: true,
      child: Column(
        children: [
          // Header
          _buildHeader(context, isDark),

          // Content
          Expanded(
            child: blockedUsersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return _buildEmptyState(isDark);
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _BlockedUserTile(
                      name: user.blockedUserName ?? '알 수 없는 사용자',
                      avatarUrl: user.blockedUserAvatar,
                      blockedDate: user.blockedDateText,
                      reason: user.reason,
                      isDark: isDark,
                      onUnblock: () => _showUnblockConfirmation(
                        context,
                        ref,
                        blockedId: user.blockedId,
                        name: user.blockedUserName ?? '알 수 없는 사용자',
                        isDark: isDark,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '차단 목록을 불러올 수 없습니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.invalidate(blockedUsersProvider),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const Expanded(
            child: Text(
              '차단 관리',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block_outlined,
            size: 64,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            '차단한 사용자가 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '채팅방에서 사용자를 차단할 수 있습니다',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _showUnblockConfirmation(
    BuildContext context,
    WidgetRef ref, {
    required String blockedId,
    required String name,
    required bool isDark,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '차단 해제',
          style: TextStyle(
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        content: Text(
          '$name님의 차단을 해제하시겠습니까?\n\n차단 해제 후 해당 사용자의 메시지가 다시 표시됩니다.',
          style: TextStyle(
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              '취소',
              style: TextStyle(
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await unblockUser(ref, blockedId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? '$name님의 차단이 해제되었습니다' : '차단 해제에 실패했습니다',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              '해제',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String blockedDate;
  final String? reason;
  final bool isDark;
  final VoidCallback onUnblock;

  const _BlockedUserTile({
    required this.name,
    this.avatarUrl,
    required this.blockedDate,
    this.reason,
    required this.isDark,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor:
                isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0] : '?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  blockedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.textMutedDark : AppColors.textMuted,
                  ),
                ),
                if (reason != null && reason!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '사유: $reason',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Unblock button
          TextButton(
            onPressed: onUnblock,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: const Text(
              '해제',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
