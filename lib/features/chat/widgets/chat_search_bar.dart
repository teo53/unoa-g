import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// KakaoTalk-style chat search bar that replaces the header when active.
/// Shows search input with result count and up/down navigation.
class ChatSearchBar extends StatefulWidget {
  final int matchCount;
  final int currentMatch;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<int> onNavigate;
  final VoidCallback onClose;

  const ChatSearchBar({
    super.key,
    required this.matchCount,
    required this.currentMatch,
    required this.onQueryChanged,
    required this.onNavigate,
    required this.onClose,
  });

  @override
  State<ChatSearchBar> createState() => _ChatSearchBarState();
}

class _ChatSearchBarState extends State<ChatSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onQueryChanged(text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasQuery = _controller.text.trim().isNotEmpty;
    final hasMatches = widget.matchCount > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark.withValues(alpha: 0.95)
            : AppColors.backgroundLight.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          // Close button
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              size: 20,
            ),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),

          // Search input
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _onTextChanged,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                      decoration: InputDecoration(
                        hintText: '메시지 검색...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (hasQuery)
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        widget.onQueryChanged('');
                      },
                      child: Icon(
                        Icons.cancel,
                        size: 16,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Match counter
          if (hasQuery)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                hasMatches
                    ? '${widget.currentMatch + 1}/${widget.matchCount}'
                    : '0/0',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: hasMatches
                      ? (isDark ? Colors.grey[300] : Colors.grey[600])
                      : (isDark ? Colors.grey[500] : Colors.grey[400]),
                ),
              ),
            ),

          // Up arrow (previous match)
          if (hasQuery)
            IconButton(
              onPressed: hasMatches && widget.currentMatch > 0
                  ? () => widget.onNavigate(-1)
                  : null,
              icon: Icon(
                Icons.keyboard_arrow_up,
                size: 22,
                color: hasMatches && widget.currentMatch > 0
                    ? (isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight)
                    : (isDark ? Colors.grey[600] : Colors.grey[300]),
              ),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),

          // Down arrow (next match)
          if (hasQuery)
            IconButton(
              onPressed:
                  hasMatches && widget.currentMatch < widget.matchCount - 1
                      ? () => widget.onNavigate(1)
                      : null,
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: 22,
                color: hasMatches && widget.currentMatch < widget.matchCount - 1
                    ? (isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight)
                    : (isDark ? Colors.grey[600] : Colors.grey[300]),
              ),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}
