import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/business_config.dart';
import '../../core/utils/accessibility_helper.dart';
import '../../shared/widgets/app_scaffold.dart';

/// 수수료 정책 화면
class FeePolicyScreen extends StatelessWidget {
  const FeePolicyScreen({super.key});

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
                    '수수료 정책',
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

                  // Section 1: 팬(이용자) 수수료
                  _buildSectionTitle(isDark, '제1조 이용자(팬) 수수료'),
                  const SizedBox(height: 12),
                  _buildFeeTable(isDark, [
                    const _FeeRow('DT 구매', '무료', '결제 금액 = 구매 금액'),
                    const _FeeRow('구독 결제', '무료', '구독료 외 추가 수수료 없음'),
                    const _FeeRow('펀딩 참여', '무료', '후원 금액 외 추가 수수료 없음'),
                    const _FeeRow('DT 환불', '무료', '환불 수수료 없음'),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    '※ 이용자에게는 별도의 수수료가 부과되지 않습니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMuted,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Section 2: 크리에이터 수수료
                  _buildSectionTitle(isDark, '제2조 크리에이터 수수료'),
                  const SizedBox(height: 12),
                  _buildFeeTable(isDark, [
                    _FeeRow(
                        '플랫폼 수수료',
                        '${BusinessConfig.platformCommissionPercent.toInt()}%',
                        '크리에이터 수익에서 차감'),
                    _FeeRow(
                        '크리에이터 정산',
                        '${BusinessConfig.creatorPayoutPercent.toInt()}%',
                        '수익의 ${BusinessConfig.creatorPayoutPercent.toInt()}% 지급'),
                    const _FeeRow('원천징수세', '3.3%', '기타소득세 3% + 지방소득세 0.3%'),
                    const _FeeRow('최소 정산금액', '₩10,000', '미만 시 익월 이월'),
                  ]),

                  const SizedBox(height: 24),

                  // Section 3: 정산 기준
                  _buildSectionTitle(isDark, '제3조 정산 기준'),
                  const SizedBox(height: 12),
                  _buildArticle(isDark, [
                    '① 정산 주기: 매월 1회 (전월 수익 기준)',
                    '② 정산일: 매월 10일 (영업일 기준)',
                    '③ 정산 대상 수익:',
                    '   • 후원(DT 도네이션)',
                    '   • 유료 답장',
                    '   • 프라이빗 카드',
                    '   • 펀딩 (성공 캠페인 한정)',
                    '④ 정산 계산: 총 수익 - 플랫폼 수수료(${BusinessConfig.platformCommissionPercent.toInt()}%) - 원천징수세(3.3%)',
                    '⑤ 정산금은 등록된 계좌로 입금됩니다.',
                    '',
                    '※ 크리에이터 정산금은 서비스 홍보 활동에 대한 용역 대가로서 지급됩니다.',
                  ]),

                  const SizedBox(height: 24),

                  // Section 4: 결제 수수료 안내
                  _buildSectionTitle(isDark, '제4조 결제 수단별 안내'),
                  const SizedBox(height: 12),
                  _buildArticle(isDark, [
                    '① 신용카드 / 체크카드: 별도 수수료 없음',
                    '② 간편결제 (카카오페이, 네이버페이 등): 별도 수수료 없음',
                    '③ 계좌이체: 별도 수수료 없음',
                    '④ 결제 취소 시 환불 수수료: 없음',
                    '',
                    '※ PG(결제대행) 수수료는 플랫폼이 부담하며, 이용자 및 크리에이터에게 전가되지 않습니다.',
                  ]),

                  const SizedBox(height: 24),

                  // Footer
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
                          '문의',
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
                          '수수료 관련 문의: support@unoa.app\n'
                          '크리에이터 정산 문의: creator@unoa.app',
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
        '최종 수정일: 2026년 02월 09일',
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

  Widget _buildFeeTable(bool isDark, List<_FeeRow> rows) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        row.item,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: Text(
                        row.fee,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.note,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (index < rows.length - 1)
                Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
            ],
          );
        }).toList(),
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

class _FeeRow {
  final String item;
  final String fee;
  final String note;

  const _FeeRow(this.item, this.fee, this.note);
}
