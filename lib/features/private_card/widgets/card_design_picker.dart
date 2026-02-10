import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/private_card.dart';
import '../../../providers/private_card_provider.dart';

/// Horizontal scrollable card template gallery
/// Shows decorative card backgrounds for the artist to choose from
class CardDesignPicker extends ConsumerWidget {
  const CardDesignPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(cardTemplatesProvider);
    final composeState = ref.watch(privateCardComposeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '카드 디자인 선택',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.text,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final template = templates[index];
              final isSelected = composeState.selectedTemplateId == template.id;
              return _CardTemplateItem(
                template: template,
                isSelected: isSelected,
                onTap: () {
                  ref.read(privateCardComposeProvider.notifier).selectTemplate(
                        template.id,
                        template.fullImageUrl,
                      );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CardTemplateItem extends StatelessWidget {
  final PrivateCardTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const _CardTemplateItem({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.vip
                : isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.vip.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSelected ? 13 : 15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: template.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: _getCategoryColor(template.category),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(template.category),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              // Gradient overlay for name
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    template.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // Check mark for selected
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.vip,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'hearts':
        return const Color(0xFFFF6B8A);
      case 'flowers':
        return const Color(0xFFFF9ECF);
      case 'stars':
        return const Color(0xFF6366F1);
      case 'birthday':
        return const Color(0xFFFBBF24);
      case 'thanks':
        return const Color(0xFF10B981);
      case 'season':
        return const Color(0xFF06B6D4);
      default:
        return AppColors.vip;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'hearts':
        return Icons.favorite;
      case 'flowers':
        return Icons.local_florist;
      case 'stars':
        return Icons.star;
      case 'birthday':
        return Icons.cake;
      case 'thanks':
        return Icons.volunteer_activism;
      case 'season':
        return Icons.eco;
      default:
        return Icons.card_giftcard;
    }
  }
}
