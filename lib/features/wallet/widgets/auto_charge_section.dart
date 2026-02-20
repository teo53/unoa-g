/// Auto-Charge Settings Section
/// 자동충전 설정 UI 위젯
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auto_charge_provider.dart';

class AutoChargeSection extends ConsumerWidget {
  const AutoChargeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final configAsync = ref.watch(autoChargeConfigProvider);

    return configAsync.when(
      data: (config) {
        final isEnabled = config?.isEnabled ?? false;
        final threshold = config?.thresholdDt ?? 100;
        final amount = config?.chargeAmountDt ?? 1000;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.base),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.autorenew_rounded,
                    size: 20,
                    color: isEnabled ? AppColors.success : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '자동 충전',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Switch(
                    value: isEnabled,
                    activeThumbColor: AppColors.primary600,
                    onChanged: (v) {
                      ref
                          .read(autoChargeNotifierProvider.notifier)
                          .toggleEnabled(v);
                    },
                  ),
                ],
              ),
              if (isEnabled) ...[
                const SizedBox(height: 12),
                Text(
                  '잔액이 $threshold DT 이하가 되면\n자동으로 $amount DT를 충전합니다',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSubDark : AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _SettingChip(
                      label: '기준: $threshold DT',
                      isDark: isDark,
                      onTap: () =>
                          _showThresholdPicker(context, ref, threshold),
                    ),
                    const SizedBox(width: 8),
                    _SettingChip(
                      label: '충전: $amount DT',
                      isDark: isDark,
                      onTap: () => _showAmountPicker(context, ref, amount,
                          threshold: threshold),
                    ),
                  ],
                ),
                if (config != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '이번 달 충전 횟수: ${config.chargesThisMonth}/${config.maxMonthlyCharges}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showThresholdPicker(BuildContext context, WidgetRef ref, int current) {
    final options = [50, 100, 300, 500, 1000];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '자동충전 기준 잔액',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            ...options.map((o) => ListTile(
                  title: Text('$o DT 이하'),
                  trailing: current == o
                      ? const Icon(Icons.check, color: AppColors.success)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    final config = ref.read(autoChargeConfigProvider).value;
                    ref.read(autoChargeNotifierProvider.notifier).saveConfig(
                          isEnabled: true,
                          thresholdDt: o,
                          chargeAmountDt: config?.chargeAmountDt ?? 1000,
                        );
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAmountPicker(BuildContext context, WidgetRef ref, int current,
      {required int threshold}) {
    final options = [500, 1000, 3000, 5000, 10000];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '자동충전 금액',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            ...options.map((o) => ListTile(
                  title: Text('$o DT'),
                  trailing: current == o
                      ? const Icon(Icons.check, color: AppColors.success)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(autoChargeNotifierProvider.notifier).saveConfig(
                          isEnabled: true,
                          thresholdDt: threshold,
                          chargeAmountDt: o,
                        );
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SettingChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _SettingChip({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSubDark : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.edit_outlined,
              size: 14,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
