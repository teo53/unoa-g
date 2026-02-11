import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/accessibility_helper.dart';
import '../../shared/widgets/app_scaffold.dart';

/// 커뮤니티 가이드라인 및 모더레이션 정책 화면
class ModerationPolicyScreen extends StatelessWidget {
  const ModerationPolicyScreen({super.key});

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
                    '커뮤니티 가이드라인',
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
                  _buildIntro(isDark),
                  const SizedBox(height: 24),
                  _buildSection(isDark, '제1조 금지 행위', [
                    '1. 스팸, 광고, 홍보성 반복 메시지 전송',
                    '2. 욕설, 비방, 혐오 표현, 차별적 발언',
                    '3. 성인물, 폭력적 콘텐츠, 불법 콘텐츠 게시',
                    '4. 사기, 피싱, 허위 정보 유포',
                    '5. 타인의 저작권 침해 콘텐츠 배포',
                    '6. 타인의 개인정보 무단 공개',
                    '7. 크리에이터 사칭 또는 허위 계정 생성',
                    '8. 서비스 운영을 방해하는 행위',
                  ]),
                  const SizedBox(height: 20),
                  _buildSection(isDark, '제2조 신고 절차', [
                    '1. 메시지 길게 누르기 → "신고하기" 선택',
                    '2. 신고 사유 선택 (스팸/괴롭힘/부적절/사기/저작권/기타)',
                    '3. 추가 설명 입력 (선택사항, 최대 500자)',
                    '4. 신고 접수 완료 → 운영팀 검토 진행',
                  ]),
                  const SizedBox(height: 20),
                  _buildSection(isDark, '제3조 제재 기준', [
                    '1. 경고: 경미한 위반 시 경고 조치',
                    '2. 일시 이용 제한: 반복 위반 시 7일~30일 이용 정지',
                    '3. 영구 이용 정지: 심각한 위반 또는 3회 이상 반복 위반',
                    '4. 콘텐츠 삭제: 위반 콘텐츠 즉시 삭제',
                    '5. 법적 조치: 불법 행위 시 수사기관 신고 및 법적 대응',
                  ]),
                  const SizedBox(height: 20),
                  _buildSection(isDark, '제4조 이의 신청', [
                    '1. 제재 통보일로부터 14일 이내 이의 신청 가능',
                    '2. 고객센터(support@unoa.app)로 이의 사유 제출',
                    '3. 운영팀 검토 후 7영업일 이내 결과 통보',
                    '4. 이의 인정 시 제재 해제 또는 변경',
                  ]),
                  const SizedBox(height: 20),
                  _buildSection(isDark, '제5조 보호 조치', [
                    '1. 신고자 정보는 비공개 처리됩니다',
                    '2. 허위 신고 시 신고자에게 제재가 적용될 수 있습니다',
                    '3. 긴급 상황(자해/위협 등) 발견 시 즉시 신고해주세요',
                    '4. 차단 기능을 통해 특정 사용자의 메시지를 차단할 수 있습니다',
                  ]),
                  const SizedBox(height: 20),
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

  Widget _buildIntro(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.primary100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: (isDark ? Colors.white : AppColors.primary500)
                .withValues(alpha: 0.12)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined,
                  color: AppColors.primary600, size: 24),
              SizedBox(width: 8),
              Text(
                '안전한 커뮤니티를 위해',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'UNO A는 모든 이용자가 안전하고 즐겁게 소통할 수 있는 환경을 만들기 위해 '
            '커뮤니티 가이드라인을 운영합니다. 아래 규칙을 준수해주세요.',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.primary700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(bool isDark, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
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
            '문의 및 신고',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '이메일: support@unoa.app\n'
            '운영시간: 평일 10:00~18:00 (공휴일 제외)\n'
            '긴급 신고는 24시간 접수 가능합니다.',
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
