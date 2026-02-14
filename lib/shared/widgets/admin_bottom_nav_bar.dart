import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Bottom navigation bar for admin mode
/// 4탭 구조: 대시보드, 크리에이터, 정산, 설정
class AdminBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomSafeArea = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 8 + bottomSafeArea),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _AdminNavItem(
            icon: Icons.dashboard_rounded,
            outlinedIcon: Icons.dashboard_outlined,
            label: '대시보드',
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _AdminNavItem(
            icon: Icons.people_rounded,
            outlinedIcon: Icons.people_outlined,
            label: '크리에이터',
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _AdminNavItem(
            icon: Icons.account_balance_wallet_rounded,
            outlinedIcon: Icons.account_balance_wallet_outlined,
            label: '정산',
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _AdminNavItem(
            icon: Icons.settings_rounded,
            outlinedIcon: Icons.settings_outlined,
            label: '설정',
            isSelected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AdminNavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = Colors.indigo;
    final inactiveColor = isDark ? Colors.grey[500] : Colors.grey[400];

    return Semantics(
      label: '$label 탭',
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? icon : outlinedIcon,
                size: 26,
                color: isSelected ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
