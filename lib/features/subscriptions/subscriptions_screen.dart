import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock/mock_data.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/primary_button.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subscriptions = MockData.mySubscriptions;

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
                    '구독 관리',
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

          // Summary Card
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.subtleGradient,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '활성 구독',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${subscriptions.length}개',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '아티스트 찾기',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Subscriptions List
          Expanded(
            child: subscriptions.isEmpty
                ? _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: subscriptions.length,
                    itemBuilder: (context, index) {
                      final sub = subscriptions[index];
                      return _SubscriptionCard(
                        artistName: sub.artistName,
                        avatarUrl: sub.avatarUrl,
                        tier: sub.tier,
                        price: sub.formattedPrice,
                        nextBillingDate: sub.formattedNextBilling,
                        isExpiringSoon: sub.isExpiringSoon,
                        onTap: () => context.push('/artist/${sub.artistId}'),
                        onManage: () {
                          _showManageSheet(context, sub);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showManageSheet(BuildContext context, dynamic subscription) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${subscription.artistName} 구독 관리',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 24),
            _ManageOption(
              icon: Icons.arrow_upward,
              title: '구독 등급 변경',
              subtitle: '더 많은 혜택을 누려보세요',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('구독 등급 변경 기능 준비 중')),
                );
              },
            ),
            _ManageOption(
              icon: Icons.autorenew,
              title: '자동 갱신 설정',
              subtitle: '현재: 켜짐',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('자동 갱신 설정 기능 준비 중')),
                );
              },
            ),
            _ManageOption(
              icon: Icons.cancel_outlined,
              title: '구독 해지',
              subtitle: '다음 결제일까지 이용 가능',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('구독 해지'),
                    content: Text(
                      '${subscription.artistName} 구독을 해지하시겠습니까?\n다음 결제일까지는 계속 이용할 수 있습니다.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('구독 해지 기능 준비 중')),
                          );
                        },
                        child: Text(
                          '해지',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_membership_outlined,
            size: 64,
            color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 구독 중인 아티스트가 없습니다',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: '아티스트 찾아보기',
            icon: Icons.search,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final String artistName;
  final String avatarUrl;
  final String tier;
  final String price;
  final String nextBillingDate;
  final bool isExpiringSoon;
  final VoidCallback onTap;
  final VoidCallback onManage;

  const _SubscriptionCard({
    required this.artistName,
    required this.avatarUrl,
    required this.tier,
    required this.price,
    required this.nextBillingDate,
    required this.isExpiringSoon,
    required this.onTap,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpiringSoon
              ? AppColors.warning
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipOval(
                    child: avatarUrl.isEmpty
                        ? Container(
                            width: 56,
                            height: 56,
                            color:
                                isDark ? Colors.grey[800] : Colors.grey[200],
                            child: Icon(
                              Icons.person,
                              color: isDark
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: avatarUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 56,
                              height: 56,
                              color:
                                  isDark ? Colors.grey[800] : Colors.grey[200],
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 56,
                              height: 56,
                              color:
                                  isDark ? Colors.grey[800] : Colors.grey[200],
                              child: Icon(
                                Icons.person,
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              artistName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textMainDark
                                    : AppColors.textMainLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tier,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$price / 월',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color:
                        isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isExpiringSoon
                      ? Icons.warning_amber_rounded
                      : Icons.event_available,
                  size: 16,
                  color:
                      isExpiringSoon ? AppColors.warning : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isExpiringSoon
                        ? '곧 만료됩니다 - $nextBillingDate'
                        : '다음 결제일: $nextBillingDate',
                    style: TextStyle(
                      fontSize: 12,
                      color: isExpiringSoon
                          ? AppColors.warning
                          : (isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onManage,
                  child: Text(
                    '관리',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ManageOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDestructive
        ? AppColors.danger
        : (isDark ? AppColors.textMainDark : AppColors.textMainLight);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.danger100
                    : (isDark
                        ? AppColors.surfaceAltDark
                        : AppColors.surfaceAlt),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
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
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                    ),
                  ),
                ],
              ),
            ),
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
