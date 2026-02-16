import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';

/// DT 이용약관 화면
/// DT = 디지털 이용권 정의, 법적 성격, 구매, 사용, 환불, 유효기간, 금지행위, 기타
/// P0.3 필수 문장 포함: 제3자 결제 차단 + 정산 성격 명시
class DtTermsScreen extends StatelessWidget {
  const DtTermsScreen({super.key});

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
                    'DT 이용약관',
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
                      '본 약관은 UNO A(이하 "회사")가 서비스 내에서 제공하는 DT(디지털 이용권)의 '
                          '정의, 구매, 사용, 환불 및 소멸에 관한 사항을 규정함을 목적으로 합니다.'),
                  _buildArticle(isDark, '제2조 (DT의 정의 및 법적 성격)',
                      '''① DT(DreamTime)는 회사가 제공하는 서비스 전용 디지털 이용권입니다.

② DT는 현금, 예금, 유가증권 또는 법정화폐가 아닙니다.

③ DT는 회사가 제공하는 디지털 서비스 이용권이며, 크리에이터(제3자)에게 결제대금을 이전하거나 지급하는 수단이 아닙니다.

④ 크리에이터에 대한 정산은 소비자 결제대금의 전달이 아니라, 회사가 별도 기준으로 산정해 지급하는 광고용역비입니다.

⑤ DT는 양도, 현금화, 외부 거래가 불가하며, 이를 시도하는 행위는 서비스 이용 제한 사유가 됩니다.'''),
                  _buildArticle(isDark, '제3조 (DT 구매)',
                      '''① DT는 회사가 정한 결제수단을 통해 구매할 수 있습니다.

② DT 구매 시 별도의 수수료가 부과되지 않습니다.

③ DT 구매 금액은 회사가 서비스 내에서 공지하는 바에 따릅니다.

④ 회사는 프로모션에 따라 보너스 DT를 추가 지급할 수 있으며, 보너스 DT는 환불 대상에서 제외됩니다.'''),
                  _buildArticle(isDark, '제4조 (DT 사용)',
                      '''① DT는 서비스 내 디지털 콘텐츠 이용, 후원, 프리미엄 기능 이용 등에 사용할 수 있습니다.

② DT의 사용 범위는 회사가 서비스 내에서 정하며, 변경 시 사전 공지합니다.

③ DT 사용은 취소가 제한될 수 있으며, 구체적인 조건은 개별 서비스 안내를 따릅니다.'''),
                  _buildArticle(isDark, '제5조 (환불)',
                      '''① 구매 후 7일 이내, 미사용 DT에 대해 전액 환불을 요청할 수 있습니다.

② 일부 사용한 경우, 미사용 잔량에 대해 부분환불이 가능합니다.

③ "사용 개시"란 DT를 디지털 상품 또는 서비스 구매에 1회라도 사용한 시점을 말합니다.

④ 보너스 DT 및 프로모션 DT는 환불 대상에서 제외됩니다.

⑤ 환불은 요청일로부터 3영업일 이내에 처리되며, 원결제 수단으로 환급됩니다.

⑥ 회사가 환불 기한을 초과하는 경우, 대통령령이 정하는 지연이자율에 따른 지연배상금을 지급합니다.'''),
                  _buildArticle(
                      isDark, '제6조 (유효기간 및 소멸)', '''① DT의 유효기간은 구매일로부터 5년입니다.

② 유효기간 만료 60일 전 앱 내 알림을 통해 안내됩니다.

③ 유효기간이 경과한 DT는 자동 소멸되며, 소멸된 DT는 복원되지 않습니다.

④ 회원 탈퇴 시 환불 가능 범위의 DT는 환불 안내 후 처리되며, 환불이 불가한 DT(보너스, 사용 개시분 등)는 소멸됩니다.'''),
                  _buildArticle(isDark, '제7조 (금지행위)',
                      '''다음 각 호의 행위를 금지하며, 위반 시 서비스 이용이 제한되고 보유 DT가 동결될 수 있습니다.

1. DT를 현금, 재화, 유가증권 등으로 환전 또는 현금화하는 행위
2. DT를 서비스 외부에서 거래, 매매, 양도 또는 담보로 제공하는 행위
3. DT를 이용한 사행행위 또는 도박행위
4. 허위 환불 신청 또는 부당한 차지백을 시도하는 행위
5. 부정한 방법으로 DT를 취득하는 행위
6. 기타 서비스의 정상적인 운영을 방해하는 행위'''),
                  _buildArticle(isDark, '제8조 (기타)',
                      '''① 본 약관에서 정하지 않은 사항은 통합 이용약관 및 관련 법령에 따릅니다.

② 본 약관과 통합 이용약관이 상충하는 경우, DT에 관한 사항은 본 약관이 우선합니다.

③ 회사는 본 약관을 변경할 수 있으며, 변경 시 적용일자 및 변경 사유를 명시하여 최소 7일 전에 공지합니다.'''),
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
        '최종 수정일: 2026년 02월 16일 v1.0',
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
