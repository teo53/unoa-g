import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

// 웹 링크 URL 상수
const String _termsOfServiceUrl = 'https://unoa.app/terms';
const String _privacyPolicyUrl = 'https://unoa.app/privacy';

/// Creator Profile Screen - Profile and settings for creators
class CreatorProfileScreen extends ConsumerWidget {
  const CreatorProfileScreen({super.key});

  /// 외부 URL을 브라우저에서 열기
  static Future<void> _launchUrl(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('링크를 열 수 없습니다: $url')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('링크를 열 수 없습니다: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(currentProfileProvider);
    final isDemoMode = ref.watch(isDemoModeProvider);

    return Column(
      children: [
        // Header
        _buildHeader(context, isDark),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Tappable Profile Area - Avatar, Name, Bio
                _TappableProfileArea(
                  profile: profile,
                  isDark: isDark,
                  onTap: () => context.push('/creator/content'),
                ),

                const SizedBox(height: 24),

                // Stats Row
                _buildStatsRow(isDark),

                const SizedBox(height: 24),

                // Profile Customization Section
                _MenuSection(
                  title: '프로필 꾸미기',
                  items: [
                    _MenuItem(
                      icon: Icons.person_rounded,
                      iconColor: AppColors.primary,
                      iconBgColor: AppColors.primary.withValues(alpha: 0.1),
                      title: '프로필 편집',
                      subtitle: '아바타, 배경, 소개글, 소셜 링크, 테마',
                      onTap: () => context.push('/creator/profile/edit'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Creator Management Section
                if (!isDemoMode) ...[
                  _MenuSection(
                    title: '크리에이터 관리',
                    items: [
                      _MenuItem(
                        icon: Icons.analytics_rounded,
                        iconColor: Colors.teal,
                        iconBgColor: Colors.teal.withValues(alpha: 0.1),
                        title: 'CRM / 수익 관리',
                        subtitle: '팬 분석, 정산 내역 및 출금',
                        onTap: () => context.push('/creator/crm'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Fan Activities Section (아티스트도 다른 아티스트의 팬이 될 수 있음)
                _MenuSection(
                  title: '내 구독',
                  items: [
                    _MenuItem(
                      icon: Icons.favorite_rounded,
                      iconColor: Colors.pink,
                      iconBgColor: Colors.pink.withValues(alpha: 0.1),
                      title: '구독 관리',
                      subtitle: '구독 중인 아티스트 관리',
                      onTap: () => context.push('/subscriptions'),
                    ),
                    _MenuItem(
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: Colors.green,
                      iconBgColor: Colors.green.withValues(alpha: 0.1),
                      title: '지갑',
                      subtitle: 'DT 충전 및 내역 확인',
                      onTap: () => context.push('/wallet'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Settings Section
                _MenuSection(
                  title: '설정',
                  items: [
                    _MenuItem(
                      icon: Icons.notifications,
                      iconColor: Colors.orange,
                      iconBgColor: Colors.orange.withValues(alpha: 0.1),
                      title: '알림 설정',
                      onTap: () => context.push('/settings/notifications'),
                    ),
                    _MenuItem(
                      icon: Icons.settings,
                      iconColor: Colors.grey,
                      iconBgColor: Colors.grey.withValues(alpha: 0.1),
                      title: '앱 설정',
                      onTap: () => context.push('/settings'),
                    ),
                    _MenuItem(
                      icon: Icons.headset_mic,
                      iconColor: Colors.purple,
                      iconBgColor: Colors.purple.withValues(alpha: 0.1),
                      title: '고객센터',
                      onTap: () => context.push('/help'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Legal Section (웹 링크)
                _MenuSection(
                  title: '법적 고지',
                  items: [
                    _MenuItem(
                      icon: Icons.description_outlined,
                      iconColor: Colors.blueGrey,
                      iconBgColor: Colors.blueGrey.withValues(alpha: 0.1),
                      title: '이용약관',
                      isExternalLink: true,
                      onTap: () => _launchUrl(_termsOfServiceUrl, context),
                    ),
                    _MenuItem(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: Colors.indigo,
                      iconBgColor: Colors.indigo.withValues(alpha: 0.1),
                      title: '개인정보 처리방침',
                      isExternalLink: true,
                      onTap: () => _launchUrl(_privacyPolicyUrl, context),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Demo mode indicator
                if (isDemoMode)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '데모 모드로 체험 중입니다. 실제 데이터는 저장되지 않습니다.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Logout / Exit Demo Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      _showLogoutDialog(context, ref, isDemoMode);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isDemoMode ? '데모 모드 종료' : '로그아웃',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // App Version
                Text(
                  'UNO A 크리에이터 v1.0.0 (데모)',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.textMutedDark : AppColors.textMuted,
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '내 프로필',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: Icon(
              Icons.settings,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: '총 구독자',
            value: '1,250',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: '이번 달 수익',
            value: '125,000 DT',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref, bool isDemoMode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          isDemoMode ? '데모 모드 종료' : '로그아웃',
          style: TextStyle(
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        content: Text(
          isDemoMode ? '데모 모드를 종료하시겠습니까?' : '정말 로그아웃 하시겠습니까?',
          style: TextStyle(
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              '취소',
              style: TextStyle(
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (isDemoMode) {
                ref.read(authProvider.notifier).exitDemoMode();
              } else {
                ref.read(authProvider.notifier).signOut();
              }
              context.go('/login');
            },
            child: Text(
              isDemoMode ? '종료' : '로그아웃',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return _buildMenuItem(entry.value, isDark, isLast: isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(_MenuItem item, bool isDark, {bool isLast = false}) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(16))
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              item.isExternalLink ? Icons.open_in_new : Icons.chevron_right,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              size: item.isExternalLink ? 18 : 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isExternalLink;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isExternalLink = false,
  });
}

/// Tappable profile area that navigates to profile edit screen
class _TappableProfileArea extends StatelessWidget {
  final UserAuthProfile? profile;
  final bool isDark;
  final VoidCallback onTap;

  const _TappableProfileArea({
    required this.profile,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withValues(alpha: 0.5)
                : AppColors.surfaceLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            children: [
              // Avatar with edit indicator
              Stack(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isDark ? AppColors.surfaceDark : AppColors.primary100,
                      border: Border.all(
                        color: (isDark ? Colors.white : AppColors.primary500)
                            .withValues(alpha: 0.12),
                      ),
                    ),
                    child: ClipOval(
                      child: profile?.avatarUrl != null
                          ? CachedNetworkImage(
                              imageUrl: profile!.avatarUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                child: const Icon(Icons.person, size: 48),
                              ),
                            )
                          : Container(
                              color:
                                  isDark ? Colors.grey[800] : Colors.grey[200],
                              child: Icon(
                                Icons.person,
                                size: 48,
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Name with creator badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      profile?.displayName ?? '크리에이터',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '크리에이터',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Bio
              Text(
                profile?.bio ?? '크리에이터 모드로 데모 중',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Edit hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 14,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '탭하여 프로필 수정',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
