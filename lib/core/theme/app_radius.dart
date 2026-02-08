/// KRDS-inspired border radius system (UNO A 톤 절충)
///
/// KRDS 기준: XSmall 2px, Small 4px, Medium 6-8px, Large 10px, XLarge 12px
/// UNO A 절충: K-pop 팬 앱의 부드러운 느낌을 유지하면서 KRDS 구조 도입
class AppRadius {
  AppRadius._();

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
