import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/poll_draft.dart';
import '../../../data/models/poll_message.dart';
import '../../chat/widgets/poll_message_card.dart';

// =============================================================================
// 단체톡방 메시지 버블
// =============================================================================

class GroupChatBubble extends StatelessWidget {
  final GroupChatMessage message;
  final bool isDark;
  final bool isHearted;
  final VoidCallback onHeartTap;
  final VoidCallback? onLongPress;
  final void Function(String fanId)? onAvatarTap;

  const GroupChatBubble({
    super.key,
    required this.message,
    required this.isDark,
    required this.isHearted,
    required this.onHeartTap,
    this.onLongPress,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    // Poll 메시지 (전체 너비, 카드 스타일)
    if (message.messageType == 'poll' && message.pollData != null) {
      return _buildPollBubble();
    }

    // 크리에이터 메시지 (오른쪽, 핑크 버블)
    if (message.isFromCreator) {
      return _buildCreatorBubble();
    }

    // 팬 메시지 (왼쪽, 팬 이름/티어 표시)
    return _buildFanBubble();
  }

  Widget _buildPollBubble() {
    final draft = message.pollData!;
    final pollMessage = PollMessage(
      id: message.id,
      messageId: message.id,
      question: draft.question,
      options: draft.options,
      createdAt: message.timestamp,
      endsAt: message.timestamp.add(const Duration(hours: 24)),
      showResultsBeforeEnd: true,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PollMessageCard(
        poll: pollMessage,
        isDark: isDark,
        isCreator: true,
      ),
    );
  }

  Widget _buildFanBubble() {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar (탭 → 팬 프로필 바텀시트)
            GestureDetector(
              onTap: onAvatarTap != null
                  ? () => onAvatarTap!(message.fanId)
                  : null,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  border: Border.all(
                    color:
                        _getTierColor(message.fanTier).withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    message.fanName.isNotEmpty ? message.fanName[0] : '?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Bubble content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fan name + tier + donation badge
                  Row(
                    children: [
                      Text(
                        message.fanName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      TierBadge(tier: message.fanTier),
                      if (message.donationAmount != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.pink.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.diamond_rounded,
                                size: 10,
                                color: Colors.pink,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${message.donationAmount}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.pink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Message bubble with heart button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Bubble
                      Flexible(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 240),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.surfaceLight,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(18),
                              bottomLeft: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                            ),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Text(
                            message.content,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: isDark
                                  ? AppColors.textMainDark
                                  : AppColors.textMainLight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Heart button
                      GestureDetector(
                        onTap: onHeartTap,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isHearted
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isHearted ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isHearted
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[400]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Time
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatorBubble() {
    // 삭제된 메시지
    if (message.isDeleted) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 240),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.block,
                      size: 16,
                      color: isDark ? Colors.grey[500] : Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    '삭제된 메시지입니다',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 읽은 수 계산
    final hasReadStats =
        message.readCount != null && message.totalSubscribers != null;
    final readCount = message.readCount ?? 0;
    final totalSubscribers = message.totalSubscribers ?? 0;
    final isDirectReply = message.isDirectReplyMessage;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Time + 읽은 수 표시
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 편집됨 표시
                if (message.isEdited)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '편집됨',
                      style: TextStyle(
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                // 1:1 답장 표시 또는 읽은 팬 수 표시
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDirectReply ? Icons.person : Icons.done_all,
                      size: 14,
                      color: isDirectReply ? Colors.purple : AppColors.primary,
                    ),
                    const SizedBox(width: 3),
                    if (isDirectReply)
                      Text(
                        '→ ${message.replyToFanName}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.purple,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (hasReadStats)
                      Text(
                        '$readCount / ${_formatNumber(totalSubscribers)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      const Text(
                        '전체',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                if (hasReadStats && !isDirectReply) ...[
                  const SizedBox(height: 2),
                  // 퍼센티지 바
                  Container(
                    width: 50,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: totalSubscribers > 0
                          ? readCount / totalSubscribers
                          : 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isDark ? AppColors.textMutedDark : AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),

            // Bubble (1:1 답장은 보라색, 일반은 핑크/빨강)
            Container(
              constraints: const BoxConstraints(maxWidth: 240),
              decoration: BoxDecoration(
                color: isDirectReply ? Colors.purple : AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 메시지 타입 배지 (1:1 답장 / 전체 / 티어 제한)
                  Container(
                    margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDirectReply
                              ? Icons.person
                              : message.minTierRequired != null
                                  ? Icons.lock_outlined
                                  : Icons.campaign_outlined,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isDirectReply
                              ? '1:1 답장'
                              : message.minTierRequired != null
                                  ? '${message.minTierRequired}+'
                                  : '전체',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 1:1 답장인 경우 원본 메시지 인용
                  if (isDirectReply && message.replyToContent != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.reply_rounded,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${message.replyToFanName}님에게 답장',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message.replyToContent!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // 답장 내용
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                      child: Text(
                        message.content,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ] else
                    // 일반 메시지
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Text(
                        message.content,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? '오후' : '오전';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period $hour:$minute';
  }

  Color _getTierColor(String tier) {
    switch (tier.toUpperCase()) {
      case 'VIP':
        return Colors.amber[700]!;
      case 'STANDARD':
        return AppColors.primary;
      default:
        return Colors.grey[500]!;
    }
  }
}

// =============================================================================
// 티어 뱃지
// =============================================================================

class TierBadge extends StatelessWidget {
  final String tier;

  const TierBadge({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (tier.toUpperCase()) {
      case 'VIP':
        bgColor = Colors.amber[100]!;
        textColor = Colors.amber[800]!;
        break;
      case 'STANDARD':
        bgColor = AppColors.primary.withValues(alpha: 0.15);
        textColor = AppColors.primary;
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[600]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        tier.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

// =============================================================================
// 데이터 모델
// =============================================================================

class GroupChatMessage {
  final String id;
  final String content;
  final String fanId;
  final String fanName;
  final String fanTier;
  final bool isFromCreator;
  final DateTime timestamp;
  final int? donationAmount;
  final int? readCount; // 읽은 팬 수
  final int? totalSubscribers; // 전체 구독자 수
  // 답장 관련 필드
  final bool isDirectReplyMessage; // 1:1 답장인지 여부
  final String? replyToFanId; // 답장 대상 팬 ID
  final String? replyToFanName; // 답장 대상 팬 이름
  final String? replyToContent; // 원본 메시지 내용
  // 메시지 타입 (text, poll, image 등)
  final String messageType;
  // Poll 데이터 (messageType == 'poll'일 때)
  final PollDraft? pollData;
  // 편집/삭제 상태
  final bool isEdited;
  final bool isDeleted;
  // 티어별 접근제어
  final String? minTierRequired;

  GroupChatMessage({
    required this.id,
    required this.content,
    required this.fanId,
    required this.fanName,
    required this.fanTier,
    required this.isFromCreator,
    required this.timestamp,
    this.donationAmount,
    this.readCount,
    this.totalSubscribers,
    this.isDirectReplyMessage = false,
    this.replyToFanId,
    this.replyToFanName,
    this.replyToContent,
    this.messageType = 'text',
    this.pollData,
    this.isEdited = false,
    this.isDeleted = false,
    this.minTierRequired,
  });

  /// P0-4: Factory to create GroupChatMessage from Supabase RPC result (get_artist_inbox)
  factory GroupChatMessage.fromJson(Map<String, dynamic> json) {
    final deliveryScope = json['delivery_scope'] as String? ?? 'broadcast';
    final senderType = json['sender_type'] as String? ?? 'fan';
    final isCreator = senderType == 'artist';

    return GroupChatMessage(
      id: (json['id'] ?? json['message_id'] ?? '').toString(),
      content: json['content'] as String? ?? '',
      fanId: json['sender_id'] as String? ?? '',
      fanName: json['sender_name'] as String? ?? '',
      fanTier: json['sender_tier'] as String? ?? '',
      isFromCreator: isCreator,
      timestamp: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      donationAmount: json['donation_amount'] as int?,
      readCount: json['read_count'] as int?,
      totalSubscribers: json['total_subscribers'] as int?,
      isDirectReplyMessage: deliveryScope == 'donation_reply',
      replyToFanId: json['target_user_id'] as String?,
      replyToFanName: json['target_user_name'] as String?,
      replyToContent: json['reply_to_content'] as String?,
      messageType: json['message_type'] as String? ?? 'text',
      isEdited: json['is_edited'] as bool? ?? false,
      isDeleted: json['deleted_at'] != null,
    );
  }

  GroupChatMessage copyWith({
    String? content,
    bool? isEdited,
    bool? isDeleted,
  }) {
    return GroupChatMessage(
      id: id,
      content: content ?? this.content,
      fanId: fanId,
      fanName: fanName,
      fanTier: fanTier,
      isFromCreator: isFromCreator,
      timestamp: timestamp,
      donationAmount: donationAmount,
      readCount: readCount,
      totalSubscribers: totalSubscribers,
      isDirectReplyMessage: isDirectReplyMessage,
      replyToFanId: replyToFanId,
      replyToFanName: replyToFanName,
      replyToContent: replyToContent,
      messageType: messageType,
      pollData: pollData,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      minTierRequired: minTierRequired,
    );
  }
}
