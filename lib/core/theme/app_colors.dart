import 'package:flutter/material.dart';

/// UNO A Enterprise Color System
/// WCAG 2.1 AA Compliant (4.5:1 contrast ratio)
///
/// Design Principles:
/// - Primary and Danger are semantically separated
/// - Primary is reserved for active states and key CTAs only
/// - Filled CTAs use primary600 for WCAG compliance
class AppColors {
  // ═══════════════════════════════════════════════════════════════
  // FOUNDATION (Neutral) - Light Theme
  // ═══════════════════════════════════════════════════════════════

  /// Background color for main screens
  static const Color background = Color(0xFFF8F8F8);

  /// Surface color for cards, sheets
  static const Color surface = Color(0xFFFFFFFF);

  /// Alternative surface for input fields, secondary cards
  static const Color surfaceAlt = Color(0xFFF3F4F6);

  /// Border color for dividers, card borders
  static const Color border = Color(0xFFE5E7EB);

  /// Main text color
  static const Color text = Color(0xFF111827);

  /// Muted text color for secondary text
  static const Color textMuted = Color(0xFF6B7280);

  /// Muted icon color for inactive icons
  static const Color iconMuted = Color(0xFF9CA3AF);

  // ═══════════════════════════════════════════════════════════════
  // BRAND (Primary Ramp) - WCAG Compliant
  // ═══════════════════════════════════════════════════════════════

  /// Tint background for promo chips, subtle highlights (limited use)
  static const Color primary100 = Color(0xFFFFE6E4);

  /// Key Color - Active states (bottom nav, indicators, tab labels)
  static const Color primary500 = Color(0xFFFF3B30);

  /// Filled CTA background - WCAG 4.5:1 compliant with white text
  static const Color primary600 = Color(0xFFDE332A);

  /// Pressed/active strong state
  static const Color primary700 = Color(0xFFC92D25);

  /// Text color on primary backgrounds
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Legacy aliases (for backward compatibility)
  static const Color primary = primary500;
  static const Color primaryDark = primary700;
  static const Color primarySoft = primary100;

  // ═══════════════════════════════════════════════════════════════
  // GLOW & PREMIUM EFFECTS
  // ═══════════════════════════════════════════════════════════════

  /// 30% opacity - Standard glow for CTAs
  static const Color primaryGlow = Color(0x4DDE332A);

  /// 50% opacity - Strong glow for VIP, DT Balance
  static const Color primaryGlowStrong = Color(0x80DE332A);

  /// 5% opacity - Subtle pearl shimmer effect
  static const Color primaryShimmer = Color(0x0DDE332A);

  // ═══════════════════════════════════════════════════════════════
  // SEMANTIC COLORS
  // ═══════════════════════════════════════════════════════════════

  /// Destructive actions only (delete, block, cancel subscription)
  /// ⚠️ NEVER use for positive actions - use primary600 instead
  static const Color danger = Color(0xFFB42318);

  /// Danger tint for backgrounds
  static const Color danger100 = Color(0xFFFEE2E2);

  /// Error alias (same as danger)
  static const Color error = danger;

  /// Success state
  static const Color success = Color(0xFF16A34A);

  /// Success tint for backgrounds
  static const Color success100 = Color(0xFFDCFCE7);

  /// Warning state
  static const Color warning = Color(0xFFD97706);

  /// Warning tint for backgrounds
  static const Color warning100 = Color(0xFFFEF3C7);

  /// Online status indicator
  static const Color online = Color(0xFF22C55E);

  /// Verified badge color
  static const Color verified = Color(0xFF3B82F6);

  /// Star/favorite color
  static const Color star = Color(0xFFFBBF24);

  /// VIP badge color
  static const Color vip = Color(0xFF8B5CF6);

  /// Standard tier color
  static const Color standard = Color(0xFF3B82F6);

  // ═══════════════════════════════════════════════════════════════
  // UNIFIED GRADIENTS
  // ═══════════════════════════════════════════════════════════════

