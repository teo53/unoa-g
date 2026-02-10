/// Structured error codes for the AI draft pipeline.
///
/// Each error carries a machine-readable [code], a Korean user-facing
/// [userMessage], and an optional [correlationId] for support tracing.
enum AiDraftErrorCode {
  /// No ANTHROPIC_API_KEY configured and Edge Function unavailable
  noApiKey,

  /// Claude API call timed out
  anthropicTimeout,

  /// Claude API returned 429 (rate limited)
  anthropicRateLimit,

  /// Claude API returned a non-200 status
  anthropicError,

  /// Could not parse JSON array from AI response
  parseFail,

  /// Supabase Edge Function returned an error
  edgeFnError,

  /// Device has no internet connectivity
  networkError,

  /// Catch-all for unexpected failures
  unknown,
}

class AiDraftError {
  final AiDraftErrorCode code;
  final String userMessage;
  final String? technicalDetail;
  final String? correlationId;

  const AiDraftError({
    required this.code,
    required this.userMessage,
    this.technicalDetail,
    this.correlationId,
  });

  /// Map an exception and HTTP status to a structured error.
  factory AiDraftError.from(
    Object error, {
    int? httpStatus,
    String? correlationId,
  }) {
    if (error is AiDraftError) return error;

    final msg = error.toString();

    // Timeout
    if (msg.contains('TimeoutException') || msg.contains('timeout')) {
      return AiDraftError(
        code: AiDraftErrorCode.anthropicTimeout,
        userMessage: 'AI 응답 시간이 초과되었어요',
        technicalDetail: msg,
        correlationId: correlationId,
      );
    }

    // Rate limit
    if (httpStatus == 429 || msg.contains('429')) {
      return AiDraftError(
        code: AiDraftErrorCode.anthropicRateLimit,
        userMessage: 'AI 요청이 너무 많아요. 잠시 후 다시 시도해주세요',
        technicalDetail: msg,
        correlationId: correlationId,
      );
    }

    // Parse failure
    if (msg.contains('파싱') ||
        msg.contains('parse') ||
        msg.contains('FormatException')) {
      return AiDraftError(
        code: AiDraftErrorCode.parseFail,
        userMessage: 'AI 응답을 처리할 수 없어요',
        technicalDetail: msg,
        correlationId: correlationId,
      );
    }

    // Network
    if (msg.contains('SocketException') ||
        msg.contains('network') ||
        msg.contains('연결')) {
      return AiDraftError(
        code: AiDraftErrorCode.networkError,
        userMessage: '인터넷 연결을 확인해주세요',
        technicalDetail: msg,
        correlationId: correlationId,
      );
    }

    // Edge Function
    if (msg.contains('Edge') || msg.contains('functions')) {
      return AiDraftError(
        code: AiDraftErrorCode.edgeFnError,
        userMessage: '서버 연결에 실패했어요',
        technicalDetail: msg,
        correlationId: correlationId,
      );
    }

    // API key missing
    if (msg.contains('API_KEY') || msg.contains('api_key')) {
      return AiDraftError(
        code: AiDraftErrorCode.noApiKey,
        userMessage: 'AI 서비스가 설정되지 않았어요',
        technicalDetail: msg,
        correlationId: correlationId,
      );
    }

    // Anthropic error (non-200)
    if (httpStatus != null && httpStatus >= 400) {
      return AiDraftError(
        code: AiDraftErrorCode.anthropicError,
        userMessage: 'AI 서비스에 일시적인 문제가 있어요',
        technicalDetail: 'HTTP $httpStatus: $msg',
        correlationId: correlationId,
      );
    }

    // Unknown
    return AiDraftError(
      code: AiDraftErrorCode.unknown,
      userMessage: '알 수 없는 오류가 발생했어요',
      technicalDetail: msg,
      correlationId: correlationId,
    );
  }

  @override
  String toString() => 'AiDraftError($code, $userMessage, corr=$correlationId)';
}
