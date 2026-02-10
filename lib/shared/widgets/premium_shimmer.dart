import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/premium_effects.dart';

/// Premium Shimmer Widget
///
/// DT/VIP 과금 요소에 적용되는 은은한 펄감 효과 (3% 이하)
///
/// 적용 대상 및 권장 설정:
/// - DT Balance Card: intensity 0.02, duration 3000ms
/// - VIP Badge: intensity 0.03, duration 2000ms
/// - 충전 CTA 버튼: intensity 0.02, duration 2500ms
/// - BEST 패키지 카드: intensity 0.025, duration 2800ms
class PremiumShimmer extends StatefulWidget {
  final Widget child;

  /// Shimmer intensity (0.01 ~ 0.03, 1~3%)
  /// Default: 0.02 (2%)
  final double intensity;

  /// Animation duration
  /// Default: 2500ms
  final Duration duration;

  /// Base color for shimmer effect
  /// Default: AppColors.primaryShimmer
  final Color? baseColor;

  /// Highlight color for shimmer peak
  /// Default: white with 8% opacity
  final Color? highlightColor;

  /// Whether shimmer is enabled
  final bool enabled;

  /// Border radius for clipping
  final BorderRadius? borderRadius;

  const PremiumShimmer({
    super.key,
    required this.child,
    this.intensity = 0.02,
    this.duration = const Duration(milliseconds: 2500),
    this.baseColor,
    this.highlightColor,
    this.enabled = true,
    this.borderRadius,
  }) : assert(intensity >= 0.01 && intensity <= 0.05,
            'Intensity should be between 0.01 and 0.05');

  /// Factory for DT Balance Card
  factory PremiumShimmer.balance({
    required Widget child,
    BorderRadius? borderRadius,
    bool enabled = true,
  }) {
    return PremiumShimmer(
      intensity: 0.02,
      duration: PremiumAnimations.shimmerSlow,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      enabled: enabled,
      child: child,
    );
  }

  /// Factory for VIP Badge
  factory PremiumShimmer.vip({
    required Widget child,
    BorderRadius? borderRadius,
    bool enabled = true,
  }) {
    return PremiumShimmer(
      intensity: 0.03,
      duration: PremiumAnimations.shimmerFast,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      enabled: enabled,
      child: child,
    );
  }

  /// Factory for CTA Button
  factory PremiumShimmer.button({
    required Widget child,
    BorderRadius? borderRadius,
    bool enabled = true,
  }) {
    return PremiumShimmer(
      intensity: 0.02,
      duration: PremiumAnimations.shimmerMedium,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      enabled: enabled,
      child: child,
    );
  }

  /// Factory for BEST Package Card
  factory PremiumShimmer.bestPackage({
    required Widget child,
    BorderRadius? borderRadius,
    bool enabled = true,
  }) {
    return PremiumShimmer(
      intensity: 0.025,
      duration: const Duration(milliseconds: 2800),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      enabled: enabled,
      child: child,
    );
  }

  @override
  State<PremiumShimmer> createState() => _PremiumShimmerState();
}

class _PremiumShimmerState extends State<PremiumShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(PremiumShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final baseColor = widget.baseColor ?? AppColors.primaryShimmer;
    final highlightColor = widget.highlightColor ??
        Colors.white
            .withValues(alpha: widget.intensity * 4); // Scale for visibility

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.transparent,
                          baseColor.withValues(alpha: widget.intensity),
                          highlightColor,
                          baseColor.withValues(alpha: widget.intensity),
                          Colors.transparent,
                        ],
                        stops: [
                          0.0,
                          (_animation.value - 0.3).clamp(0.0, 1.0),
                          _animation.value.clamp(0.0, 1.0),
                          (_animation.value + 0.3).clamp(0.0, 1.0),
                          1.0,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Glow Wrapper Widget
///
/// 요소에 글로우 효과를 추가하는 래퍼
class GlowWrapper extends StatelessWidget {
  final Widget child;
  final bool strong;
  final bool enabled;
  final BorderRadius? borderRadius;

  const GlowWrapper({
    super.key,
    required this.child,
    this.strong = false,
    this.enabled = true,
    this.borderRadius,
  });

  /// Factory for Premium elements (VIP, DT Balance)
  factory GlowWrapper.premium({
    required Widget child,
    BorderRadius? borderRadius,
    bool enabled = true,
  }) {
    return GlowWrapper(
      strong: true,
      borderRadius: borderRadius,
      enabled: enabled,
      child: child,
    );
  }

  /// Factory for CTA buttons
  factory GlowWrapper.cta({
    required Widget child,
    BorderRadius? borderRadius,
    bool enabled = true,
  }) {
    return GlowWrapper(
      strong: false,
      borderRadius: borderRadius,
      enabled: enabled,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: strong
            ? PremiumEffects.premiumCardShadows
            : PremiumEffects.primaryCtaShadows,
      ),
      child: child,
    );
  }
}

/// Premium Container
///
/// Shimmer + Glow가 결합된 프리미엄 컨테이너
class PremiumContainer extends StatelessWidget {
  final Widget child;
  final bool withShimmer;
  final bool withGlow;
  final bool strongGlow;
  final double shimmerIntensity;
  final Duration shimmerDuration;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Border? border;

  const PremiumContainer({
    super.key,
    required this.child,
    this.withShimmer = true,
    this.withGlow = true,
    this.strongGlow = false,
    this.shimmerIntensity = 0.02,
    this.shimmerDuration = const Duration(milliseconds: 2500),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.backgroundColor,
    this.gradient,
    this.border,
  });

  /// Factory for DT Balance Card
  factory PremiumContainer.balance({
    required Widget child,
  }) {
    return PremiumContainer(
      withShimmer: true,
      withGlow: true,
      strongGlow: true,
      shimmerIntensity: 0.02,
      shimmerDuration: PremiumAnimations.shimmerSlow,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: AppColors.premiumGradient,
      ),
      child: child,
    );
  }

  /// Factory for VIP Badge
  factory PremiumContainer.vip({
    required Widget child,
    BorderRadius? borderRadius,
  }) {
    return PremiumContainer(
      withShimmer: true,
      withGlow: true,
      strongGlow: true,
      shimmerIntensity: 0.03,
      shimmerDuration: PremiumAnimations.shimmerFast,
      borderRadius: borderRadius ?? const BorderRadius.all(Radius.circular(12)),
      backgroundColor: AppColors.vip,
      child: child,
    );
  }

  /// Factory for BEST package
  factory PremiumContainer.bestPackage({
    required Widget child,
  }) {
    return PremiumContainer(
      withShimmer: true,
      withGlow: true,
      strongGlow: false,
      shimmerIntensity: 0.025,
      shimmerDuration: const Duration(milliseconds: 2800),
      backgroundColor: AppColors.primary100,
      border: Border.all(color: AppColors.primary600, width: 1.5),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: BoxDecoration(
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: border,
        boxShadow: withGlow
            ? (strongGlow
                ? PremiumEffects.premiumCardShadows
                : PremiumEffects.primaryCtaShadows)
            : null,
      ),
      child: child,
    );

    if (withShimmer) {
      content = PremiumShimmer(
        intensity: shimmerIntensity,
        duration: shimmerDuration,
        borderRadius: borderRadius,
        child: content,
      );
    }

    return content;
  }
}
