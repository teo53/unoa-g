import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/core/utils/korean_text_utils.dart';

void main() {
  group('KoreanTextUtils', () {
    group('isHangulSyllable', () {
      test('returns true for 가 (first syllable)', () {
        expect(KoreanTextUtils.isHangulSyllable('가'.codeUnitAt(0)), isTrue);
      });

      test('returns true for 힣 (last syllable)', () {
        expect(KoreanTextUtils.isHangulSyllable('힣'.codeUnitAt(0)), isTrue);
      });

      test('returns false for ㄱ (jamo)', () {
        expect(KoreanTextUtils.isHangulSyllable('ㄱ'.codeUnitAt(0)), isFalse);
      });

      test('returns false for ASCII A', () {
        expect(KoreanTextUtils.isHangulSyllable('A'.codeUnitAt(0)), isFalse);
      });
    });

    group('isChosungJamo', () {
      test('returns true for ㄱ', () {
        expect(KoreanTextUtils.isChosungJamo('ㄱ'.codeUnitAt(0)), isTrue);
      });

      test('returns true for ㅎ', () {
        expect(KoreanTextUtils.isChosungJamo('ㅎ'.codeUnitAt(0)), isTrue);
      });

      test('returns false for 가 (syllable)', () {
        expect(KoreanTextUtils.isChosungJamo('가'.codeUnitAt(0)), isFalse);
      });

      test('returns false for A (ASCII)', () {
        expect(KoreanTextUtils.isChosungJamo('A'.codeUnitAt(0)), isFalse);
      });
    });

    group('extractChosung', () {
      test('하늘덕후 -> ㅎㄴㄷㅎ', () {
        expect(KoreanTextUtils.extractChosung('하늘덕후'), 'ㅎㄴㄷㅎ');
      });

      test('별빛팬 -> ㅂㅂㅍ', () {
        expect(KoreanTextUtils.extractChosung('별빛팬'), 'ㅂㅂㅍ');
      });

      test('달빛소녀 -> ㄷㅂㅅㄴ', () {
        expect(KoreanTextUtils.extractChosung('달빛소녀'), 'ㄷㅂㅅㄴ');
      });

      test('응원봇 -> ㅇㅇㅂ', () {
        expect(KoreanTextUtils.extractChosung('응원봇'), 'ㅇㅇㅂ');
      });

      test('mixed Korean and ASCII preserves ASCII', () {
        expect(KoreanTextUtils.extractChosung('팬A'), 'ㅍA');
      });

      test('pure ASCII returns as-is', () {
        expect(KoreanTextUtils.extractChosung('VIP'), 'VIP');
      });

      test('empty string returns empty', () {
        expect(KoreanTextUtils.extractChosung(''), '');
      });
    });

    group('isChosungQuery', () {
      test('returns true for ㅎㄴ', () {
        expect(KoreanTextUtils.isChosungQuery('ㅎㄴ'), isTrue);
      });

      test('returns true for single ㄱ', () {
        expect(KoreanTextUtils.isChosungQuery('ㄱ'), isTrue);
      });

      test('returns false for 하늘 (full syllables)', () {
        expect(KoreanTextUtils.isChosungQuery('하늘'), isFalse);
      });

      test('returns false for empty string', () {
        expect(KoreanTextUtils.isChosungQuery(''), isFalse);
      });

      test('returns false for mixed ㅎ늘', () {
        expect(KoreanTextUtils.isChosungQuery('ㅎ늘'), isFalse);
      });

      test('returns false for ASCII', () {
        expect(KoreanTextUtils.isChosungQuery('abc'), isFalse);
      });
    });

    group('matchesKoreanSearch', () {
      test('matches standard substring', () {
        expect(KoreanTextUtils.matchesKoreanSearch('하늘덕후', '하늘'), isTrue);
      });

      test('matches chosung ㅎㄴ against 하늘덕후', () {
        expect(KoreanTextUtils.matchesKoreanSearch('하늘덕후', 'ㅎㄴ'), isTrue);
      });

      test('matches full chosung ㅎㄴㄷㅎ against 하늘덕후', () {
        expect(KoreanTextUtils.matchesKoreanSearch('하늘덕후', 'ㅎㄴㄷㅎ'), isTrue);
      });

      test('matches partial chosung ㄷㅎ at end of 하늘덕후', () {
        expect(KoreanTextUtils.matchesKoreanSearch('하늘덕후', 'ㄷㅎ'), isTrue);
      });

      test('does not match wrong chosung ㅎㅂ against 하늘덕후', () {
        expect(KoreanTextUtils.matchesKoreanSearch('하늘덕후', 'ㅎㅂ'), isFalse);
      });

      test('empty query matches everything', () {
        expect(KoreanTextUtils.matchesKoreanSearch('아무이름', ''), isTrue);
      });

      test('empty target does not match non-empty query', () {
        expect(KoreanTextUtils.matchesKoreanSearch('', 'ㅎ'), isFalse);
      });

      test('matches 별빛팬 with ㅂㅂ', () {
        expect(KoreanTextUtils.matchesKoreanSearch('별빛팬', 'ㅂㅂ'), isTrue);
      });

      test('matches 응원봇 with ㅇㅇ', () {
        expect(KoreanTextUtils.matchesKoreanSearch('응원봇', 'ㅇㅇ'), isTrue);
      });

      test('case insensitive for ASCII portions', () {
        expect(KoreanTextUtils.matchesKoreanSearch('VIP팬', 'vip'), isTrue);
      });
    });
  });
}
