import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Bottom navigation bar for creator/artist mode
/// 5탭 구조: 대시보드, 채팅, 펀딩, 탐색, 프로필
class CreatorBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CreatorBottomNavBar({
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
          // 대시보드 - CRM 통합 (수익, 통계, 팬 관리)
          _CreatorNavItem(
            icon: Icons.dashboard_rounded,
            outlinedIcon: Icons.dashboard_outlined,
            label: '대시보드',
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
            showBadge: true, // 팬 메시지 알림
          ),
          // 채팅 - 내 채널 + 프라이빗 카드 + 구독 아티스트
          _CreatorNavItem(
            icon: Icons.chat_bubble_rounded,
            outlinedIcon: Icons.chat_bubble_outline_rounded,
            label: '채팅',
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          // 펀딩 - 내 캠페인 + 탐색
          _CreatorNavItem(
            icon: Icons.campaign_rounded,
            outlinedIcon: Icons.campaign_outlined,
            label: '펀딩',
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          // 탐색 - 다른 아티스트 탐색
          _CreatorNavItem(
            icon: Icons.explore_rounded,
            outlinedIcon: Icons.explore_outlined,
            label: '탐색',
            isSelected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          // 프로필
          _CreatorNavItem(
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

class _CreatorNavItem extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showBadge;
  final bool isProfile;

  const _CreatorNavItem({
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
    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? Colors.grey[500] : Colors.grey[400];

    return GestureDetector(
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
                    size: 26,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                if (showBadge)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
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
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
