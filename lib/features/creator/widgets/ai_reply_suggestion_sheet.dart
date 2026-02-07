import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
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

  // 직접 입력/편집용 컨트롤러
  final TextEditingController _editController = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _editController.addListener(_onEditTextChanged);
    _fetchSuggestions();
  }

  @override
  void dispose() {
    _editController.removeListener(_onEditTextChanged);
    _editController.dispose();
    super.dispose();
  }

  void _onEditTextChanged() {
    final hasText = _editController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  Future<void> _fetchSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (AppConfig.openaiApiKey.isNotEmpty) {
        await _fetchFromGPT();
      } else {
        await _fetchFromSupabase();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// GPT API 직접 호출 (데모/개발 환경)
  Future<void> _fetchFromGPT() async {
    final prompt = _buildPrompt(widget.fanMessagePreview ?? '');

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConfig.openaiApiKey}',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 1024,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('GPT API 오류 (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text = data['choices'][0]['message']['content'] as String;

    final suggestions = _parseGPTResponse(text);
    setState(() {
      _suggestions = suggestions;
      _isLoading = false;
    });
  }

  String _buildPrompt(String fanMessage) {
    return '당신은 K-pop/엔터테인먼트 크리에이터의 팬 메시지 답글 초안을 작성하는 도우미입니다.\n\n'
        '[팬 메시지]\n"$fanMessage"\n\n'
        '[안전 규칙]\n'
        '- 친근하되 기만적이지 않게 작성\n'
        '- "AI"라는 단어 사용 금지\n'
        '- 각 답변 200자 이내\n\n'
        '정확히 3개의 서로 다른 스타일의 답글 초안을 JSON 배열 형식으로 반환하세요.\n'
        '스타일: 짧게, 따뜻하게, 재미있게\n\n'
        '예시 형식:\n'
        '["첫 번째 답글", "두 번째 답글", "세 번째 답글"]\n\n'
        '답글만 출력하고 다른 설명은 포함하지 마세요.';
  }

  List<ReplySuggestion> _parseGPTResponse(String text) {
    const labels = ['짧게', '따뜻하게', '재미있게'];

    final match = RegExp(r'\[[\s\S]*\]').firstMatch(text);
    if (match != null) {
      final parsed = jsonDecode(match.group(0)!) as List<dynamic>;
      return parsed.take(3).toList().asMap().entries.map((e) {
        return ReplySuggestion(
          id: 'opt${e.key + 1}',
          label: e.key < labels.length ? labels[e.key] : '옵션 ${e.key + 1}',
          text: (e.value as String).trim(),
        );
      }).toList();
    }

    throw Exception('GPT 응답을 파싱할 수 없습니다');
  }

  /// Supabase Edge Function 호출 (프로덕션)
  Future<void> _fetchFromSupabase() async {
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

  /// 초안 카드 탭 → 편집창에 텍스트 세팅
  void _fillEditField(String text) {
    _editController.text = text;
    _editController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
  }

  /// 초안 리롤 (다시 생성)
  void _rerollSuggestions() {
    setState(() {
      _suggestions = null;
      _selectedId = null;
    });
    _fetchSuggestions();
  }

  void _insertAndClose(String text) {
    Navigator.pop(context);
    widget.onInsert(text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
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
            _buildHeader(isDark),

            // Fan message preview
            if (widget.fanMessagePreview != null) ...[
              const SizedBox(height: 12),
              _buildFanMessagePreview(isDark),
            ],

            const SizedBox(height: 12),

            // Content (suggestions or loading/error)
            Flexible(
              child: _buildContent(isDark),
            ),

            // 하단 입력창 (항상 표시)
            _buildEditBar(isDark),

            SizedBox(height: bottomPadding + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
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
                Text(
                  '참고용 초안 \u2022 AI가 만들었습니다',
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
    );
  }

  Widget _buildFanMessagePreview(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 16,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.fanMessagePreview!,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 섹션 라벨 + 리롤 버튼
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '참고용 AI 초안 (탭하여 편집창에 넣기)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _isLoading ? null : _rerollSuggestions,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 14,
                      color: _isLoading
                          ? (isDark ? Colors.grey[600] : Colors.grey[400])
                          : AppColors.primary500,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '다시 생성',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _isLoading
                            ? (isDark ? Colors.grey[600] : Colors.grey[400])
                            : AppColors.primary500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 초안 목록
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _suggestions!.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final suggestion = _suggestions![index];
              final isSelected = _selectedId == suggestion.id;

              return _SuggestionCard(
                suggestion: suggestion,
                isDark: isDark,
                isSelected: isSelected,
                onTap: () {
                  setState(() => _selectedId = suggestion.id);
                  _fillEditField(suggestion.text);
                },
                onCopy: () => _copyToClipboard(suggestion.text),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEditBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _hasText
              ? AppColors.primary500.withValues(alpha: 0.4)
              : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _editController,
              maxLines: 4,
              minLines: 1,
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? AppColors.textMainDark
                    : AppColors.textMainLight,
              ),
              decoration: InputDecoration(
                hintText: '직접 입력하거나 위 초안을 탭하세요...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSubDark
                      : AppColors.textSubLight,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _hasText
                ? () => _insertAndClose(_editController.text.trim())
                : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _hasText
                    ? AppColors.primary600
                    : (isDark ? Colors.grey[700] : Colors.grey[300]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.send_rounded,
                size: 18,
                color: _hasText
                    ? Colors.white
                    : (isDark ? Colors.grey[500] : Colors.grey[500]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '참고용 초안을 생성하고 있어요...',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '아래 입력창에 직접 입력할 수도 있어요',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSubDark.withValues(alpha: 0.7)
                  : AppColors.textSubLight.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 36,
            color: AppColors.danger,
          ),
          const SizedBox(height: 10),
          Text(
            '초안을 불러올 수 없습니다',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _error!,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _fetchSuggestions,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('다시 시도'),
          ),
          const SizedBox(height: 4),
          Text(
            '아래 입력창에 직접 입력할 수도 있어요',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSubDark.withValues(alpha: 0.7)
                  : AppColors.textSubLight.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.edit_note_outlined,
            size: 36,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
          const SizedBox(height: 10),
          Text(
            '제안할 초안이 없습니다',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '아래 입력창에 직접 입력해주세요',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
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
  final VoidCallback onCopy;

  const _SuggestionCard({
    required this.suggestion,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary500.withValues(alpha: 0.08)
              : (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary500 : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label + copy button
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
                if (isSelected)
                  GestureDetector(
                    onTap: onCopy,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy, size: 13, color: AppColors.primary600),
                        const SizedBox(width: 3),
                        Text(
                          '복사',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Text
            Text(
              suggestion.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 6),
              Text(
                '\u2191 탭하여 편집창에 넣었습니다',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary500,
                ),
              ),
            ],
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
