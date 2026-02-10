import 'package:flutter/material.dart';

/// Enterprise-grade animation utilities
/// Provides consistent, performant animations throughout the app

/// Standard duration constants
class AnimationDurations {
  /// Extra short animation (50ms) - Micro-interactions
  static const Duration extraShort = Duration(milliseconds: 50);

  /// Short animation (100ms) - Quick feedback
  static const Duration short = Duration(milliseconds: 100);

  /// Normal animation (200ms) - Standard transitions
  static const Duration normal = Duration(milliseconds: 200);

  /// Medium animation (300ms) - Page transitions
  static const Duration medium = Duration(milliseconds: 300);

  /// Long animation (500ms) - Complex animations
  static const Duration long = Duration(milliseconds: 500);

  /// Extra long animation (800ms) - Elaborate animations
  static const Duration extraLong = Duration(milliseconds: 800);
}

/// Standard curve constants
class AnimationCurves {
  /// Standard easing - Use for most animations
  static const Curve standard = Curves.easeInOut;

  /// Decelerate - Use for entering elements
  static const Curve decelerate = Curves.decelerate;

  /// Accelerate - Use for exiting elements
  static const Curve accelerate = Curves.easeIn;

  /// Emphasized - Use for important transitions
  static const Curve emphasized = Curves.easeOutCubic;

  /// Bounce - Use for playful feedback
  static const Curve bounce = Curves.elasticOut;

  /// Sharp - Use for quick snaps
  static const Curve sharp = Curves.easeOutQuart;
}

/// Fade in animation widget
class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Duration delay;
  final bool animate;

  const FadeInAnimation({
    super.key,
    required this.child,
    this.duration = AnimationDurations.normal,
    this.curve = AnimationCurves.standard,
    this.delay = Duration.zero,
    this.animate = true,
  });

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    if (widget.animate) {
      if (widget.delay > Duration.zero) {
        Future.delayed(widget.delay, () {
          if (mounted) _controller.forward();
        });
      } else {
        _controller.forward();
      }
    } else {
      _controller.value = 1.0;
    }
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
      child: widget.child,
    );
  }
}

/// Slide fade animation widget
class SlideFadeAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Duration delay;
  final Offset beginOffset;
  final bool animate;

  const SlideFadeAnimation({
    super.key,
    required this.child,
    this.duration = AnimationDurations.medium,
    this.curve = AnimationCurves.emphasized,
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, 0.1),
    this.animate = true,
  });

  /// Slide from bottom
  const SlideFadeAnimation.fromBottom({
    super.key,
    required this.child,
    this.duration = AnimationDurations.medium,
    this.curve = AnimationCurves.emphasized,
    this.delay = Duration.zero,
    this.animate = true,
  }) : beginOffset = const Offset(0, 0.2);

  /// Slide from top
  const SlideFadeAnimation.fromTop({
    super.key,
    required this.child,
    this.duration = AnimationDurations.medium,
    this.curve = AnimationCurves.emphasized,
    this.delay = Duration.zero,
    this.animate = true,
  }) : beginOffset = const Offset(0, -0.2);

  /// Slide from left
  const SlideFadeAnimation.fromLeft({
    super.key,
    required this.child,
    this.duration = AnimationDurations.medium,
    this.curve = AnimationCurves.emphasized,
    this.delay = Duration.zero,
    this.animate = true,
  }) : beginOffset = const Offset(-0.2, 0);

  /// Slide from right
  const SlideFadeAnimation.fromRight({
    super.key,
    required this.child,
    this.duration = AnimationDurations.medium,
    this.curve = AnimationCurves.emphasized,
    this.delay = Duration.zero,
    this.animate = true,
  }) : beginOffset = const Offset(0.2, 0);

  @override
  State<SlideFadeAnimation> createState() => _SlideFadeAnimationState();
}

class _SlideFadeAnimationState extends State<SlideFadeAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.animate) {
      if (widget.delay > Duration.zero) {
        Future.delayed(widget.delay, () {
          if (mounted) _controller.forward();
        });
      } else {
        _controller.forward();
      }
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Scale animation widget for tap feedback
class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;
  final bool enabled;

  const ScaleOnTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.95,
    this.duration = AnimationDurations.short,
    this.enabled = true,
  });

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationCurves.standard,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enabled) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.enabled) {
      _controller.reverse();
      widget.onTap?.call();
    }
  }

  void _onTapCancel() {
    if (widget.enabled) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _animation,
        child: widget.child,
      ),
    );
  }
}

/// Staggered list animation for list items
class StaggeredListAnimation extends StatelessWidget {
  final List<Widget> children;
  final Duration itemDuration;
  final Duration staggerDelay;
  final Curve curve;
  final bool animate;

  const StaggeredListAnimation({
    super.key,
    required this.children,
    this.itemDuration = AnimationDurations.medium,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.curve = AnimationCurves.emphasized,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(children.length, (index) {
        return SlideFadeAnimation.fromBottom(
          duration: itemDuration,
          curve: curve,
          delay: Duration(milliseconds: staggerDelay.inMilliseconds * index),
          animate: animate,
          child: children[index],
        );
      }),
    );
  }
}

/// Animated counter for numeric values
class AnimatedCounter extends StatelessWidget {
  final int value;
  final Duration duration;
  final Curve curve;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = AnimationDurations.medium,
    this.curve = AnimationCurves.emphasized,
    this.style,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Text(
          '${prefix ?? ''}$value${suffix ?? ''}',
          style: style,
        );
      },
    );
  }
}

/// Shimmer effect for loading states
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        widget.baseColor ?? (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final highlightColor = widget.highlightColor ??
        (isDark ? Colors.grey[700]! : Colors.grey[100]!);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Page route with custom transition
class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final RouteTransitionType transitionType;

  CustomPageRoute({
    required this.page,
    this.transitionType = RouteTransitionType.fade,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            switch (transitionType) {
              case RouteTransitionType.fade:
                return FadeTransition(opacity: animation, child: child);
              case RouteTransitionType.slideRight:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: AnimationCurves.emphasized,
                  )),
                  child: child,
                );
              case RouteTransitionType.slideUp:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: AnimationCurves.emphasized,
                  )),
                  child: child,
                );
              case RouteTransitionType.scale:
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: AnimationCurves.emphasized,
                    ),
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                );
            }
          },
          transitionDuration: AnimationDurations.medium,
        );
}

enum RouteTransitionType {
  fade,
  slideRight,
  slideUp,
  scale,
}
