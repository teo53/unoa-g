import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/accessibility_helper.dart';
import '../../shared/widgets/app_scaffold.dart';

/// 마케팅 동의 이력 조회 화면
/// consent_history 테이블 데이터를 표시
class ConsentHistoryScreen extends StatelessWidget {
  const ConsentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      showStatusBar: true,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              children: [
                AccessibleTapTarget(
                  semanticLabel: '뒤로가기',
                  onTap: () => context.pop(),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const Expanded(
                  child: Text(
                    '동의 내역 확인',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 현재 동의 상태
                  _buildCurrentStatus(isDark),
                  const SizedBox(height: 24),

                  // 동의 변경 이력
                  Text(
                    '동의 변경 이력',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // History list (mock data for demo)
                  _buildHistoryItem(
                    isDark,
                    action: '동의',
                    consentType: '마케팅 수신 (이메일)',
                    date: '2025-01-15 14:30',
                    method: 'app',
                  ),
                  _buildHistoryItem(
                    isDark,
                    action: '동의',
                    consentType: '마케팅 수신 (푸시)',
                    date: '2025-01-15 14:30',
                    method: 'app',
                  ),
                  _buildHistoryItem(
                    isDark,
                    action: '철회',
                    consentType: '마케팅 수신 (SMS)',
                    date: '2025-01-10 09:15',
                    method: 'app',
                    reason: '수신 거부',
                  ),
                  _buildHistoryItem(
                    isDark,
                    action: '동의',
                    consentType: '마케팅 수신 (SMS)',
                    date: '2024-12-20 16:45',
                    method: 'web',
                  ),
                  _buildHistoryItem(
                    isDark,
                    action: '동의',
                    consentType: '서비스 이용약관',
                    date: '2024-12-20 16:44',
                    method: 'web',
                  ),
                  _buildHistoryItem(
                    isDark,
                    action: '동의',
                    consentType: '개인정보 처리방침',
                    date: '2024-12-20 16:44',
                    method: 'web',
                  ),

                  const SizedBox(height: 24),

                  // 안내 사항
                  _buildNotice(isDark),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary100,
            AppColors.primary100.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_outlined,
                  color: AppColors.primary600, size: 24),
              SizedBox(width: 8),
              Text(
                '현재 동의 상태',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildConsentStatusRow('서비스 이용약관', true, required: true),
          const SizedBox(height: 8),
          _buildConsentStatusRow('개인정보 처리방침', true, required: true),
          const SizedBox(height: 8),
          _buildConsentStatusRow('마케팅 수신 (이메일)', true),
          const SizedBox(height: 8),
          _buildConsentStatusRow('마케팅 수신 (푸시)', true),
          const SizedBox(height: 8),
          _buildConsentStatusRow('마케팅 수신 (SMS)', false),
        ],
      ),
    );
  }

  Widget _buildConsentStatusRow(String label, bool agreed,
      {bool required = false}) {
    return Row(
      children: [
        Icon(
          agreed ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: agreed ? AppColors.success : AppColors.danger,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primary700,
            ),
          ),
        ),
        if (required)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary600,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '필수',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        if (!required)
          Text(
            agreed ? '동의' : '미동의',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: agreed ? AppColors.success : AppColors.danger,
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryItem(
    bool isDark, {
    required String action,
    required String consentType,
    required String date,
    required String method,
    String? reason,
  }) {
    final isConsent = action == '동의';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isConsent
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.danger.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isConsent ? Icons.check : Icons.close,
              size: 18,
              color: isConsent ? AppColors.success : AppColors.danger,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isConsent
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        action,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              isConsent ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        consentType,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceAltDark
                            : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        _methodLabel(method),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight,
                        ),
                      ),
                    ),
                  ],
                ),
                if (reason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '사유: $reason',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'web':
        return '웹';
      case 'app':
        return '앱';
      case 'api':
        return 'API';
      default:
        return method;
    }
  }

  Widget _buildNotice(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '안내',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• 동의 내역은 정보통신망법에 따라 최소 5년간 보관됩니다.\n'
            '• 마케팅 수신 동의는 설정 화면에서 변경할 수 있습니다.\n'
            '• 필수 동의 항목은 서비스 이용을 위해 철회할 수 없습니다.\n'
            '• 동의 이력에 대한 문의는 support@unoa.app으로 연락주세요.',
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
        ],
      ),
    );
  }
}
