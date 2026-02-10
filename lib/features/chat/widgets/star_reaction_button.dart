import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// UNO A 스타일 하트 반응 버튼
/// - 골드/스타 컬러 사용 (레퍼런스 앱의 빨간 하트와 차별화)
/// - 15% 알파 배경, 30% 알파 테두리
/// - ScaleOnTap 애니메이션
class StarReactionButton extends StatefulWidget {
  final int count;
  final bool hasReacted;
  final VoidCallback? onTap;
  final bool compact;

  const StarReactionButton({
    super.key,
    required this.count,
    required this.hasReacted,
    this.onTap,
    this.compact = false,
  });

  @override
  State<StarReactionButton> createState() => _StarReactionButtonState();
}

class _StarReactionButtonState extends State<StarReactionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.85),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.15),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0),
        weight: 30,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(StarReactionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 리액션 상태가 변경되면 애니메이션 실행
    if (oldWidget.hasReacted != widget.hasReacted && widget.hasReacted) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      _controller.forward(from: 0);
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const starColor = AppColors.star;

    // 리액션이 0이고 반응하지 않은 경우, 아이콘만 표시 (컴팩트 모드에서는 숨김)
    if (widget.count == 0 && !widget.hasReacted && widget.compact) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildButton(isDark, starColor),
          );
        },
      ),
    );
  }

  Widget _buildButton(bool isDark, Color starColor) {
    final hasCount = widget.count > 0;

    // 반응이 있는 경우: 배경 있는 버튼
    if (hasCount || widget.hasReacted) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 6 : 8,
          vertical: widget.compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: widget.hasReacted
              ? starColor.withValues(alpha: 0.15)
              : (isDark
                  ? AppColors.surfaceAltDark.withValues(alpha: 0.5)
                  : AppColors.surfaceAlt.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.hasReacted
                ? starColor.withValues(alpha: 0.3)
                : (isDark
                    ? AppColors.borderDark.withValues(alpha: 0.3)
                    : AppColors.border.withValues(alpha: 0.3)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.hasReacted ? _pulseAnimation.value : 1.0,
                  child: Icon(
                    widget.hasReacted
                        ? Icons.favorite
                        : Icons.favorite_outline,
                    color: widget.hasReacted
                        ? starColor
                        : (isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMuted),
                    size: widget.compact ? 14 : 16,
                  ),
                );
              },
            ),
            if (hasCount) ...[
              SizedBox(width: widget.compact ? 2 : 4),
              Text(
                _formatCount(widget.count),
                style: TextStyle(
                  fontSize: widget.compact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: widget.hasReacted
                      ? starColor
                      : (isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // 반응이 없는 경우: 아이콘만
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Icon(
        Icons.favorite_outline,
        color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
        size: widget.compact ? 14 : 16,
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// AnimatedBuilder를 사용하기 위한 래퍼
/// (Flutter에 이미 있지만 명시적으로 사용)
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
