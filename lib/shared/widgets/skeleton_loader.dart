import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Enterprise-grade skeleton loader with shimmer animation
/// Provides smooth loading states for a polished UX
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final bool isCircle;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.isCircle = false,
    this.borderRadius,
    this.margin,
  });

  /// Creates a circular skeleton (e.g., for avatars)
  const SkeletonLoader.circle({
    super.key,
    required double size,
    this.margin,
  })  : width = size,
        height = size,
        isCircle = true,
        borderRadius = null;

  /// Creates a text-line skeleton
  const SkeletonLoader.text({
    super.key,
    required this.width,
    double? height,
    this.margin,
  })  : height = height ?? 14,
        isCircle = false,
        borderRadius = null;

  /// Creates a rectangular card skeleton
  const SkeletonLoader.card({
    super.key,
    required this.width,
    required this.height,
    BorderRadius? borderRadius,
    this.margin,
  })  : isCircle = false,
        borderRadius = borderRadius ?? const BorderRadius.all(Radius.circular(12));

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.4, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceAltDark.withValues(alpha: _animation.value)
                : AppColors.surfaceAlt.withValues(alpha: _animation.value + 0.3),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius:
                widget.isCircle ? null : (widget.borderRadius ?? BorderRadius.circular(8)),
          ),
        );
      },
    );
  }
}

/// Skeleton list tile for chat lists, notifications, etc.
class SkeletonListTile extends StatelessWidget {
  final bool showAvatar;
  final bool showSubtitle;
  final bool showTrailing;
  final double avatarSize;

  const SkeletonListTile({
    super.key,
    this.showAvatar = true,
    this.showSubtitle = true,
    this.showTrailing = false,
    this.avatarSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (showAvatar) ...[
            SkeletonLoader.circle(size: avatarSize),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader.text(width: 120),
                if (showSubtitle) ...[
                  const SizedBox(height: 8),
                  const SkeletonLoader.text(width: 200, height: 12),
                ],
              ],
            ),
          ),
          if (showTrailing) ...[
            const SizedBox(width: 12),
            const SkeletonLoader.text(width: 40, height: 12),
          ],
        ],
      ),
    );
  }
}

/// Skeleton card for grid items, stories, etc.
class SkeletonCard extends StatelessWidget {
  final double width;
  final double height;
  final bool showTitle;
  final bool showSubtitle;

  const SkeletonCard({
    super.key,
    this.width = double.infinity,
    this.height = 120,
    this.showTitle = true,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SkeletonLoader.card(
          width: width,
          height: height,
          borderRadius: BorderRadius.circular(16),
        ),
        if (showTitle) ...[
          const SizedBox(height: 8),
          const SkeletonLoader.text(width: 80),
        ],
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          const SkeletonLoader.text(width: 60, height: 12),
        ],
      ],
    );
  }
}

/// Skeleton message bubble for chat screens
class SkeletonMessageBubble extends StatelessWidget {
  final bool isFromArtist;
  final double width;

  const SkeletonMessageBubble({
    super.key,
    this.isFromArtist = true,
    this.width = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (isFromArtist) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader.circle(size: 36),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonLoader.text(width: 60, height: 12),
              const SizedBox(height: 6),
              SkeletonLoader.card(
                width: width,
                height: 60,
                borderRadius: BorderRadius.circular(16),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SkeletonLoader.card(
          width: width,
          height: 40,
          borderRadius: BorderRadius.circular(16),
        ),
      ],
    );
  }
}

/// Full screen skeleton for content loading
class SkeletonScreen extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final Widget? loadingWidget;

  const SkeletonScreen({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ?? const _DefaultLoadingSkeleton();
    }
    return child;
  }
}

class _DefaultLoadingSkeleton extends StatelessWidget {
  const _DefaultLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header skeleton
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: const [
              SkeletonLoader.circle(size: 40),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader.text(width: 100),
                    SizedBox(height: 6),
                    SkeletonLoader.text(width: 150, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List skeletons
        Expanded(
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            itemBuilder: (context, index) => const SkeletonListTile(),
          ),
        ),
      ],
    );
  }
}
