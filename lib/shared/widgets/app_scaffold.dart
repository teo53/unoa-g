import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app.dart';
import '../../core/theme/app_colors.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;
  final bool showStatusBar;
  final Color? backgroundColor;
  final bool showThemeToggle;

  const AppScaffold({
    super.key,
    required this.child,
    this.bottomNavigationBar,
    this.showStatusBar = true,
    this.backgroundColor,
    this.showThemeToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.backgroundDark : AppColors.backgroundLight);

    return Scaffold(
      backgroundColor: Colors.grey[isDark ? 900 : 200],
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 400,
              height: 844,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(48),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[900]!,
                  width: 8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        if (showStatusBar) const StatusBarWidget(),
                        Expanded(child: child),
                        if (bottomNavigationBar != null) bottomNavigationBar!,
                        // Home indicator
                        Container(
                          padding: const EdgeInsets.only(bottom: 8, top: 4),
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          child: Center(
                            child: Container(
                              width: 128,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[700]
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Dark mode toggle button - positioned outside the phone frame
          if (showThemeToggle)
            Positioned(
              right: 24,
              bottom: 24,
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return _ThemeToggleButton(
                    isDark: themeProvider.isDark,
                    onTap: () => themeProvider.toggleTheme(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeToggleButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeToggleButton({
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<_ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            widget.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: widget.isDark ? Colors.amber : Colors.indigo,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class StatusBarWidget extends StatelessWidget {
  const StatusBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textMainDark : AppColors.textMainLight;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '9:41',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          Row(
            children: [
              Icon(Icons.signal_cellular_alt, size: 16, color: textColor),
              const SizedBox(width: 4),
              Icon(Icons.wifi, size: 16, color: textColor),
              const SizedBox(width: 4),
              Icon(Icons.battery_full, size: 16, color: textColor),
            ],
          ),
        ],
      ),
    );
  }
}
