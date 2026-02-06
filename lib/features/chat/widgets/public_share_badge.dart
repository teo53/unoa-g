import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// UNO A 스타일 전체공개 배지
/// - primary500 컬러 사용
/// - 15% 알파 배경, 30% 알파 테두리
/// - Icons.public 아이콘 사용
class PublicShareBadge extends StatelessWidget {
  /// Badge size variant
  final PublicShareBadgeSize size;

  const PublicShareBadge({
    super.key,
    this.size = PublicShareBadgeSize.small,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primary500;

    switch (size) {
      case PublicShareBadgeSize.small:
        return _SmallBadge(primaryColor: primaryColor);
      case PublicShareBadgeSize.medium:
        return _MediumBadge(primaryColor: primaryColor, isDark: isDark);
      case PublicShareBadgeSize.large:
        return _LargeBadge(primaryColor: primaryColor, isDark: isDark);
    }
  }
}

enum PublicShareBadgeSize {
  /// 작은 배지 (sender info 줄에 표시)
  small,

  /// 중간 배지 (메시지 상단에 표시)
  medium,

  /// 큰 배지 (단독 표시)
  large,
}

/// 작은 배지 - sender info 줄에 표시
class _SmallBadge extends StatelessWidget {
  final Color primaryColor;

  const _SmallBadge({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.public,
            size: 10,
            color: primaryColor,
          ),
          const SizedBox(width: 3),
          Text(
            '전체공개',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 중간 배지 - 메시지 상단에 표시
class _MediumBadge extends StatelessWidget {
  final Color primaryColor;
  final bool isDark;

  const _MediumBadge({
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.public,
            size: 12,
            color: primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            '전체공개',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 큰 배지 - 단독 표시 또는 강조용
class _LargeBadge extends StatelessWidget {
  final Color primaryColor;
  final bool isDark;

  const _LargeBadge({
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.public,
            size: 16,
            color: primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            '전체공개',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 전체공개 메시지임을 나타내는 인라인 텍스트
/// 메시지 버블 내부에 사용
class PublicShareInlineText extends StatelessWidget {
  const PublicShareInlineText({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.public,
          size: 12,
          color: AppColors.primary500,
        ),
        const SizedBox(width: 4),
        Text(
          '전체공개',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.primary500,
          ),
        ),
      ],
    );
  }
}
