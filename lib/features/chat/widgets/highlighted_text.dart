import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Utility widget that highlights matching text within a string.
/// Used for chat message search to show matching keywords.
class HighlightedText extends StatelessWidget {
  final String text;
  final String? query;
  final TextStyle? baseStyle;
  final Color? highlightColor;
  final int? maxLines;
  final TextOverflow? overflow;

  const HighlightedText({
    super.key,
    required this.text,
    this.query,
    this.baseStyle,
    this.highlightColor,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    if (query == null || query!.isEmpty || text.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = highlightColor ??
        (isDark
            ? AppColors.primary500.withValues(alpha: 0.3)
            : const Color(0xFFFFF3CD));

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query!.toLowerCase();
    int start = 0;

    while (start < text.length) {
      final matchIndex = lowerText.indexOf(lowerQuery, start);
      if (matchIndex == -1) {
        // No more matches -- add remaining text
        spans.add(TextSpan(
          text: text.substring(start),
          style: baseStyle,
        ));
        break;
      }

      // Add text before match
      if (matchIndex > start) {
        spans.add(TextSpan(
          text: text.substring(start, matchIndex),
          style: baseStyle,
        ));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(matchIndex, matchIndex + query!.length),
        style: (baseStyle ?? const TextStyle()).copyWith(
          backgroundColor: bgColor,
          fontWeight: FontWeight.w600,
        ),
      ));

      start = matchIndex + query!.length;
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
