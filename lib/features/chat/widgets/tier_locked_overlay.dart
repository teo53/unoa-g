import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 티어별 콘텐츠 접근제어 오버레이
///
/// 팬이 자신의 구독 티어보다 높은 티어 메시지를 볼 때 표시됩니다.
/// 메시지 내용을 블러 처리하고 업그레이드 CTA를 보여줍니다.
class TierLockedOverlay extends StatelessWidget {
  /// 메시지 열람에 필요한 최소 티어
  final String requiredTier;

  /// 현재 사용자 티어
  final String? currentTier;

  /// 업그레이드 버튼 콜백
  final VoidCallback? onUpgradeTap;

  /// 블러 처리할 자식 위젯 (원본 메시지 버블)
  final Widget child;

  const TierLockedOverlay({
    super.key,
    required this.requiredTier,
    this.currentTier,
    this.onUpgradeTap,
    required this.child,
  });

  /// 티어에 해당하는 색상 반환
  static Color tierColor(String tier) {
    switch (tier.toUpperCase()) {
      case 'VIP':
        return const Color(0xFFFFD700); // Gold
      case 'STANDARD':
        return const Color(0xFF9B59B6); // Purple
      case 'BASIC':
      default:
        return const Color(0xFF3498DB); // Blue
    }
  }

  /// 티어 한국어 표시명
  static String tierDisplayName(String tier) {
    switch (tier.toUpperCase()) {
      case 'VIP':
        return 'VIP';
      case 'STANDARD':
        return 'STANDARD';
      case 'BASIC':
      default:
        return 'BASIC';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = tierColor(requiredTier);

    return Stack(
      children: [
        // 블러 처리된 원본 메시지
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: child,
          ),
        ),

        // 오버레이
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color:
                  (isDark ? Colors.black : Colors.white).withValues(alpha: 0.6),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 잠금 아이콘 + 티어 배지
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tierDisplayName(requiredTier)} 전용',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 안내 텍스트
                  Text(
                    '${tierDisplayName(requiredTier)} 이상 구독자만\n볼 수 있는 메시지입니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),

                  // 업그레이드 버튼
                  if (onUpgradeTap != null) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: onUpgradeTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '구독 업그레이드',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 크리에이터 채팅에서 티어 선택 위젯
///
/// 브로드캐스트 전송 시 최소 티어를 선택할 수 있는 칩 그룹입니다.
class TierSelector extends StatelessWidget {
  /// 현재 선택된 티어 (null = 전체)
  final String? selectedTier;

  /// 선택 변경 콜백
  final ValueChanged<String?> onChanged;

  const TierSelector({
    super.key,
    this.selectedTier,
    required this.onChanged,
  });

  static const _tiers = [
    (null, '전체', Icons.public, AppColors.primary),
    ('BASIC', 'BASIC', Icons.star_border, Color(0xFF3498DB)),
    ('STANDARD', 'STANDARD', Icons.star_half, Color(0xFF9B59B6)),
    ('VIP', 'VIP', Icons.star, Color(0xFFFFD700)),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _tiers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final tier = _tiers[index];
          final isSelected = selectedTier == tier.$1;

          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tier.$3,
                  size: 14,
                  color: isSelected ? Colors.white : tier.$4,
                ),
                const SizedBox(width: 4),
                Text(
                  tier.$2,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.grey[300] : Colors.grey[700]),
                  ),
                ),
              ],
            ),
            selected: isSelected,
            onSelected: (_) => onChanged(tier.$1),
            selectedColor: tier.$4,
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
            side: BorderSide(
              color: isSelected
                  ? tier.$4
                  : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }
}
