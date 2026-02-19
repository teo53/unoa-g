import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/status_timeline.dart';
import 'my_pledges_screen.dart';

/// Result screen after funding pledge
class FundingResultScreen extends StatelessWidget {
  final bool success;
  final Map<String, dynamic> campaign;
  final Map<String, dynamic> tier;
  final int totalAmount;
  final String? pledgeId;
  final int? newBalance;
  final String? errorMessage;

  const FundingResultScreen({
    super.key,
    required this.success,
    required this.campaign,
    required this.tier,
    required this.totalAmount,
    this.pledgeId,
    this.newBalance,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Result icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: success
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.danger.withValues(alpha: 0.1),
                ),
                child: Icon(
                  success
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  size: 60,
                  color: success ? AppColors.success : AppColors.danger,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                success ? '후원 완료!' : '후원 실패',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : AppColors.text,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                success
                    ? '${campaign['title']}에\n${_formatNumber(totalAmount)}원을 후원했습니다'
                    : errorMessage ?? '후원 처리 중 오류가 발생했습니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // Details card
              if (success)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        isDark,
                        '선택한 리워드',
                        tier['title'] ?? '',
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        isDark,
                        '후원 금액',
                        '${_formatNumber(totalAmount)}원',
                      ),
                      if (newBalance != null) ...[
                        const Divider(height: 24),
                        _buildDetailRow(
                          isDark,
                          '잔액',
                          '${_formatNumber(newBalance!)}원',
                        ),
                      ],
                    ],
                  ),
                ),

              if (success) ...[
                const SizedBox(height: 16),

                // Funding progress timeline
                const StatusTimeline(
                  steps: [
                    StatusTimelineStep(
                      title: '후원 완료',
                      subtitle: '결제가 정상 처리되었습니다',
                      status: StepStatus.completed,
                    ),
                    StatusTimelineStep(
                      title: '펀딩 진행 중',
                      subtitle: '목표 금액 달성까지 진행 중',
                      status: StepStatus.active,
                    ),
                    StatusTimelineStep(
                      title: '펀딩 종료',
                      subtitle: '목표 달성 여부 확인',
                      status: StepStatus.pending,
                    ),
                    StatusTimelineStep(
                      title: '리워드 발송',
                      subtitle: '크리에이터가 리워드를 발송합니다',
                      status: StepStatus.pending,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: AppColors.primary600,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '펀딩 성공 시 리워드가 발송됩니다.\n진행 상황은 마이페이지에서 확인하세요.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop to funding list
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              if (success) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyPledgesScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    '내 후원 내역 보기',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],

              if (!success) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: const Text(
                    '다시 시도',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(bool isDark, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDark : AppColors.text,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(0)}만';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}천';
    }
    return number.toString();
  }
}
