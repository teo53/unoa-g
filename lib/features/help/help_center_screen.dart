import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/search_field.dart';
import 'widgets/faq_answer_sheet.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

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
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const Expanded(
                  child: Text(
                    '고객센터',
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
                  // Search
                  const SearchField(hintText: '무엇을 도와드릴까요?'),

                  const SizedBox(height: 32),

                  // Quick Actions
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.chat_bubble_outline,
                          title: '1:1 문의',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('1:1 문의 기능 준비 중')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.headset_mic_outlined,
                          title: '전화 상담',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('전화 상담 기능 준비 중')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // FAQ Categories
                  Text(
                    '자주 묻는 질문',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 16),

                  const _FaqCategory(
                    icon: Icons.diamond_outlined,
                    title: 'DT 구매 및 사용',
                    questions: [
                      'DT는 어떻게 구매하나요?',
                      'DT 환불이 가능한가요?',
                      'DT 유효기간이 있나요?',
                    ],
                  ),

                  const _FaqCategory(
                    icon: Icons.card_membership_outlined,
                    title: '구독 관리',
                    questions: [
                      '구독을 해지하면 어떻게 되나요?',
                      '구독 등급을 변경할 수 있나요?',
                      '자동 갱신을 끄는 방법은?',
                    ],
                  ),

                  const _FaqCategory(
                    icon: Icons.chat_outlined,
                    title: '메시지 및 채팅',
                    questions: [
                      '메시지는 어떻게 보내나요?',
                      '아티스트 답장은 언제 오나요?',
                      '메시지 알림 설정은 어디서 하나요?',
                    ],
                  ),

                  const _FaqCategory(
                    icon: Icons.person_outline,
                    title: '계정 및 보안',
                    questions: [
                      '비밀번호를 잊어버렸어요',
                      '계정을 삭제하고 싶어요',
                      '로그인이 안 돼요',
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Contact Info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.surfaceDark : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '운영시간 안내',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _InfoRow(
                          label: '채팅 상담',
                          value: '평일 09:00 - 18:00',
                        ),
                        const SizedBox(height: 8),
                        const _InfoRow(
                          label: '전화 상담',
                          value: '평일 10:00 - 17:00',
                        ),
                        const SizedBox(height: 8),
                        const _InfoRow(
                          label: '이메일',
                          value: 'support@unoa.com',
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
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primary100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primary600,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqCategory extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> questions;

  const _FaqCategory({
    required this.icon,
    required this.title,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          children: questions
              .map(
                (q) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(
                    q,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color:
                        isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
                  ),
                  onTap: () {
                    FaqAnswerSheet.show(context, question: q);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
      ],
    );
  }
}
