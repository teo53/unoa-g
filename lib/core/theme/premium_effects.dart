import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';

/// UNO A Premium Effects
///
/// DT/VIP 과금 요소에 적용되는 프리미엄 시각 효과
/// - Glow: 버튼, 카드에 은은한 빛 효과
/// - Gradient: 통일된 그래디언트 프리셋
class PremiumEffects {
  // ═══════════════════════════════════════════════════════════════
  // GLOW EFFECTS
  // ═══════════════════════════════════════════════════════════════

  /// Subtle Glow - 기본 과금 요소용 (CTA 버튼, FAB)
  /// 30% opacity, blur 16
  static BoxShadow get subtleGlow => BoxShadow(
    color: AppColors.primaryGlow,
    blurRadius: 16,
    spreadRadius: 0,
    offset: const Offset(0, 4),
  );

  /// Strong Glow - VIP/프리미엄 요소용 (DT Balance Card, VIP Badge)
  /// 50% opacity, blur 24
  static BoxShadow get strongGlow => BoxShadow(
    color: AppColors.primaryGlowStrong,
    blurRadius: 24,
    spreadRadius: 2,
    offset: const Offset(0, 6),
  );

  /// Ambient Glow - 전체 둘레 글로우 (호버/포커스 상태)
  /// 20% opacity, blur 20, 사방으로 퍼짐
  static BoxShadow get ambientGlow => BoxShadow(
    color: AppColors.primaryGlow.withOpacity(0.2),
    blurRadius: 20,
    spreadRadius: 4,
    offset: Offset.zero,
  );

  // ═══════════════════════════════════════════════════════════════
  // SHADOW PRESETS
  // ═══════════════════════════════════════════════════════════════

  /// Card Shadow - 일반 카드용
  static BoxShadow get cardShadow => BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 16,
    spreadRadius: 0,
    offset: const Offset(0, 4),
  );

  /// Elevated Shadow - 떠있는 요소용 (FAB, Dialogs)
  static BoxShadow get elevatedShadow => BoxShadow(
    color: Colors.black.withOpacity(0.12),
    blurRadius: 24,
    spreadRadius: 0,
    offset: const Offset(0, 8),
  );

  // ═══════════════════════════════════════════════════════════════
  // COMBINED SHADOW LISTS
  // ═══════════════════════════════════════════════════════════════

  /// Primary CTA Shadow - subtleGlow + cardShadow
  static List<BoxShadow> get primaryCtaShadows => [
    subtleGlow,
    cardShadow,
  ];

  /// Premium Card Shadow - strongGlow + elevatedShadow
  static List<BoxShadow> get premiumCardShadows => [
    strongGlow,
    elevatedShadow,
  ];

  /// VIP Badge Shadow - strongGlow only
  static List<BoxShadow> get vipBadgeShadows => [
    strongGlow,
  ];

  /// FAB Shadow - subtleGlow + elevatedShadow
  static List<BoxShadow> get fabShadows => [
    subtleGlow,
    elevatedShadow,
  ];

  // ═══════════════════════════════════════════════════════════════
  // GRADIENT DECORATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Primary Gradient Decoration - CTA 버튼, 배너
  static BoxDecoration get primaryGradientDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: AppColors.primaryGradient,
    ),
    borderRadius: BorderRadius.circular(AppRadius.lg),
    boxShadow: primaryCtaShadows,
  );

  /// Premium Gradient Decoration - VIP 카드, DT Balance
  static BoxDecoration get premiumGradientDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: AppColors.premiumGradient,
    ),
    borderRadius: BorderRadius.circular(AppRadius.lg),
    boxShadow: premiumCardShadows,
  );

  /// Subtle Gradient Decoration - 피처드 배너
  static BoxDecoration get subtleGradientDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: AppColors.subtleGradient,
    ),
    borderRadius: BorderRadius.circular(AppRadius.lg),
  );

  // ═══════════════════════════════════════════════════════════════
  // BUTTON DECORATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Primary Filled Button - WCAG 준수 primary600
  static BoxDecoration primaryButtonDecoration({
    double borderRadius = AppRadius.md,
    bool withGlow = false,
  }) => BoxDecoration(
    color: AppColors.primary600,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: withGlow ? primaryCtaShadows : null,
  );

  /// Secondary Button - 투명 배경 + 테두리
  static BoxDecoration secondaryButtonDecoration({
    double borderRadius = AppRadius.md,
    bool isDark = false,
  }) => BoxDecoration(
    color: isDark ? AppColors.surfaceDark : AppColors.surface,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: isDark ? AppColors.borderDark : AppColors.border,
    ),
  );

  /// Destructive Button - Danger 색상 사용
  static BoxDecoration destructiveButtonDecoration({
    double borderRadius = AppRadius.md,
  }) => BoxDecoration(
    color: AppColors.danger,
    borderRadius: BorderRadius.circular(borderRadius),
  );

  /// Destructive Outline Button
  static BoxDecoration destructiveOutlineDecoration({
    double borderRadius = AppRadius.md,
    bool isDark = false,
  }) => BoxDecoration(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: AppColors.danger,
      width: 1.5,
    ),
  );

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Apply glow to existing decoration
  static BoxDecoration addGlow(
    BoxDecoration decoration, {
    bool strong = false,
  }) {
    return decoration.copyWith(
      boxShadow: [
        ...?decoration.boxShadow,
        strong ? strongGlow : subtleGlow,
      ],
    );
  }

  /// Create rounded container with optional glow
  static BoxDecoration roundedContainer({
    Color? color,
    double borderRadius = AppRadius.lg,
    Border? border,
    bool withGlow = false,
    bool strongGlow = false,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: color ?? (isDark ? AppColors.surfaceDark : AppColors.surface),
      borderRadius: BorderRadius.circular(borderRadius),
      border: border,
      boxShadow: withGlow
          ? (strongGlow ? premiumCardShadows : primaryCtaShadows)
          : null,
    );
  }
}

/// KRDS 4단계 엘리베이션 시스템
///
/// KRDS style_08 기반 시멘틱 쉐도우 레벨
/// Basic → Interaction → Elevated → Critical/Modal
class KRDSElevation {
  KRDSElevation._();

  /// Level 1 (Basic) - 카드, 리스트 아이템 기본 상태
  static List<BoxShadow> get level1 => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 4,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];

  /// Level 2 (Interaction) - 호버, 포커스, 선택 상태
  static List<BoxShadow> get level2 => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 8,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  /// Level 3 (Elevated) - FAB, 드롭다운, 팝오버
  static List<BoxShadow> get level3 => [
    BoxShadow(
      color: Colors.black.withOpacity(0.16),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  /// Level 4 (Critical/Modal) - 모달, 다이얼로그, 바텀시트
  static List<BoxShadow> get level4 => [
    BoxShadow(
      color: Colors.black.withOpacity(0.22),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 12),
    ),
  ];

  /// Dimmed overlay - 모달 뒤 배경 어둡게
  static Color get dimmedOverlay => Colors.black.withOpacity(0.4);
}

/// Animation durations for premium effects
class PremiumAnimations {
  static const Duration shimmerSlow = Duration(milliseconds: 3000);
  static const Duration shimmerMedium = Duration(milliseconds: 2500);
  static const Duration shimmerFast = Duration(milliseconds: 2000);

  static const Duration glowPulse = Duration(milliseconds: 1500);
  static const Duration buttonPress = Duration(milliseconds: 150);
  static const Duration fadeIn = Duration(milliseconds: 300);
}
