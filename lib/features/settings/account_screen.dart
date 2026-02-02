import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/primary_button.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  _SectionHeader(title: '계정 정보'),
                  const SizedBox(height: 12),
                  _InfoCard(
                    children: [
                      _InfoItem(
                        label: '이메일',
                        value: 'user@example.com',
                        verified: true,
                      ),
                      _CardDivider(),
                      _InfoItem(
                        label: '전화번호',
                        value: '010-****-1234',
                        verified: true,
                      ),
                      _CardDivider(),
                      _InfoItem(
                        label: '가입일',
                        value: '2024년 1월 15일',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Security Section
                  _SectionHeader(title: '보안'),
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
                          onChanged: (value) {},
                          activeColor: AppColors.primary600,
                        ),
                        onTap: () {},
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
                  _SectionHeader(title: '연결된 계정'),
                  const SizedBox(height: 12),
                  _ActionCard(
                    children: [
                      _ConnectedAccount(
                        icon: Icons.g_mobiledata,
                        title: 'Google',
                        connected: true,
                        email: 'user@gmail.com',
                      ),
                      _CardDivider(),
                      _ConnectedAccount(
                        icon: Icons.apple,
                        title: 'Apple',
                        connected: false,
                      ),
                      _CardDivider(),
                      _ConnectedAccount(
                        icon: Icons.chat_bubble,
                        title: 'Kakao',
                        connected: true,
                        email: 'kakao_user',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Login History
                  _SectionHeader(title: '로그인 기록'),
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
                  _SectionHeader(title: '계정 삭제'),
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
                        Text(
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
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('계정 삭제'),
                                content: const Text(
                                    '정말로 계정을 삭제하시겠습니까?\n이 작업은 취소할 수 없습니다.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('계정 삭제 기능 준비 중')),
                                      );
                                    },
                                    child: Text(
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
                      Icon(
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
                    : (isDark
                        ? AppColors.textSubDark
                        : AppColors.textSubLight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
