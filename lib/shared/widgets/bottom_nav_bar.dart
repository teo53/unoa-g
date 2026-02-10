import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
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
          _NavItem(
            icon: Icons.home_rounded,
            outlinedIcon: Icons.home_outlined,
            label: '홈',
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
            showBadge: true,
          ),
          _NavItem(
            icon: Icons.chat_bubble_rounded,
            outlinedIcon: Icons.chat_bubble_outline_rounded,
            label: '메시지',
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
            showBadge: true,
          ),
          _NavItem(
            icon: Icons.campaign_rounded,
            outlinedIcon: Icons.campaign_outlined,
            label: '펀딩',
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.explore_rounded,
            outlinedIcon: Icons.explore_outlined,
            label: '탐색',
            isSelected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _NavItem(
            icon: Icons.person_rounded,
            outlinedIcon: Icons.person_outline_rounded,
            label: '프로필',
            isSelected: currentIndex == 4,
            onTap: () => onTap(4),
            isProfile: true,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showBadge;
  final bool isProfile;

  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.showBadge = false,
    this.isProfile = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = AppColors.primary;
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  if (isProfile)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? activeColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Container(
                          color: isDark ? Colors.grey[700] : Colors.grey[200],
                          child: Icon(
                            Icons.person,
                            size: 20,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                        ),
                      ),
                    )
                  else
                    Icon(
                      isSelected ? icon : outlinedIcon,
                      size: 28,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                  if (showBadge)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.surfaceLight,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
