import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_logger.dart';
import '../../providers/ops_config_provider.dart';

/// 네이티브 광고 카드.
/// OpsPublishedBanner를 받아 sourceType에 따라 렌더링.
/// - ops: 운영자 배너 (일반 스타일)
/// - fanAd: 팬 유료 광고 ('팬 광고' 뱃지 표시)
class NativeAdCard extends StatelessWidget {
  final OpsPublishedBanner banner;

  const NativeAdCard({super.key, required this.banner});

  Future<void> _handleTap(BuildContext context) async {
    if (banner.linkUrl.isEmpty || banner.linkType == 'none') return;

    if (banner.linkType == 'external') {
      final uri = Uri.tryParse(banner.linkUrl);
      if (uri == null) return;
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        AppLogger.error('NativeAdCard: launchUrl failed — $e', tag: 'Ad');
      }
      return;
    }

    if (banner.linkType == 'internal') {
      final raw = banner.linkUrl.trim();
      if (raw.isEmpty) return;

      // 잘못 들어온 절대 URL은 외부 브라우저로 우회한다.
      if (raw.startsWith('http://') || raw.startsWith('https://')) {
        final uri = Uri.tryParse(raw);
        if (uri == null) return;
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          AppLogger.error('NativeAdCard: internal->external fallback failed — $e',
              tag: 'Ad');
        }
        return;
      }

      final route = raw.startsWith('/') ? raw : '/$raw';
      try {
        context.push(route);
      } catch (e) {
        AppLogger.error('NativeAdCard: internal route failed ($route) — $e',
            tag: 'Ad');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFanAd = banner.sourceType == BannerSourceType.fanAd;

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceAltDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFanAd
                ? AppColors.primary500.withValues(alpha: 0.4)
                : (isDark ? AppColors.borderDark : AppColors.border),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (banner.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 5 / 1,
                  child: CachedNetworkImage(
                    imageUrl: banner.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.surfaceAlt,
                    ),
                  ),
                ),
              ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  if (isFanAd) ...[
                    const _AdBadge(label: '팬 광고', color: AppColors.primary500),
                    const SizedBox(width: 6),
                  ] else ...[
                    _AdBadge(
                        label: '광고',
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.iconMuted),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      banner.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (banner.linkType != 'none')
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.iconMuted,
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

class _AdBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _AdBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
