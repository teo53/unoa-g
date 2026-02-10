import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/config/business_config.dart';

/// Bottom sheet explaining the reply token system.
/// Shown once on first chat entry (caller manages the flag).
class TokenExplanationSheet {
  TokenExplanationSheet._();

  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    borderRadius: AppRadius.smBR,
                  ),
                ),
                const SizedBox(height: 24),

                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  '답글 토큰 안내',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 12),

                // Explanation items
                _ExplanationItem(
                  icon: Icons.mark_email_read_outlined,
                  text:
                      '아티스트가 새 메시지를 보낼 때마다 답글 토큰 ${BusinessConfig.defaultReplyTokens}개가 충전됩니다.',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _ExplanationItem(
                  icon: Icons.reply_rounded,
                  text: '토큰 1개로 답글 1회를 보낼 수 있어요.',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _ExplanationItem(
                  icon: Icons.workspace_premium_outlined,
                  text: 'VIP 구독자는 더 많은 토큰을 받습니다.',
                  isDark: isDark,
                ),

                const SizedBox(height: 24),

                // Confirm button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.baseBR,
                      ),
                    ),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExplanationItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _ExplanationItem({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: AppRadius.mdBR,
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSubDark
                    : AppColors.textSubLight,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
