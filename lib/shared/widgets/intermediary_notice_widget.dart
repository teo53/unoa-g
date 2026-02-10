import 'package:flutter/material.dart';

/// 통신판매중개자 고지 위젯
///
/// 법적 근거: 전자상거래법 §20①, §20-2①
/// 표시 위치: 펀딩 관련 모든 화면 (목록, 상세, 체크아웃, 티어 선택)
/// 폰트 크기: 판매자 정보 이상 (시행규칙 제11조의2)
class IntermediaryNoticeWidget extends StatelessWidget {
  const IntermediaryNoticeWidget({super.key});

  static const String noticeText =
      '[UNO A]는 크라우드펀딩 거래의 통신판매중개자로서 '
      '당사자가 아니며, 해당 거래에 대한 책임은 각 크리에이터에게 있습니다.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade800.withValues(alpha: 0.5)
            : Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              noticeText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
