import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/creator_content.dart';

/// 직캠 섹션
class ContentFancamsSection extends StatelessWidget {
  final bool isDark;
  final List<CreatorFancam> fancams;
  final Color themeColor;
  final void Function(CreatorFancam) onFancamTap;

  const ContentFancamsSection({
    super.key,
    required this.isDark,
    required this.fancams,
    required this.themeColor,
    required this.onFancamTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('아티스트 직캠', '${fancams.length}개', isDark, themeColor),
        if (fancams.isEmpty)
          _emptyPlaceholder('직캠을 추가하세요', Icons.videocam_outlined, isDark)
        else
          SizedBox(
            height: 180,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: fancams.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => ContentFancamCard(
                fancam: fancams[i],
                isDark: isDark,
                themeColor: themeColor,
                onTap: () => onFancamTap(fancams[i]),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _sectionHeader(
      String title, String count, bool isDark, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.text,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 14,
              color: themeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPlaceholder(String message, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 32, color: isDark ? Colors.grey[600] : Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// 직캠 카드
class ContentFancamCard extends StatelessWidget {
  final CreatorFancam fancam;
  final bool isDark;
  final Color themeColor;
  final VoidCallback onTap;

  const ContentFancamCard({
    super.key,
    required this.fancam,
    required this.isDark,
    required this.themeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: fancam.thumbnailUrl,
                    width: 220,
                    height: 130,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      child: const Icon(Icons.videocam, size: 40),
                    ),
                  ),
                ),
                // Play button overlay
                const Positioned.fill(
                  child: Center(
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.red,
                      child:
                          Icon(Icons.play_arrow, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                // Pinned badge
                if (fancam.isPinned)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.push_pin, size: 10, color: Colors.white),
                          SizedBox(width: 2),
                          Text('고정됨',
                              style:
                                  TextStyle(fontSize: 9, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                // View count
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      fancam.formattedViewCount,
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                fancam.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.text,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 드롭 섹션
class ContentDropsSection extends StatelessWidget {
  final bool isDark;
  final List<CreatorDrop> drops;
  final Color themeColor;
  final void Function(CreatorDrop) onDropTap;

  const ContentDropsSection({
    super.key,
    required this.isDark,
    required this.drops,
    required this.themeColor,
    required this.onDropTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('최신 드롭 (Drops)', '${drops.length}개', isDark, themeColor),
        if (drops.isEmpty)
          _emptyPlaceholder('드롭을 추가하세요', Icons.card_giftcard_outlined, isDark)
        else
          SizedBox(
            height: 200,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: drops.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => ContentDropCard(
                drop: drops[i],
                isDark: isDark,
                themeColor: themeColor,
                onTap: () => onDropTap(drops[i]),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _sectionHeader(
      String title, String count, bool isDark, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.text,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 14,
              color: themeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPlaceholder(String message, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 32, color: isDark ? Colors.grey[600] : Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// 드롭 카드
class ContentDropCard extends StatelessWidget {
  final CreatorDrop drop;
  final bool isDark;
  final Color themeColor;
  final VoidCallback onTap;

  const ContentDropCard({
    super.key,
    required this.drop,
    required this.isDark,
    required this.themeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    ),
                  ),
                  child: drop.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: CachedNetworkImage(
                            imageUrl: drop.imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.checkroom,
                          size: 40,
                          color: isDark ? Colors.grey[600] : Colors.grey[400]),
                ),
                if (drop.isSoldOut)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('SOLD OUT',
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  )
                else if (drop.isNew)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('NEW',
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                drop.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.text,
                  decoration:
                      drop.isSoldOut ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                drop.formattedPrice,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: drop.isSoldOut ? Colors.grey : themeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 이벤트 섹션
class ContentEventsSection extends StatelessWidget {
  final bool isDark;
  final List<CreatorEvent> events;
  final Color themeColor;
  final void Function(CreatorEvent) onEventTap;

  const ContentEventsSection({
    super.key,
    required this.isDark,
    required this.events,
    required this.themeColor,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('다가오는 이벤트', '${events.length}개', isDark, themeColor),
        if (events.isEmpty)
          _emptyPlaceholder('이벤트를 추가하세요', Icons.event_outlined, isDark)
        else
          ...events.map((event) => ContentEventCard(
                event: event,
                isDark: isDark,
                themeColor: themeColor,
                onTap: () => onEventTap(event),
              )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _sectionHeader(
      String title, String count, bool isDark, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.text,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 14,
              color: themeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPlaceholder(String message, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 32, color: isDark ? Colors.grey[600] : Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// 이벤트 카드
class ContentEventCard extends StatelessWidget {
  final CreatorEvent event;
  final bool isDark;
  final Color themeColor;
  final VoidCallback onTap;

  const ContentEventCard({
    super.key,
    required this.event,
    required this.isDark,
    required this.themeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                event.isOffline ? Icons.location_on : Icons.videocam,
                color: themeColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: event.isOffline
                              ? Colors.grey[200]
                              : themeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.typeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color:
                                event.isOffline ? Colors.grey[600] : themeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        event.formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.text,
                    ),
                  ),
                  Text(
                    event.location,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
