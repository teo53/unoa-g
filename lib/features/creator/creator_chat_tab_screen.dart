import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_list_provider.dart';
import '../../shared/widgets/message_action_sheet.dart';

/// 크리에이터 채팅 탭 화면
///
/// ## 핵심 구조 (Bubble/Fromm 스타일)
///
/// **탭 1: 내 채널 (단체톡방)**
/// - 크리에이터가 메시지 입력 → 모든 팬에게 전송
/// - 모든 팬의 메시지가 통합 타임라인으로 표시 (단체톡방처럼)
/// - 팬 메시지: 왼쪽 정렬 + 팬 이름/티어 표시
/// - 크리에이터 메시지: 오른쪽 정렬 + "전체 전송됨" 표시
///
/// **탭 2: 구독 아티스트**
/// - 크리에이터가 팬으로서 구독한 다른 아티스트 채팅 리스트
///
/// ⚠️ 브로드캐스트는 별도 기능이 아님 - 채팅 자체가 이 구조임
class CreatorChatTabScreen extends ConsumerStatefulWidget {
  const CreatorChatTabScreen({super.key});

  @override
  ConsumerState<CreatorChatTabScreen> createState() =>
      _CreatorChatTabScreenState();
}

class _CreatorChatTabScreenState extends ConsumerState<CreatorChatTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _heartedMessages = {};
  bool _showAttachPanel = false;
  bool _isQuestionMinimized = false;
  bool _showBroadcastBanner = true;

  // Mock messages - 실제로는 provider에서 가져옴
  final List<_GroupChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMockMessages();
  }

  void _loadMockMessages() {
    final now = DateTime.now();
    _messages.addAll([
      _GroupChatMessage(
        id: '1',
        content: '오늘 컨텐츠 너무 좋았어요!',
        fanId: 'fan_1',
        fanName: '하늘덕후',
        fanTier: 'VIP',
        isFromCreator: false,
        timestamp: now.subtract(const Duration(hours: 2)),
        reactions: {'❤️': ['creator'], '👍': ['fan_2', 'fan_3']},
      ),
      _GroupChatMessage(
        id: '2',
        content: '항상 응원합니다 💕',
        fanId: 'fan_2',
        fanName: '별빛팬',
        fanTier: 'STANDARD',
        isFromCreator: false,
        timestamp: now.subtract(const Duration(hours: 1, minutes: 45)),
      ),
      _GroupChatMessage(
        id: '3',
        content: '고마워요 여러분~ 오늘도 힘내세요!',
        fanId: 'creator',
        fanName: '',
        fanTier: '',
        isFromCreator: true,
        timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
        readCount: 1087,
        totalSubscribers: 1250,
        reactions: {'❤️': ['fan_1', 'fan_2', 'fan_3'], '🎉': ['fan_1']},
      ),
      _GroupChatMessage(
        id: '4',
        content: '내일 라이브 기대돼요!',
        fanId: 'fan_3',
        fanName: '달빛소녀',
        fanTier: 'VIP',
        isFromCreator: false,
        timestamp: now.subtract(const Duration(hours: 1)),
        donationAmount: 1000,
      ),
      _GroupChatMessage(
        id: '5',
        content: '저도 기대돼요 ㅎㅎ',
        fanId: 'fan_1',
        fanName: '하늘덕후',
        fanTier: 'VIP',
        isFromCreator: false,
        timestamp: now.subtract(const Duration(minutes: 45)),
      ),
      _GroupChatMessage(
        id: '6',
        content: '선물 감사합니다! 💖',
        fanId: 'creator',
        fanName: '',
        fanTier: '',
        isFromCreator: true,
        timestamp: now.subtract(const Duration(minutes: 30)),
        readCount: 892,
        totalSubscribers: 1250,
      ),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(_GroupChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: _messageController.text.trim(),
        fanId: 'creator',
        fanName: '',
        fanTier: '',
        isFromCreator: true,
        timestamp: DateTime.now(),
        readCount: 0, // 방금 전송됨 - 아직 아무도 안 읽음
        totalSubscribers: 1250,
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

  void _toggleHeart(String messageId) {
    setState(() {
      if (_heartedMessages.contains(messageId)) {
        _heartedMessages.remove(messageId);
      } else {
        _heartedMessages.add(messageId);
      }
    });
  }

  /// 크리에이터 자신의 메시지 Long Press 시 액션 시트 표시
  void _showCreatorMessageActionSheet(
    BuildContext context,
    _GroupChatMessage message,
    bool isDark,
  ) {
    HapticFeedback.mediumImpact();

    final canEdit = DateTime.now().difference(message.timestamp).inHours < 24;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Message preview
              if (message.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message.content.length > 80
                          ? '${message.content.substring(0, 80)}...'
                          : message.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Emoji reaction row
              _buildEmojiReactionRow(context, message, isDark),

              const SizedBox(height: 8),
              Divider(height: 1, thickness: 0.5, color: isDark ? Colors.grey[800] : Colors.grey[200]),

              // Copy
              _buildActionTile(
                icon: Icons.copy_rounded,
                label: '복사',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('메시지가 복사되었습니다'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),

              // Reply (quote reply to own broadcast)
              _buildActionTile(
                icon: Icons.reply_rounded,
                label: '답장',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _startQuoteReply(message);
                },
              ),

              // Edit (within 24 hours)
              if (canEdit)
                _buildActionTile(
                  icon: Icons.edit_rounded,
                  label: '수정',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    _showCreatorEditDialog(context, message, isDark);
                  },
                ),

              // Forward
              _buildActionTile(
                icon: Icons.forward_rounded,
                label: '전달',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('전달 기능 준비 중입니다'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),

              // Pin as announcement
              _buildActionTile(
                icon: Icons.push_pin_outlined,
                label: '공지 등록',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    final idx = _messages.indexWhere((m) => m.id == message.id);
                    if (idx >= 0) {
                      // Demo mode: show snackbar
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('공지로 등록되었습니다'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),

              // Delete
              _buildActionTile(
                icon: Icons.delete_outline_rounded,
                label: '삭제',
                isDark: isDark,
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, message, isDark);
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Emoji reaction data for action sheets
  static const List<_EmojiReaction> _reactions = [
    _EmojiReaction(icon: Icons.favorite_rounded, color: Color(0xFFFF4B6E), label: '좋아요', emoji: '❤️'),
    _EmojiReaction(icon: Icons.thumb_up_rounded, color: Color(0xFF5B8DEF), label: '최고', emoji: '👍'),
    _EmojiReaction(icon: Icons.celebration_rounded, color: Color(0xFFFFAB40), label: '축하', emoji: '🎉'),
    _EmojiReaction(icon: Icons.sentiment_very_satisfied_rounded, color: Color(0xFFFFCA28), label: '웃겨', emoji: '😂'),
    _EmojiReaction(icon: Icons.auto_awesome_rounded, color: Color(0xFFAB47BC), label: '감동', emoji: '✨'),
    _EmojiReaction(icon: Icons.local_fire_department_rounded, color: Color(0xFFFF7043), label: '불타오르네', emoji: '🔥'),
  ];

  Widget _buildEmojiReactionRow(BuildContext context, _GroupChatMessage message, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _reactions.map((reaction) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              _handleReaction(message.id, reaction.emoji);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: reaction.color.withValues(alpha: isDark ? 0.2 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    reaction.icon,
                    size: 22,
                    color: reaction.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reaction.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _handleReaction(String messageId, String emoji) {
    setState(() {
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex == -1) return;

      final message = _messages[messageIndex];
      final reactions = Map<String, List<String>>.from(
        message.reactions ?? {},
      );

      const userId = 'creator';
      final users = List<String>.from(reactions[emoji] ?? []);

      if (users.contains(userId)) {
        users.remove(userId);
        if (users.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = users;
        }
      } else {
        users.add(userId);
        reactions[emoji] = users;
      }

      message.reactions = reactions.isEmpty ? null : reactions;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$emoji 반응을 보냈습니다'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required bool isDark,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isDestructive
                  ? const Color(0xFFEF4444)
                  : isDark ? Colors.grey[300] : Colors.grey[700],
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDestructive
                    ? const Color(0xFFEF4444)
                    : isDark ? Colors.grey[200] : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    _GroupChatMessage message,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('메시지 삭제'),
        content: const Text('이 메시지를 삭제하시겠습니까?\n모든 팬에게 전송된 메시지가 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '취소',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.removeWhere((m) => m.id == message.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('메시지가 삭제되었습니다'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 인용 답장 시작 (카톡 스타일)
  void _startQuoteReply(_GroupChatMessage message) {
    // 입력창에 포커스를 주고 인용 표시
    _messageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.reply_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '답장: ${message.content.length > 30 ? '${message.content.substring(0, 30)}...' : message.content}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 크리에이터 메시지 수정 다이얼로그
  void _showCreatorEditDialog(
    BuildContext context,
    _GroupChatMessage message,
    bool isDark,
  ) {
    final controller = TextEditingController(text: message.content);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('메시지 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '수정된 메시지는 모든 팬에게 반영됩니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 5,
                minLines: 1,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(
                  hintText: '메시지를 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                '취소',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: controller.text.trim().isEmpty ||
                      controller.text.trim() == message.content
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      setState(() {
                        final idx = _messages.indexWhere((m) => m.id == message.id);
                        if (idx >= 0) {
                          _messages[idx] = _GroupChatMessage(
                            id: message.id,
                            content: controller.text.trim(),
                            fanId: message.fanId,
                            fanName: message.fanName,
                            fanTier: message.fanTier,
                            isFromCreator: message.isFromCreator,
                            timestamp: message.timestamp,
                            readCount: message.readCount,
                            totalSubscribers: message.totalSubscribers,
                            donationAmount: message.donationAmount,
                            isDirectReplyMessage: message.isDirectReplyMessage,
                            replyToFanId: message.replyToFanId,
                            replyToFanName: message.replyToFanName,
                            replyToContent: message.replyToContent,
                            isEdited: true,
                          );
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('메시지가 수정되었습니다'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
              child: const Text('수정'),
            ),
          ],
        ),
      ),
    );
  }

  /// 팬 메시지 Long Press 시 답장 옵션 바텀시트 표시
  void _showReplyOptionsSheet(
    BuildContext context,
    _GroupChatMessage originalMessage,
    bool isDark,
  ) {
    bool isDirectReply = true; // 기본값: 1:1 답장
    final replyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Icon(
                    Icons.reply_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${originalMessage.fanName}님에게 답장',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 원본 메시지 미리보기
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey[800]!.withValues(alpha: 0.5)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                          ),
                          child: Center(
                            child: Text(
                              originalMessage.fanName.isNotEmpty
                                  ? originalMessage.fanName[0]
                                  : '?',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          originalMessage.fanName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSubDark
                                : AppColors.textSubLight,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getTierColorForSheet(originalMessage.fanTier)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            originalMessage.fanTier,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _getTierColorForSheet(originalMessage.fanTier),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      originalMessage.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Emoji quick reactions
              _buildEmojiReactionRow(context, originalMessage, isDark),

              const SizedBox(height: 16),
              Divider(height: 1, thickness: 0.5, color: isDark ? Colors.grey[700] : Colors.grey[200]),
              const SizedBox(height: 16),

              // 답장 타입 선택
              Text(
                '답장 방식',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // 1:1 답장
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => isDirectReply = true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDirectReply
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : (isDark ? Colors.grey[800] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDirectReply
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!),
                            width: isDirectReply ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person,
                              color: isDirectReply
                                  ? AppColors.primary
                                  : (isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '1:1 답장',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDirectReply
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.textMainDark
                                        : AppColors.textMainLight),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '이 팬에게만 보임',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 전체 답장
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => isDirectReply = false),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: !isDirectReply
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : (isDark ? Colors.grey[800] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !isDirectReply
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!),
                            width: !isDirectReply ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.groups,
                              color: !isDirectReply
                                  ? AppColors.primary
                                  : (isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '전체 답장',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: !isDirectReply
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.textMainDark
                                        : AppColors.textMainLight),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '모든 팬에게 보임',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 답장 입력 필드
              TextField(
                controller: replyController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '답장을 입력하세요...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
                style: TextStyle(
                  color: isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 16),

              // 보내기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (replyController.text.trim().isEmpty) return;
                    _sendReply(
                      content: replyController.text.trim(),
                      isDirectReply: isDirectReply,
                      originalMessage: originalMessage,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDirectReply ? Icons.send : Icons.campaign,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isDirectReply ? '1:1 답장 보내기' : '전체 답장 보내기',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 답장 전송
  void _sendReply({
    required String content,
    required bool isDirectReply,
    required _GroupChatMessage originalMessage,
  }) {
    setState(() {
      _messages.add(_GroupChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        fanId: 'creator',
        fanName: '',
        fanTier: '',
        isFromCreator: true,
        timestamp: DateTime.now(),
        readCount: isDirectReply ? 1 : 0, // 1:1이면 1명만
        totalSubscribers: isDirectReply ? 1 : 1250,
        // 답장 관련 정보
        isDirectReplyMessage: isDirectReply,
        replyToFanId: originalMessage.fanId,
        replyToFanName: originalMessage.fanName,
        replyToContent: originalMessage.content,
      ));
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

    // 성공 스낵바
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isDirectReply
              ? '${originalMessage.fanName}님에게 1:1 답장을 보냈습니다'
              : '전체 팬에게 답장을 보냈습니다',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getTierColorForSheet(String tier) {
    switch (tier.toUpperCase()) {
      case 'VIP':
        return Colors.amber[700]!;
      case 'STANDARD':
        return AppColors.primary;
      default:
        return Colors.grey[500]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Header with TabBar
        _buildHeader(context, isDark),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 탭 1: 내 채널 (단체톡방)
              _buildMyChannelTab(isDark),

              // 탭 2: 구독 아티스트
              _buildSubscribedArtistsTab(isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Column(
        children: [
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '채팅',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color:
                        isDark ? AppColors.textMainDark : AppColors.textMainLight,
                  ),
                ),
                IconButton(
                  onPressed: () => context.push('/notifications'),
                  icon: Stack(
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color:
                            isDark ? AppColors.textSubDark : AppColors.textSubLight,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // TabBar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor:
                  isDark ? AppColors.textMutedDark : AppColors.textMuted,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: '내 채널'),
                Tab(text: '구독 아티스트'),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// 탭 1: 내 채널 (단체톡방 형태)
  /// - 모든 팬의 메시지가 통합 타임라인으로 표시
  /// - 크리에이터가 메시지 입력 → 모든 팬에게 전송
  Widget _buildMyChannelTab(bool isDark) {
    return Stack(
      children: [
        Column(
      children: [
        // 채널 정보 바 (닫기 가능)
        if (_showBroadcastBanner)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.campaign_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '여기서 보내는 메시지는 모든 구독자(1,234명)에게 전송됩니다',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() => _showBroadcastBanner = false),
                  child: Icon(Icons.close, size: 16, color: AppColors.primary.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),

        // 오늘의 질문 (확장 상태)
        if (!_isQuestionMinimized)
          _buildTodaysQuestionSection(isDark),

        // 메시지 리스트 (단체톡방 형태)
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyChannelState(isDark)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final prevMessage = index > 0 ? _messages[index - 1] : null;
                    final showDate = _shouldShowDate(message, prevMessage);

                    return Column(
                      children: [
                        if (showDate)
                          _buildDateSeparator(message.timestamp, isDark),
                        _GroupChatBubble(
                          message: message,
                          isDark: isDark,
                          isHearted: _heartedMessages.contains(message.id),
                          onHeartTap: () => _toggleHeart(message.id),
                          onLongPress: message.isFromCreator
                              ? () => _showCreatorMessageActionSheet(
                                    context,
                                    message,
                                    isDark,
                                  )
                              : () => _showReplyOptionsSheet(
                                    context,
                                    message,
                                    isDark,
                                  ),
                          onReaction: (emoji) => _handleReaction(message.id, emoji),
                        ),
                      ],
                    );
                  },
                ),
        ),

        // 메시지 입력 바
        _buildInputBar(isDark),
      ],
        ),

        // 오늘의 질문 플로팅 미니 배너 (최소화 상태)
        if (_isQuestionMinimized)
          Positioned(
            top: _showBroadcastBanner ? 52 : 8,
            right: 12,
            child: GestureDetector(
              onTap: () => setState(() => _isQuestionMinimized = false),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('❓', style: TextStyle(fontSize: 20)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTodaysQuestionSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 아이콘 + 오늘의 질문 + 참여수 + 최소화 버튼
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('💬', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 8),
              Text(
                '오늘의 질문',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '135명 참여',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _isQuestionMinimized = true),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '마음에 드는 질문에 투표해 주세요',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 10),
          // 질문 카드 목록
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuestionCard('오늘 기분을 날씨로 표현하면?', 'Lv.1', '아이스브레이커', isDark),
                const SizedBox(width: 10),
                _buildQuestionCard('지금 마시고 싶은 음료 하나만!', 'Lv.1', '아이스브레이커', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String question, String level, String category, bool isDark) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  level,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                category,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              question,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChannelState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 64,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 메시지가 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '팬들에게 첫 메시지를 보내보세요!',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // + Button (KakaoTalk style)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showAttachPanel = !_showAttachPanel;
                  });
                  if (_showAttachPanel) {
                    FocusScope.of(context).unfocus();
                  }
                },
                child: AnimatedRotation(
                  turns: _showAttachPanel ? 0.125 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _showAttachPanel
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: _showAttachPanel
                          ? AppColors.primary
                          : isDark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),

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
                    onTap: () {
                      if (_showAttachPanel) {
                        setState(() => _showAttachPanel = false);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: '모든 팬에게 메시지 보내기...',
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
                decoration: BoxDecoration(
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

          // Expandable attachment panel (KakaoTalk style)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _showAttachPanel
                ? _buildCreatorAttachPanel(isDark)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorAttachPanel(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachItem(
            icon: Icons.photo_library_rounded,
            label: '앨범',
            color: const Color(0xFF4CAF50),
            isDark: isDark,
            onTap: () {
              setState(() => _showAttachPanel = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('앨범에서 이미지를 선택합니다 (데모)'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildAttachItem(
            icon: Icons.camera_alt_rounded,
            label: '카메라',
            color: const Color(0xFF2196F3),
            isDark: isDark,
            onTap: () {
              setState(() => _showAttachPanel = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('카메라를 실행합니다 (데모)'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildAttachItem(
            icon: Icons.mic_rounded,
            label: '음성메시지',
            color: const Color(0xFFFF9800),
            isDark: isDark,
            onTap: () {
              setState(() => _showAttachPanel = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('음성 메시지 녹음 (데모)'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildAttachItem(
            icon: Icons.poll_rounded,
            label: '투표',
            color: const Color(0xFF9C27B0),
            isDark: isDark,
            onTap: () {
              setState(() => _showAttachPanel = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('팬 투표 만들기 (데모)'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

  bool _shouldShowDate(_GroupChatMessage current, _GroupChatMessage? previous) {
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

  /// 탭 2: 구독 아티스트 (기존 유지)
  Widget _buildSubscribedArtistsTab(bool isDark) {
    final chatThreads = ref.watch(chatThreadsProvider);
    final isLoading = ref.watch(chatListLoadingProvider);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chatThreads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              '구독 중인 아티스트가 없습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '다른 크리에이터를 구독해보세요',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: chatThreads.length,
      itemBuilder: (context, index) {
        final thread = chatThreads[index];
        return _ChatRoomTile(
          artistName: thread.artistName,
          artistImageUrl: thread.avatarUrl,
          lastMessage: thread.lastMessage ?? '',
          lastMessageTime: thread.lastMessageAt ?? DateTime.now(),
          unreadCount: thread.unreadCount,
          isDark: isDark,
          onTap: () => context.push('/chat/${thread.channelId}'),
        );
      },
    );
  }
}

// =============================================================================
// 단체톡방 메시지 버블
// =============================================================================

class _GroupChatBubble extends StatelessWidget {
  final _GroupChatMessage message;
  final bool isDark;
  final bool isHearted;
  final VoidCallback onHeartTap;
  final VoidCallback? onLongPress;
  final Function(String emoji)? onReaction;

  const _GroupChatBubble({
    required this.message,
    required this.isDark,
    required this.isHearted,
    required this.onHeartTap,
    this.onLongPress,
    this.onReaction,
  });

  @override
  Widget build(BuildContext context) {
    // 크리에이터 메시지 (오른쪽, 핑크 버블)
    if (message.isFromCreator) {
      return _buildCreatorBubble();
    }

    // 팬 메시지 (왼쪽, 팬 이름/티어 표시)
    return _buildFanBubble();
  }

  Widget _buildFanBubble() {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
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
                color: _getTierColor(message.fanTier).withValues(alpha: 0.5),
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
                    _TierBadge(tier: message.fanTier),
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
                            Icon(
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
                            ? AppColors.textMutedDark
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),

                // Reactions bar
                if (message.reactions != null && message.reactions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: MessageReactionsBar(
                      reactions: message.reactions,
                      onTapReaction: onReaction,
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

  Widget _buildCreatorBubble() {
    // 읽은 수 계산
    final hasReadStats = message.readCount != null && message.totalSubscribers != null;
    final readCount = message.readCount ?? 0;
    final totalSubscribers = message.totalSubscribers ?? 0;
    final isDirectReply = message.isDirectReplyMessage;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Time + 읽은 수 표시
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
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
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.purple,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (hasReadStats)
                    Text(
                      '$readCount / ${_formatNumber(totalSubscribers)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Text(
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
                    widthFactor: totalSubscribers > 0 ? readCount / totalSubscribers : 0,
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
              if (message.isEdited)
                Text(
                  '(수정됨)',
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
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
                // 답장인 경우 원본 메시지 인용 (1:1 및 전체답장 모두)
                if (message.replyToContent != null) ...[
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
                              isDirectReply ? Icons.reply_rounded : Icons.campaign_rounded,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${message.replyToFanName}님에게 답장',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                            if (!isDirectReply) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '전체공개',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.95),
                                  ),
                                ),
                              ),
                            ],
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

      // Reactions bar (creator bubble)
      if (message.reactions != null && message.reactions!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 8),
          child: MessageReactionsBar(
            reactions: message.reactions,
            onTapReaction: onReaction,
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
// 채팅방 타일 (구독 아티스트용)
// =============================================================================

class _ChatRoomTile extends StatelessWidget {
  final String artistName;
  final String? artistImageUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isDark;
  final VoidCallback onTap;

  const _ChatRoomTile({
    required this.artistName,
    this.artistImageUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isDark,
    required this.onTap,
  });

  String get _formattedTime {
    final now = DateTime.now();
    final diff = now.difference(lastMessageTime);

    if (diff.inDays > 0) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 전';
    }
    return '방금';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: ClipOval(
                child: artistImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: artistImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                        ),
                      )
                    : Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: Icon(
                          Icons.person,
                          size: 28,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          artistName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: unreadCount > 0
                                ? (isDark
                                    ? AppColors.textSubDark
                                    : AppColors.textSubLight)
                                : (isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMuted),
                            fontWeight: unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
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
}

// =============================================================================
// 데이터 모델
// =============================================================================

class _GroupChatMessage {
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
  final bool isEdited; // 수정 여부
  Map<String, List<String>>? reactions; // emoji → [userId, ...]

  _GroupChatMessage({
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
    this.isEdited = false,
    this.reactions,
  });
}

class _EmojiReaction {
  final IconData icon;
  final Color color;
  final String label;
  final String emoji;

  const _EmojiReaction({
    required this.icon,
    required this.color,
    required this.label,
    required this.emoji,
  });
}
