import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/template_renderer.dart';

/// 웰컴 채팅 설정 바텀시트
///
/// 크리에이터가 신규 구독자에게 자동 전송되는 웰컴 메시지를 설정합니다.
/// - 자동 웰컴 메시지 ON/OFF
/// - 메시지 내용 편집 (템플릿 변수 지원)
/// - 미디어 첨부 (이미지/비디오)
/// - 미리보기
class WelcomeChatSettings extends ConsumerStatefulWidget {
  final bool autoWelcomeEnabled;
  final String welcomeMessage;
  final String? welcomeMediaUrl;
  final void Function(bool enabled, String message, String? mediaUrl) onSave;

  const WelcomeChatSettings({
    super.key,
    required this.autoWelcomeEnabled,
    required this.welcomeMessage,
    this.welcomeMediaUrl,
    required this.onSave,
  });

  /// 바텀시트로 표시
  static Future<void> show({
    required BuildContext context,
    required bool autoWelcomeEnabled,
    required String welcomeMessage,
    String? welcomeMediaUrl,
    required void Function(bool, String, String?) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: WelcomeChatSettings(
            autoWelcomeEnabled: autoWelcomeEnabled,
            welcomeMessage: welcomeMessage,
            welcomeMediaUrl: welcomeMediaUrl,
            onSave: onSave,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<WelcomeChatSettings> createState() =>
      _WelcomeChatSettingsState();
}

class _WelcomeChatSettingsState extends ConsumerState<WelcomeChatSettings> {
  late bool _isEnabled;
  late TextEditingController _messageController;
  String? _mediaUrl;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.autoWelcomeEnabled;
    _messageController = TextEditingController(text: widget.welcomeMessage);
    _mediaUrl = widget.welcomeMediaUrl;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// 템플릿 변수 목록
  static const _templateVars = [
    ('{nickname}', '팬 이름'),
    ('{day_count}', '구독 일수'),
    ('{artist_name}', '아티스트명'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '웰컴 메시지 설정',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onSave(
                      _isEnabled,
                      _messageController.text.trim(),
                      _mediaUrl,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('저장'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // ON/OFF 토글
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.waving_hand_outlined,
                        color: _isEnabled ? AppColors.primary : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '자동 웰컴 메시지',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '신규 구독자에게 자동으로 인사 메시지를 보냅니다',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isEnabled,
                        onChanged: (v) => setState(() => _isEnabled = v),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 메시지 편집 영역
                AnimatedOpacity(
                  opacity: _isEnabled ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_isEnabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '메시지 내용',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),

                        // 텍스트 입력
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: TextField(
                            controller: _messageController,
                            maxLines: 5,
                            maxLength: 500,
                            decoration: InputDecoration(
                              hintText:
                                  '웰컴 메시지를 입력하세요...\n예: {nickname}님, 환영합니다!',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 템플릿 변수 칩
                        Text(
                          '사용 가능한 변수',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _templateVars.map((v) {
                            return ActionChip(
                              label: Text('${v.$1} ${v.$2}'),
                              labelStyle: Theme.of(context).textTheme.bodySmall,
                              backgroundColor:
                                  isDark ? Colors.grey[800] : Colors.grey[100],
                              side: BorderSide.none,
                              onPressed: () {
                                final sel = _messageController.selection;
                                final text = _messageController.text;
                                final newText =
                                    text.replaceRange(sel.start, sel.end, v.$1);
                                _messageController.value = TextEditingValue(
                                  text: newText,
                                  selection: TextSelection.collapsed(
                                    offset: sel.start + v.$1.length,
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // 미리보기
                        Text(
                          '미리보기',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        _buildPreview(isDark),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(bool isDark) {
    final rendered = TemplateRenderer.preview(
      _messageController.text.isEmpty
          ? '안녕하세요! 제 채널에 와주셔서 감사합니다.'
          : _messageController.text,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '웰컴 메시지',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rendered,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
