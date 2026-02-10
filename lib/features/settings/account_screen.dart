import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/accessibility_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/primary_button.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  /// Gets user email from auth state
  static String _getUserEmail(AuthState state) {
    if (state is AuthAuthenticated) {
      return state.user.email ?? 'unknown@example.com';
    }
    if (state is AuthDemoMode) {
      return 'demo@unoa.app';
    }
    return 'unknown@example.com';
  }

  /// Masks an email address for privacy
  /// Example: user@example.com -> u***r@example.com
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    if (name.isEmpty) return email;
    final masked = name.length > 2
        ? '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}'
        : name.length == 2
            ? '${name[0]}*'
            : name;
    return '$masked@${parts[1]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const Expanded(
                  child: Text(
                    '계정 및 보안',
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
                  // Account Info Section
                  const _SectionHeader(title: '계정 정보'),
                  const SizedBox(height: 12),
                  _InfoCard(
                    children: [
                      _InfoItem(
                        label: '이메일',
                        value: maskEmail(
                          _getUserEmail(ref.watch(authProvider)),
                        ),
                        verified: true,
                      ),
                      _CardDivider(),
                      const _InfoItem(
                        label: '전화번호',
                        value: '010-****-1234',
                        verified: true,
                      ),
                      _CardDivider(),
                      const _InfoItem(
                        label: '가입일',
                        value: '2024년 1월 15일',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Security Section
                  const _SectionHeader(title: '보안'),
                  const SizedBox(height: 12),
                  _ActionCard(
                    children: [
                      _ActionItem(
                        icon: Icons.lock_outline,
                        title: '비밀번호 변경',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('비밀번호 변경 기능 준비 중')),
                          );
                        },
                      ),
                      _CardDivider(),
                      _ActionItem(
                        icon: Icons.fingerprint,
                        title: '생체 인증',
                        trailing: Switch(
                          value: true,
                          onChanged: (value) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('생체 인증 설정 준비 중')),
                            );
                          },
                          activeThumbColor: AppColors.primary600,
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('생체 인증 설정 준비 중')),
                          );
                        },
                      ),
                      _CardDivider(),
                      _ActionItem(
                        icon: Icons.security,
                        title: '2단계 인증',
                        subtitle: '활성화됨',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('2단계 인증 설정 준비 중')),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Connected Accounts
                  const _SectionHeader(title: '연결된 계정'),
                  const SizedBox(height: 12),
                  _ActionCard(
                    children: [
                      _ConnectedAccount(
                        icon: Icons.g_mobiledata,
                        title: 'Google',
                        connected: true,
                        email: maskEmail('user@gmail.com'),
                      ),
                      _CardDivider(),
                      const _ConnectedAccount(
                        icon: Icons.apple,
                        title: 'Apple',
                        connected: false,
                      ),
                      _CardDivider(),
                      const _ConnectedAccount(
                        icon: Icons.chat_bubble,
                        title: 'Kakao',
                        connected: true,
                        email: 'k****o_user',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Login History
                  const _SectionHeader(title: '로그인 기록'),
                  const SizedBox(height: 12),
                  _ActionCard(
                    children: [
                      _ActionItem(
                        icon: Icons.history,
                        title: '로그인 기록 보기',
                        subtitle: '최근 7일',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('로그인 기록 기능 준비 중')),
                          );
                        },
                      ),
                      _CardDivider(),
                      _ActionItem(
                        icon: Icons.devices,
                        title: '로그인된 기기 관리',
                        subtitle: '3개 기기',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('기기 관리 기능 준비 중')),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Danger Zone
                  const _SectionHeader(title: '계정 삭제'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.danger100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.danger),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '계정을 삭제하면 모든 데이터가 영구적으로 삭제됩니다.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DestructiveButton(
                          label: '계정 삭제',
                          isOutline: true,
                          onPressed: () {
                            final isDemoMode = ref.read(isDemoModeProvider);
                            final balance = isDemoMode
                                ? 0
                                : ref.read(currentBalanceProvider);
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('계정 삭제'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                        '정말로 계정을 삭제하시겠습니까?\n이 작업은 취소할 수 없습니다.'),
                                    if (balance > 0) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.warning_amber_rounded,
                                                color: AppColors.warning,
                                                size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '잔여 DT 잔액: $balance DT\n삭제 시 환불되지 않습니다.',
                                                style: const TextStyle(
                                                    fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(dialogContext);
                                      try {
                                        await ref
                                            .read(authProvider.notifier)
                                            .deleteAccount();
                                        if (context.mounted) {
                                          context.go('/login');
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  '계정 삭제에 실패했습니다. 다시 시도해주세요.'),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text(
                                      '삭제',
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

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

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

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

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
      child: Column(children: children),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final List<Widget> children;

  const _ActionCard({required this.children});

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
      child: Column(children: children),
    );
  }
}

class _CardDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final bool verified;

  const _InfoItem({
    required this.label,
    required this.value,
    this.verified = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                    if (verified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: AppColors.verified,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
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
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
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
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
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

class _ConnectedAccount extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool connected;
  final String? email;

  const _ConnectedAccount({
    required this.icon,
    required this.title,
    required this.connected,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
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
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
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
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                if (email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    email!,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: connected ? AppColors.success100 : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              connected ? '연결됨' : '연결',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: connected
                    ? AppColors.success
                    : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
