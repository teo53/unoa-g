import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';

/// 앱 레이아웃 Scaffold
///
/// 플랫폼별 렌더링:
/// - 모바일 네이티브(안드로이드/iOS): 전체 화면으로 표시 (테두리 없음)
/// - 모바일 웹 (화면 너비 ≤ 600px): 전체 화면으로 표시 (브라우저 대응)
/// - 데스크톱 웹 (화면 너비 > 600px): 폰 프레임 UI로 데모 표시
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

    // 모바일 디바이스(네이티브): 전체 화면 레이아웃 (테두리 없음)
    if (!kIsWeb) {
      return _MobileLayout(
        backgroundColor: bgColor,
        bottomNavigationBar: bottomNavigationBar,
        child: child,
      );
    }

    // 웹: 화면 너비에 따라 모바일/데스크톱 분기
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileWeb = screenWidth <= 600;

    // 모바일 웹: 전체 화면 레이아웃 (폰 프레임 없이)
    if (isMobileWeb) {
      return _MobileWebLayout(
        backgroundColor: bgColor,
        bottomNavigationBar: bottomNavigationBar,
        child: child,
      );
    }

    // 데스크톱 웹: 폰 프레임 데모 레이아웃
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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bottomNavigationBar != null)
            SafeArea(
              top: false,
              bottom: false,
              child: bottomNavigationBar!,
            ),
          // Demo disclaimer text at very bottom
          if (!AppConfig.isProduction)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4, top: 2),
                child: Center(child: const _DemoDisclaimerText()),
              ),
            ),
        ],
      ),
    );
  }
}

/// 모바일 웹 전체 화면 레이아웃
///
/// 모바일 브라우저에서 Firebase 링크로 접속 시 사용.
/// 특징:
/// - 폰 프레임 없이 전체 화면으로 표시
/// - 브라우저 하단 바/노치에 대한 safe area 패딩 처리
/// - 뷰포트 높이를 100% 활용
class _MobileWebLayout extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;
  final Color backgroundColor;

  const _MobileWebLayout({
    required this.child,
    required this.backgroundColor,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: child,
      bottomNavigationBar: bottomNavigationBar != null || !AppConfig.isProduction
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (bottomNavigationBar != null) bottomNavigationBar!,
                // Demo disclaimer text
                if (!AppConfig.isProduction)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Center(child: const _DemoDisclaimerText()),
                  ),
                // 브라우저 하단 safe area 여백
                SizedBox(height: bottomPadding > 0 ? bottomPadding : 8),
              ],
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

    final phoneFrame = Container(
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
    );

    return Scaffold(
      backgroundColor: Colors.grey[isDark ? 900 : 200],
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            phoneFrame,
            // Demo version disclaimer text (below phone frame)
            if (!AppConfig.isProduction)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: _DemoDisclaimerText(),
              ),
          ],
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

/// 데모 버전 고지 텍스트
///
/// 프로덕션이 아닌 환경에서 표시.
/// 은은한 텍스트로 확정 버전이 아님을 고지.
class _DemoDisclaimerText extends StatelessWidget {
  const _DemoDisclaimerText();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      'DEMO  ·  본 데모는 확정 버전이 아니며, 실제 서비스와 다를 수 있습니다.',
      style: TextStyle(
        color: isDark ? Colors.grey[600] : Colors.grey[500],
        fontSize: 10,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
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
    final textColor = isDark ? AppColors.textMainDark : AppColors.textMainLight;

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
