import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/mock/reply_templates.dart';
import '../../../data/models/ai_draft_state.dart';
import '../../../data/services/ai_draft_service.dart';

/// Bottom sheet for AI reply suggestions
///
/// IMPORTANT: This is for DRAFT suggestions only.
/// AI NEVER sends messages automatically - creator must review and send.
///
/// State machine:
/// ```
/// idle → generating → success (AI suggestions)
///                    → softFail (template fallback + retry)
///                    → hardFail (manual editor + template library)
/// ```
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
  AiDraftState _state = const AiDraftIdle();
  String? _selectedId;
  bool _showingTemplateLibrary = false;

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
      _state = AiDraftGenerating(correlationId: '');
      _showingTemplateLibrary = false;
    });

    final result = await AiDraftService.instance.fetchSuggestions(
      channelId: widget.channelId,
      messageId: widget.messageId,
      fanMessage: widget.fanMessagePreview ?? '',
    );

    if (mounted) {
      setState(() => _state = result);
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

  void _fillEditField(String text) {
    _editController.text = text;
    _editController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
  }

  void _rerollSuggestions() {
    setState(() => _selectedId = null);
    _fetchSuggestions();
  }

  void _showTemplateLibrary() {
    setState(() => _showingTemplateLibrary = true);
  }

  void _insertAndClose(String text) {
    Navigator.pop(context);
    widget.onInsert(text);
  }

  // Extract suggestions list from current state
  List<ReplySuggestion> get _currentSuggestions {
    final state = _state;
    if (state is AiDraftSuccess) return state.suggestions;
    if (state is AiDraftSoftFail) return state.templateSuggestions;
    return [];
  }

  bool get _isGenerating => _state is AiDraftGenerating;

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

            // Content (suggestions / loading / error states)
            Flexible(
              child: _showingTemplateLibrary
                  ? _buildTemplateLibrary(isDark)
                  : _buildContent(isDark),
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
    final state = _state;

    if (state is AiDraftGenerating) {
      return _buildLoading(isDark);
    }

    if (state is AiDraftHardFail) {
      return _buildHardFail(isDark, state);
    }

    if (state is AiDraftSoftFail) {
      return _buildSoftFail(isDark, state);
    }

    if (state is AiDraftSuccess) {
      if (state.suggestions.isEmpty) {
        return _buildEmpty(isDark);
      }
      return _buildSuggestionList(isDark, state.suggestions, isAi: true);
    }

    // AiDraftIdle
    return _buildEmpty(isDark);
  }

  /// Displays AI-generated or template suggestions in a list.
  Widget _buildSuggestionList(
    bool isDark,
    List<ReplySuggestion> suggestions, {
    required bool isAi,
  }) {
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
                  isAi
                      ? '참고용 AI 초안 (탭하여 편집창에 넣기)'
                      : '추천 템플릿 (탭하여 편집창에 넣기)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _isGenerating ? null : _rerollSuggestions,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 14,
                      color: _isGenerating
                          ? (isDark ? Colors.grey[600] : Colors.grey[400])
                          : AppColors.primary500,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '다시 생성',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _isGenerating
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
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
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

  /// Template library — shows all categories with selectable templates.
  Widget _buildTemplateLibrary(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showingTemplateLibrary = false),
                child: Icon(
                  Icons.arrow_back_ios,
                  size: 16,
                  color: AppColors.primary500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '템플릿 라이브러리',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: ReplyTemplates.categories.map((category) {
              final templates = ReplyTemplates.getByCategoryAsSuggestions(category);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 6),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                      ),
                    ),
                  ),
                  ...templates.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _SuggestionCard(
                      suggestion: t,
                      isDark: isDark,
                      isSelected: _selectedId == t.id,
                      onTap: () {
                        setState(() => _selectedId = t.id);
                        _fillEditField(t.text);
                      },
                      onCopy: () => _copyToClipboard(t.text),
                    ),
                  )),
                ],
              );
            }).toList(),
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

  /// Soft fail: AI failed but templates are available.
  /// Recovery: "다시 시도" + "템플릿에서 선택" (2 actions).
  Widget _buildSoftFail(bool isDark, AiDraftSoftFail state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Error banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${state.error.userMessage} — 대신 추천 템플릿을 보여드릴게요',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Recovery actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _ActionChip(
                icon: Icons.refresh,
                label: '다시 시도',
                onTap: _rerollSuggestions,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.library_books_outlined,
                label: '템플릿 보기',
                onTap: _showTemplateLibrary,
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Show template suggestions
        Flexible(
          child: _buildSuggestionList(isDark, state.templateSuggestions, isAi: false),
        ),
      ],
    );
  }

  /// Hard fail: nothing worked.
  /// Recovery: "직접 작성하기" (edit bar always visible) + "템플릿 보기" + "짧은 프롬프트로 시도" (3 actions).
  Widget _buildHardFail(bool isDark, AiDraftHardFail state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 40,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
          const SizedBox(height: 12),
          Text(
            state.error.userMessage,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // 3 recovery actions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _ActionChip(
                icon: Icons.refresh,
                label: '다시 시도',
                onTap: _rerollSuggestions,
                isDark: isDark,
              ),
              _ActionChip(
                icon: Icons.library_books_outlined,
                label: '템플릿 보기',
                onTap: _showTemplateLibrary,
                isDark: isDark,
              ),
              _ActionChip(
                icon: Icons.edit_outlined,
                label: '직접 작성하기',
                onTap: () {
                  // Focus the edit bar
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                isDark: isDark,
                isPrimary: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '아래 입력창에 직접 입력할 수 있어요',
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionChip(
                icon: Icons.library_books_outlined,
                label: '템플릿 보기',
                onTap: _showTemplateLibrary,
                isDark: isDark,
              ),
            ],
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

/// Small action chip button for recovery actions.
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isPrimary;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary500.withValues(alpha: 0.1)
              : (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPrimary
                ? AppColors.primary500.withValues(alpha: 0.3)
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isPrimary
                  ? AppColors.primary500
                  : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isPrimary
                    ? AppColors.primary500
                    : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
              ),
            ),
          ],
        ),
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
