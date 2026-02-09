import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/mock/mock_data.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/animation_utils.dart';
import '../../shared/widgets/primary_button.dart';

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(currentProfileProvider);

    // Guest: show login/demo CTA instead of fake data
    if (profile == null) {
      return _GuestProfileView(isDark: isDark);
    }

    final isCreator = profile.isCreator;
    final user = MockData.currentUser;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '내 프로필',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
                ),
              ),
              IconButton(
                onPressed: () => context.push('/settings'),
                icon: Icon(
                  Icons.settings,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Avatar (tap to edit profile)
                GestureDetector(
                  onTap: () => context.push('/profile/edit'),
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: ClipOval(
                          child: profile.avatarUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: profile.avatarUrl!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.person, size: 48),
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
                              width: 4,
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
                ),

                const SizedBox(height: 16),

                // Name
                Text(
                  profile.displayName ?? user.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),

                const SizedBox(height: 4),

                // Username
                Text(
                  user.username,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),

                const SizedBox(height: 10),

                // Edit profile link
                GestureDetector(
                  onTap: () => context.push('/profile/edit'),
                  child: Text(
                    '탭하여 프로필 수정',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Stats Row - Fan only sees subscription count and DT balance
                if (!isCreator) ...[
                  SlideFadeAnimation.fromBottom(
                    delay: const Duration(milliseconds: 100),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: '구독 중',
                            value: '${user.subscriptionCount}명',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'DT 잔액',
                            value: '${user.dtBalance}',
                            valueColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Menu Section 1
                SlideFadeAnimation.fromBottom(
                  delay: const Duration(milliseconds: 200),
                  child: _MenuSection(
                  items: [
                    _MenuItem(
                      icon: Icons.account_balance_wallet,
                      iconColor: AppColors.primary,
                      iconBgColor: AppColors.primary.withOpacity(0.1),
                      title: 'Wallet / DreamTime (DT)',
                      subtitle: '잔액: ${user.dtBalance} DT',
                      onTap: () => context.push('/wallet'),
                    ),
                    _MenuItem(
                      icon: Icons.card_membership,
                      iconColor: Colors.blue,
                      iconBgColor: Colors.blue.withOpacity(0.1),
                      title: '구독 관리',
                      subtitle: '${user.subscriptionCount}개 구독 중',
                      onTap: () => context.push('/subscriptions'),
                    ),
                  ],
                ),
                ),

                const SizedBox(height: 16),

                // Creator Section
                if (isCreator) ...[
                  SlideFadeAnimation.fromBottom(
                    delay: const Duration(milliseconds: 250),
                    child: _MenuSection(
                      items: [
                        _MenuItem(
                          icon: Icons.dashboard_rounded,
                          iconColor: AppColors.primary,
                          iconBgColor: AppColors.primary.withOpacity(0.1),
                          title: '크리에이터 스튜디오',
                          subtitle: '크리에이터 대시보드로 이동',
                          onTap: () => context.go('/creator/dashboard'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Menu Section 2
                SlideFadeAnimation.fromBottom(
                  delay: const Duration(milliseconds: 300),
                  child: _MenuSection(
                    items: [
                      _MenuItem(
                        icon: Icons.notifications,
                        iconColor: Colors.orange,
                        iconBgColor: Colors.orange.withOpacity(0.1),
                        title: '알림 설정',
                        onTap: () => context.push('/settings/notifications'),
                      ),
                      _MenuItem(
                        icon: Icons.security,
                        iconColor: Colors.purple,
                        iconBgColor: Colors.purple.withOpacity(0.1),
                        title: '계정 / 보안',
                        onTap: () => context.push('/settings/account'),
                      ),
                      _MenuItem(
                        icon: Icons.headset_mic,
                        iconColor: Colors.green,
                        iconBgColor: Colors.green.withOpacity(0.1),
                        title: '고객센터',
                        onTap: () => context.push('/help'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // App Version
                Text(
                  '앱 버전 2.4.0',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Guest profile view — login/demo CTA instead of fake user data
class _GuestProfileView extends StatelessWidget {
  final bool isDark;

  const _GuestProfileView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header (settings/help still accessible)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '내 프로필',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
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
        ),

        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'UNO A에 오신 것을 환영합니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '로그인하면 좋아하는 아티스트와\n직접 소통할 수 있어요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Login CTA
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: '로그인',
                      onPressed: () => context.push('/login?next=/profile'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Demo CTA
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        try {
                          final container = ProviderScope.containerOf(context);
                          container
                              .read(authProvider.notifier)
                              .enterDemoModeAsFan();
                        } catch (_) {}
                      },
                      child: Text(
                        '데모로 체험하기',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Divider
                  Divider(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  const SizedBox(height: 16),

                  // Settings/Help still accessible
                  _MenuSection(
                    items: [
                      _MenuItem(
                        icon: Icons.headset_mic,
                        iconColor: Colors.green,
                        iconBgColor: Colors.green.withOpacity(0.1),
                        title: '고객센터',
                        onTap: () => context.push('/help'),
                      ),
                      _MenuItem(
                        icon: Icons.info_outline,
                        iconColor: Colors.blue,
                        iconBgColor: Colors.blue.withOpacity(0.1),
                        title: '앱 정보',
                        onTap: () => context.push('/settings'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: AppRadius.lgBR,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor ??
                  (isDark ? AppColors.textMainDark : AppColors.textMainLight),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;

  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: AppRadius.lgBR,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              item,
              if (index < items.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 64),
                  child: Divider(
                    height: 1,
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgBR,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
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
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[600] : Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }
}
