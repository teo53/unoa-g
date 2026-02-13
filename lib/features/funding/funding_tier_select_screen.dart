import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'funding_checkout_screen.dart';

/// Screen for selecting a reward tier
class FundingTierSelectScreen extends StatefulWidget {
  final Map<String, dynamic> campaign;
  final List<Map<String, dynamic>> tiers;

  const FundingTierSelectScreen({
    super.key,
    required this.campaign,
    required this.tiers,
  });

  @override
  State<FundingTierSelectScreen> createState() =>
      _FundingTierSelectScreenState();
}

class _FundingTierSelectScreenState extends State<FundingTierSelectScreen> {
  String? _selectedTierId;

  Map<String, dynamic>? get _selectedTier {
    if (_selectedTierId == null) return null;
    try {
      return widget.tiers.firstWhere((t) => t['id'] == _selectedTierId);
    } catch (_) {
      return null;
    }
  }

  int get _totalAmount {
    final tier = _selectedTier;
    if (tier == null) return 0;
    return tier['price_krw'] as int? ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        title: Text(
          '리워드 선택',
          style: TextStyle(
            color: isDark ? AppColors.textDark : AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.textDark : AppColors.text,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Tier list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Campaign info
                Text(
                  widget.campaign['title'] ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDark : AppColors.text,
                  ),
                ),
                const SizedBox(height: 20),

                // Tiers
                ...widget.tiers.map((tier) {
                  final isSelected = tier['id'] == _selectedTierId;
                  final isSoldOut = tier['total_quantity'] != null &&
                      (tier['remaining_quantity'] ?? 0) <= 0;

                  return GestureDetector(
                    onTap: isSoldOut
                        ? null
                        : () {
                            setState(() {
                              _selectedTierId = tier['id'];
                            });
                          },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.surfaceDark : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.borderDark
                                  : AppColors.border),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Opacity(
                        opacity: isSoldOut ? 0.5 : 1,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Radio indicator
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.borderDark
                                          : AppColors.border),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),

                            // Tier info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          tier['title'] ?? '',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppColors.textDark
                                                : AppColors.text,
                                          ),
                                        ),
                                      ),
                                      if (isSoldOut)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.danger100,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            '품절',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.danger,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_formatNumber(tier['price_krw'] ?? 0)}원',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    tier['description'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? AppColors.textMutedDark
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                  if (tier['total_quantity'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '${tier['remaining_quantity']}개 남음',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color:
                                            (tier['remaining_quantity'] ?? 0) <=
                                                    5
                                                ? AppColors.danger
                                                : (isDark
                                                    ? AppColors.textMutedDark
                                                    : AppColors.textMuted),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom bar
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
              ),
            ),
            child: Column(
              children: [
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '총 후원금액',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '${_formatNumber(_totalAmount)}원',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        (_selectedTierId == null || _selectedTier == null)
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FundingCheckoutScreen(
                                      campaign: widget.campaign,
                                      tier: _selectedTier!,
                                    ),
                                  ),
                                );
                              },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      foregroundColor: AppColors.onPrimary,
                      disabledBackgroundColor: isDark
                          ? AppColors.surfaceAltDark
                          : AppColors.surfaceAlt,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _selectedTierId == null ? '리워드를 선택해주세요' : '다음',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  String _formatNumber(int number) {
    if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(0)}만';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}천';
    }
    return number.toString();
  }
}
