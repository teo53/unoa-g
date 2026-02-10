import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import '../../data/models/poll_message.dart';
import '../chat/widgets/poll_message_card.dart';

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
  _GroupChatMessage? _replyingTo;
  bool _isReplyDirect = true;

  // Mock messages - 실제로는 provider에서 가져옴
  final List<_GroupChatMessage> _messages = [];

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
      _GroupChatMessage(
        id: '1',
        content: '오늘 컨텐츠 너무 좋았어요!',
        fanId: 'fan_1',
        fanName: '하늘덕후',
        fanTier: 'VIP',
        isFromCreator: false,
        timestamp: now.subtract(const Duration(hours: 2)),
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
        totalSubscribers: DemoConfig.demoSubscriberCount,
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
      // 1:1 답장 예시
      _GroupChatMessage(
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
      _GroupChatMessage(
        id: '5',
        content: '저도 기대돼요 ㅎㅎ',
        fanId: 'fan_1',
        fanName: '하늘덕후',
        fanTier: 'VIP',
        isFromCreator: false,
        timestamp: now.subtract(const Duration(minutes: 45)),
      ),
      // 전체 답장 예시
      _GroupChatMessage(
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
      _messages.add(_GroupChatMessage(
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
      _messages.add(_GroupChatMessage(
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
    _GroupChatMessage message,
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
    _GroupChatMessage message,
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

  void _showDeleteConfirmation(
      BuildContext context, _GroupChatMessage message) {
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
    _GroupChatMessage originalMessage,
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
                            _TierBadge(tier: originalMessage.fanTier),
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
                        _GroupChatBubble(
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
                              _messages.add(_GroupChatMessage(
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

  const _GroupChatBubble({
    required this.message,
    required this.isDark,
    required this.isHearted,
    required this.onHeartTap,
    this.onLongPress,
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
                  // 메시지 타입 배지 (1:1 답장 / 전체)
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
                              : Icons.campaign_outlined,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isDirectReply ? '1:1 답장' : '전체',
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
  // 메시지 타입 (text, poll, image 등)
  final String messageType;
  // Poll 데이터 (messageType == 'poll'일 때)
  final PollDraft? pollData;
  // 편집/삭제 상태
  final bool isEdited;
  final bool isDeleted;

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
    this.messageType = 'text',
    this.pollData,
    this.isEdited = false,
    this.isDeleted = false,
  });

  _GroupChatMessage copyWith({
    String? content,
    bool? isEdited,
    bool? isDeleted,
  }) {
    return _GroupChatMessage(
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
    );
  }
}
