import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/accessibility_helper.dart';
import '../../shared/widgets/app_scaffold.dart';

/// 통합 환불 정책 화면
class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

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
                    '환불 정책',
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

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLastUpdated(isDark),
                  const SizedBox(height: 24),

                  // Section 1: DT 환불
                  _buildSectionTitle(isDark, '제1조 DT(디지털 토큰) 환불'),
                  const SizedBox(height: 12),
                  _buildArticle(isDark, [
                    '① DT는 UNO A 앱 내에서만 사용 가능한 선불전자지급수단(선불 크레딧)입니다.',
                    '② 구매 후 7일 이내에 미사용 DT에 대해 환불을 요청할 수 있습니다.',
                    '③ 이미 사용한 DT는 환불 대상에서 제외됩니다.',
                    '④ 보너스로 지급된 DT는 환불 대상에서 제외됩니다.',
                    '⑤ 부분 환불이 가능하며, 환불 금액은 구매 DT 기준 비율로 산정됩니다.',
                    '⑥ DT의 유효기간은 구매일로부터 5년이며, 전자금융거래법에 따릅니다.',
                    '⑦ 유효기간 만료 60일 전 앱 내 알림을 통해 안내됩니다.',
                  ]),
                  const SizedBox(height: 24),

                  // Section 2: 구독 환불
                  _buildSectionTitle(isDark, '제2조 구독 서비스 환불'),
                  const SizedBox(height: 12),
                  _buildArticle(isDark, [
                    '① 구독 결제 후 7일 이내, 해당 구독 혜택을 이용하지 않은 경우 환불이 가능합니다.',
                    '② 구독 기간 중 서비스를 이용한 경우, 남은 기간에 대한 일할 환불은 지원하지 않습니다.',
                    '③ 구독 해지는 언제든 가능하며, 해지 시 현재 결제 주기 종료일까지 서비스를 이용할 수 있습니다.',
                    '④ 자동갱신을 원하지 않는 경우, 결제일 최소 24시간 전에 해지해야 합니다.',
                  ]),
                  const SizedBox(height: 24),

                  // Section 3: 펀딩 환불
                  _buildSectionTitle(isDark, '제3조 펀딩 환불'),
                  const SizedBox(height: 12),
                  _buildArticle(isDark, [
                    '① 펀딩 기간 종료 전: 후원자는 자유롭게 펀딩 참여를 취소하고 환불받을 수 있습니다.',
                    '② 펀딩 실패(목표 미달): 펀딩기간 종료일로부터 20영업일 이내에 전액 자동 환불됩니다.',
                    '③ 리워드 미제공: 크리에이터가 리워드 제공 의무를 이행하지 않는 경우 환불 신청이 가능합니다.',
                    '④ 리워드 하자: 서비스에 게시된 내용과 현저하게 다르거나 정상 작동하지 않는 경우 환불됩니다.',
                    '⑤ 펀딩은 원화(KRW)로 결제되며, 환불도 원결제 수단으로 진행됩니다.',
                  ]),
                  const SizedBox(height: 24),

                  // Section 4: 환불 절차
                  _buildSectionTitle(isDark, '제4조 환불 절차'),
                  const SizedBox(height: 12),
                  _buildArticle(isDark, [
                    '① 환불 요청 방법:',
                    '   • DT 환불: 앱 > 지갑 > 거래내역에서 해당 충전건 선택 후 "환불 요청"',
                    '   • 구독/펀딩 환불: 앱 > 설정 > 고객센터를 통해 신청',
                    '② 환불 처리 기간: 요청일로부터 영업일 기준 3~5일 이내',
                    '③ 환불 금액은 원결제 수단으로 반환됩니다. 원결제 수단 환불이 불가능한 경우 별도 안내드립니다.',
                    '④ 부분 환불 시 보너스 DT 및 프로모션 혜택은 차감될 수 있습니다.',
                  ]),
                  const SizedBox(height: 24),

                  // Section 5: 차지백
                  _buildSectionTitle(isDark, '제5조 결제 취소 및 차지백'),
                  const SizedBox(height: 12),
                  _buildArticle(isDark, [
                    '① 신용카드사를 통한 결제 취소(차지백) 발생 시, 해당 DT는 분쟁 해결 시까지 동결됩니다.',
                    '② 차지백이 확정(가맹점 패소)되면 해당 DT는 영구 차감됩니다.',
                    '③ 차지백이 철회(가맹점 승소)되면 동결된 DT는 복원됩니다.',
                    '④ 부당한 차지백 시도는 서비스 이용 제한 사유가 될 수 있습니다.',
                  ]),
                  const SizedBox(height: 24),

                  // Section 6: 문의
                  _buildSectionTitle(isDark, '제6조 고객 문의'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceAltDark
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '환불 관련 문의',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• 이메일: support@unoa.app\n'
                          '• 고객센터: 앱 > 설정 > 고객센터\n'
                          '• 운영시간: 평일 10:00 - 18:00 (공휴일 제외)',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: isDark
                                ? AppColors.textSubDark
                                : AppColors.textSubLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Footer
                  Text(
                    '※ 본 환불 정책은 전자상거래 등에서의 소비자보호에 관한 법률, 콘텐츠산업진흥법, 전자금융거래법 등 관련 법령에 따라 운영됩니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMuted,
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '최종 수정일: 2026년 02월 09일 | 시행일: 2026년 02월 09일',
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(bool isDark, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
      ),
    );
  }

  Widget _buildArticle(bool isDark, List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Text(
        items.join('\n'),
        style: TextStyle(
          fontSize: 13,
          height: 1.7,
          color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
        ),
      ),
    );
  }
}
