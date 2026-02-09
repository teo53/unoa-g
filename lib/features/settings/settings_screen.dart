import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../shared/widgets/app_scaffold.dart';

/// 설정 화면
///
/// 계정, 알림, 구독, 앱 설정을 관리하는 화면
/// 다크 모드 토글이 여기서 동작함

/// Marketing consent change confirmation dialog
void _showConsentChangeDialog(
  BuildContext context,
  String consentType,
  bool newValue,
) {
  final action = newValue ? '수신 동의' : '수신 거부';
  
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('$consentType $action'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            newValue 
                ? '$consentType 수신에 동의하시겠습니까?'
                : '$consentType 수신을 거부하시겠습니까?',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              newValue
                  ? '동의 시 프로모션, 이벤트 등의 정보를 받을 수 있습니다.'
                  : '거부 시에도 서비스 이용에 필요한 필수 안내는 수신됩니다.\n\n정보통신망법에 따라 마케팅 수신 동의는 언제든지 철회할 수 있습니다.',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$consentType $action가 처리되었습니다'),
              ),
            );
            // TODO: Call API to update consent preference
          },
          child: Text(action),
        ),
      ],
    ),
  );
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = ref.read(themeProvider.notifier);

    return AppScaffold(
      showStatusBar: true,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const Expanded(
                  child: Text(
                    '설정',
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

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account Section
                  _SectionTitle(title: '계정'),
                  const SizedBox(height: 12),
                  _SettingsGroup(
                    items: [
                      _SettingsItem(
                        icon: Icons.person_outline,
                        title: '프로필 편집',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('프로필 편집 기능 준비 중')),
                          );
                        },
                      ),
                      _SettingsItem(
                        icon: Icons.lock_outline,
                        title: '계정 및 보안',
                        onTap: () => context.push('/settings/account'),
                      ),
                      _SettingsItem(
                        icon: Icons.credit_card,
                        title: '결제 수단 관리',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('결제 수단 관리 기능 준비 중')),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Notifications Section
                  _SectionTitle(title: '알림'),
                  const SizedBox(height: 12),
                  _SettingsGroup(
                    items: [
                      _SettingsItem(
                        icon: Icons.notifications_outlined,
                        title: '알림 설정',
                        onTap: () => context.push('/settings/notifications'),
                      ),
                      _SettingsItem(
                        icon: Icons.do_not_disturb_on_outlined,
                        title: '방해금지 모드',
                        trailing: Switch(
                          value: false,
                          onChanged: (value) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('방해금지 모드 설정 준비 중')),
                            );
                          },
                          activeColor: AppColors.primary600,
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('방해금지 모드 설정 준비 중')),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Subscription Section
                  _SectionTitle(title: '구독'),
                  const SizedBox(height: 12),
                  _SettingsGroup(
                    items: [
                      _SettingsItem(
                        icon: Icons.card_membership,
                        title: '구독 관리',
                        subtitle: '3개 아티스트 구독 중',
                        onTap: () => context.push('/subscriptions'),
                      ),
                      _SettingsItem(
                        icon: Icons.history,
                        title: '결제 내역',
                        onTap: () => context.push('/wallet/history'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // App Section
                  _SectionTitle(title: '앱'),
                  const SizedBox(height: 12),
                  _SettingsGroup(
                    items: [
                      _SettingsItem(
                        icon: isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        title: '다크 모드',
                        subtitle: isDark ? '켜짐' : '꺼짐',
                        trailing: Switch(
                          value: isDark,
                          onChanged: (value) {
                            themeNotifier.toggleTheme();
                          },
                          activeColor: AppColors.primary600,
                        ),
                        onTap: () => themeNotifier.toggleTheme(),
                      ),
                      _SettingsItem(
                        icon: Icons.language,
                        title: '언어',
                        subtitle: '한국어',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('언어 설정 기능 준비 중')),
                          );
                        },
                      ),
                      _SettingsItem(
                        icon: Icons.storage_outlined,
                        title: '저장공간 관리',
                        subtitle: '23.5 MB 사용 중',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('저장공간 관리 기능 준비 중')),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Privacy & Marketing Section
                  _SectionTitle(title: '개인정보 및 마케팅'),
                  const SizedBox(height: 12),
                  _SettingsGroup(
                    items: [
                      _SettingsItem(
                        icon: Icons.email_outlined,
                        title: '이메일 마케팅 수신',
                        subtitle: '프로모션, 이벤트 안내',
                        trailing: Switch(
                          value: true,
                          onChanged: (value) {
                            _showConsentChangeDialog(
                              context,
                              '이메일 마케팅',
                              value,
                            );
                          },
                          activeColor: AppColors.primary600,
                        ),
                        onTap: () {},
                      ),
                      _SettingsItem(
                        icon: Icons.sms_outlined,
                        title: 'SMS 마케팅 수신',
                        subtitle: '문자 알림, 할인 정보',
                        trailing: Switch(
                          value: false,
                          onChanged: (value) {
                            _showConsentChangeDialog(
                              context,
                              'SMS 마케팅',
                              value,
                            );
                          },
                          activeColor: AppColors.primary600,
                        ),
                        onTap: () {},
                      ),
                      _SettingsItem(
                        icon: Icons.campaign_outlined,
                        title: '푸시 마케팅 수신',
                        subtitle: '앱 푸시 광고 알림',
                        trailing: Switch(
                          value: true,
                          onChanged: (value) {
                            _showConsentChangeDialog(
                              context,
                              '푸시 마케팅',
                              value,
                            );
                          },
                          activeColor: AppColors.primary600,
                        ),
                        onTap: () {},
                      ),
                      _SettingsItem(
                        icon: Icons.history,
                        title: '동의 내역 확인',
                        subtitle: '마케팅 수신 동의 변경 기록',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('동의 내역 확인 기능 준비 중')),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Support Section
                  _SectionTitle(title: '지원'),
                  const SizedBox(height: 12),
                  _SettingsGroup(
                    items: [
                      _SettingsItem(
                        icon: Icons.help_outline,
                        title: '고객센터',
                        onTap: () => context.push('/help'),
                      ),
                      _SettingsItem(
                        icon: Icons.description_outlined,
                        title: '이용약관',
                        onTap: () => context.push('/settings/terms'),
                      ),
                      _SettingsItem(
                        icon: Icons.privacy_tip_outlined,
                        title: '개인정보 처리방침',
                        onTap: () => context.push('/settings/privacy'),
                      ),
                      _SettingsItem(
                        icon: Icons.business_outlined,
                        title: '사업자 정보',
                        onTap: () => context.push('/settings/company-info'),
                      ),
                      _SettingsItem(
                        icon: Icons.info_outline,
                        title: '앱 정보',
                        subtitle: '버전 1.0.0',
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'UNO A',
                            applicationVersion: '1.0.0',
                            applicationLegalese: '© 2024 UNO A',
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Logout
                  _SettingsGroup(
                    items: [
                      _SettingsItem(
                        icon: Icons.logout,
                        title: '로그아웃',
                        titleColor: AppColors.danger,
                        onTap: () {
                          final isDemoMode = ref.read(isDemoModeProvider);
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('로그아웃'),
                              content: Text(isDemoMode
                                  ? '데모 모드를 종료하시겠습니까?'
                                  : '정말 로그아웃 하시겠습니까?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    // Actually sign out or exit demo mode
                                    if (isDemoMode) {
                                      ref.read(authProvider.notifier).exitDemoMode();
                                    } else {
                                      ref.read(authProvider.notifier).signOut();
                                    }
                                    // Navigate to login screen
                                    context.go('/login');
                                  },
                                  child: Text(
                                    '로그아웃',
                                    style: TextStyle(color: AppColors.danger),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

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

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsItem> items;

  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              item,
              if (index < items.length - 1)
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

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsItem({
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
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
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
