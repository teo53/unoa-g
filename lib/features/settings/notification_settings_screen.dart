import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/accessibility_helper.dart';
import '../../shared/widgets/app_scaffold.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Notification settings state
  bool _newMessages = true;
  bool _artistPosts = true;
  bool _liveNotifications = true;
  bool _subscriptionUpdates = true;
  bool _promotions = false;
  bool _systemAlerts = true;

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
                    '알림 설정',
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
                  // Messages Section
                  _SectionHeader(title: '메시지'),
                  const SizedBox(height: 12),
                  _NotificationCard(
                    children: [
                      _NotificationToggle(
                        title: '새 메시지',
                        subtitle: '아티스트로부터 새 메시지를 받으면 알림',
                        value: _newMessages,
                        onChanged: (value) =>
                            setState(() => _newMessages = value),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Content Section
                  _SectionHeader(title: '콘텐츠'),
                  const SizedBox(height: 12),
                  _NotificationCard(
                    children: [
                      _NotificationToggle(
                        title: '아티스트 게시물',
                        subtitle: '구독 중인 아티스트가 새 게시물을 올리면 알림',
                        value: _artistPosts,
                        onChanged: (value) =>
                            setState(() => _artistPosts = value),
                      ),
                      _Divider(),
                      _NotificationToggle(
                        title: '라이브 알림',
                        subtitle: '아티스트가 라이브를 시작하면 알림',
                        value: _liveNotifications,
                        onChanged: (value) =>
                            setState(() => _liveNotifications = value),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Account Section
                  _SectionHeader(title: '계정'),
                  const SizedBox(height: 12),
                  _NotificationCard(
                    children: [
                      _NotificationToggle(
                        title: '구독 업데이트',
                        subtitle: '구독 갱신, 만료 등 알림',
                        value: _subscriptionUpdates,
                        onChanged: (value) =>
                            setState(() => _subscriptionUpdates = value),
                      ),
                      _Divider(),
                      _NotificationToggle(
                        title: '프로모션',
                        subtitle: '이벤트, 할인 등 프로모션 알림',
                        value: _promotions,
                        onChanged: (value) =>
                            setState(() => _promotions = value),
                      ),
                      _Divider(),
                      _NotificationToggle(
                        title: '시스템 알림',
                        subtitle: '앱 업데이트, 점검 등 시스템 알림',
                        value: _systemAlerts,
                        onChanged: (value) =>
                            setState(() => _systemAlerts = value),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Info text
                  Text(
                    '알림 설정은 앱 내 알림에만 적용됩니다. 기기의 알림 설정은 시스템 설정에서 변경해주세요.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMuted,
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

    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final List<Widget> children;

  const _NotificationCard({required this.children});

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

class _NotificationToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
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
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary600,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
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
