import '../models/ai_draft_state.dart';

/// Pre-written Korean reply templates for fallback when AI is unavailable.
///
/// Organized by category. Each template is a [ReplySuggestion] that can be
/// used directly in the AI reply suggestion sheet.
class ReplyTemplates {
  ReplyTemplates._();

  /// All template categories.
  static const List<String> categories = [
    '감사',
    '응원',
    '일상 인사',
    '일정 안내',
    '짧은 반응',
  ];

  /// All templates organized by category.
  static const Map<String, List<String>> byCategory = {
    '감사': [
      '항상 응원해줘서 정말 고마워요~ 💕',
      '덕분에 힘이 나요! 감사합니다 🙏',
      '이렇게 따뜻한 말 해줘서 감동이에요 🥹',
      '여러분이 있어서 행복해요~ 고마워요!',
    ],
    '응원': [
      '오늘도 화이팅! 항상 좋은 일만 가득하길 바라요 ✨',
      '힘든 일 있어도 금방 좋아질 거예요! 응원할게요 💪',
      '여러분 최고예요~ 항상 응원해요! 🎉',
    ],
    '일상 인사': [
      '오늘 하루도 수고했어요~ 푹 쉬세요! 😴',
      '좋은 아침이에요! 오늘도 좋은 하루 보내세요 ☀️',
      '오늘 날씨가 좋아서 기분도 좋아요~ 🌸',
      '뭐 하고 있어요? 맛있는 거 먹었으면 좋겠다~ 🍕',
    ],
    '일정 안내': [
      '곧 새로운 소식 들고 올게요! 기대해주세요~ 🎵',
      '다음 주에 특별한 걸 준비하고 있어요! 🤫',
      '조만간 만나요! 준비하고 있으니까 기대해주세요 💫',
    ],
    '짧은 반응': [
      '헤헤 고마워요~ 😊',
      '앗 귀여워요!! 🥰',
      'ㅋㅋㅋ 맞아요~ 😄',
      '진짜요?! 너무 좋아요! 💖',
      '우와~ 감동이에요! 😭💕',
      '사랑해요~ ❤️',
    ],
  };

  /// Get 3 random templates as [ReplySuggestion] objects for fallback display.
  static List<ReplySuggestion> getRandomSuggestions() {
    final all = <String>[];
    for (final templates in byCategory.values) {
      all.addAll(templates);
    }
    all.shuffle();

    const labels = ['짧게', '따뜻하게', '재미있게'];
    return all.take(3).toList().asMap().entries.map((e) {
      return ReplySuggestion(
        id: 'tmpl_${e.key + 1}',
        label: labels[e.key],
        text: e.value,
      );
    }).toList();
  }

  /// Get templates filtered by category.
  static List<ReplySuggestion> getByCategoryAsSuggestions(String category) {
    final templates = byCategory[category] ?? [];
    return templates.asMap().entries.map((e) {
      return ReplySuggestion(
        id: 'tmpl_${category}_${e.key}',
        label: category,
        text: e.value,
      );
    }).toList();
  }
}
