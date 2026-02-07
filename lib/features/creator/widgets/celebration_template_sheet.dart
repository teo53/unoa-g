import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/template_renderer.dart';
import '../../../data/mock/mock_celebrations.dart';
import '../../../data/models/celebration_event.dart';
import '../../../data/models/celebration_template.dart';

/// Bottom sheet for selecting and sending celebration templates.
///
/// Shows templates for the given event type, with variable preview.
/// Creator selects a template → sees rendered preview → sends.
class CelebrationTemplateSheet extends StatefulWidget {
  final CelebrationEvent event;
  final String channelId;
  final String artistName;
  final Function(String renderedText) onSend;

  const CelebrationTemplateSheet({
    super.key,
    required this.event,
    required this.channelId,
    required this.artistName,
    required this.onSend,
  });

  static Future<void> show({
    required BuildContext context,
    required CelebrationEvent event,
    required String channelId,
    required String artistName,
    required Function(String renderedText) onSend,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CelebrationTemplateSheet(
        event: event,
        channelId: channelId,
        artistName: artistName,
        onSend: onSend,
      ),
    );
  }

  @override
  State<CelebrationTemplateSheet> createState() =>
      _CelebrationTemplateSheetState();
}

class _CelebrationTemplateSheetState extends State<CelebrationTemplateSheet> {
  List<CelebrationTemplate>? _templates;
  bool _isLoading = false;
  CelebrationTemplate? _selectedTemplate;
  bool _isSending = false;

  final TextEditingController _editController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);

    try {
      if (AppConfig.enableDemoMode) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() {
            _templates =
                MockCelebrations.templatesForType(widget.event.eventType);
            _isLoading = false;
          });
        }
        return;
      }

      // Production: Load from Supabase celebration_templates
      final response = await Supabase.instance.client
          .from('celebration_templates')
          .select()
          .or('channel_id.is.null,channel_id.eq.${widget.channelId}')
          .eq('event_type', widget.event.eventType)
          .eq('is_active', true)
          .order('sort_order');

      if (mounted) {
        setState(() {
          _templates = (response as List<dynamic>)
              .map((t) => CelebrationTemplate.fromJson(
                  t as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _templates = [];
          _isLoading = false;
        });
      }
    }
  }

  String _renderTemplate(String templateText) {
    return TemplateRenderer.render(
      templateText,
      nickname: widget.event.payload.nickname,
      dayCount: widget.event.payload.dayCount,
      artistName: widget.artistName,
    );
  }

  void _selectTemplate(CelebrationTemplate template) {
    final rendered = _renderTemplate(template.templateText);
    setState(() {
      _selectedTemplate = template;
      _editController.text = rendered;
      _isEditing = false;
    });
  }

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
    if (_isEditing) {
      // Focus on edit field
    }
  }

  Future<void> _send() async {
    if (_selectedTemplate == null) return;

    final text = _isEditing
        ? _editController.text.trim()
        : _renderTemplate(_selectedTemplate!.templateText);

    if (text.isEmpty) return;

    setState(() => _isSending = true);
    Navigator.pop(context);
    widget.onSend(text);
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
            // Handle
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

            // Template list
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else if (_templates != null && _templates!.isNotEmpty)
              Flexible(child: _buildTemplateList(isDark))
            else
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  '사용 가능한 템플릿이 없습니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSubDark
                        : AppColors.textSubLight,
                  ),
                ),
              ),

            // Preview + Edit + Send (when selected)
            if (_selectedTemplate != null) ...[
              _buildPreviewSection(isDark),
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
          Text(
            widget.event.eventTypeEmoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.event.payload.nickname}님에게 축하 보내기',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                Text(
                  widget.event.isBirthday
                      ? '생일 축하 메시지'
                      : '구독 ${widget.event.payload.dayCount}일 기념 메시지',
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

  Widget _buildTemplateList(bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _templates!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final template = _templates![index];
        final isSelected = _selectedTemplate?.id == template.id;
        final rendered = _renderTemplate(template.templateText);

        return GestureDetector(
          onTap: () => _selectTemplate(template),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
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
            child: Row(
              children: [
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.check_circle,
                      size: 20,
                      color: AppColors.primary500,
                    ),
                  ),
                Expanded(
                  child: Text(
                    rendered,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '미리보기',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSubDark
                      : AppColors.textSubLight,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _toggleEdit,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isEditing ? Icons.preview : Icons.edit_outlined,
                      size: 14,
                      color: AppColors.primary500,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _isEditing ? '미리보기' : '수정하기',
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
          const SizedBox(height: 8),
          if (_isEditing)
            TextField(
              controller: _editController,
              maxLines: 3,
              minLines: 2,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textMainDark
                    : AppColors.textMainLight,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: '메시지를 수정하세요...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSubDark
                      : AppColors.textSubLight,
                ),
              ),
            )
          else
            Text(
              _renderTemplate(_selectedTemplate!.templateText),
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? AppColors.textMainDark
                    : AppColors.textMainLight,
              ),
            ),
        ],
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
          onPressed: _isSending ? null : _send,
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
          label: Text(
            _isSending
                ? '전송 중...'
                : '${widget.event.payload.nickname}님에게 보내기',
          ),
        ),
      ),
    );
  }
}
