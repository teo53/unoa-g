import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';

/// Bottom sheet for AI reply suggestions
///
/// IMPORTANT: This is for DRAFT suggestions only.
/// AI NEVER sends messages automatically - creator must review and send.
class AiReplySuggestionSheet extends StatefulWidget {
  final String channelId;
  final String messageId;
  final String? fanMessagePreview;
  final Function(String text) onInsert;

  const AiReplySuggestionSheet({
    super.key,
    required this.channelId,
    required this.messageId,
    this.fanMessagePreview,
    required this.onInsert,
  });

  /// Show the sheet as a modal bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String channelId,
    required String messageId,
    String? fanMessagePreview,
    required Function(String text) onInsert,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiReplySuggestionSheet(
        channelId: channelId,
        messageId: messageId,
        fanMessagePreview: fanMessagePreview,
        onInsert: onInsert,
      ),
    );
  }

  @override
  State<AiReplySuggestionSheet> createState() => _AiReplySuggestionSheetState();
}

class _AiReplySuggestionSheetState extends State<AiReplySuggestionSheet> {
  List<ReplySuggestion>? _suggestions;
  bool _isLoading = false;
  String? _error;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  Future<void> _fetchSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'ai-reply-suggest',
        body: {
          'channel_id': widget.channelId,
          'message_id': widget.messageId,
        },
      );

      if (response.status != 200) {
        throw Exception(response.data?['error'] ?? 'Failed to get suggestions');
      }

      final data = response.data as Map<String, dynamic>;
      final suggestionsJson = data['suggestions'] as List<dynamic>;

      setState(() {
        _suggestions = suggestionsJson
            .map((s) => ReplySuggestion.fromJson(s as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('복사되었습니다'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _insertAndClose(String text) {
    Navigator.pop(context);
    widget.onInsert(text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 24,
                  color: AppColors.primary500,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '답글 초안 제안',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight,
                        ),
                      ),
                      // IMPORTANT: AI generated label (MUST show)
                      Text(
                        'AI가 만들었습니다 • 수정 후 전송하세요',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  iconSize: 22,
                ),
              ],
            ),
          ),

          // Fan message preview
          if (widget.fanMessagePreview != null) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceAltDark
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: isDark
                        ? AppColors.textSubDark
                        : AppColors.textSubLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.fanMessagePreview!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Content
          Flexible(
            child: _buildContent(isDark),
          ),

          SizedBox(height: bottomPadding + 12),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return _buildLoading(isDark);
    }

    if (_error != null) {
      return _buildError(isDark);
    }

    if (_suggestions == null || _suggestions!.isEmpty) {
      return _buildEmpty(isDark);
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _suggestions!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final suggestion = _suggestions![index];
        final isSelected = _selectedId == suggestion.id;

        return _SuggestionCard(
          suggestion: suggestion,
          isDark: isDark,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedId = suggestion.id),
          onInsert: () => _insertAndClose(suggestion.text),
          onCopy: () => _copyToClipboard(suggestion.text),
        );
      },
    );
  }

  Widget _buildLoading(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '초안을 생성하고 있어요...',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: AppColors.danger,
          ),
          const SizedBox(height: 12),
          Text(
            '초안을 불러올 수 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _fetchSuggestions,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.edit_note_outlined,
            size: 40,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
          const SizedBox(height: 12),
          Text(
            '제안할 초안이 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final ReplySuggestion suggestion;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onInsert;
  final VoidCallback onCopy;

  const _SuggestionCard({
    required this.suggestion,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
    required this.onInsert,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary500.withValues(alpha: 0.08)
              : (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary500
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    suggestion.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary500,
                    ),
                  ),
                ),
                const Spacer(),
                if (isSelected) ...[
                  _ActionButton(
                    icon: Icons.copy,
                    label: '복사',
                    onTap: onCopy,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.add,
                    label: '입력창에 넣기',
                    onTap: onInsert,
                    primary: true,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // Text
            Text(
              suggestion.text,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool primary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDark = false,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = primary ? Colors.white : AppColors.primary600;
    final bgColor = primary
        ? AppColors.primary600
        : AppColors.primary500.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fgColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reply suggestion model
class ReplySuggestion {
  final String id;
  final String label;
  final String text;

  const ReplySuggestion({
    required this.id,
    required this.label,
    required this.text,
  });

  factory ReplySuggestion.fromJson(Map<String, dynamic> json) {
    return ReplySuggestion(
      id: json['id'] as String,
      label: json['label'] as String,
      text: json['text'] as String,
    );
  }
}
