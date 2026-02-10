import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/reply_quota.dart';

/// Token Counter Widget
/// Displays remaining reply tokens in a subtle, non-gamified way
/// Fromm/Bubble style: Shows "N/3" for available replies
class TokenCounter extends StatelessWidget {
  final ReplyQuota? quota;
  final int maxTokens;
  final bool showLabel;
  final bool compact;

  const TokenCounter({
    super.key,
    this.quota,
    this.maxTokens = 3,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final available = quota?.tokensAvailable ?? 0;
    final isFallback = quota?.isFallbackOnly ?? false;
    final canReply = quota?.canReply ?? false;

    if (compact) {
      return _buildCompact(isDark, available, isFallback, canReply);
    }

    return _buildFull(isDark, available, isFallback, canReply);
  }

  Widget _buildCompact(
      bool isDark, int available, bool isFallback, bool canReply) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: canReply
            ? (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt)
            : (isDark ? Colors.grey[800] : Colors.grey[200]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFallback ? Icons.hourglass_bottom : Icons.chat_bubble_outline,
            size: 14,
            color: canReply
                ? AppColors.primary500
                : (isDark ? Colors.grey[500] : Colors.grey[400]),
          ),
          const SizedBox(width: 4),
          Text(
            isFallback ? '1' : '$available',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: canReply
                  ? (isDark ? AppColors.textMainDark : AppColors.textMainLight)
                  : (isDark ? Colors.grey[500] : Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull(
      bool isDark, int available, bool isFallback, bool canReply) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canReply
              ? AppColors.primary500.withValues(alpha: 0.3)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: canReply
                  ? AppColors.primary100
                  : (isDark ? Colors.grey[800] : Colors.grey[200]),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFallback ? Icons.hourglass_bottom : Icons.chat_bubble_outline,
              size: 16,
              color: canReply
                  ? AppColors.primary600
                  : (isDark ? Colors.grey[500] : Colors.grey[400]),
            ),
          ),
          const SizedBox(width: 10),

          // Counter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLabel)
                Text(
                  isFallback ? '추가 답장' : '답장 가능',
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              Row(
                children: [
                  Text(
                    isFallback ? '1' : '$available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: canReply
                          ? AppColors.primary600
                          : (isDark ? Colors.grey[500] : Colors.grey[400]),
                    ),
                  ),
                  if (!isFallback) ...[
                    Text(
                      ' / $maxTokens',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Inline token indicator for chat header
class TokenIndicator extends StatelessWidget {
  final ReplyQuota? quota;

  const TokenIndicator({super.key, this.quota});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final available = quota?.tokensAvailable ?? 0;
    final isFallback = quota?.isFallbackOnly ?? false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isActive = index < available || (isFallback && index == 0);
        return Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? (isFallback && index == 0
                      ? AppColors.warning
                      : AppColors.primary500)
                  : (isDark ? Colors.grey[700] : Colors.grey[300]),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

/// Character limit indicator
class CharacterLimitIndicator extends StatelessWidget {
  final int currentLength;
  final int maxLength;
  final bool showWarning;

  const CharacterLimitIndicator({
    super.key,
    required this.currentLength,
    required this.maxLength,
    this.showWarning = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = maxLength - currentLength;
    final isOverLimit = remaining < 0;
    final isNearLimit = remaining <= 10 && remaining >= 0;

    Color textColor;
    if (isOverLimit) {
      textColor = AppColors.error;
    } else if (isNearLimit) {
      textColor = AppColors.warning;
    } else {
      textColor = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    }

    return Text(
      '$currentLength / $maxLength',
      style: TextStyle(
        fontSize: 11,
        fontWeight: isOverLimit || isNearLimit ? FontWeight.w600 : FontWeight.w400,
        color: textColor,
      ),
    );
  }
}
