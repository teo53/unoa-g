import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/accessibility_helper.dart';
import '../../shared/widgets/app_scaffold.dart';

/// 펀딩 서비스 이용약관 화면
/// docs/legal/funding_terms_ko.md 내용을 인앱 렌더링
class FundingTermsScreen extends StatelessWidget {
  const FundingTermsScreen({super.key});

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
                    '펀딩 서비스 이용약관',
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

                  // Chapter 1
                  _buildChapterTitle(isDark, '제1장 총칙'),
                  const SizedBox(height: 16),
                  _buildSectionTitle(isDark, '제1조 (목적)'),
                  _buildParagraph(isDark,
                    '본 약관은 주식회사 언도어엔터테인먼트(이하 "회사")가 운영하는 UNO A 펀딩 서비스를 이용함에 있어 '
                    '회사와 이용자 간의 권리, 의무 및 기타 필요한 사항을 규정함을 목적으로 합니다.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle(isDark, '제2조 (정의)'),
                  _buildParagraph(isDark,
                    '1. \'펀딩\'이라 함은 크리에이터의 특정 프로젝트에 대한 자금조달을 위해 후원자로부터 펀딩금을 모집하고, '
                    '성공 시 리워드를 제공하는 보상형 크라우드 펀딩 서비스를 의미합니다.\n'
                    '2. \'크리에이터\'라 함은 펀딩을 개설하여 자금을 모집하는 회원을 의미합니다.\n'
                    '3. \'후원자\'라 함은 펀딩에 참여하여 펀딩금을 지급하는 회원을 의미합니다.\n'
                    '4. \'리워드\'라 함은 펀딩 성공 시 크리에이터가 후원자에게 제공하기로 약속한 재화 또는 서비스를 의미합니다.\n'
                    '5. \'목표금액\'이라 함은 펀딩 성공을 위해 설정된 최소 모집 금액을 의미합니다.\n'
                    '6. \'펀딩기간\'이라 함은 펀딩 시작일부터 종료일까지의 기간을 의미합니다.',
                  ),

                  const SizedBox(height: 24),

                  // Chapter 2
                  _buildChapterTitle(isDark, '제2장 펀딩 서비스'),
                  const SizedBox(height: 16),
                  _buildSectionTitle(isDark, '제3조 (회사의 의무)'),
                  _buildParagraph(isDark,
                    '① 회사는 펀딩 및 리워드에 관한 세부 내용을 서비스에 게시합니다.\n'
                    '② 회사는 펀딩 중개 플랫폼으로서 크리에이터와 후원자 간의 거래를 중개하며, 리워드 제공의 최종 책임은 크리에이터에게 있습니다.\n'
                    '③ 회사는 펀딩 개설, 운영과 관련하여 관련 법규를 준수합니다.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle(isDark, '제4조 (크리에이터의 의무)'),
                  _buildParagraph(isDark,
                    '① 크리에이터는 펀딩 정보를 정확하고 성실하게 작성해야 합니다.\n'
                    '② 크리에이터는 펀딩 성공 시 약속한 리워드를 성실히 제공해야 합니다.\n'
                    '③ 크리에이터는 리워드 제공이 불가능하거나 지연될 경우, 후원자에게 즉시 통지해야 합니다.\n'
                    '④ 크리에이터는 허위 정보 게재, 사기적 펀딩 개설 등 부정행위를 해서는 안 됩니다.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle(isDark, '제5조 (후원자의 의무)'),
                  _buildParagraph(isDark,
                    '① 후원자는 본인의 판단에 따라 펀딩 참여 여부를 결정합니다.\n'
                    '② 후원자는 펀딩 참여 전 목적, 기간, 목표금액, 리워드 내용을 충분히 확인해야 합니다.\n'
                    '③ 펀딩기간 종료 후에는 임의로 취소하거나 반환을 요청할 수 없습니다. (단, 제8조 해당 시 예외)',
                  ),

                  const SizedBox(height: 24),

                  // Chapter 3
                  _buildChapterTitle(isDark, '제3장 결제 및 환불'),
                  const SizedBox(height: 16),
                  _buildSectionTitle(isDark, '제6조 (결제)'),
                  _buildParagraph(isDark,
                    '① 펀딩은 원화(KRW)로 결제합니다. (DT 결제 미지원)\n'
                    '② 결제 수단: 신용/체크카드, 계좌이체, 간편결제(카카오페이, 네이버페이 등)\n'
                    '③ 펀딩기간 종료 전 결제 취소 또는 환불 요청이 가능합니다.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle(isDark, '제7조 (펀딩 종료 및 후속 조치)'),
                  _buildParagraph(isDark,
                    '① 펀딩 성공: 목표금액 이상 모집 시, 크리에이터가 리워드를 제공합니다.\n'
                    '② 펀딩 실패: 목표금액 미달 시, 종료일로부터 20영업일 이내 자동 환불 처리됩니다.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle(isDark, '제8조 (환불 사유)'),
                  _buildInfoBox(isDark,
                    '다음 사유에 해당하는 경우 환불됩니다:\n\n'
                    '1. 목표금액 미달로 펀딩 실패\n'
                    '2. 리워드 제작에 법적 문제 발생\n'
                    '3. 리워드가 게시 내용과 현저히 상이\n'
                    '4. 리워드가 정상 작동하지 않음\n'
                    '5. 크리에이터 리워드 제공 의무 불이행\n\n'
                    '환불은 신청일로부터 7영업일 이내 처리됩니다.',
                  ),

                  const SizedBox(height: 24),

                  // Chapter 4
                  _buildChapterTitle(isDark, '제4장 책임 및 면책'),
                  const SizedBox(height: 16),
                  _buildParagraph(isDark,
                    '① 회사: 펀딩 중개 플랫폼으로서 안전한 거래 진행을 위해 노력합니다. 리워드의 품질, 배송 등 최종 책임은 크리에이터에게 있습니다.\n'
                    '② 크리에이터: 펀딩 정보의 정확성과 리워드 제공에 대한 책임을 집니다.\n'
                    '③ 후원자: 본인의 판단에 따라 펀딩에 참여하며, 충분한 정보 확인 후 결제해야 합니다.',
                  ),

                  const SizedBox(height: 24),

                  // Footer
                  Text(
                    '부칙\n'
                    '• 본 약관은 2026년 02월 09일부터 시행합니다.\n'
                    '• 본 약관에서 정하지 않은 사항은 UNO A 통합 이용약관에 따릅니다.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
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
        '시행일: 2026년 02월 09일',
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildChapterTitle(bool isDark, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primary100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.primary700,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(bool isDark, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
        ),
      ),
    );
  }

  Widget _buildParagraph(bool isDark, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.7,
          color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
        ),
      ),
    );
  }

  Widget _buildInfoBox(bool isDark, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary100,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.7,
          color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
        ),
      ),
    );
  }
}
