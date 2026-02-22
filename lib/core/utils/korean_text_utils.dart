/// Korean text processing utilities for Hangul chosung (initial consonant) search.
///
/// Hangul syllable Unicode structure:
///   code = 0xAC00 + (chosung * 21 * 28) + (jungsung * 28) + jongsung
///
/// Range: 가 (0xAC00) ~ 힣 (0xD7A3)
class KoreanTextUtils {
  KoreanTextUtils._();

  static const int _hangulBase = 0xAC00;
  static const int _hangulEnd = 0xD7A3;
  static const int _jungsungCount = 21;
  static const int _jongsungCount = 28;

  /// The 19 chosung (initial consonants) in Unicode order.
  static const List<String> chosung = [
    'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', //
    'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
  ];

  /// Whether [codeUnit] is a complete Hangul syllable (가-힣).
  static bool isHangulSyllable(int codeUnit) {
    return codeUnit >= _hangulBase && codeUnit <= _hangulEnd;
  }

  /// Whether [codeUnit] is a standalone chosung jamo (ㄱ-ㅎ, 0x3131-0x314E).
  static bool isChosungJamo(int codeUnit) {
    return codeUnit >= 0x3131 && codeUnit <= 0x314E;
  }

  /// Extract the chosung string from a Hangul syllable code unit.
  static String getChosung(int codeUnit) {
    final index =
        (codeUnit - _hangulBase) ~/ (_jungsungCount * _jongsungCount);
    return chosung[index];
  }

  /// Extract the chosung sequence from [text].
  ///
  /// For Hangul syllables, returns their initial consonant.
  /// For non-Korean characters, returns them as-is.
  ///
  /// Example: '하늘덕후' → 'ㅎㄴㄷㅎ'
  static String extractChosung(String text) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (isHangulSyllable(code)) {
        buffer.write(getChosung(code));
      } else {
        buffer.write(text[i]);
      }
    }
    return buffer.toString();
  }

  /// Whether [query] consists entirely of chosung jamo characters.
  static bool isChosungQuery(String query) {
    if (query.isEmpty) return false;
    for (int i = 0; i < query.length; i++) {
      if (!isChosungJamo(query.codeUnitAt(i))) return false;
    }
    return true;
  }

  /// Match [query] against [target].
  ///
  /// Supports:
  /// - Standard case-insensitive substring matching
  /// - Chosung substring matching when query is all jamo
  ///
  /// Example: matchesKoreanSearch('하늘덕후', 'ㅎㄴ') → true
  static bool matchesKoreanSearch(String target, String query) {
    if (query.isEmpty) return true;
    if (target.isEmpty) return false;

    final lowerTarget = target.toLowerCase();
    final lowerQuery = query.toLowerCase();

    // Standard substring match
    if (lowerTarget.contains(lowerQuery)) return true;

    // Chosung match: if query is entirely chosung jamo
    if (isChosungQuery(query)) {
      final targetChosung = extractChosung(lowerTarget);
      return targetChosung.contains(query);
    }

    return false;
  }
}
