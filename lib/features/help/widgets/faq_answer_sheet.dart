import 'package:flutter/material.dart';

import '../../../core/config/business_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Bottom sheet showing an FAQ answer.
///
/// Keeps numeric values sourced from [BusinessConfig] to avoid scattered hardcoding.
class FaqAnswerSheet {
  FaqAnswerSheet._();

  static void show(
    BuildContext context, {
    required String question,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final answer = _answers[question] ??
        '해당 질문에 대한 답변을 준비 중입니다.\n\n추가 도움이 필요하면 고객센터로 문의해 주세요.';

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      borderRadius: AppRadius.smBR,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  question,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 12),

                // Answer
                Text(
                  answer,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),

                const SizedBox(height: 20),

                // CTA
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.baseBR,
                      ),
                    ),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Map<String, String> get _answers {
    final tokensBase = BusinessConfig.defaultReplyTokens;
    final tokensStandard = BusinessConfig.getTokensForTier('STANDARD');
    final tokensVip = BusinessConfig.getTokensForTier('VIP');
    final refundDays = BusinessConfig.dtRefundWindowDays;
    final expiryYears = BusinessConfig.dtExpiryYears;

    return {
      // DT
      'DT는 어떻게 구매하나요?': '지갑(Wallet) > DT 충전에서 원하는 패키지를 선택해 결제할 수 있습니다.\n\n'
          '결제 완료 후 DT 잔액이 반영되며, DT는 아티스트 후원 및 일부 유료 기능에 사용됩니다.\n\n'
          '※ 표시된 금액은 VAT(부가가치세)가 포함된 금액입니다.',
      'DT 환불이 가능한가요?':
          '결제 완료 후 ${refundDays}일 이내이며, 사용하지 않은 DT에 한해 환불이 가능합니다.\n\n'
              '환불은 결제 수단/승인 상태에 따라 처리 시간이 달라질 수 있습니다.\n'
              '도움이 필요하면 고객센터로 문의해 주세요.',
      'DT 유효기간이 있나요?': '네. DT는 결제(또는 지급) 후 최대 ${expiryYears}년까지 사용할 수 있으며, '
          '유효기간이 지난 미사용 DT는 만료될 수 있습니다.\n\n'
          '유효기간 및 만료 정책은 서비스 운영 정책에 따라 변경될 수 있습니다.',

      // Subscription
      '구독을 해지하면 어떻게 되나요?':
          '구독을 해지해도 남아있는 구독 기간(다음 결제 예정일 전)까지는 혜택을 사용할 수 있습니다.\n\n'
              '기간이 종료되면 자동 갱신이 중단되며, 이후에는 기본 혜택으로 전환됩니다.',
      '구독 등급을 변경할 수 있나요?': '가능합니다.\n\n'
          '등급 변경 시 적용 시점(즉시/다음 결제 주기)은 결제 플랫폼 정책에 따라 달라질 수 있습니다.\n'
          '변경 전에 각 등급 혜택을 확인해 주세요.',
      '자동 갱신을 끄는 방법은?': '자동 갱신(구독 관리)은 결제한 플랫폼에서 설정합니다.\n\n'
          '• iOS: 설정 > Apple ID > 구독\n'
          '• Android: Google Play > 결제 및 구독 > 구독\n\n'
          '플랫폼 메뉴 경로는 OS 버전에 따라 약간 다를 수 있습니다.',

      // Messaging
      '메시지는 어떻게 보내나요?':
          '아티스트의 브로드캐스트 메시지를 확인한 뒤, 답글 토큰을 사용해 메시지를 보낼 수 있습니다.\n\n'
              '기본으로 브로드캐스트당 토큰 ${tokensBase}개가 제공되며, '
              'STANDARD는 ${tokensStandard}개, VIP는 ${tokensVip}개로 더 많이 제공됩니다.',
      '아티스트 답장은 언제 오나요?':
          '아티스트의 일정과 운영 방식에 따라 답장 시점은 달라질 수 있으며, 모든 메시지에 답장이 보장되지는 않습니다.\n\n'
              '답글이 늦어질 경우 알림을 확인하고, 필요하면 다시 메시지를 남겨 주세요.',
      '메시지 알림 설정은 어디서 하나요?': '앱 설정에서 알림을 켜고/끌 수 있습니다.\n\n'
          '기기 설정에서 UNO A 알림이 차단되어 있다면 기기 설정에서 알림 허용을 확인해 주세요.',

      // Account
      '비밀번호를 잊어버렸어요': '로그인 화면에서 비밀번호 재설정을 진행할 수 있습니다.\n\n'
          '재설정 메일이 오지 않는다면 스팸함을 확인해 주세요.',
      '계정을 삭제하고 싶어요': '계정 삭제는 보안 및 정산 이슈로 인해 고객센터 확인이 필요할 수 있습니다.\n\n'
          '고객센터로 "계정 삭제"를 문의해 주시면 안내해 드립니다.',
      '로그인이 안 돼요': '다음 항목을 확인해 주세요.\n\n'
          '1) 네트워크 연결 상태\n'
          '2) 앱 최신 버전 업데이트\n'
          '3) 이메일/비밀번호 입력 오류\n\n'
          '계속 문제가 발생하면 고객센터로 문의해 주세요.',
    };
  }
}
