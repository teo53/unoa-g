import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/broadcast_message.dart';
import '../../data/repositories/mock_chat_repository.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'widgets/fan_reply_tile.dart';
import 'widgets/inbox_filter_bar.dart';

/// Artist Inbox Screen
/// Shows all fan messages (replies + donation messages) for the artist
class ArtistInboxScreen extends StatefulWidget {
  final String channelId;

  const ArtistInboxScreen({
    super.key,
    required this.channelId,
  });

  @override
  State<ArtistInboxScreen> createState() => _ArtistInboxScreenState();
}

class _ArtistInboxScreenState extends State<ArtistInboxScreen> {
  final MockArtistInboxRepository _repository = MockArtistInboxRepository();

  String _filterType = 'all';
  List<BroadcastMessage> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final messages = await _repository.getFanMessages(
        widget.channelId,
        filterType: _filterType,
      );
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onFilterChanged(String filterType) {
    setState(() => _filterType = filterType);
    _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      showStatusBar: true,
      child: Column(
        children: [
          // Header
          _buildHeader(context, isDark),

          // Filter Bar
          InboxFilterBar(
            selectedFilter: _filterType,
            onFilterChanged: _onFilterChanged,
          ),

          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState(isDark)
                    : _buildMessagesList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark.withValues(alpha: 0.95)
            : AppColors.backgroundLight.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              '팬 메시지',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
          ),
          // Broadcast compose button
          IconButton(
            onPressed: () {
              context.push('/artist/broadcast/compose');
            },
            icon: Icon(
              Icons.edit_square,
              color: AppColors.primary500,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '아직 팬 메시지가 없어요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '메시지를 보내면 팬들의 답장이 여기에 표시돼요',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return FanReplyTile(
            message: message,
            onTap: () {
              // Navigate to fan thread
              context.push('/artist/inbox/${message.senderId}');
            },
            onHighlightTap: () async {
              await _repository.toggleHighlight(message.id);
              _loadMessages();
            },
            onReplyTap: message.deliveryScope == DeliveryScope.donationMessage
                ? () {
                    // Show reply input for donation messages
                    _showDonationReplySheet(context, message);
                  }
                : null,
          );
        },
      ),
    );
  }

  void _showDonationReplySheet(BuildContext context, BroadcastMessage message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

        return Container(
          margin: EdgeInsets.only(bottom: bottomPadding),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.reply, color: AppColors.primary500),
                    const SizedBox(width: 8),
                    Text(
                      '${message.senderName ?? '팬'}님에게 답장',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color:
                            isDark ? AppColors.textSubDark : AppColors.textSubLight,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Original message preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.diamond,
                        size: 16,
                        color: AppColors.primary500,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '"${message.content}"',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? AppColors.textSubDark
                                : AppColors.textSubLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Reply input
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: '답장을 입력하세요...',
                      hintStyle: TextStyle(
                        color:
                            isDark ? AppColors.textMutedDark : AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                      counterStyle: TextStyle(
                        fontSize: 11,
                        color:
                            isDark ? AppColors.textSubDark : AppColors.textSubLight,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Send button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final content = controller.text.trim();
                      if (content.isEmpty) return;

                      try {
                        await _repository.replyToDonation(
                          widget.channelId,
                          message.id,
                          content,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('답장을 보냈습니다'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('답장 전송 실패: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '답장 보내기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
