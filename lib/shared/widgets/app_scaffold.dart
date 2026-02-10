import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/theme/app_colors.dart';

/// 앱 레이아웃 Scaffold
///
/// 플랫폼별 렌더링:
/// - 웹: 폰 프레임 UI로 데모 표시
/// - 모바일(안드로이드/iOS): 전체 화면으로 표시 (테두리 없음)
class AppScaffold extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;
  final bool showStatusBar;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.child,
    this.bottomNavigationBar,
    this.showStatusBar = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.backgroundDark : AppColors.backgroundLight);

    // 모바일 디바이스: 전체 화면 레이아웃 (테두리 없음)
    if (!kIsWeb) {
      return _MobileLayout(
        backgroundColor: bgColor,
        bottomNavigationBar: bottomNavigationBar,
        child: child,
      );
    }

    // 웹: 폰 프레임 데모 레이아웃
    return _WebPreviewLayout(
      backgroundColor: bgColor,
      showStatusBar: showStatusBar,
      bottomNavigationBar: bottomNavigationBar,
      child: child,
    );
  }
}

/// 모바일 전체 화면 레이아웃 (안드로이드/iOS)
///
/// 특징:
/// - 테두리 없이 전체 화면 사용
/// - SafeArea로 노치/펀치홀 대응
/// - 시스템 네비게이션 바 영역 확보
class _MobileLayout extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;
  final Color backgroundColor;

  const _MobileLayout({
    required this.child,
    required this.backgroundColor,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false, // 하단 네비게이션 바에서 처리
        child: child,
      ),
      bottomNavigationBar: bottomNavigationBar != null
          ? SafeArea(
              top: false,
              child: bottomNavigationBar!,
            )
          : null,
    );
  }
}

/// 웹 데모용 폰 프레임 레이아웃
///
/// 특징:
/// - 고정 사이즈 폰 프레임 (400x844)
/// - 둥근 모서리와 베젤
/// - 가짜 상태바와 홈 인디케이터
class _WebPreviewLayout extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;
  final bool showStatusBar;
  final Color backgroundColor;

  const _WebPreviewLayout({
    required this.child,
    required this.backgroundColor,
    required this.showStatusBar,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.grey[isDark ? 900 : 200],
      body: Center(
        child: Container(
          width: 400,
          height: 844,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(48),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[900]!,
              width: 8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Column(
              children: [
                if (showStatusBar) const StatusBarWidget(),
                Expanded(child: child),
                if (bottomNavigationBar != null) bottomNavigationBar!,
                _HomeIndicator(isDark: isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 홈 인디케이터 (웹 데모용)
class _HomeIndicator extends StatelessWidget {
  final bool isDark;

  const _HomeIndicator({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Center(
        child: Container(
          width: 128,
          height: 4,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[700] : Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// 웹 데모용 가짜 상태바
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
