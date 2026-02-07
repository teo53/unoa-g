import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/fan_filter.dart';
import '../../../providers/private_card_provider.dart';

/// Step 3: Preview & Send confirmation
/// Shows the card as the fan would see it, with recipient summary and warning
class CardPreviewStep extends ConsumerWidget {
  const CardPreviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final composeState = ref.watch(privateCardComposeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final previewText = composeState.cardText;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Step header
          _buildStepHeader(isDark, '3', '미리보기'),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '팬에게 이렇게 보여집니다',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Card preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.privateCardGradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.vip.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card label
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.vip, AppColors.cardAccentPink],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('💌', style: TextStyle(fontSize: 12)),
                                SizedBox(width: 4),
                                Text(
                                  '프라이빗 카드',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Card image
                    if (composeState.selectedTemplateImageUrl != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: CachedNetworkImage(
                              imageUrl: composeState.selectedTemplateImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppColors.cardGradientEnd,
                                child: const Center(
                                  child: Icon(Icons.favorite, color: Colors.white, size: 40),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.cardGradientEnd,
                                child: const Center(
                                  child: Icon(Icons.favorite, color: Colors.white, size: 40),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Message text
                    if (previewText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Text(
                          previewText,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.7,
                            color: isDark ? Colors.white : AppColors.text,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    // Signature
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${DemoConfig.demoCreatorName.replaceAll(' (데모)', '')} 드림',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Recipient summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '전송 정보',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: '수신자',
                    value: '${composeState.selectedFanCount}명',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  if (composeState.selectedFilter != null)
                    _InfoRow(
                      label: '사용된 필터',
                      value: composeState.selectedFilter!.displayName,
                      isDark: isDark,
                    ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    label: '카드 글자수',
                    value: '${composeState.cardText.length}자',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Warning
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${composeState.selectedFanCount}명의 팬에게 전송됩니다.\n전송 후에는 취소할 수 없습니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.amber[200] : AppColors.warning,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
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
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.text,
          ),
        ),
      ],
    );
  }
}
