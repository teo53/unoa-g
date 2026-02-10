import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/mock/mock_polls.dart';
import '../../../data/models/poll_draft.dart';

/// Bottom sheet for AI-generated poll/VS suggestions + custom creation.
///
/// Two tabs:
/// - AI 추천: loading → loaded(5 drafts) → selected(1 draft) → sending → sent
/// - 직접 만들기: category → question → options → send
///
/// IMPORTANT: Creator must select/create and send — AI never auto-posts polls.
class PollSuggestionSheet extends StatefulWidget {
  final String channelId;
  final Function(PollDraft draft, String? comment) onSend;

  const PollSuggestionSheet({
    super.key,
    required this.channelId,
    required this.onSend,
  });

  static Future<void> show({
    required BuildContext context,
    required String channelId,
    required Function(PollDraft draft, String? comment) onSend,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PollSuggestionSheet(
        channelId: channelId,
        onSend: onSend,
      ),
    );
  }

  @override
  State<PollSuggestionSheet> createState() => _PollSuggestionSheetState();
}

class _PollSuggestionSheetState extends State<PollSuggestionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // AI suggestion state
  List<PollDraft>? _drafts;
  bool _isLoading = false;
  String? _error;
  PollDraft? _selectedDraft;
  bool _isSending = false;
  final TextEditingController _commentController = TextEditingController();

  // Custom poll state
  String _selectedCategory = 'preference_vs';
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final TextEditingController _customCommentController =
      TextEditingController();

  static const List<String> _categories = [
    'preference_vs',
    'content_choice',
    'light_tmi',
    'schedule_choice',
    'mini_mission',
  ];

  static const Map<String, String> _categoryLabels = {
    'preference_vs': '취향 VS',
    'content_choice': '콘텐츠 선택',
    'light_tmi': '가벼운 TMI',
    'schedule_choice': '일정 선택',
    'mini_mission': '미니 미션',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchDrafts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    _customCommentController.dispose();
    super.dispose();
  }

  // ─── AI SUGGESTION METHODS ───

  Future<void> _fetchDrafts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (AppConfig.enableDemoMode) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          setState(() {
            _drafts = MockPolls.sampleDrafts;
            _isLoading = false;
          });
        }
        return;
      }

      final response = await Supabase.instance.client.functions.invoke(
        'ai-poll-suggest',
        body: {
          'channel_id': widget.channelId,
          'count': 5,
        },
      );

      if (response.status != 200) {
        final errorMsg = response.data is Map
            ? (response.data as Map)['error']?.toString() ??
                '투표 제안을 불러올 수 없어요'
            : '투표 제안을 불러올 수 없어요';
        throw Exception(errorMsg);
      }

      final data = response.data as Map<String, dynamic>;
      final draftsJson = data['drafts'] as List<dynamic>;

      if (mounted) {
        setState(() {
          _drafts = draftsJson
              .map((d) => PollDraft.fromJson(d as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _selectDraft(PollDraft draft) {
    setState(() => _selectedDraft = draft);
  }

  Future<void> _sendAiPoll() async {
    if (_selectedDraft == null) return;

    setState(() => _isSending = true);
    Navigator.pop(context);
    widget.onSend(
      _selectedDraft!,
      _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
    );
  }

  // ─── CUSTOM POLL METHODS ───

  bool get _isCustomPollValid {
    if (_questionController.text.trim().isEmpty) return false;
    final filledOptions = _optionControllers
        .where((c) => c.text.trim().isNotEmpty)
        .toList();
    return filledOptions.length >= 2;
  }

  void _addOption() {
    if (_optionControllers.length >= 4) return;
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  void _sendCustomPoll() {
    if (!_isCustomPollValid) return;

    final options = <PollOption>[];
    for (int i = 0; i < _optionControllers.length; i++) {
      final text = _optionControllers[i].text.trim();
      if (text.isNotEmpty) {
        options.add(PollOption(id: 'opt_$i', text: text));
      }
    }

    final draft = PollDraft(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      channelId: widget.channelId,
      category: _selectedCategory,
      question: _questionController.text.trim(),
      options: options,
      status: 'selected',
      createdAt: DateTime.now(),
    );

    Navigator.pop(context);
    widget.onSend(
      draft,
      _customCommentController.text.trim().isEmpty
          ? null
          : _customCommentController.text.trim(),
    );
  }

  // ─── BUILD ───

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
            const SizedBox(height: 8),

            // Tab bar
            _buildTabBar(isDark),
            const SizedBox(height: 8),

            // Tab content
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAiTab(isDark),
                  _buildCustomTab(isDark),
                ],
              ),
            ),

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
          const Icon(Icons.poll_outlined, size: 24, color: AppColors.primary500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '투표/VS 제안',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                Text(
                  '팬들과 대화를 시작해보세요',
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

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(3),
        dividerColor: Colors.transparent,
        labelColor:
            isDark ? AppColors.textMainDark : AppColors.textMainLight,
        unselectedLabelColor:
            isDark ? AppColors.textSubDark : AppColors.textSubLight,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'AI 추천', height: 36),
          Tab(text: '직접 만들기', height: 36),
        ],
      ),
    );
  }

  // ─── AI TAB ───

  Widget _buildAiTab(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: _buildAiContent(isDark)),
        if (_selectedDraft != null) ...[
          _buildCommentBar(isDark, _commentController),
          const SizedBox(height: 8),
          _buildSendButton(isDark, '채팅에 투표 보내기', _isSending, _sendAiPoll),
        ],
      ],
    );
  }

  Widget _buildAiContent(bool isDark) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '투표 아이디어를 생성하고 있어요...',
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 40,
                color:
                    isDark ? AppColors.textSubDark : AppColors.textSubLight),
            const SizedBox(height: 12),
            Text(
              '투표 제안을 불러올 수 없어요',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textMainDark
                    : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _fetchDrafts,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_drafts == null || _drafts!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text('투표 제안이 없습니다'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section label + reroll
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '하나를 골라주세요 (탭하여 선택)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textSubDark
                        : AppColors.textSubLight,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _selectedDraft = null;
                          _drafts = null;
                        });
                        _fetchDrafts();
                      },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh,
                        size: 14, color: AppColors.primary500),
                    SizedBox(width: 3),
                    Text(
                      '다시 생성',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _drafts!.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final draft = _drafts![index];
              final isSelected = _selectedDraft?.id == draft.id;
              return _PollDraftCard(
                draft: draft,
                isDark: isDark,
                isSelected: isSelected,
                onTap: () => _selectDraft(draft),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── CUSTOM TAB ───

  Widget _buildCustomTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),

          // Category selection
          Text(
            '카테고리',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(
                  _categoryLabels[cat] ?? cat,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.primary500,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary500,
                backgroundColor: isDark
                    ? AppColors.surfaceAltDark
                    : AppColors.primary500.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary500
                        : AppColors.primary500.withValues(alpha: 0.3),
                  ),
                ),
                showCheckmark: false,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedCategory = cat);
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Question input
          Text(
            '질문',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _questionController,
            maxLength: 100,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textMainDark
                  : AppColors.textMainLight,
            ),
            decoration: InputDecoration(
              hintText: '예: 여름 vs 겨울 어느 쪽이 더 좋아요?',
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSubDark
                    : AppColors.textSubLight,
              ),
              filled: true,
              fillColor: isDark
                  ? AppColors.surfaceAltDark
                  : AppColors.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              counterStyle: TextStyle(
                fontSize: 10,
                color: isDark
                    ? AppColors.textSubDark
                    : AppColors.textSubLight,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Options
          Row(
            children: [
              Text(
                '선택지',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSubDark
                      : AppColors.textSubLight,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(최소 2개, 최대 4개)',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textSubDark
                      : AppColors.textSubLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ...List.generate(_optionControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _optionControllers[index],
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                      decoration: InputDecoration(
                        hintText: '선택지 ${index + 1}',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.surfaceAltDark
                            : AppColors.surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  if (_optionControllers.length > 2)
                    IconButton(
                      onPressed: () => _removeOption(index),
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                        size: 20,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            );
          }),

          if (_optionControllers.length < 4)
            GestureDetector(
              onTap: _addOption,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: AppColors.primary500,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '선택지 추가',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Comment bar
          _buildCommentBar(isDark, _customCommentController),

          const SizedBox(height: 12),

          // Send button
          _buildSendButton(
            isDark,
            '채팅에 투표 보내기',
            false,
            _isCustomPollValid ? _sendCustomPoll : null,
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── SHARED WIDGETS ───

  Widget _buildCommentBar(bool isDark, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        maxLines: 2,
        minLines: 1,
        style: TextStyle(
          fontSize: 14,
          color:
              isDark ? AppColors.textMainDark : AppColors.textMainLight,
        ),
        decoration: InputDecoration(
          hintText: '한마디 코멘트 추가 (선택)...',
          hintStyle: TextStyle(
            fontSize: 13,
            color:
                isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildSendButton(
    bool isDark,
    String label,
    bool isSending,
    VoidCallback? onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton.icon(
          onPressed: isSending ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary600,
            foregroundColor: Colors.white,
            disabledBackgroundColor: isDark
                ? AppColors.surfaceAltDark
                : Colors.grey[300],
            disabledForegroundColor: isDark
                ? AppColors.textSubDark
                : Colors.grey[500],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 18),
          label: Text(isSending ? '전송 중...' : label),
        ),
      ),
    );
  }
}

class _PollDraftCard extends StatelessWidget {
  final PollDraft draft;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  const _PollDraftCard({
    required this.draft,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
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
            color:
                isSelected ? AppColors.primary500 : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary500.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                draft.categoryLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Question
            Text(
              draft.question,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textMainDark
                    : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 8),
            // Options preview
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: draft.options.map((opt) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    opt.text,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
