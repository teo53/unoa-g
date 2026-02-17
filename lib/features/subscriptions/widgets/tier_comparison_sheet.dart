import 'package:flutter/material.dart';

import '../../../core/config/business_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Tier comparison bottom sheet.
///
/// Shows BASIC / STANDARD / VIP side-by-side for the *current* purchase platform.
/// (Never shows cross-platform price comparison inside iOS.)
class TierComparisonSheet {
  TierComparisonSheet._();

  static const List<String> _tiers = ['BASIC', 'STANDARD', 'VIP'];

  static void show(
    BuildContext context, {
    required PurchasePlatform platform,
    required String currentTier,
    required bool isDemoMode,
    double multiplier = 1.0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      borderRadius: AppRadius.smBR,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  '구독 등급 비교',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '표시된 가격은 VAT(부가가치세)가 포함된 금액입니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.textMutedDark : AppColors.textMuted,
                  ),
                ),
                if (platform == PurchasePlatform.android)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Android 앱 결제의 경우 인앱결제 수수료가 포함될 수 있습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMuted,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Horizontal tier cards (3-column feel)
                SizedBox(
                  height: 380,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _tiers.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final tier = _tiers[index];
                      final isCurrent = tier.toUpperCase() == currentTier.toUpperCase();
                      final basePrice = BusinessConfig.getTierPrice(tier, platform);
                      final priceKrw = multiplier == 1.0
                          ? basePrice
                          : ((basePrice * multiplier / 100).round() * 100);
                      final tokens = BusinessConfig.getTokensForTier(tier);
                      final benefits = BusinessConfig.tierBenefits[tier.toUpperCase()] ?? const <String>[];

                      return _TierCard(
                        tier: tier,
                        priceKrw: priceKrw,
                        basePrice: multiplier != 1.0 ? basePrice : null,
                        tokens: tokens,
                        benefits: benefits,
                        isCurrent: isCurrent,
                        isDark: isDark,
                        onSelect: isCurrent
                            ? null
                            : () {
                                Navigator.pop(sheetContext);
                                if (isDemoMode) {
                                  showDialog(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('데모 모드'),
                                      content: Text('"$tier" 등급으로 변경된 것으로 처리됩니다.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(c),
                                          child: const Text('확인'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('구독 등급 변경 결제는 준비 중입니다.'),
                                    ),
                                  );
                                }
                              },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  '글자수 한도는 구독 등급과 별개로, 구독 유지 기간(누적 일수)에 따라 점진적으로 증가합니다.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TierCard extends StatelessWidget {
  final String tier;
  final int priceKrw;
  final int? basePrice;
  final int tokens;
  final List<String> benefits;
  final bool isCurrent;
  final bool isDark;
  final VoidCallback? onSelect;

  const _TierCard({
    required this.tier,
    required this.priceKrw,
    this.basePrice,
    required this.tokens,
    required this.benefits,
    required this.isCurrent,
    required this.isDark,
    required this.onSelect,
  });

  String _formatKrw(int amount) {
    return '${amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        )}원';
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isCurrent
        ? AppColors.primary600
        : (isDark ? AppColors.borderDark : AppColors.borderLight);

    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                tier,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              const Spacer(),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary600.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '현재',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (basePrice != null) ...[
            Text(
              _formatKrw(basePrice!),
              style: TextStyle(
                fontSize: 14,
                decoration: TextDecoration.lineThrough,
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            _formatKrw(priceKrw),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '월 구독',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                size: 16,
                color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
              ),
              const SizedBox(width: 8),
              Text(
                '답글 토큰: ${tokens}개/브로드캐스트',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: benefits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefits[index],
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSelect,
              style: FilledButton.styleFrom(
                backgroundColor: isCurrent ? (isDark ? AppColors.borderDark : AppColors.borderLight) : AppColors.primary600,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.baseBR),
              ),
              child: Text(isCurrent ? '현재 등급' : '이 등급으로 변경'),
            ),
          ),
        ],
      ),
    );
  }
}
