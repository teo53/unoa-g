import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';

/// 이용약관 화면
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: isDark ? AppColors.textDark : AppColors.text,
                  ),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Text(
                    '이용약관',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDark : AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // 본문
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLastUpdated(isDark),
                  const SizedBox(height: 24),
                  _buildArticle(
                      isDark,
                      '제1조 (목적)',
                      '본 약관은 UNO A(이하 "회사")가 제공하는 모바일 애플리케이션 서비스(이하 "서비스")의 이용조건 및 절차, '
                          '회사와 이용자 간의 권리·의무 및 책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다.'),
                  _buildArticle(
                      isDark, '제2조 (용어의 정의)', '''본 약관에서 사용하는 용어의 정의는 다음과 같습니다.

1. "서비스"란 회사가 제공하는 UNO A 플랫폼 및 관련 제반 서비스를 의미합니다.
2. "이용자"란 본 약관에 따라 서비스를 이용하는 회원 및 비회원을 말합니다.
3. "크리에이터"란 서비스를 통해 콘텐츠를 제작·배포하고 팬과 소통하며, 서비스의 활성화 및 홍보에 기여하는 이용자를 말합니다.
4. "구독자(팬)"란 크리에이터의 채널을 구독하고 메시지를 수신하는 이용자를 말합니다.
5. "DT(DreamTime)"란 서비스 내에서 사용되는 서비스 전용 디지털 이용권으로, 현금 또는 법정화폐가 아닙니다.
6. "펀딩"이란 크리에이터가 특정 목표를 설정하고 팬의 후원을 모집하는 기능을 말합니다.'''),
                  _buildArticle(isDark, '제3조 (약관의 효력 및 변경)',
                      '''① 본 약관은 서비스 화면에 게시하거나 기타의 방법으로 이용자에게 공지함으로써 효력이 발생합니다.
② 회사는 관련 법령을 위배하지 않는 범위에서 본 약관을 변경할 수 있으며, 변경 시 적용일자 및 변경 사유를 명시하여 최소 7일 전에 공지합니다.
③ 이용자가 변경된 약관에 동의하지 않는 경우 서비스 이용을 중단하고 탈퇴할 수 있습니다.'''),
                  _buildArticle(isDark, '제4조 (계정 관리)',
                      '''① 이용자는 회원가입 시 정확한 정보를 제공해야 하며, 변경 사항이 있을 경우 즉시 수정해야 합니다.
② 계정의 관리 책임은 이용자 본인에게 있으며, 제3자에게 이용을 허락해서는 안 됩니다.
③ 이용자는 계정 정보가 도용되거나 부정하게 사용된 사실을 발견한 경우 즉시 회사에 통보해야 합니다.
④ 회사는 이용자가 서비스 이용을 원하지 않을 경우 계정 삭제를 요청할 수 있는 기능을 제공합니다.'''),
                  _buildArticle(isDark, '제5조 (DT 이용 및 결제)',
                      '''① DT는 서비스 내에서만 사용 가능한 서비스 전용 디지털 이용권이며, 현금 또는 법정화폐가 아닙니다.
② DT 구매 시 별도의 수수료가 부과되지 않습니다.
③ DT의 환불은 관련 법령 및 회사의 환불 정책에 따릅니다.
④ 미사용 DT는 최종 이용일로부터 5년이 경과한 경우 관련 법령에 따라 소멸될 수 있습니다.
⑤ DT를 이용한 후원, 선물 등은 취소가 제한될 수 있으며, 구체적인 조건은 개별 서비스 안내를 따릅니다.'''),
                  _buildArticle(isDark, '제6조 (콘텐츠 정책)',
                      '''① 이용자는 서비스 내에서 다음 각 호에 해당하는 콘텐츠를 게시할 수 없습니다.
  1. 타인의 명예를 훼손하거나 불이익을 주는 내용
  2. 음란·폭력적이거나 공서양속에 반하는 내용
  3. 범죄와 결부된다고 객관적으로 인정되는 내용
  4. 타인의 저작권, 초상권 등 권리를 침해하는 내용
  5. 기타 관련 법령에 위배되는 내용
② 회사는 위 사항에 해당하는 콘텐츠를 사전 통지 없이 삭제하거나 이용을 제한할 수 있습니다.'''),
                  _buildArticle(isDark, '제7조 (서비스 중단 및 책임 제한)',
                      '''① 회사는 다음 각 호의 경우 서비스 제공을 일시적으로 중단할 수 있습니다.
  1. 시스템 정기점검, 서버 증설·교체 등 기술적 필요
  2. 전기통신사업법에 규정된 기간통신사업자의 서비스 중단
  3. 천재지변, 국가비상사태 등 불가항력적 사유
② 회사는 무료로 제공되는 서비스에 대해서는 손해배상을 하지 않습니다.
③ 회사는 이용자의 귀책사유로 인한 서비스 이용 장애에 대해 책임을 지지 않습니다.'''),
                  _buildArticle(isDark, '제8조 (준거법 및 관할)',
                      '''① 본 약관의 해석 및 적용에 관하여는 대한민국 법률을 적용합니다.
② 서비스 이용과 관련하여 분쟁이 발생한 경우, 당사자 간 합의에 의해 해결함을 원칙으로 합니다.
③ 합의가 이루어지지 않을 경우, 관할법원은 민사소송법에 따른 법원으로 합니다.'''),
                  const SizedBox(height: 40),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '최종 수정일: 2025년 1월 1일',
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildArticle(bool isDark, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textDark : AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? AppColors.textDark : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
