import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/business_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/private_card_provider.dart';
import 'card_design_picker.dart';

/// Step 1: Card content editing
/// - Card design selection (background template)
/// - Card text with personalization placeholders
/// - Media attachments
class CardEditorStep extends ConsumerStatefulWidget {
  const CardEditorStep({super.key});

  @override
  ConsumerState<CardEditorStep> createState() => _CardEditorStepState();
}

class _CardEditorStepState extends ConsumerState<CardEditorStep> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    final currentText = ref.read(privateCardComposeProvider).cardText;
    _textController = TextEditingController(text: currentText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final composeState = ref.watch(privateCardComposeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const maxChars = BusinessConfig.privateCardMaxChars;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // ① Step indicator
          _buildStepHeader(isDark, '1', '프라이빗 카드 작성하기'),

          const SizedBox(height: 20),

          // ② Card design picker
          const CardDesignPicker(),

          const SizedBox(height: 24),

          // ③ Card text input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '카드쓰기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.text,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '(필수)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Text input
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _textController,
                        maxLines: 6,
                        maxLength: maxChars,
                        onChanged: (text) {
                          ref.read(privateCardComposeProvider.notifier).updateCardText(text);
                        },
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white : AppColors.text,
                          height: 1.6,
                        ),
                        decoration: InputDecoration(
                          hintText: '팬에게 전할 마음을 담아보세요\n($maxChars자 이내)',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          counterText: '',
                        ),
                      ),
                      // Character count
                      Padding(
                        padding: const EdgeInsets.only(right: 16, bottom: 12),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${composeState.cardText.length}/$maxChars',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: composeState.cardText.length > maxChars * 0.9
                                  ? AppColors.primary
                                  : isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),

          const SizedBox(height: 24),

          // ④ Media attachments
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '콘텐츠',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),

                // Media preview / add button
                if (composeState.attachedMediaUrls.isEmpty)
                  _buildAddMediaButton(isDark)
                else
                  _buildMediaPreview(isDark, composeState),

                const SizedBox(height: 8),
                Text(
                  '최대 용량 : ${BusinessConfig.privateCardMaxMediaSizeMb}MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
                Text(
                  '지원 형식: PNG, JPG, GIF, MP4, MOV, m4a, mp3',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(bool isDark, String number, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.vip,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMediaButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        // Demo mode: show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('데모 모드에서는 미디어 첨부를 지원하지 않습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: 160,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.cardWarmPink, AppColors.cardGradientEnd],
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  '콘텐츠 추가',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview(bool isDark, PrivateCardComposeState state) {
    return Wrap(
      spacing: 8,
      children: [
        ...state.attachedMediaUrls.asMap().entries.map((entry) {
          return Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                ),
                child: const Icon(Icons.image, size: 32),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    ref.read(privateCardComposeProvider.notifier).removeMedia(entry.key);
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          );
        }),
        _buildAddMediaButton(isDark),
      ],
    );
  }
}

