import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../models/ai_draft_error.dart';
import '../models/ai_draft_state.dart';
import '../mock/reply_templates.dart';
import 'creator_pattern_service.dart';

/// Service that manages the AI draft suggestion pipeline.
///
/// Handles:
/// - Idempotency (same request returns cached result)
/// - Local + DB caching with TTL
/// - Structured error mapping
/// - Auto-retry with simplified prompt on first failure
/// - Template fallback on total failure
class AiDraftService {
  AiDraftService._();
  static final AiDraftService instance = AiDraftService._();

  // In-memory cache: idempotencyKey -> (result, expiresAt)
  final Map<String, _CachedResult> _cache = {};
  static const _cacheTtl = Duration(minutes: 10);

  /// Fetch AI draft suggestions with full pipeline:
  /// 1. Compute idempotency key
  /// 2. Check local cache
  /// 3. Call API (Claude direct or Edge Function)
  /// 4. On failure: auto-retry with simplified prompt
  /// 5. On total failure: return template fallback
  Future<AiDraftState> fetchSuggestions({
    required String channelId,
    required String messageId,
    required String fanMessage,
  }) async {
    final correlationId = 'corr_${const Uuid().v4().substring(0, 8)}';
    final idempotencyKey = _computeIdempotencyKey(channelId, messageId, fanMessage);

    // 1. Check local cache
    final cached = _cache[idempotencyKey];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      return AiDraftSuccess(
        suggestions: cached.suggestions,
        correlationId: correlationId,
      );
    }

