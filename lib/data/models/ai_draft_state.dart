import 'ai_draft_error.dart';

/// Reply suggestion model used across the AI draft pipeline.
class ReplySuggestion {
  final String id;
  final String label;
  final String text;

  const ReplySuggestion({
    required this.id,
    required this.label,
    required this.text,
  });

  factory ReplySuggestion.fromJson(Map<String, dynamic> json) {
    return ReplySuggestion(
      id: json['id'] as String,
      label: json['label'] as String,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'text': text,
      };
}

/// Sealed state machine for the AI draft suggestion UX.
///
/// ```
/// idle → generating → success
///                    → softFail (templates available + retry)
///                    → hardFail (manual editor + template library)
/// ```
sealed class AiDraftState {
  const AiDraftState();
}

/// Initial state — nothing happening yet.
class AiDraftIdle extends AiDraftState {
  const AiDraftIdle();
}

/// API call in flight.
class AiDraftGenerating extends AiDraftState {
  final String correlationId;
  const AiDraftGenerating({required this.correlationId});
}

/// AI returned valid suggestions.
class AiDraftSuccess extends AiDraftState {
  final List<ReplySuggestion> suggestions;
  final String correlationId;
  const AiDraftSuccess({
    required this.suggestions,
    required this.correlationId,
  });
}

/// AI failed but fallback templates are available.
/// Shows: "다시 시도" + "템플릿에서 선택"
class AiDraftSoftFail extends AiDraftState {
  final AiDraftError error;
  final List<ReplySuggestion> templateSuggestions;
  const AiDraftSoftFail({
    required this.error,
    required this.templateSuggestions,
  });
}

/// AI failed hard — no templates could be loaded either.
/// Shows: "직접 작성하기" (edit bar always visible) + "템플릿 보기" + "짧은 프롬프트로 시도"
class AiDraftHardFail extends AiDraftState {
  final AiDraftError error;
  const AiDraftHardFail({required this.error});
}
