import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/private_card.dart';
import '../../../providers/private_card_provider.dart';

/// Embeddable private card list view for use inside tabs
/// (No Scaffold, no header, no FAB — those are in the parent)
class PrivateCardListView extends ConsumerWidget {
  const PrivateCardListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(privateCardHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (historyState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.vip),
      );
    }

    if (historyState.sentCards.isEmpty) {
      return _buildEmptyState(context, isDark);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 새 카드 작성 CTA 버튼 (인라인)
        _buildComposeButton(context, isDark),
        const SizedBox(height: 20),

        // Quick stats
        _buildQuickStats(isDark, historyState),
        const SizedBox(height: 24),

        // Favorites section
        _buildFavoritesSection(context, ref, isDark),
        const SizedBox(height: 24),

        // Sent cards history
        Text(
          '발송 내역',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        ...historyState.sentCards.map((card) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SentCardTile(card: card),
            )),
      ],
    );
  }

  Widget _buildComposeButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/creator/private-card/compose'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.privateCardGradient,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.vip.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              '새 카드 작성',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.vip.withValues(alpha: 0.2),
                  AppColors.cardAccentPink.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: const Icon(
              Icons.mail_outline_rounded,
              size: 36,
              color: AppColors.vip,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '아직 보낸 카드가 없어요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '팬에게 특별한 손편지 스타일의\n프라이빗 카드를 보내보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => context.push('/creator/private-card/compose'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.vip,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                '첫 카드 작성하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(bool isDark, PrivateCardHistoryState state) {
    final totalCards = state.sentCards.length;
    final totalRecipients = state.sentCards.fold<int>(
      0,
      (sum, card) => sum + card.recipientCount,
    );

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.mail_rounded,
            label: '보낸 카드',
            value: '$totalCards장',
            color: AppColors.vip,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.people_rounded,
            label: '총 수신자',
            value: '$totalRecipients명',
            color: AppColors.cardAccentPink,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesSection(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    // Get demo fans who are favorites
    final favoriteFans =
        DemoConfig.demoFans.where((f) => f['isFavorite'] == true).toList();

    if (favoriteFans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star_rounded, color: AppColors.star, size: 20),
            const SizedBox(width: 6),
            Text(
              '즐겨찾기 팬',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.text,
              ),
            ),
            const Spacer(),
            Text(
              '${favoriteFans.length}명',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: favoriteFans.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final fan = favoriteFans[index];
              return _FavoriteFanChip(
                name: fan['name'] as String,
                tier: fan['tier'] as String,
                avatarSeed: fan['seed'] as String,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FavoriteFanChip extends StatelessWidget {
  final String name;
  final String tier;
  final String avatarSeed;

  const _FavoriteFanChip({
    required this.name,
    required this.tier,
    required this.avatarSeed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: CachedNetworkImageProvider(
                DemoConfig.avatarUrl(avatarSeed),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.star,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.star, size: 8, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppColors.text,
          ),
        ),
      ],
    );
  }
}

class _SentCardTile extends StatelessWidget {
  final PrivateCard card;

  const _SentCardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preview = card.templateContent ?? '';
    final shortPreview =
        preview.length > 60 ? '${preview.substring(0, 60)}...' : preview;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          // Card preview icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.privateCardGradient,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('\u{1F48C}', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),

          // Card info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shortPreview,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.text,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${card.recipientCount}\uba85\uc5d0\uac8c \uc804\uc1a1',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(card.sentAt ?? card.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: card.status == PrivateCardStatus.sent
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              card.status == PrivateCardStatus.sent
                  ? '\uc804\uc1a1\uc644\ub8cc'
                  : '\uc804\uc1a1\uc911',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: card.status == PrivateCardStatus.sent
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return '\uc624\ub298';
    if (diff.inDays == 1) return '\uc5b4\uc81c';
    if (diff.inDays < 7) return '${diff.inDays}\uc77c \uc804';
    return '${date.month}\uc6d4 ${date.day}\uc77c';
  }
}