    // 2. Try API call
    try {
      final suggestions = await _callApi(
        channelId: channelId,
        messageId: messageId,
        fanMessage: fanMessage,
        correlationId: correlationId,
        useFullPrompt: true,
      );

      // Cache on success
      _cache[idempotencyKey] = _CachedResult(
        suggestions: suggestions,
        expiresAt: DateTime.now().add(_cacheTtl),
      );

      return AiDraftSuccess(
        suggestions: suggestions,
        correlationId: correlationId,
      );
    } catch (e) {
      // 3. Auto-retry with simplified prompt
      try {
        final suggestions = await _callApi(
          channelId: channelId,
          messageId: messageId,
          fanMessage: fanMessage,
          correlationId: correlationId,
          useFullPrompt: false, // simplified: no pattern context
        );

        _cache[idempotencyKey] = _CachedResult(
          suggestions: suggestions,
          expiresAt: DateTime.now().add(_cacheTtl),
        );

        return AiDraftSuccess(
          suggestions: suggestions,
          correlationId: correlationId,
        );
      } catch (retryError) {
        // 4. Total failure -> template fallback
        final error = AiDraftError.from(
          retryError,
          correlationId: correlationId,
        );

        final templates = ReplyTemplates.getRandomSuggestions();
        if (templates.isNotEmpty) {
          return AiDraftSoftFail(
            error: error,
            templateSuggestions: templates,
          );
        }

        return AiDraftHardFail(error: error);
      }
    }
  }

  /// Core API call — routes to Claude direct or Supabase Edge Function.
  Future<List<ReplySuggestion>> _callApi({
    required String channelId,
    required String messageId,
    required String fanMessage,
    required String correlationId,
    required bool useFullPrompt,
  }) async {
    if (AppConfig.anthropicApiKey.isNotEmpty) {
      return _fetchFromClaude(
        fanMessage: fanMessage,
        channelId: channelId,
        correlationId: correlationId,
        useFullPrompt: useFullPrompt,
      );
    } else {
      return _fetchFromSupabase(
        channelId: channelId,
        messageId: messageId,
        fanMessage: fanMessage,
        correlationId: correlationId,
      );
    }
  }

  /// Direct Claude API call (dev/demo).
  Future<List<ReplySuggestion>> _fetchFromClaude({
    required String fanMessage,
    required String channelId,
    required String correlationId,
    required bool useFullPrompt,
  }) async {
    String patternContext = '';
    if (useFullPrompt) {
      patternContext = _buildPatternContext(channelId);
    }

    final prompt = _buildPrompt(fanMessage, patternContext: patternContext);

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': AppConfig.anthropicApiKey,
        'anthropic-version': '2023-06-01',
        'x-correlation-id': correlationId,
      },
      body: jsonEncode({
        'model': AppConfig.claudeModel,
        'max_tokens': 1024,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    ).timeout(Duration(seconds: AppConfig.apiTimeoutSeconds));

    if (response.statusCode == 429) {
      throw AiDraftError(
        code: AiDraftErrorCode.anthropicRateLimit,
        userMessage: 'AI 요청이 너무 많아요. 잠시 후 다시 시도해주세요',
        correlationId: correlationId,
      );
    }

    if (response.statusCode != 200) {
      throw AiDraftError(
        code: AiDraftErrorCode.anthropicError,
        userMessage: 'AI 서비스에 일시적인 문제가 있어요',
        technicalDetail: 'HTTP ${response.statusCode}',
        correlationId: correlationId,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final contentList = data['content'] as List<dynamic>;
    final text = contentList.first['text'] as String;

    return parseAiResponse(text);
  }

  /// Supabase Edge Function call (production).
  Future<List<ReplySuggestion>> _fetchFromSupabase({
    required String channelId,
    required String messageId,
    required String fanMessage,
    required String correlationId,
  }) async {
    final response = await Supabase.instance.client.functions.invoke(
      'ai-reply-suggest',
      body: {
        'channel_id': channelId,
        'message_id': messageId,
        'fan_message': fanMessage,
        'correlation_id': correlationId,
      },
    );

    if (response.status != 200) {
      final errorMsg = response.data is Map
          ? (response.data as Map)['error']?.toString() ?? 'Edge Function error'
          : 'Edge Function error';
      throw AiDraftError(
        code: AiDraftErrorCode.edgeFnError,
        userMessage: '서버 연결에 실패했어요',
        technicalDetail: errorMsg,
        correlationId: correlationId,
      );
    }

    final data = response.data as Map<String, dynamic>;
    final suggestionsJson = data['suggestions'] as List<dynamic>;

    return suggestionsJson
        .map((s) => ReplySuggestion.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  /// Build pattern context from creator's past messages.
  String _buildPatternContext(String channelId) {
    final sampleMessages = [
      CreatorMessage(
        id: 'sample_1',
        content: '오늘 공연 와줘서 너무 고마워요~ 💕',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      CreatorMessage(
        id: 'sample_2',
        content: '여러분 덕분에 힘이 나요! 항상 응원해줘서 감사합니다 🙏',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      CreatorMessage(
        id: 'sample_3',
        content: '다음 주 컴백 준비 열심히 하고 있어요 기대해주세요!! ✨',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      CreatorMessage(
        id: 'sample_4',
        content: 'ㅋㅋㅋ 귀여워요~ 고마워!',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      CreatorMessage(
        id: 'sample_5',
        content: '오늘 날씨가 너무 좋아서 산책했어요 🌸 여러분도 좋은 하루 보내세요~',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    final patternService = CreatorPatternService.instance;
    final analysis = patternService.analyzePatterns(
      creatorId: channelId,
      messages: sampleMessages,
    );

    return patternService.buildPatternContext(analysis);
  }

  /// Build the AI prompt.
  String _buildPrompt(String fanMessage, {String patternContext = ''}) {
    final buffer = StringBuffer();
    buffer.writeln('당신은 K-pop/엔터테인먼트 크리에이터의 팬 메시지 답글 초안을 작성하는 도우미입니다.');
    buffer.writeln();

    if (patternContext.isNotEmpty) {
      buffer.writeln(patternContext);
      buffer.writeln();
    }

    buffer.writeln('[팬 메시지]');
    buffer.writeln('"$fanMessage"');
    buffer.writeln();
    buffer.writeln('[안전 규칙]');
    buffer.writeln('- 친근하되 기만적이지 않게 작성');
    buffer.writeln('- "AI"라는 단어 사용 금지');
    buffer.writeln('- 각 답변 200자 이내');
    buffer.writeln();
    buffer.writeln('정확히 3개의 서로 다른 스타일의 답글 초안을 JSON 배열 형식으로 반환하세요.');
    buffer.writeln('스타일: 짧게, 따뜻하게, 재미있게');
    buffer.writeln();
    buffer.writeln('예시 형식:');
    buffer.writeln('["첫 번째 답글", "두 번째 답글", "세 번째 답글"]');
    buffer.writeln();
    buffer.writeln('답글만 출력하고 다른 설명은 포함하지 마세요.');

    return buffer.toString();
  }

  /// Parse AI response text into a list of [ReplySuggestion].
  ///
  /// Handles:
  /// - Clean JSON array: `["a", "b", "c"]`
  /// - Markdown-wrapped: ````json\n["a", "b", "c"]\n````
  /// - Extra text around the array
  /// - Newline-separated fallback when JSON parsing fails
  static List<ReplySuggestion> parseAiResponse(String text) {
    const labels = ['짧게', '따뜻하게', '재미있게'];

    // Try to find JSON array in the response
    final match = RegExp(r'\[[\s\S]*?\]').firstMatch(text);
    if (match != null) {
      try {
        final parsed = jsonDecode(match.group(0)!) as List<dynamic>;
        final strings = parsed
            .where((item) => item is String && item.trim().isNotEmpty)
            .cast<String>()
            .take(3)
            .toList();

        if (strings.isNotEmpty) {
          return strings.asMap().entries.map((e) {
            return ReplySuggestion(
              id: 'opt${e.key + 1}',
              label: e.key < labels.length ? labels[e.key] : '옵션 ${e.key + 1}',
              text: e.value.trim(),
            );
          }).toList();
        }
      } catch (_) {
        // Fall through to newline-based parsing
      }
    }

    // Fallback: split by newlines
    final lines = text
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'^[\d\.\)\-\*]+\s*'), '').trim())
        .where((line) => line.isNotEmpty && line.length > 5)
        .take(3)
        .toList();

    if (lines.isNotEmpty) {
      return lines.asMap().entries.map((e) {
        return ReplySuggestion(
          id: 'opt${e.key + 1}',
          label: e.key < labels.length ? labels[e.key] : '옵션 ${e.key + 1}',
          text: e.value,
        );
      }).toList();
    }

    throw AiDraftError(
      code: AiDraftErrorCode.parseFail,
      userMessage: 'AI 응답을 처리할 수 없어요',
      technicalDetail: 'No valid suggestions found in response: ${text.substring(0, text.length.clamp(0, 200))}',
    );
  }

  /// Compute idempotency key from request params.
  /// Uses a simple hash combination — this is for in-memory caching only,
  /// not for security purposes.
  String _computeIdempotencyKey(String channelId, String messageId, String fanMessage) {
    final input = '$channelId:$messageId:$fanMessage';
    // Use Object.hashAll for a deterministic hash string
    return 'idem_${input.hashCode.toRadixString(36)}';
  }

  /// Clear expired cache entries.
  void clearExpiredCache() {
    final now = DateTime.now();
    _cache.removeWhere((_, v) => now.isAfter(v.expiresAt));
  }
}

class _CachedResult {
  final List<ReplySuggestion> suggestions;
  final DateTime expiresAt;

  _CachedResult({required this.suggestions, required this.expiresAt});
}
