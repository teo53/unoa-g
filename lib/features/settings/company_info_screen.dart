import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';

/// 사업자 정보 화면
class CompanyInfoScreen extends StatelessWidget {
  const CompanyInfoScreen({super.key});

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
                    '사업자 정보',
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
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '전자상거래 등에서의 소비자보호에 관한 법률에 의한 사업자 정보',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow(isDark, '상호(법인명)', '주식회사 언도어엔터테인먼트'),
                    _buildInfoRow(isDark, '서비스명', 'UNO A (유노에이)'),
                    _buildInfoRow(isDark, '대표자', '권해성'),
                    _buildInfoRow(isDark, '사업자등록번호', '487-86-03682'),
                    _buildInfoRow(isDark, '법인등록번호', '110111-0938047'),
                    _buildInfoRow(isDark, '통신판매업신고', '(신고 진행 중)'),
                    _buildInfoRow(isDark, '개업일', '2025년 09월 26일'),
                    _buildInfoRow(isDark, '업태 / 종목', '전문서비스업 / 매니저업, 광고대행업'),
                    _buildInfoRow(isDark, '사업장 소재지',
                        '서울특별시 강남구 논현로 509, 9층 이노워크센터 801-27호(역삼동, 송암II빌딩)'),
                    _buildInfoRow(isDark, '고객센터', 'support@unoa.app'),
                    _buildInfoRow(isDark, '이메일', 'contact@unoa.app'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textDark : AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
