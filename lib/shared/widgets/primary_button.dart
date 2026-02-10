import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/premium_effects.dart';
import 'premium_shimmer.dart';

/// Primary Button - WCAG Compliant
///
/// Uses primary600 (#DE332A) for background to ensure 4.5:1 contrast ratio
/// with white text. Includes optional shimmer and glow effects for premium CTAs.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool showPulse;
  final IconData? icon;
  final double? width;

  /// Enable premium shimmer effect (for DT/VIP CTAs)
  final bool withShimmer;

  /// Enable glow effect
  final bool withGlow;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.showPulse = false,
    this.icon,
    this.width,
    this.withShimmer = false,
    this.withGlow = true,
  });

  /// Factory for premium CTA (DT charge, VIP actions)
  factory PrimaryButton.premium({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
  }) {
    return PrimaryButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      withShimmer: true,
      withGlow: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget button = Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: AppRadius.baseBR,
        boxShadow: withGlow ? PremiumEffects.primaryCtaShadows : null,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary600, // WCAG compliant
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primary600.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.baseBR,
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else ...[
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 14),
              ],
              if (showPulse) ...[
                const SizedBox(width: 6),
                _PulsingDot(),
              ],
            ],
          ],
        ),
      ),
    );

    if (withShimmer) {
      button = PremiumShimmer.button(child: button);
    }

    return button;
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Secondary Button - Outline style
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        foregroundColor: isDark ? AppColors.textMainDark : AppColors.text,
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.baseBR,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 14),
          ],
        ],
      ),
    );
  }
}

/// Destructive Button - For delete/block actions
///
/// Uses AppColors.danger (#B42318) - completely separate from Primary
class DestructiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isOutline;
  final bool isLoading;

  const DestructiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isOutline = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutline) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(
            color: AppColors.danger,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.baseBR,
          ),
        ),
        child: _buildChild(),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.danger,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.danger.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.baseBR,
        ),
        elevation: 0,
      ),
      child: _buildChild(),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: isOutline ? AppColors.danger : Colors.white,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Badge Chip with VIP shimmer effect
class BadgeChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final BadgeType type;

  const BadgeChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.type = BadgeType.standard,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor;
    Color fgColor;

    switch (type) {
      case BadgeType.vip:
        // VIP badge with shimmer effect
        return PremiumShimmer.vip(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.badgeVip,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [PremiumEffects.subtleGlow],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: textColor ?? AppColors.badgeVipText,
              ),
            ),
          ),
        );
      case BadgeType.live:
        bgColor = backgroundColor ?? AppColors.primary600;
        fgColor = textColor ?? Colors.white;
        break;
      case BadgeType.newBadge:
        bgColor = backgroundColor ?? AppColors.primary600;
        fgColor = textColor ?? Colors.white;
        break;
      case BadgeType.top:
        // Glassmorphism style - black/30 with backdrop blur
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      case BadgeType.danger:
        bgColor = backgroundColor ?? AppColors.danger100;
        fgColor = textColor ?? AppColors.danger;
        break;
      case BadgeType.success:
        bgColor = backgroundColor ?? AppColors.success100;
        fgColor = textColor ?? AppColors.success;
        break;
      case BadgeType.warning:
        bgColor = backgroundColor ?? AppColors.warning100;
        fgColor = textColor ?? AppColors.warning;
        break;
      case BadgeType.standard:
        bgColor = backgroundColor ??
            (isDark ? Colors.grey[800]! : AppColors.badgeStandard);
        fgColor = textColor ??
            (isDark ? Colors.grey[400]! : AppColors.badgeStandardText);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fgColor,
        ),
      ),
    );
  }
}

enum BadgeType {
  standard,
  vip,
  live,
  newBadge,
  top,
  danger,
  success,
  warning,
}