  /// Primary Gradient - For CTAs, banners (primary600 based)
  static const List<Color> primaryGradient = [
    Color(0xFFDE332A),  // primary600
    Color(0xFFFF6B6B),  // lighter
  ];

  /// Premium Gradient - For VIP, DT cards
  static const List<Color> premiumGradient = [
    Color(0xFFDE332A),
    Color(0xFFFF8E53),
  ];

  /// Subtle Gradient - For featured banners
  static const List<Color> subtleGradient = [
    Color(0xFFFF6B6B),
    Color(0xFFFF8E8E),
  ];

  // ═══════════════════════════════════════════════════════════════
  // PRIVATE CARD COLORS
  // ═══════════════════════════════════════════════════════════════

  /// Private card gradient start (soft purple)
  static const Color cardGradientStart = Color(0xFFE8B5FF);

  /// Private card gradient end (soft pink)
  static const Color cardGradientEnd = Color(0xFFFF8FAB);

  /// Private card accent pink
  static const Color cardAccentPink = Color(0xFFEC4899);

  /// Private card warm pink (for media placeholders/fallback)
  static const Color cardWarmPink = Color(0xFFFFB6C8);

  /// Private Card Gradient - For card borders and decorative elements
  static const List<Color> privateCardGradient = [cardGradientStart, cardGradientEnd];

  /// Private Card Label Gradient - For the "private card" badge
  static const List<Color> privateCardLabelGradient = [vip, cardAccentPink];

  // ═══════════════════════════════════════════════════════════════
  // DARK THEME FOUNDATION
  // ═══════════════════════════════════════════════════════════════

  /// Dark mode background
  static const Color backgroundDark = Color(0xFF000000);

  /// Dark mode surface
  static const Color surfaceDark = Color(0xFF1C1C1E);

  /// Dark mode alternative surface
  static const Color surfaceAltDark = Color(0xFF2C2C2E);

  /// Dark mode border
  static const Color borderDark = Color(0xFF38383A);

  /// Dark mode main text
  static const Color textDark = Color(0xFFFFFFFF);

  /// Dark mode muted text
  static const Color textMutedDark = Color(0xFF8E8E93);

  /// Dark mode muted icon
  static const Color iconMutedDark = Color(0xFF636366);

  // Legacy dark theme aliases
  static const Color textMainDark = textDark;
  static const Color textSubDark = textMutedDark;

  // Legacy light theme aliases
  static const Color backgroundLight = background;
  static const Color surfaceLight = surface;
  static const Color textMainLight = text;
  static const Color textSubLight = textMuted;
  static const Color borderLight = border;
  static const Color highlightLight = primary100;
  static const Color cardLight = surface;
  static const Color highlightDark = Color(0xFF2C1515);
  static const Color cardDark = surfaceDark;

  // ═══════════════════════════════════════════════════════════════
  // CHAT BUBBLES
  // ═══════════════════════════════════════════════════════════════

  /// Fan message bubble - Light mode
  static const Color bubbleFanLight = Color(0xFFFCECEF);

  /// Fan message bubble - Dark mode
  static const Color bubbleFanDark = Color(0xFF3F181C);

  /// Artist message bubble - Light mode
  static const Color bubbleArtistLight = Color(0xFFFFFFFF);

  /// Artist message bubble - Dark mode
  static const Color bubbleArtistDark = Color(0xFF1E1E1E);

  // ═══════════════════════════════════════════════════════════════
  // PIN/HIGHLIGHT BACKGROUNDS
  // ═══════════════════════════════════════════════════════════════

  /// Pinned message background - Light mode
  static const Color pinnedLight = Color(0x80FFF0F0);

  /// Pinned message background - Dark mode
  static const Color pinnedDark = Color(0xFF2C1515);

  // ═══════════════════════════════════════════════════════════════
  // BADGE COLORS
  // ═══════════════════════════════════════════════════════════════

  /// Standard badge background
  static const Color badgeStandard = Color(0xFFF3F4F6);

  /// Standard badge text
  static const Color badgeStandardText = Color(0xFF6B7280);

  /// VIP badge background
  static const Color badgeVip = Color(0xFFFDF4FF);

