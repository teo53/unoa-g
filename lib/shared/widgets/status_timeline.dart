import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// 다단계 상태 타임라인 위젯
/// 환불/정산/주문 처리 등의 진행 상태를 시각화
class StatusTimeline extends StatelessWidget {
  final List<StatusTimelineStep> steps;

  const StatusTimeline({
    super.key,
    required this.steps,
  });

  /// 환불 진행 상태 프리셋
  factory StatusTimeline.refund({
    required String currentStatus,
    String? requestedAt,
    String? processingAt,
    String? completedAt,
  }) {
    final statusIndex = {
      'requested': 0,
      'processing': 1,
      'completed': 2,
    }[currentStatus] ?? 0;

    return StatusTimeline(
      steps: [
        StatusTimelineStep(
          title: '환불 요청',
          subtitle: requestedAt,
          status: statusIndex >= 0
              ? StepStatus.completed
              : StepStatus.pending,
        ),
        StatusTimelineStep(
          title: '처리 중',
          subtitle: processingAt ?? (statusIndex >= 1 ? '확인 중' : null),
          status: statusIndex >= 1
              ? (statusIndex > 1 ? StepStatus.completed : StepStatus.active)
              : StepStatus.pending,
        ),
        StatusTimelineStep(
          title: '환불 완료',
          subtitle: completedAt ?? (statusIndex >= 2 ? '영업일 기준 3-5일 이내 입금' : null),
          status: statusIndex >= 2
              ? StepStatus.completed
              : StepStatus.pending,
        ),
      ],
    );
  }

  /// 정산 진행 상태 프리셋
  factory StatusTimeline.payout({
    required String currentStatus,
    String? calculatedAt,
    String? approvedAt,
    String? paidAt,
  }) {
    final statusMap = {
      'pending_review': 0,
      'approved': 1,
      'processing': 2,
      'paid': 3,
    };
    final statusIndex = statusMap[currentStatus] ?? 0;

    return StatusTimeline(
      steps: [
        StatusTimelineStep(
          title: '정산 산출',
          subtitle: calculatedAt,
          status: statusIndex >= 0
              ? StepStatus.completed
              : StepStatus.pending,
        ),
        StatusTimelineStep(
          title: '승인 대기',
          subtitle: statusIndex >= 1 ? approvedAt ?? '승인됨' : null,
          status: statusIndex >= 1
              ? StepStatus.completed
              : (statusIndex == 0 ? StepStatus.active : StepStatus.pending),
        ),
        StatusTimelineStep(
          title: '입금 처리',
          subtitle: statusIndex >= 2 ? '계좌 이체 중' : null,
          status: statusIndex >= 2
              ? (statusIndex > 2 ? StepStatus.completed : StepStatus.active)
              : StepStatus.pending,
        ),
        StatusTimelineStep(
          title: '정산 완료',
          subtitle: paidAt,
          status: statusIndex >= 3
              ? StepStatus.completed
              : StepStatus.pending,
        ),
      ],
    );
  }

  /// 차지백 분쟁 상태 프리셋
  factory StatusTimeline.chargeback({
    required String currentStatus,
  }) {
    final statusMap = {
      'opened': 0,
      'evidence_submitted': 1,
      'won': 2,
      'lost': 2,
    };
    final statusIndex = statusMap[currentStatus] ?? 0;
    final isResolved = currentStatus == 'won' || currentStatus == 'lost';

    return StatusTimeline(
      steps: [
        const StatusTimelineStep(
          title: '분쟁 접수',
          subtitle: 'DT 동결',
          status: StepStatus.completed,
        ),
        StatusTimelineStep(
          title: '증빙 제출',
          subtitle: statusIndex >= 1 ? '검토 중' : null,
          status: statusIndex >= 1
              ? StepStatus.completed
              : (statusIndex == 0 ? StepStatus.active : StepStatus.pending),
        ),
        StatusTimelineStep(
          title: isResolved
              ? (currentStatus == 'won' ? '승소 (DT 복원)' : '패소 (DT 차감)')
              : '결과 대기',
          status: isResolved
              ? StepStatus.completed
              : StepStatus.pending,
          isSuccess: currentStatus == 'won',
          isError: currentStatus == 'lost',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                _buildStepIndicator(isDark, step),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 32,
                    color: step.status == StepStatus.completed
                        ? (step.isError ? AppColors.danger : AppColors.success)
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Step content
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: step.status == StepStatus.active
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _getTextColor(isDark, step),
                      ),
                    ),
                    if (step.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        step.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStepIndicator(bool isDark, StatusTimelineStep step) {
    switch (step.status) {
      case StepStatus.completed:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: step.isError
                ? AppColors.danger
                : (step.isSuccess ? AppColors.success : AppColors.success),
            shape: BoxShape.circle,
          ),
          child: Icon(
            step.isError ? Icons.close : Icons.check,
            color: Colors.white,
            size: 14,
          ),
        );
      case StepStatus.active:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.primary500,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        );
      case StepStatus.pending:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 2,
            ),
          ),
        );
    }
  }

  Color _getTextColor(bool isDark, StatusTimelineStep step) {
    if (step.isError) return AppColors.danger;
    if (step.isSuccess) return AppColors.success;
    switch (step.status) {
      case StepStatus.completed:
        return isDark ? AppColors.textMainDark : AppColors.textMainLight;
      case StepStatus.active:
        return AppColors.primary600;
      case StepStatus.pending:
        return isDark ? AppColors.textMutedDark : AppColors.textMuted;
    }
  }
}

enum StepStatus {
  pending,
  active,
  completed,
}

class StatusTimelineStep {
  final String title;
  final String? subtitle;
  final StepStatus status;
  final bool isSuccess;
  final bool isError;

  const StatusTimelineStep({
    required this.title,
    this.subtitle,
    this.status = StepStatus.pending,
    this.isSuccess = false,
    this.isError = false,
  });
}
