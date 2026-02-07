import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/mock/mock_polls.dart';
import '../../../data/models/poll_draft.dart';

/// Bottom sheet for AI-generated poll/VS suggestions.
///
/// Flow: loading → loaded(5 drafts) → selected(1 draft) → sending → sent
///
/// IMPORTANT: Creator must select and send — AI never auto-posts polls.
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

class _PollSuggestionSheetState extends State<PollSuggestionSheet> {
  List<PollDraft>? _drafts;
  bool _isLoading = false;
  String? _error;
  PollDraft? _selectedDraft;
  bool _isSending = false;

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDrafts();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchDrafts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (AppConfig.enableDemoMode) {
        // Demo mode: use mock data
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
            ? (response.data as Map)['error']?.toString() ?? '투표 제안을 불러올 수 없어요'
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

  Future<void> _sendPoll() async {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
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
            const SizedBox(height: 12),

            // Content
            Flexible(
              child: _buildContent(isDark),
            ),

            // Comment + Send bar (only when a draft is selected)
            if (_selectedDraft != null) ...[
              _buildCommentBar(isDark),
              const SizedBox(height: 8),
              _buildSendButton(isDark),
            ],

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
          Icon(Icons.poll_outlined, size: 24, color: AppColors.primary500),
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
                    color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                  ),
                ),
                Text(
                  '팬들과 대화를 시작해보세요',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
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

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
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
              '투표 아이디어를 생성하고 있어요...',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
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
            Icon(Icons.cloud_off_outlined, size: 40,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight),
            const SizedBox(height: 12),
            Text(
              '투표 제안을 불러올 수 없어요',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
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
                    color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _isLoading ? null : () {
                  setState(() {
                    _selectedDraft = null;
                    _drafts = null;
                  });
                  _fetchDrafts();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 14, color: AppColors.primary500),
                    const SizedBox(width: 3),
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

  Widget _buildCommentBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _commentController,
        maxLines: 2,
        minLines: 1,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
        ),
        decoration: InputDecoration(
          hintText: '한마디 코멘트 추가 (선택)...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildSendButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton.icon(
          onPressed: _isSending ? null : _sendPoll,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 18),
          label: Text(_isSending ? '전송 중...' : '채팅에 투표 보내기'),
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
            color: isSelected ? AppColors.primary500 : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary500.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                draft.categoryLabel,
                style: TextStyle(
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
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 8),
            // Options preview
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: draft.options.map((opt) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    opt.text,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
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
