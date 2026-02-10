import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';

/// Creator DM Screen - Bubble-style unified chat view for creators
/// Shows all fan messages in a single timeline with heart reaction buttons
class CreatorDMScreen extends ConsumerStatefulWidget {
  const CreatorDMScreen({super.key});

  @override
  ConsumerState<CreatorDMScreen> createState() => _CreatorDMScreenState();
}

class _CreatorDMScreenState extends ConsumerState<CreatorDMScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedFanId = 'all'; // 'all' for unified view, or specific fan id

  // Track which messages have been hearted
  final Set<String> _heartedMessages = {};

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleHeart(String messageId) {
    setState(() {
      if (_heartedMessages.contains(messageId)) {
        _heartedMessages.remove(messageId);
      } else {
        _heartedMessages.add(messageId);
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _allMessages.add(_ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: _messageController.text.trim(),
        fanId: _selectedFanId == 'all' ? 'fan_1' : _selectedFanId,
        fanName: _selectedFanId == 'all' ? '김민지' : _getFanName(_selectedFanId),
        fanTier: 'VIP',
        isFromCreator: true,
        timestamp: DateTime.now(),
        isRead: false,
      ));
      _messageController.clear();
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getFanName(String fanId) {
    final fan = _mockFans.firstWhere(
      (f) => f.id == fanId,
      orElse: () => _mockFans.first,
    );
    return fan.name;
  }

  List<_ChatMessage> get _filteredMessages {
    if (_selectedFanId == 'all') {
      return _allMessages;
    }
    return _allMessages.where((m) => m.fanId == _selectedFanId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Header with fan selector
        _buildHeader(context, isDark),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _filteredMessages.length,
            itemBuilder: (context, index) {
              final message = _filteredMessages[index];
              final prevMessage = index > 0 ? _filteredMessages[index - 1] : null;
              final showDate = _shouldShowDate(message, prevMessage);

              return Column(
                children: [
                  if (showDate) _buildDateSeparator(message.timestamp, isDark),
                  _MessageBubble(
                    message: message,
                    isDark: isDark,
                    isHearted: _heartedMessages.contains(message.id),
                    onHeartTap: () => _toggleHeart(message.id),
                    showFanInfo: _selectedFanId == 'all',
                  ),
                ],
              );
            },
          ),
        ),

        // Input
        _buildInput(context, isDark),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    // Get selected fan info
    final selectedFan = _selectedFanId == 'all'
        ? null
        : _mockFans.firstWhere(
            (f) => f.id == _selectedFanId,
            orElse: () => _mockFans.first,
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button (if specific fan selected)
          if (_selectedFanId != 'all')
            IconButton(
              onPressed: () => setState(() => _selectedFanId = 'all'),
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),

          // Fan avatar/info or all chats
          if (_selectedFanId == 'all') ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.forum_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '전체 채팅',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                Text(
                  '${_mockFans.length}명의 팬',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getTierColor(selectedFan!.tier).withValues(alpha: 0.15),
                border: Border.all(
                  color: _getTierColor(selectedFan.tier),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  selectedFan.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getTierColor(selectedFan.tier),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        selectedFan.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _TierBadge(tier: selectedFan.tier),
                    ],
                  ),
                  Text(
                    '${selectedFan.subscribeDays}일째 구독 중',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),

          // DT balance indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.diamond_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '0',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    String text;
    if (messageDate == today) {
      text = '오늘';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      text = '어제';
    } else {
      text = '${date.month}월 ${date.day}일';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        12,
        12,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply token info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '3/3',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '+1 대기',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '0/50',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Image picker
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              // Heart reaction (quick react to latest fan message)
              IconButton(
                onPressed: () {
                  // Find latest fan message and heart it
                  final latestFanMessage = _filteredMessages.lastWhere(
                    (m) => !m.isFromCreator,
                    orElse: () => _filteredMessages.first,
                  );
                  _toggleHeart(latestFanMessage.id);
                },
                icon: const Icon(
                  Icons.favorite_border,
                  color: AppColors.primary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              const SizedBox(width: 8),
              // Input field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send button
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _shouldShowDate(_ChatMessage current, _ChatMessage? previous) {
    if (previous == null) return true;
    final currentDate = DateTime(
      current.timestamp.year,
      current.timestamp.month,
      current.timestamp.day,
    );
    final prevDate = DateTime(
      previous.timestamp.year,
      previous.timestamp.month,
      previous.timestamp.day,
    );
    return currentDate != prevDate;
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
// MESSAGE BUBBLE - Bubble style with heart button
// =============================================================================

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isDark;
  final bool isHearted;
  final VoidCallback onHeartTap;
  final bool showFanInfo;

  const _MessageBubble({
    required this.message,
    required this.isDark,
    required this.isHearted,
    required this.onHeartTap,
    this.showFanInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    // Creator message (right side, pink bubble)
    if (message.isFromCreator) {
      return _buildCreatorBubble();
    }

    // Fan message (left side with heart button)
    return _buildFanBubble();
  }

  Widget _buildFanBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
              size: 18,
            ),
          ),
          const SizedBox(width: 10),

          // Bubble content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fan name
                if (showFanInfo)
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
                const SizedBox(height: 6),

                // Message bubble with heart button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Bubble
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 220),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.bubbleArtistDark
                              : AppColors.bubbleArtistLight,
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
                            width: 1,
                          ),
                        ),
                        child: Text(
                          message.content,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Heart button - always visible for easy reaction
                    GestureDetector(
                      onTap: onHeartTap,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isHearted
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isHearted ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isHearted
                              ? AppColors.primary
                              : (isDark ? Colors.grey[600] : Colors.grey[400]),
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
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Time and read status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.isRead)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.done_all,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              const SizedBox(height: 2),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.textSubDark
                      : AppColors.textSubLight,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),

          // Bubble - Bubble style pink/red
          Container(
            constraints: const BoxConstraints(maxWidth: 240),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? '오후' : '오전';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period $hour:$minute';
  }
}

// =============================================================================
// TIER BADGE
// =============================================================================

class _TierBadge extends StatelessWidget {
  final String tier;

  const _TierBadge({required this.tier});

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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        tier.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

// =============================================================================
// DATA MODELS & MOCK DATA
// =============================================================================

class _ChatMessage {
  final String id;
  final String content;
  final String fanId;
  final String fanName;
  final String fanTier;
  final bool isFromCreator;
  final DateTime timestamp;
  final bool isRead;

  _ChatMessage({
    required this.id,
    required this.content,
    required this.fanId,
    required this.fanName,
    required this.fanTier,
    required this.isFromCreator,
    required this.timestamp,
    this.isRead = true,
  });
}

class _FanInfo {
  final String id;
  final String name;
  final String tier;
  final int subscribeDays;
  final int totalDonation;

  const _FanInfo({
    required this.id,
    required this.name,
    required this.tier,
    required this.subscribeDays,
    required this.totalDonation,
  });
}

final _mockFans = [
  const _FanInfo(
    id: 'fan_1',
    name: '김민지',
    tier: 'VIP',
    subscribeDays: 200,
    totalDonation: 15000,
  ),
  const _FanInfo(
    id: 'fan_2',
    name: '별빛팬',
    tier: 'STANDARD',
    subscribeDays: 45,
    totalDonation: 2000,
  ),
  const _FanInfo(
    id: 'fan_3',
    name: '팬클럽회장',
    tier: 'VIP',
    subscribeDays: 365,
    totalDonation: 50000,
  ),
];

// All messages from all fans in timeline order
final _allMessages = <_ChatMessage>[
  // 1월 29일
  _ChatMessage(
    id: '1',
    content: '안녕하세요! 김민지입니다. 제 채팅방에 오신 것을 환영해요! 💕',
    fanId: 'fan_1',
    fanName: '김민지',
    fanTier: 'VIP',
    isFromCreator: false,
    timestamp: DateTime(2025, 1, 29, 0, 40),
  ),
  _ChatMessage(
    id: '2',
    content: '환영해주셔서 감사합니다! 항상 응원해요!',
    fanId: 'fan_1',
    fanName: '김민지',
    fanTier: 'VIP',
    isFromCreator: true,
    timestamp: DateTime(2025, 1, 29, 12, 40),
    isRead: true,
  ),
  // 2월 2일
  _ChatMessage(
    id: '3',
    content: '오늘 하루도 모두 화이팅! 행복한 하루 보내세요 ☀️',
    fanId: 'fan_1',
    fanName: '김민지',
    fanTier: 'VIP',
    isFromCreator: false,
    timestamp: DateTime(2025, 2, 2, 0, 40),
  ),
  // 오늘
  _ChatMessage(
    id: '4',
    content: '오늘 공연 와줘서 너무 고마워요!',
    fanId: 'fan_1',
    fanName: '김민지',
    fanTier: 'VIP',
    isFromCreator: false,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
  ),
];
