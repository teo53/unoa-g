import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/funding_provider.dart';

/// Screen showing the user's funding pledge history
class MyPledgesScreen extends ConsumerWidget {
  const MyPledgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pledges = ref.watch(myPledgesProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        title: Text(
          '내 후원 내역',
          style: TextStyle(
            color: isDark ? AppColors.textDark : AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.textDark : AppColors.text,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: pledges.isEmpty
          ? _buildEmptyState(isDark)
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: pledges.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final pledge = pledges[index];
                return _PledgeCard(pledge: pledge);
              },
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.volunteer_activism_outlined,
            size: 64,
            color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 후원 내역이 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '마음에 드는 펀딩을 후원해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PledgeCard extends StatelessWidget {
  final Pledge pledge;

  const _PledgeCard({required this.pledge});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campaign title
          Row(
            children: [
              Expanded(
                child: Text(
                  pledge.campaignTitle ?? '캠페인',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDark : AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusBadge(pledge.status, isDark),
            ],
          ),

          const SizedBox(height: 10),

          // Tier info
          Row(
            children: [
              Icon(
                Icons.card_giftcard_rounded,
                size: 16,
                color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
              ),
              const SizedBox(width: 6),
              Text(
                pledge.tierTitle ?? '리워드',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          const SizedBox(height: 12),

          // Amount and date
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '후원 금액',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatNumber(pledge.totalAmount)}원',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '후원일',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(pledge.createdAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textDark : AppColors.text,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Support message
          if (pledge.supportMessage != null && pledge.supportMessage!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 14,
                    color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pledge.supportMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? AppColors.success100 : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? '후원중' : '완료',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.textMuted,
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(0)}만';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}천';
    }
    return number.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
