import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/fan_ad_provider.dart';
import '../../shared/widgets/app_toast.dart' show showAppSuccess, showAppError;
import '../../shared/widgets/state_widgets.dart';

class MyAdsScreen extends ConsumerStatefulWidget {
  const MyAdsScreen({super.key});

  @override
  ConsumerState<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends ConsumerState<MyAdsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _statusTabs = [
    (label: '전체', status: null),
    (label: '심사중', status: 'pending_review'),
    (label: '노출중', status: 'active'),
    (label: '완료', status: 'completed'),
    (label: '거절', status: 'rejected'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _statusTabs.length, vsync: this);
    Future.microtask(() => ref.read(fanAdProvider.notifier).loadMyAds());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _confirmCancel(BuildContext context, FanAd ad) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('광고 취소'),
        content: const Text('광고를 취소하시겠어요?\n심사 대기 중인 광고만 취소할 수 있어요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('아니오')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('취소하기',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final success = await ref.read(fanAdProvider.notifier).cancelAd(ad.id);
    if (!mounted) return;
    if (success) {
      showAppSuccess(context, '광고가 취소됐어요');
    } else {
      showAppError(context, '취소에 실패했어요. 다시 시도해주세요');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adState = ref.watch(fanAdProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('내 광고'),
        elevation: 0,
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: _statusTabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: adState.loading
          ? const LoadingState()
          : adState.error != null
              ? ErrorDisplay(
                  error: adState.error ?? 'Unknown error',
                  onRetry: () => ref.read(fanAdProvider.notifier).loadMyAds(),
                )
              : TabBarView(
                  controller: _tabs,
                  children: _statusTabs.map((t) {
                    final ads = ref.watch(myAdsByStatusProvider(t.status));
                    if (ads.isEmpty) {
                      return const EmptyState(
                        title: '광고가 없어요',
                        message: '아티스트 프로필에서 광고를 구매해보세요',
                        icon: Icons.campaign_outlined,
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () =>
                          ref.read(fanAdProvider.notifier).loadMyAds(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: ads.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _AdCard(
                          ad: ads[i],
                          isDark: isDark,
                          onCancel: ads[i].isCancellable
                              ? () => _confirmCancel(context, ads[i])
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}

// ── Ad Card ──

class _AdCard extends StatelessWidget {
  final FanAd ad;
  final bool isDark;
  final VoidCallback? onCancel;

  const _AdCard({
    required this.ad,
    required this.isDark,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy.MM.dd');
    final numFmt = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ad.title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: ad.status),
            ],
          ),
          if (ad.body != null && ad.body!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              ad.body!,
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.iconMuted : AppColors.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 12,
                  color: isDark ? AppColors.textMuted : AppColors.iconMuted),
              const SizedBox(width: 4),
              Text(
                '${fmt.format(ad.startAt)} ~ ${fmt.format(ad.endAt)}',
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textMuted : AppColors.textMuted),
              ),
              const Spacer(),
              Text(
                '${numFmt.format(ad.paymentAmountKrw)}원',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (ad.isActive) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _StatChip(
                    icon: Icons.visibility_outlined, value: ad.impressions),
                const SizedBox(width: 8),
                _StatChip(icon: Icons.ads_click, value: ad.clicks),
              ],
            ),
          ],
          if (ad.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Text(
              '거절 사유: ${ad.rejectionReason}',
              style: const TextStyle(fontSize: 12, color: AppColors.danger),
            ),
          ],
          if (onCancel != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: const Text('취소', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  static const _labels = {
    'pending_review': '심사중',
    'approved': '승인됨',
    'active': '노출중',
    'completed': '완료',
    'rejected': '거절',
    'cancelled': '취소됨',
  };

  Color _color() => switch (status) {
        'active' => AppColors.success,
        'rejected' => AppColors.danger,
        'cancelled' => AppColors.textMuted,
        'completed' => AppColors.textMuted,
        _ => AppColors.warning,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color().withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color().withValues(alpha: 0.4)),
      ),
      child: Text(
        _labels[status] ?? status,
        style: TextStyle(
            fontSize: 11, color: _color(), fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int value;
  const _StatChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(
          NumberFormat('#,###').format(value),
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
