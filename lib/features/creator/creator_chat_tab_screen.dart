import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
import '../../core/config/demo_config.dart';
import '../../providers/chat_list_provider.dart';
import '../private_card/widgets/private_card_list_view.dart';
import '../chat/widgets/chat_search_bar.dart';
import '../chat/widgets/media_gallery_sheet.dart';
import '../chat/widgets/daily_question_cards_panel.dart';
import 'widgets/poll_suggestion_sheet.dart';
import '../../data/models/poll_draft.dart';
import 'widgets/group_chat_bubble.dart';
import 'widgets/chat_room_tile.dart';

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
/// **탭 2: 프라이빗 카드**
/// - 프라이빗 카드 발송 내역 + 즐겨찾기 팬 + 새 카드 작성
///
/// **탭 3: 구독**
/// - 크리에이터가 팬으로서 구독한 다른 아티스트 채팅 리스트
///
/// ⚠️ 브로드캐스트는 별도 기능이 아님 - 채팅 자체가 이 구조임
class CreatorChatTabScreen extends ConsumerStatefulWidget {
  final String? prefillText;
  final PollDraft? pollDraft;
  final String? pollComment;

  const CreatorChatTabScreen({
    super.key,
    this.prefillText,
    this.pollDraft,
    this.pollComment,
  });

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

  // 배너 닫기 상태
  bool _isBannerDismissed = false;

  // 검색 상태
  bool _isSearchActive = false;
  List<int> _searchMatchIndices = [];
  int _currentSearchMatchIndex = -1;

  // 미디어 메뉴 상태
  bool _isMediaMenuOpen = false;

  // 답장 상태
  GroupChatMessage? _replyingTo;
  bool _isReplyDirect = true;

