import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// 설정 화면 공통 위젯 모음
///
/// 사용법:
/// - SettingsSectionTitle: 섹션 제목 ("계정", "알림" 등)
/// - SettingsGroup: 설정 항목 그룹 컨테이너
/// - SettingsItem: 개별 설정 항목
///
/// 예시:
/// ```dart
/// SettingsSectionTitle(title: '계정'),
/// SettingsGroup(
///   children: [
///     SettingsItem(
///       icon: Icons.person_outline,
///       title: '프로필 편집',
///       onTap: () {},
///     ),
///   ],
/// ),
/// ```

/// 설정 섹션 제목
class SettingsSectionTitle extends StatelessWidget {
  final String title;

  const SettingsSectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
        ),
      ),
    );
  }
}

/// 설정 항목 그룹 컨테이너
///
/// 둥근 모서리와 테두리가 있는 카드 스타일
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const SettingsGroup({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              item,
              if (index < children.length - 1)
                Divider(
                  height: 1,
                  indent: 56,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// 개별 설정 항목
///
/// 아이콘, 제목, 부제목, 후행 위젯(스위치 등)을 포함
class SettingsItem extends StatelessWidget {
  /// 왼쪽 아이콘
  final IconData icon;

  /// 제목 텍스트
  final String title;

  /// 부제목 텍스트 (선택)
  final String? subtitle;

  /// 제목 색상 (기본: 테마 텍스트 색상)
  final Color? titleColor;

  /// 오른쪽 위젯 (기본: 화살표 아이콘)
  final Widget? trailing;

  /// 탭 콜백
  final VoidCallback onTap;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 아이콘 배경
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: titleColor ??
                    (isDark ? AppColors.textSubDark : AppColors.textSubLight),
              ),
            ),
            const SizedBox(width: 12),

            // 제목 및 부제목
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor ??
                          (isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 후행 위젯 (기본: 화살표)
            trailing ??
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
                ),
          ],
        ),
      ),
    );
  }
}

/// 스위치가 있는 설정 항목
///
/// [SettingsItem]과 동일하지만 스위치 위젯이 기본 포함됨
class SettingsSwitchItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsItem(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary600,
      ),
      onTap: () => onChanged(!value),
    );
  }
}
