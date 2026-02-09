import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';

/// 개인정보처리방침 화면
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    '개인정보처리방침',
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
                  const SizedBox(height: 16),
                  Text(
                    'UNO A(이하 "회사")는 이용자의 개인정보를 중요시하며, '
                    '「개인정보 보호법」 등 관련 법령을 준수합니다.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark ? AppColors.textDark : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildArticle(isDark, '제1조 (수집하는 개인정보 항목)', '''회사는 서비스 제공을 위해 다음의 개인정보를 수집합니다.

[필수 수집 항목]
• 이메일 주소, 비밀번호, 닉네임
• 서비스 이용 기록, 접속 로그, 기기 정보

[선택 수집 항목]
• 프로필 사진, 생년월일
• 결제 정보 (결제 시)

[자동 수집 항목]
• 기기 식별자, OS 버전, 앱 버전
• 접속 IP, 접속 일시, 서비스 이용 기록'''),
                  _buildArticle(isDark, '제2조 (개인정보의 수집·이용 목적)', '''회사는 수집한 개인정보를 다음의 목적으로 이용합니다.

• 회원 가입 및 관리: 본인 확인, 서비스 부정 이용 방지
• 서비스 제공: 콘텐츠 제공, 구독 관리, 채팅 기능, DT 거래 처리
• 결제 처리: 유료 서비스 결제, 환불 처리, 정산
• 고객 지원: 문의 응대, 공지사항 전달, 분쟁 처리
• 서비스 개선: 이용 통계 분석, 서비스 개선 및 개발'''),
                  _buildArticle(isDark, '제3조 (개인정보의 보유 및 이용 기간)', '''회사는 개인정보 수집·이용 목적이 달성된 후에는 해당 정보를 지체 없이 파기합니다.
단, 관련 법령에 의해 보존할 필요가 있는 경우 해당 기간 동안 보관합니다.

• 계약 또는 청약철회에 관한 기록: 5년 (전자상거래법)
• 대금 결제 및 재화 등의 공급에 관한 기록: 5년 (전자상거래법)
• 소비자 불만 또는 분쟁 처리에 관한 기록: 3년 (전자상거래법)
• 접속 로그: 3개월 (통신비밀보호법)'''),
                  _buildArticle(isDark, '제4조 (개인정보의 제3자 제공)', '''회사는 원칙적으로 이용자의 동의 없이 개인정보를 제3자에게 제공하지 않습니다.
다만, 다음의 경우에는 예외로 합니다.

• 이용자가 사전에 동의한 경우
• 법령에 따라 수사기관의 요청이 있는 경우
• 서비스 제공을 위해 필요한 경우 (결제 대행사 등)

위탁 처리되는 경우 위탁 업체 및 위탁 업무 내용을 공개합니다.'''),
                  _buildArticle(isDark, '제5조 (개인정보의 파기)', '''회사는 개인정보 보유 기간이 경과하거나 처리 목적이 달성된 경우 지체 없이 해당 개인정보를 파기합니다.

• 전자적 파일: 복원이 불가능한 방법으로 영구 삭제
• 종이 문서: 분쇄기로 분쇄하거나 소각'''),
                  _buildArticle(isDark, '제6조 (이용자의 권리·의무)', '''이용자는 다음의 권리를 행사할 수 있습니다.

• 개인정보 열람, 정정, 삭제, 처리 정지를 요청할 수 있습니다.
• 회원 탈퇴를 통해 개인정보 삭제를 요청할 수 있습니다.
• 14세 미만 아동의 경우 법정대리인의 동의가 필요합니다.

권리 행사는 앱 내 설정 또는 고객센터를 통해 가능합니다.'''),
                  _buildArticle(isDark, '제7조 (개인정보 보호책임자)', '''회사는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 이용자의 불만 처리 및 피해 구제를 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.

• 개인정보 보호책임자: UNO A 개인정보보호팀
• 이메일: privacy@unoa.app
• 문의: 앱 내 [설정 > 고객센터] 또는 이메일

기타 개인정보 침해 신고·상담은 아래 기관에 문의하실 수 있습니다.
• 개인정보침해 신고센터 (privacy.kisa.or.kr / 국번 없이 118)
• 개인정보 분쟁조정위원회 (kopico.go.kr / 1833-6972)'''),
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
