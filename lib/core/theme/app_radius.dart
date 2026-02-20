/// KRDS-inspired border radius reference values (설계 문서 전용).
///
/// ⚠️ 실제 앱 코드에서는 이 파일을 직접 import하지 마세요.
/// 대신 `app_spacing.dart`의 `AppRadius` 클래스를 사용하세요.
///
/// 이 파일은 KRDS 디자인 시스템 참조값을 보존하기 위한 것입니다.
/// KRDS 기준: XSmall 2px, Small 4px, Medium 6-8px, Large 10px, XLarge 12px
/// UNO A 절충: K-pop 팬 앱의 부드러운 느낌을 유지하면서 KRDS 구조 도입
///
/// 실제 사용: `import '../../core/theme/app_spacing.dart';`
/// ```dart
/// AppRadius.baseBR  // BorderRadius.circular(12)
/// AppRadius.lgBR    // BorderRadius.circular(16)
/// ```
library;

class KrdsRadiusReference {
  KrdsRadiusReference._();

  /// 4px - 작은 칩, 배지, 태그
  static const double xs = 4;

  /// 8px - 인풋 내부 요소, 작은 카드
  static const double sm = 8;

  /// 10px - 버튼, 드롭다운
  static const double md = 10;

  /// 14px - 카드, 컨테이너, 다이얼로그 (KRDS 10→14 절충)
  static const double lg = 14;

  /// 18px - 채팅 버블, 큰 컨테이너
  static const double xl = 18;

  /// 24px - 바텀 시트, 모달
  static const double xxl = 24;

  /// 999px - 원형 (pill shape)
  static const double full = 999;
}
