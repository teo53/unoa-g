import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// 섹션 헤더 위젯
///
/// 제목과 선택적으로 후행 텍스트/위젯을 표시
/// trailing이 있고 onTrailingTap이 있으면 클릭 가능한 스타일로 표시
class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;
  final Widget? trailingWidget;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailingTap,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAction = onTrailingTap != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          if (trailingWidget != null)
            trailingWidget!
          else if (trailing != null)
            GestureDetector(
              onTap: onTrailingTap,
              behavior: hasAction ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  trailing!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    // 클릭 가능하면 primary 색상, 아니면 grey
                    color: hasAction ? AppColors.primary500 : Colors.grey[400],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