  /// VIP badge text
  static const Color badgeVipText = Color(0xFF8B5CF6);
}

// ═══════════════════════════════════════════════════════════════
// ARTIST THEME COLORS (크리에이터별 테마 색상)
// ═══════════════════════════════════════════════════════════════

/// 아티스트가 선택할 수 있는 프리셋 테마 색상 시스템.
/// themeColorIndex(0-5)를 Color로 변환하는 유틸리티.
class ArtistThemeColors {
  ArtistThemeColors._();

  /// 프리셋 색상 목록 (index 0-5)
  static const List<Color> presets = [
    AppColors.primary,     // 0: 기본 (레드)
    Color(0xFFE91E63),     // 1: 핑크
    Color(0xFF2196F3),     // 2: 블루
    Color(0xFF9C27B0),     // 3: 퍼플
    Color(0xFF009688),     // 4: 틸
    Color(0xFFFF9800),     // 5: 오렌지
  ];

  /// 프리셋 색상 이름 (한국어)
  static const List<String> names = [
    '기본',
    '핑크',
    '블루',
    '퍼플',
    '틸',
    '오렌지',
  ];

  /// themeColorIndex → Color 변환 (범위 벗어나면 기본색)
  static Color fromIndex(int index) {
    return presets[index.clamp(0, presets.length - 1)];
  }

  /// CTA용 약간 어두운 색상 (WCAG 대비 강화)
  static Color fromIndexDark(int index) {
    final base = fromIndex(index);
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0))
        .toColor();
  }

  /// 프리셋 개수
  static int get count => presets.length;
}

/// Theme Extension for dynamic color access
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color surface;
  final Color card;
  final Color textMain;
  final Color textSub;
  final Color border;
  final Color highlight;
  final Color bubbleFan;
  final Color bubbleArtist;
  final Color pinned;

  const AppColorsExtension({
    required this.surface,
    required this.card,
    required this.textMain,
    required this.textSub,
    required this.border,
    required this.highlight,
    required this.bubbleFan,
    required this.bubbleArtist,
    required this.pinned,
  });

  static const light = AppColorsExtension(
    surface: AppColors.surfaceLight,
    card: AppColors.cardLight,
    textMain: AppColors.textMainLight,
    textSub: AppColors.textSubLight,
    border: AppColors.borderLight,
    highlight: AppColors.highlightLight,
    bubbleFan: AppColors.bubbleFanLight,
    bubbleArtist: AppColors.bubbleArtistLight,
    pinned: AppColors.pinnedLight,
  );

  static const dark = AppColorsExtension(
    surface: AppColors.surfaceDark,
    card: AppColors.cardDark,
    textMain: AppColors.textMainDark,
    textSub: AppColors.textSubDark,
    border: AppColors.borderDark,
    highlight: AppColors.highlightDark,
    bubbleFan: AppColors.bubbleFanDark,
    bubbleArtist: AppColors.bubbleArtistDark,
    pinned: AppColors.pinnedDark,
  );

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? surface,
    Color? card,
    Color? textMain,
    Color? textSub,
    Color? border,
    Color? highlight,
    Color? bubbleFan,
    Color? bubbleArtist,
    Color? pinned,
  }) {
    return AppColorsExtension(
      surface: surface ?? this.surface,
      card: card ?? this.card,
      textMain: textMain ?? this.textMain,
      textSub: textSub ?? this.textSub,
      border: border ?? this.border,
      highlight: highlight ?? this.highlight,
      bubbleFan: bubbleFan ?? this.bubbleFan,
      bubbleArtist: bubbleArtist ?? this.bubbleArtist,
      pinned: pinned ?? this.pinned,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      textMain: Color.lerp(textMain, other.textMain, t)!,
      textSub: Color.lerp(textSub, other.textSub, t)!,
      border: Color.lerp(border, other.border, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      bubbleFan: Color.lerp(bubbleFan, other.bubbleFan, t)!,
      bubbleArtist: Color.lerp(bubbleArtist, other.bubbleArtist, t)!,
      pinned: Color.lerp(pinned, other.pinned, t)!,
    );
  }
}
