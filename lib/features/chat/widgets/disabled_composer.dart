import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Disabled Composer Widget
/// Shown when user has no reply tokens available
/// Fromm/Bubble style: Friendly message indicating wait for next broadcast
class DisabledComposer extends StatelessWidget {
  final DateTime? lastBroadcastAt;
  final String artistName;
  final VoidCallback? onDonationTap;

  const DisabledComposer({
    super.key,
    this.lastBroadcastAt,
    this.artistName = '아티스트',
    this.onDonationTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main disabled message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              children: [
                // Lock icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 24,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  '답장 횟수를 모두 사용했어요',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  '$artistName님의 새 메시지가 오면\n다시 답장할 수 있어요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),

                // Last broadcast time
                if (lastBroadcastAt != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '마지막 메시지: ${_formatTime(lastBroadcastAt!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Donation alternative
          if (onDonationTap != null)
            GestureDetector(
              onTap: onDonationTap,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary500.withValues(alpha: 0.1),
                      AppColors.primary600.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary500.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.diamond,
                      size: 18,
                      color: AppColors.primary500,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'DT 후원으로 메시지 보내기',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary600,
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays == 1) return '어제';
    if (diff.inDays < 7) return '${diff.inDays}일 전';

    return '${time.month}/${time.day}';
  }
}

/// Compact disabled state for inline display
class DisabledComposerCompact extends StatelessWidget {
  final VoidCallback? onDonationTap;

  const DisabledComposerCompact({
    super.key,
    this.onDonationTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          // Disabled input hint
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '새 메시지가 오면 답장할 수 있어요',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Donation button
          if (onDonationTap != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onDonationTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primary500,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.diamond,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
