import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Content Performance tab for Creator CRM
/// Shows content stats, best messages, and message type performance
class CrmContentTab extends StatelessWidget {
  const CrmContentTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content stats overview
          _ContentStatsCard(isDark: isDark),
          const SizedBox(height: 20),

          // Best performing messages
          _BestMessagesCard(isDark: isDark),
          const SizedBox(height: 20),

          // Message type performance
          _MessageTypePerformanceCard(isDark: isDark),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _ContentStatsCard extends StatelessWidget {
  final bool isDark;

  const _ContentStatsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '콘텐츠 성과 요약',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ContentStatItem(
                  label: '총 브로드캐스트',
                  value: '156',
                  subLabel: '이번 달 +24',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _ContentStatItem(
                  label: '받은 답장',
                  value: '892',
                  subLabel: '평균 5.7개/메시지',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ContentStatItem(
                  label: '평균 열람률',
                  value: '87%',
                  subLabel: '업계 평균 대비 +12%',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _ContentStatItem(
                  label: '평균 응답률',
                  value: '23%',
                  subLabel: '업계 평균 대비 +5%',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContentStatItem extends StatelessWidget {
  final String label;
  final String value;
  final String subLabel;
  final bool isDark;

  const _ContentStatItem({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _BestMessagesCard extends StatelessWidget {
  final bool isDark;

  const _BestMessagesCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final messages = [
      const _MessagePerf('오늘 연습 끝났어요! 집 가는 중~', 127, 89, '2시간 전'),
      const _MessagePerf('컴백 준비 중... 기대해주세요!', 98, 76, '어제'),
      const _MessagePerf('오늘 날씨 너무 좋다 ☀️', 76, 65, '2일 전'),
      const _MessagePerf('새 앨범 작업 중이에요 🎵', 68, 58, '3일 전'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '반응 좋은 메시지',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...messages.asMap().entries.map((entry) => _MessagePerfTile(
                rank: entry.key + 1,
                message: entry.value,
                isDark: isDark,
              )),
        ],
      ),
    );
  }
}

class _MessagePerf {
  final String content;
  final int replyCount;
  final int readRate;
  final String time;

  const _MessagePerf(this.content, this.replyCount, this.readRate, this.time);
}

class _MessagePerfTile extends StatelessWidget {
  final int rank;
  final _MessagePerf message;
  final bool isDark;

  const _MessagePerfTile({
    required this.rank,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: rank == 1
                  ? Colors.orange
                  : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: rank == 1
                    ? Colors.white
                    : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _PerfBadge(
                      icon: Icons.reply_rounded,
                      value: '답장 ${message.replyCount}',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    _PerfBadge(
                      icon: Icons.visibility_rounded,
                      value: '열람 ${message.readRate}%',
                      color: AppColors.verified,
                    ),
                    const Spacer(),
                    Text(
                      message.time,
                      style: TextStyle(
                        fontSize: 11,
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
    );
  }
}

class _PerfBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _PerfBadge({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MessageTypePerformanceCard extends StatelessWidget {
  final bool isDark;

  const _MessageTypePerformanceCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category_rounded, color: AppColors.verified, size: 20),
              const SizedBox(width: 8),
              Text(
                '메시지 유형별 성과',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TypePerfRow(
            type: '일상 공유',
            count: 68,
            avgReply: 8.2,
            avgRate: 91,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _TypePerfRow(
            type: '작업 근황',
            count: 45,
            avgReply: 12.5,
            avgRate: 94,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _TypePerfRow(
            type: '이벤트/공지',
            count: 23,
            avgReply: 5.3,
            avgRate: 88,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _TypePerfRow(
            type: '인사/감사',
            count: 20,
            avgReply: 6.8,
            avgRate: 85,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _TypePerfRow extends StatelessWidget {
  final String type;
  final int count;
  final double avgReply;
  final int avgRate;
  final bool isDark;

  const _TypePerfRow({
    required this.type,
    required this.count,
    required this.avgReply,
    required this.avgRate,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            type,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
        ),
        Expanded(
          child: Text(
            '$count개',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            '답장 ${avgReply.toStringAsFixed(1)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            '열람 $avgRate%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.success,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
