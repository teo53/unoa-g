import '../models/reply_quota.dart';
import '../../core/utils/app_logger.dart';

/// Result type for chat operations
class ChatSendResult {
  final bool success;
  final String? errorCode;
  final String? errorMessage;
  final String? messageId;

  const ChatSendResult._({
    required this.success,
    this.errorCode,
    this.errorMessage,
    this.messageId,
  });

  factory ChatSendResult.success(String messageId) => ChatSendResult._(
        success: true,
        messageId: messageId,
      );

  factory ChatSendResult.error(String code, String message) => ChatSendResult._(
        success: false,
        errorCode: code,
        errorMessage: message,
      );

  // Common error factories
  static ChatSendResult quotaExceeded() =>
      ChatSendResult.error('QUOTA_EXCEEDED', '일일 답장 횟수를 초과했습니다.');

  static ChatSendResult characterLimitExceeded(int limit) =>
      ChatSendResult.error('CHARACTER_LIMIT', '메시지는 $limit자를 초과할 수 없습니다.');

  static ChatSendResult subscriptionExpired() =>
      ChatSendResult.error('SUBSCRIPTION_EXPIRED', '구독이 만료되었습니다.');

  static ChatSendResult networkError() =>
      ChatSendResult.error('NETWORK_ERROR', '네트워크 오류가 발생했습니다.');

  static ChatSendResult unauthorized() =>
      ChatSendResult.error('UNAUTHORIZED', '로그인이 필요합니다.');
}

/// Chat service for handling chat business logic
///
/// Separates business rules (quota checking, character limits) from
/// data access (repository) and state management (provider).
class ChatService {
  // Note: Repository dependency can be added when IChatRepository is implemented
  // final IChatRepository _repository;
  // ChatService(this._repository);

  ChatService();

  /// Check if user can send a reply based on quota and subscription
  bool canSendReply(ReplyQuota? quota) {
    if (quota == null) return false;
    return quota.canReply;
  }

  /// Get character limit based on subscription days
  int getCharacterLimit(int daysSubscribed) {
    // F-P1-2: Bounds validation
    if (daysSubscribed < 0) {
      AppLogger.warning(
        'Invalid daysSubscribed: $daysSubscribed (negative). Returning base limit.',
        tag: 'ChatService',
      );
      return 50; // Base limit
    }

    if (daysSubscribed > 3650) {
      AppLogger.warning(
        'daysSubscribed out of bounds: $daysSubscribed (>10 years). Clamping to 3650.',
        tag: 'ChatService',
      );
      return ReplyQuota.getCharacterLimitForDays(3650);
    }

    return ReplyQuota.getCharacterLimitForDays(daysSubscribed);
  }

  /// Validate message content before sending
  ChatSendResult? validateMessage({
    required String content,
    required int characterLimit,
    required ReplyQuota? quota,
    required bool isSubscriptionActive,
  }) {
    // Check subscription
    if (!isSubscriptionActive) {
      return ChatSendResult.subscriptionExpired();
    }

    // Check quota
    if (quota == null || !quota.canReply) {
      return ChatSendResult.quotaExceeded();
    }

    // Check character limit
    if (content.length > characterLimit) {
      return ChatSendResult.characterLimitExceeded(characterLimit);
    }

    // Validation passed
    return null;
  }

  /// Validate donation message (bypass quota but has own character limit)
  ChatSendResult? validateDonationMessage({
    required String content,
    required int maxLength,
  }) {
    // Donation messages have their own character limit (typically 100)
    if (content.length > maxLength) {
      return ChatSendResult.characterLimitExceeded(maxLength);
    }

    return null;
  }

  /// Calculate spam score for message
  /// Returns 0-100, higher = more likely spam
  int calculateSpamScore(String content) {
    int score = 0;

    // Too many repeated characters
    final repeatedChars = RegExp(r'(.)\1{4,}');
    if (repeatedChars.hasMatch(content)) score += 30;

    // All caps
    if (content == content.toUpperCase() && content.length > 5) score += 20;

    // Too many URLs
    final urls = RegExp(r'https?://');
    if (urls.allMatches(content).length > 2) score += 25;

    // Too many emojis
    final emojis = RegExp(
        r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}]',
        unicode: true);
    if (emojis.allMatches(content).length > content.length / 3) score += 15;

    return score.clamp(0, 100);
  }

  /// Check if message should be blocked as spam
  bool isSpam(String content, {int threshold = 70}) {
    return calculateSpamScore(content) >= threshold;
  }

  /// Format message for display (sanitize, trim whitespace)
  String formatMessageContent(String content) {
    // Trim whitespace
    String formatted = content.trim();

    // Normalize multiple newlines
    formatted = formatted.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Normalize multiple spaces
    formatted = formatted.replaceAll(RegExp(r' {2,}'), ' ');

    return formatted;
  }
}

/// Character limit tiers based on subscription duration
class CharacterLimitTier {
  final int days;
  final int limit;
  final String description;

  const CharacterLimitTier({
    required this.days,
    required this.limit,
    required this.description,
  });

  static const List<CharacterLimitTier> tiers = [
    CharacterLimitTier(days: 1, limit: 50, description: '신규 구독자'),
    CharacterLimitTier(days: 3, limit: 100, description: '3일 이상'),
    CharacterLimitTier(days: 7, limit: 150, description: '1주일 이상'),
    CharacterLimitTier(days: 30, limit: 200, description: '1개월 이상'),
  ];

  static CharacterLimitTier getTierForDays(int days) {
    for (final tier in tiers.reversed) {
      if (days >= tier.days) return tier;
    }
    return tiers.first;
  }
}
