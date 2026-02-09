import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/accessibility_helper.dart';
import '../../providers/settlement_provider.dart';
import '../../shared/widgets/app_scaffold.dart';

/// 크리에이터 세금 설정 화면
/// 소득유형 선택: 사업소득 3.3% / 기타소득 8.8% / 세금계산서 0%
class TaxSettingsScreen extends ConsumerStatefulWidget {
  const TaxSettingsScreen({super.key});

  @override
  ConsumerState<TaxSettingsScreen> createState() => _TaxSettingsScreenState();
}

class _TaxSettingsScreenState extends ConsumerState<TaxSettingsScreen> {
  String? _selectedIncomeType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(settlementProvider);
    _selectedIncomeType = state.incomeType ?? 'business_income';
  }

  Future<void> _saveIncomeType() async {
    if (_selectedIncomeType == null) return;

    setState(() => _isSaving = true);

    final success = await ref
        .read(settlementProvider.notifier)
        .updateIncomeType(_selectedIncomeType!);

    if (mounted) {
      setState(() => _isSaving = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('소득유형이 변경되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('변경에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentType = ref.watch(settlementProvider).incomeType;

    return AppScaffold(
      showStatusBar: true,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              children: [
                AccessibleTapTarget(
                  semanticLabel: '뒤로가기',
                  onTap: () => context.pop(),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                  ),
                ),
                const Expanded(
                  child: Text(
                    '세금 설정',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.info.withValues(alpha: 0.1)
                          : AppColors.info.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 20, color: AppColors.info),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '정산 시 적용되는 원천징수 세율을 설정합니다. '
                            '변경 사항은 다음 정산부터 적용됩니다.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    '소득유형 선택',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Income type options
                  _buildIncomeTypeOption(
                    isDark,
                    title: '사업소득',
                    subtitle: '프리랜서/개인사업자 (가장 일반적)',
                    taxRate: '3.3%',
                    description: '소득세 3.0% + 지방소득세 0.3%',
                    value: 'business_income',
                    isRecommended: true,
                  ),
                  const SizedBox(height: 12),

                  _buildIncomeTypeOption(
                    isDark,
                    title: '기타소득',
                    subtitle: '일시적 소득 (비정기 활동)',
                    taxRate: '8.8%',
                    description: '소득세 8.0% + 지방소득세 0.8%',
                    value: 'other_income',
                  ),
                  const SizedBox(height: 12),

                  _buildIncomeTypeOption(
                    isDark,
                    title: '세금계산서 발행',
                    subtitle: '사업자등록증 보유자',
                    taxRate: '0%',
                    description: '원천징수 없음, 부가세 별도 신고',
                    value: 'invoice',
                  ),

                  const SizedBox(height: 24),

                  // Current status
                  if (currentType != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '현재 적용 세율: ${_getIncomeTypeLabel(currentType)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (_isSaving || _selectedIncomeType == currentType)
                          ? null
                          : _saveIncomeType,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppColors.primary600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _selectedIncomeType == currentType
                                  ? '현재 설정과 동일합니다'
                                  : '세율 변경 저장',
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
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeTypeOption(
    bool isDark, {
    required String title,
    required String subtitle,
    required String taxRate,
    required String description,
    required String value,
    bool isRecommended = false,
  }) {
    final isSelected = _selectedIncomeType == value;

    return InkWell(
      onTap: () => setState(() => _selectedIncomeType = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedIncomeType,
              onChanged: (v) => setState(() => _selectedIncomeType = v),
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '추천',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceAltDark
                              : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          taxRate,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getIncomeTypeLabel(String type) {
    switch (type) {
      case 'business_income':
        return '사업소득 (3.3%)';
      case 'other_income':
        return '기타소득 (8.8%)';
      case 'invoice':
        return '세금계산서 (0%)';
      default:
        return type;
    }
  }
}
