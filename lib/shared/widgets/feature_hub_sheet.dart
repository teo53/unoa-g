import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Quick-access feature hub bottom sheet.
///
/// Shows a grid of shortcuts to key app features,
/// helping users discover functionality in one tap.
class FeatureHubSheet {
  FeatureHubSheet._();

  static void show(BuildContext context, {bool isCreator = false}) {
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
                const SizedBox(height: 20),

                // Title
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '바로가기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Grid
                _buildGrid(sheetContext, isDark, isCreator),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildGrid(
    BuildContext context,
    bool isDark,
    bool isCreator,
  ) {
    final items = _getItems(isCreator);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 8,
      childAspectRatio: 0.85,
      children: items.map((item) {
        return _HubItem(
          icon: item.icon,
          label: item.label,
          color: item.color,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.push(item.route);
          },
        );
      }).toList(),
    );
  }

  static List<_HubItemData> _getItems(bool isCreator) {
    final items = <_HubItemData>[
      const _HubItemData(
        icon: Icons.account_balance_wallet_outlined,
        label: '지갑',
        route: '/wallet',
        color: AppColors.primary500,
      ),
      const _HubItemData(
        icon: Icons.card_membership_outlined,
        label: '구독 관리',
        route: '/subscriptions',
        color: Colors.blue,
      ),
      const _HubItemData(
        icon: Icons.notifications_outlined,
        label: '알림',
        route: '/notifications',
        color: Colors.orange,
      ),
      const _HubItemData(
        icon: Icons.settings_outlined,
        label: '설정',
        route: '/settings',
        color: Colors.grey,
      ),
      const _HubItemData(
        icon: Icons.headset_mic_outlined,
        label: '고객센터',
        route: '/help',
        color: Colors.green,
      ),
      const _HubItemData(
        icon: Icons.add_circle_outline,
        label: 'DT 충전',
        route: '/wallet/charge',
        color: Colors.deepPurple,
      ),
    ];

    if (isCreator) {
      items.addAll(const [
        _HubItemData(
          icon: Icons.dashboard_outlined,
          label: '대시보드',
          route: '/creator/dashboard',
          color: AppColors.primary500,
        ),
        _HubItemData(
          icon: Icons.receipt_long_outlined,
          label: '정산',
          route: '/creator/settlement',
          color: Colors.teal,
        ),
      ]);
    }

    return items;
  }
}

class _HubItemData {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _HubItemData({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}

class _HubItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _HubItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
        ],
      ),
    );
  }
}