  // Mock messages - 실제로는 provider에서 가져옴
  final List<GroupChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMockMessages();
    // AI 답글 시트에서 전달받은 텍스트가 있으면 입력창에 세팅
    if (widget.prefillText != null && widget.prefillText!.isNotEmpty) {
      _messageController.text = widget.prefillText!;
    }
    // 대시보드에서 전달받은 투표가 있으면 채팅에 추가
    if (widget.pollDraft != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addPollFromExternal(widget.pollDraft!, widget.pollComment);
      });
    }
  }

  void _loadMockMessages() {
    final now = DateTime.now();
    _messages.addAll([
      GroupChatMessage(
        id: '1',
        content: '오늘 컨텐츠 너무 좋았어요!',
        fanId: 'fan_1',
        fanName: '하늘덕후',
        fanTier: 'VIP',
        isFromCreator: false,
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      GroupChatMessage(
        id: '2',
        content: '항상 응원합니다 💕',
        fanId: 'fan_2',
        fanName: '별빛팬',
        fanTier: 'STANDARD',
        isFromCreator: false,
        timestamp: now.subtract(const Duration(hours: 1, minutes: 45)),
      ),
      GroupChatMessage(
        id: '3',
        content: '고마워요 여러분~ 오늘도 힘내세요!',
        fanId: 'creator',
        fanName: '',
        fanTier: '',
        isFromCreator: true,
        timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
        readCount: 1087,
        totalSubscribers: DemoConfig.demoSubscriberCount,
      ),
      GroupChatMessage(
        id: '4',
        content: '내일 라이브 기대돼요!',
        fanId: 'fan_3',
        fanName: '달빛소녀',
        fanTier: 'VIP',
        isFromCreator: false,
        timestamp: now.subtract(const Duration(hours: 1)),
        donationAmount: 1000,
      ),
      // 1:1 답장 예시
      GroupChatMessage(
        id: '4b',
        content: '달빛아 감사해요~ 내일 꼭 와주세요!',
        fanId: 'creator',
        fanName: '',
        fanTier: '',
        isFromCreator: true,
        timestamp: now.subtract(const Duration(minutes: 55)),
        readCount: 1,
        totalSubscribers: 1,
        isDirectReplyMessage: true,
        replyToFanId: 'fan_3',
        replyToFanName: '달빛소녀',
        replyToContent: '내일 라이브 기대돼요!',
      ),
      GroupChatMessage(
        id: '5',
        content: '저도 기대돼요 ㅎㅎ',
        fanId: 'fan_1',
        fanName: '하늘덕후',
        fanTier: 'VIP',
        isFromCreator: false,
        timestamp: now.subtract(const Duration(minutes: 45)),
      ),
      // 전체 답장 예시
      GroupChatMessage(
        id: '6',
        content: '여러분 내일 라이브 7시에 시작해요! 많이 와주세요~',
        fanId: 'creator',
        fanName: '',
        fanTier: '',
        isFromCreator: true,
        timestamp: now.subtract(const Duration(minutes: 30)),
        readCount: 750,
        totalSubscribers: DemoConfig.demoSubscriberCount,
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

    final isReply = _replyingTo != null;

    setState(() {
      _messages.add(GroupChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: _messageController.text.trim(),
        fanId: 'creator',
        fanName: '',
        fanTier: '',
        isFromCreator: true,
        timestamp: DateTime.now(),
        readCount: isReply && _isReplyDirect ? 1 : 0,
        totalSubscribers:
            isReply && _isReplyDirect ? 1 : DemoConfig.demoSubscriberCount,
        isDirectReplyMessage: isReply ? _isReplyDirect : false,
        replyToFanId: _replyingTo?.fanId,
        replyToFanName: _replyingTo?.fanName,
        replyToContent: _replyingTo?.content,
      ));
      _messageController.clear();
      _replyingTo = null;
      _isMediaMenuOpen = false;
    });

    // Scroll to bottom
    _scrollToBottom();

    if (isReply) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isReplyDirect
                ? '${_replyingTo?.fanName ?? ''}님에게 1:1 답장을 보냈습니다'
                : '전체 팬에게 답장을 보냈습니다',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _scrollToBottom() {
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

  void _addPollFromExternal(PollDraft draft, String? comment) {
    setState(() {
      _messages.add(GroupChatMessage(
        id: 'poll_${DateTime.now().millisecondsSinceEpoch}',
        content: draft.question,
        fanId: 'creator',
        fanName: '',
        fanTier: '',
        isFromCreator: true,
        timestamp: DateTime.now(),
        readCount: 0,
        totalSubscribers: DemoConfig.demoSubscriberCount,
        messageType: 'poll',
        pollData: draft,
      ));
    });
    _scrollToBottom();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('투표가 전송되었습니다: ${draft.question}')),
      );
    }
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

  /// 크리에이터 자신의 메시지 Long Press 시 편집/삭제/복사 바텀시트
  void _showCreatorMessageActionsSheet(
    BuildContext context,
    GroupChatMessage message,
    bool isDark,
  ) {
    final hoursSinceCreation =
        DateTime.now().difference(message.timestamp).inHours;
    final canEdit = hoursSinceCreation < 24 && message.messageType == 'text';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 메시지 미리보기
            if (message.content.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message.content.length > 100
                      ? '${message.content.substring(0, 100)}...'
                      : message.content,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            const SizedBox(height: 8),

            // 편집
            if (canEdit)
              _buildActionTile(
                icon: Icons.edit_outlined,
                label: '편집',
                sublabel: '24시간 이내',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context, message, isDark);
                },
              ),

            // 삭제
            _buildActionTile(
              icon: Icons.delete_outline,
              label: '삭제',
              isDark: isDark,
              isDanger: true,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, message);
              },
            ),

            // 복사
            _buildActionTile(
              icon: Icons.copy_outlined,
              label: '복사',
              isDark: isDark,
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('메시지가 복사되었습니다'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            // 취소
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.close,
              label: '취소',
              isDark: isDark,
              isCancel: true,
              onTap: () => Navigator.pop(context),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    String? sublabel,
    required bool isDark,
    bool isDanger = false,
    bool isCancel = false,
    required VoidCallback onTap,
  }) {
    final color = isDanger
        ? AppColors.danger
        : isCancel
            ? (isDark ? AppColors.textSubDark : AppColors.textSubLight)
            : (isDark ? AppColors.textMainDark : AppColors.textMainLight);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  if (sublabel != null)
                    Text(
                      sublabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
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

  void _showEditDialog(
    BuildContext context,
    GroupChatMessage message,
    bool isDark,
  ) {
    final controller = TextEditingController(text: message.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메시지 편집'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              maxLines: 5,
              minLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '메시지를 수정하세요',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '편집된 메시지는 "편집됨"으로 표시됩니다',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty && newContent != message.content) {
                final index = _messages.indexWhere((m) => m.id == message.id);
                if (index != -1) {
                  setState(() {
                    _messages[index] = _messages[index].copyWith(
                      content: newContent,
                      isEdited: true,
                    );
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('메시지가 수정되었습니다'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, GroupChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메시지 삭제'),
        content: const Text(
          '이 메시지를 삭제하시겠습니까?\n삭제된 메시지는 팬들에게 "삭제된 메시지"로 표시됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final index = _messages.indexWhere((m) => m.id == message.id);
              if (index != -1) {
                setState(() {
                  _messages[index] = _messages[index].copyWith(isDeleted: true);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('메시지가 삭제되었습니다'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 팬 메시지 Long Press 시 답장 타입 선택 바텀시트
  void _showReplyOptionsSheet(
    BuildContext context,
    GroupChatMessage originalMessage,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Row(
              children: [
                const Icon(Icons.reply_rounded,
                    color: AppColors.primary, size: 24),
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
                  icon: Icon(Icons.close,
                      color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),

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
              child: Row(
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
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(originalMessage.fanName,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textSubDark
                                        : AppColors.textSubLight)),
                            const SizedBox(width: 6),
                            TierBadge(tier: originalMessage.fanTier),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(originalMessage.content,
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textMainDark
                                    : AppColors.textMainLight),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 답장 타입 버튼
            Row(
              children: [
                // 1:1 답장
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _replyingTo = originalMessage;
                        _isReplyDirect = true;
                      });
                    },
                    icon: const Icon(Icons.person, size: 18),
                    label: const Text('1:1 답장'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 전체 답장
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _replyingTo = originalMessage;
                        _isReplyDirect = false;
                      });
                    },
                    icon: const Icon(Icons.groups, size: 18),
                    label: const Text('전체 답장'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 검색 메서드
  // =========================================================================

  void _onSearchQueryChanged(String query) {
    setState(() {
      // query used for filtering
      _searchMatchIndices = [];
      _currentSearchMatchIndex = -1;
      if (query.isNotEmpty) {
        for (int i = 0; i < _messages.length; i++) {
          if (_messages[i]
              .content
              .toLowerCase()
              .contains(query.toLowerCase())) {
            _searchMatchIndices.add(i);
          }
        }
        if (_searchMatchIndices.isNotEmpty) {
          _currentSearchMatchIndex = 0;
          _scrollToSearchMatch();
        }
      }
    });
  }

  void _onSearchNavigate(int direction) {
    if (_searchMatchIndices.isEmpty) return;
    setState(() {
      _currentSearchMatchIndex = (_currentSearchMatchIndex + direction)
          .clamp(0, _searchMatchIndices.length - 1);
    });
    _scrollToSearchMatch();
  }

  void _scrollToSearchMatch() {
    if (_currentSearchMatchIndex < 0 || _searchMatchIndices.isEmpty) return;
    final msgIndex = _searchMatchIndices[_currentSearchMatchIndex];
    // 대략적 위치 계산 (각 메시지 약 80px)
    final estimatedOffset = msgIndex * 80.0;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        estimatedOffset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onSearchClose() {
    setState(() {
      _isSearchActive = false;
      _searchMatchIndices = [];
      _currentSearchMatchIndex = -1;
    });
  }

  // =========================================================================
  // 미디어 메뉴 핸들러
  // =========================================================================

  void _handleMediaAction(String actionName) {
    setState(() {
      _isMediaMenuOpen = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$actionName 기능은 백엔드 연동 후 활성화됩니다'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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

              // 탭 2: 프라이빗 카드
              const PrivateCardListView(),

              // 탭 3: 구독
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
            padding: const EdgeInsets.fromLTRB(24, 16, 8, 12),
            child: Row(
              children: [
                Text(
                  '채팅',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const Spacer(),
                // 검색 버튼
                IconButton(
                  onPressed: () => setState(() {
                    _isSearchActive = true;
                  }),
                  icon: Icon(
                    Icons.search,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                  tooltip: '메시지 검색',
                ),
                // 미디어 모아보기 버튼
                IconButton(
                  onPressed: () => MediaGallerySheet.show(
                    context: context,
                    channelId: DemoConfig.demoChannelId,
                  ),
                  icon: Icon(
                    Icons.perm_media_outlined,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                  tooltip: '미디어 모아보기',
                ),
                // 알림 버튼
                IconButton(
                  onPressed: () => context.push('/notifications'),
                  icon: Stack(
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
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
                Tab(text: '카드'),
                Tab(text: '구독'),
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
    return Column(
      children: [
        // 검색 바 (활성화 시)
        if (_isSearchActive)
          ChatSearchBar(
            matchCount: _searchMatchIndices.length,
            currentMatch: _currentSearchMatchIndex,
            onQueryChanged: _onSearchQueryChanged,
            onNavigate: _onSearchNavigate,
            onClose: _onSearchClose,
          ),

        // 채널 정보 바 (닫기 가능)
        if (!_isBannerDismissed && !_isSearchActive)
          AnimatedCrossFade(
            firstChild: Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.campaign_rounded,
                        size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '전체 전송 모드',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '입력한 메시지는 구독자 ${DemoConfig.demoSubscriberCount}명에게 모두 전송됩니다',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '팬 메시지에 1:1 답장 시 해당 팬에게만 전송됩니다',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isBannerDismissed = true),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child:
                          Icon(Icons.close, size: 16, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),

        // 질문카드 패널
        const DailyQuestionCardsPanel(
          channelId: DemoConfig.demoChannelId,
          compact: true,
        ),

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
                        GroupChatBubble(
                          message: message,
                          isDark: isDark,
                          isHearted: _heartedMessages.contains(message.id),
                          onHeartTap: () => _toggleHeart(message.id),
                          onLongPress: message.isDeleted
                              ? null
                              : message.isFromCreator
                                  ? () => _showCreatorMessageActionsSheet(
                                        context,
                                        message,
                                        isDark,
                                      )
                                  : () => _showReplyOptionsSheet(
                                        context,
                                        message,
                                        isDark,
                                      ),
                        ),
                      ],
                    );
                  },
                ),
        ),

        // 메시지 입력 바
        _buildInputBar(isDark),
      ],
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
        8,
        12,
        MediaQuery.of(context).padding.bottom + 8,
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
          // 답장 미리보기 바
          if (_replyingTo != null) _buildReplyPreviewBar(isDark),

          // 미디어 메뉴 (확장 시)
          if (_isMediaMenuOpen)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMediaMenuButton(
                    icon: Icons.photo_library_outlined,
                    label: '사진',
                    color: const Color(0xFF4CAF50),
                    isDark: isDark,
                    onTap: () => _handleMediaAction('사진 전송'),
                  ),
                  _buildMediaMenuButton(
                    icon: Icons.videocam_outlined,
                    label: '동영상',
                    color: const Color(0xFF9C27B0),
                    isDark: isDark,
                    onTap: () => _handleMediaAction('동영상 전송'),
                  ),
                  _buildMediaMenuButton(
                    icon: Icons.mic_outlined,
                    label: '음성',
                    color: const Color(0xFFFF9800),
                    isDark: isDark,
                    onTap: () => _handleMediaAction('음성 메시지'),
                  ),
                  _buildMediaMenuButton(
                    icon: Icons.camera_alt_outlined,
                    label: '카메라',
                    color: const Color(0xFF2196F3),
                    isDark: isDark,
                    onTap: () => _handleMediaAction('카메라 촬영'),
                  ),
                  _buildMediaMenuButton(
                    icon: Icons.poll_outlined,
                    label: '투표',
                    color: const Color(0xFFE91E63),
                    isDark: isDark,
                    onTap: () {
                      setState(() => _isMediaMenuOpen = false);
                      PollSuggestionSheet.show(
                        context: context,
                        channelId: 'channel_1',
                        onSend: (draft, comment) async {
                          if (AppConfig.enableDemoMode) {
                            // Demo mode: add poll message to local list
                            setState(() {
                              _messages.add(GroupChatMessage(
                                id: 'poll_${DateTime.now().millisecondsSinceEpoch}',
                                content: draft.question,
                                fanId: 'creator',
                                fanName: '',
                                fanTier: '',
                                isFromCreator: true,
                                timestamp: DateTime.now(),
                                readCount: 0,
                                totalSubscribers:
                                    DemoConfig.demoSubscriberCount,
                                messageType: 'poll',
                                pollData: draft,
                              ));
                            });
                            _scrollToBottom();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('투표가 전송되었습니다: ${draft.question}')),
                              );
                            }
                            return;
                          }

                          // Production: call Supabase RPC
                          try {
                            await Supabase.instance.client.rpc(
                              'create_poll_message',
                              params: {
                                'p_channel_id': 'channel_1',
                                'p_question': draft.question,
                                'p_options': draft.options
                                    .map((o) => o.toJson())
                                    .toList(),
                                'p_comment': comment,
                                'p_draft_id': draft.id.startsWith('draft_')
                                    ? null
                                    : draft.id,
                              },
                            );
                            if (context.mounted) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('투표가 전송되었습니다')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('투표 전송 실패: $e')),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

          // 입력 Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // + 버튼 (미디어 메뉴 토글)
              IconButton(
                onPressed: () => setState(() {
                  _isMediaMenuOpen = !_isMediaMenuOpen;
                }),
                icon: AnimatedRotation(
                  turns: _isMediaMenuOpen ? 0.125 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.add,
                    color: _isMediaMenuOpen
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight),
                    size: 26,
                  ),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
                    decoration: InputDecoration(
                      hintText: _replyingTo != null
                          ? '${_isReplyDirect ? '1:1' : '전체'} 답장 입력...'
                          : '모든 팬에게 메시지 보내기...',
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
                  color: _replyingTo != null && _isReplyDirect
                      ? Colors.purple
                      : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(
                    _replyingTo != null
                        ? (_isReplyDirect ? Icons.send_rounded : Icons.campaign)
                        : Icons.send_rounded,
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

  Widget _buildReplyPreviewBar(bool isDark) {
    final replyColor = _isReplyDirect ? Colors.purple : AppColors.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: replyColor.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: replyColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply_rounded, size: 16, color: replyColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_isReplyDirect ? '1:1' : '전체'} → ${_replyingTo!.fanName}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: replyColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyingTo!.content.length > 50
                      ? '${_replyingTo!.content.substring(0, 50)}...'
                      : _replyingTo!.content,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _replyingTo = null;
            }),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
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

  bool _shouldShowDate(GroupChatMessage current, GroupChatMessage? previous) {
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
        return ChatRoomTile(
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
