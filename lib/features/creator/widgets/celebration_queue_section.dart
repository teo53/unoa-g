import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/mock/mock_celebrations.dart';
import '../../../data/models/celebration_event.dart';
import 'celebration_template_sheet.dart';

/// Dashboard section showing today's pending celebrations.
///
/// Shows count badges for birthdays and milestones,
/// with tap-to-send via template selection.
class CelebrationQueueSection extends StatefulWidget {
  final String channelId;
  final String? artistName;

  const CelebrationQueueSection({
    super.key,
    required this.channelId,
    this.artistName,
  });

  @override
  State<CelebrationQueueSection> createState() =>
      _CelebrationQueueSectionState();
}

class _CelebrationQueueSectionState extends State<CelebrationQueueSection> {
  List<CelebrationEvent>? _events;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (AppConfig.enableDemoMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          setState(() {
            _events = MockCelebrations.todayEvents;
            _isLoading = false;
          });
        }
        return;
      }

      // Production: Call Supabase RPC get_celebration_queue
      final response = await Supabase.instance.client.rpc(
        'get_celebration_queue',
        params: {'p_channel_id': widget.channelId},
      );

      if (mounted) {
        final data = response as Map<String, dynamic>?;
        final eventsJson = (data?['events'] as List<dynamic>?) ?? [];
        setState(() {
          _events = eventsJson
              .map((e) => CelebrationEvent.fromJson(
                    (e as Map<String, dynamic>)
                      ..putIfAbsent('channel_id', () => widget.channelId),
                  ))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onEventTap(CelebrationEvent event) {
    CelebrationTemplateSheet.show(
      context: context,
      event: event,
      channelId: widget.channelId,
      artistName: widget.artistName ?? '아티스트',
      onSend: (renderedText) async {
        // Mark event as sent locally
        setState(() {
          _events = _events
              ?.map((e) => e.id == event.id
                  ? CelebrationEvent(
                      id: e.id,
                      channelId: e.channelId,
                      fanCelebrationId: e.fanCelebrationId,
                      eventType: e.eventType,
                      dueDate: e.dueDate,
                      status: 'sent',
                      payload: e.payload,
                      createdAt: e.createdAt,
                      sentAt: DateTime.now(),
                    )
                  : e)
              .toList();
        });

        // Send message via chat system (production only)
        if (!AppConfig.enableDemoMode) {
          try {
            // 1. Insert broadcast message
            final msgResponse = await Supabase.instance.client
                .from('messages')
                .insert({
                  'channel_id': widget.channelId,
                  'sender_type': 'artist',
                  'delivery_scope': 'broadcast',
                  'content': renderedText,
                  'message_type': 'text',
                })
                .select('id')
                .single();

            // 2. Update celebration_events status
            if (event.id.isNotEmpty) {
              await Supabase.instance.client.from('celebration_events').update({
                'status': 'sent',
                'sent_at': DateTime.now().toUtc().toIso8601String(),
                'message_id': msgResponse['id'],
              }).eq('id', event.id);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('축하 메시지 전송 실패: $e')),
              );
            }
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_error != null || _events == null || _events!.isEmpty) {
      return const SizedBox.shrink();
    }

    final pendingEvents = _events!.where((e) => e.status == 'pending').toList();
    if (pendingEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    final birthdayCount = pendingEvents.where((e) => e.isBirthday).length;
    final milestoneCount = pendingEvents.where((e) => e.isMilestone).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Text(
              '🎉',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              '오늘의 축하 이벤트',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const Spacer(),
            // Count badges
            if (birthdayCount > 0)
              _CountBadge(
                label: '생일 $birthdayCount',
                icon: Icons.cake_outlined,
                isDark: isDark,
              ),
            if (milestoneCount > 0) ...[
              const SizedBox(width: 6),
              _CountBadge(
                label: '기념일 $milestoneCount',
                icon: Icons.star_outlined,
                isDark: isDark,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Event cards
        ...pendingEvents.map((event) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CelebrationEventCard(
                event: event,
                isDark: isDark,
                onTap: () => _onEventTap(event),
              ),
            )),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;

  const _CountBadge({
    required this.label,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary500),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebrationEventCard extends StatelessWidget {
  final CelebrationEvent event;
  final bool isDark;
  final VoidCallback onTap;

  const _CelebrationEventCard({
    required this.event,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSent = event.status == 'sent';

    return GestureDetector(
      onTap: isSent ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSent
              ? (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSent
                ? Colors.transparent
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Row(
          children: [
            // Event type emoji
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  event.eventTypeEmoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.payload.nickname,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary500.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.payload.tier,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.isBirthday
                        ? '오늘이 생일이에요!'
                        : '구독 ${event.payload.dayCount}일 기념일',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                    ),
                  ),
                ],
              ),
            ),
            // Action
            if (isSent)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '전송 완료',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '축하 보내기',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
