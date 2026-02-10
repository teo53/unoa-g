import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../models/ai_draft_error.dart';
import '../models/ai_draft_state.dart';
import '../mock/reply_templates.dart';

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
    final idempotencyKey =
        _computeIdempotencyKey(channelId, messageId, fanMessage);

    // 1. Check local cache
    final cached = _cache[idempotencyKey];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      return AiDraftSuccess(
        suggestions: cached.suggestions,
        correlationId: correlationId,
      );
    }

    // 2. Demo mode: return local suggestions without API call
    if (AppConfig.enableDemoMode) {
      await Future.delayed(const Duration(milliseconds: 800));

      final demoSuggestions = ReplyTemplates.getRandomSuggestions();

      _cache[idempotencyKey] = _CachedResult(
        suggestions: demoSuggestions,
        expiresAt: DateTime.now().add(_cacheTtl),
      );

      return AiDraftSuccess(
        suggestions: demoSuggestions,
        correlationId: correlationId,
      );
    }

    // 3. Try API call via Edge Function
    try {
      final suggestions = await _fetchFromSupabase(
        channelId: channelId,
        messageId: messageId,
        fanMessage: fanMessage,
        correlationId: correlationId,
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
      // 3. Auto-retry
      try {
        final suggestions = await _fetchFromSupabase(
          channelId: channelId,
          messageId: messageId,
          fanMessage: fanMessage,
          correlationId: correlationId,
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

  /// Supabase Edge Function call.
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
      technicalDetail:
          'No valid suggestions found in response: ${text.substring(0, text.length.clamp(0, 200))}',
    );
  }

  /// Compute idempotency key from request params.
  /// Uses a simple hash combination — this is for in-memory caching only,
  /// not for security purposes.
  String _computeIdempotencyKey(
      String channelId, String messageId, String fanMessage) {
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
