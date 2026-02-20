import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/private_card_provider.dart';
import 'widgets/card_editor_step.dart';
import 'widgets/fan_filter_step.dart';
import 'widgets/card_preview_step.dart';

/// Full-screen 3-step compose screen for private cards
/// Step 1: Card content (design + text + media)
/// Step 2: Fan selection (filter-based)
/// Step 3: Preview & Send
class PrivateCardComposeScreen extends ConsumerStatefulWidget {
  const PrivateCardComposeScreen({super.key});

  @override
  ConsumerState<PrivateCardComposeScreen> createState() =>
      _PrivateCardComposeScreenState();
}

class _PrivateCardComposeScreenState
    extends ConsumerState<PrivateCardComposeScreen> {
  late PageController _pageController;
  bool _hasSentSuccessfully = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    ref.read(privateCardComposeProvider.notifier).goToStep(step);
  }

  /// Check if there are unsaved changes
  bool _hasUnsavedChanges() {
    final state = ref.read(privateCardComposeProvider);
    return state.cardText.isNotEmpty ||
        state.selectedTemplateId != null ||
        state.selectedFanIds.isNotEmpty;
  }

  /// Show confirmation dialog before discarding changes
  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges() || _hasSentSuccessfully) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('작성 중인 카드가 있습니다'),
        content: const Text('나가면 작성 중인 내용이 사라집니다.\n정말 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('계속 작성'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('나가기', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final composeState = ref.watch(privateCardComposeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Handle send success
    if (composeState.isSent && !_hasSentSuccessfully) {
      _hasSentSuccessfully = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${composeState.selectedFanCount}명의 팬에게 카드가 전송되었습니다!'),
            backgroundColor: AppColors.vip,
            duration: const Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && context.mounted) context.pop();
        });
      });
    }

    // Handle error state
    if (composeState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(composeState.error!),
            backgroundColor: AppColors.danger,
            action: SnackBarAction(
              label: '다시 시도',
              textColor: Colors.white,
              onPressed: () {
                ref.read(privateCardComposeProvider.notifier).sendCard();
              },
            ),
          ),
        );
        ref.read(privateCardComposeProvider.notifier).clearError();
      });
    }

    return PopScope(
      canPop: !_hasUnsavedChanges() || _hasSentSuccessfully,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (shouldPop && mounted && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : AppColors.text,
            ),
            onPressed: () async {
              if (composeState.currentStep > 0) {
                _goToStep(composeState.currentStep - 1);
              } else {
                final shouldPop = await _confirmDiscard();
                if (shouldPop && mounted && context.mounted) {
                  context.pop();
                }
              }
            },
          ),
          title: Text(
            '프라이빗 카드 작성',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.text,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: _StepIndicator(
              currentStep: composeState.currentStep,
              onStepTap: (step) {
                // Only allow tapping to go back, not forward
                if (step < composeState.currentStep) {
                  _goToStep(step);
                }
              },
            ),
          ),
        ),
        body: Column(
          children: [
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  ref.read(privateCardComposeProvider.notifier).goToStep(page);
                },
                children: const [
                  CardEditorStep(),
                  FanFilterStep(),
                  CardPreviewStep(),
                ],
              ),
            ),

            // Bottom action bar
            _buildBottomBar(isDark, composeState),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark, PrivateCardComposeState state) {
    final isLastStep = state.currentStep == 2;
    final canProceed = state.currentStep == 0
        ? state.isStep1Valid
        : state.currentStep == 1
            ? state.isStep2Valid
            : state.isStep1Valid && state.isStep2Valid;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous button
          if (state.currentStep > 0)
            Expanded(
              child: GestureDetector(
                onTap: () => _goToStep(state.currentStep - 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '이전',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.text,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (state.currentStep > 0) const SizedBox(width: 12),

          // Next / Send button
          Expanded(
            flex: state.currentStep > 0 ? 2 : 1,
            child: GestureDetector(
              onTap: canProceed
                  ? () {
                      if (isLastStep) {
                        ref
                            .read(privateCardComposeProvider.notifier)
                            .sendCard();
                      } else {
                        _goToStep(state.currentStep + 1);
                      }
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: canProceed
                      ? AppColors.vip
                      : isDark
                          ? Colors.grey[800]
                          : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: state.isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isLastStep ? '전송하기' : '다음',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: canProceed
                                ? Colors.white
                                : isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[500],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step indicator showing progress (1 → 2 → 3)
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final Function(int) onStepTap;

  const _StepIndicator({
    required this.currentStep,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(5, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIndex < currentStep
                    ? AppColors.vip
                    : isDark
                        ? Colors.grey[700]
                        : Colors.grey[300],
              ),
            );
          }

          // Step circle
          final stepIndex = index ~/ 2;
          final isActive = stepIndex <= currentStep;
          final isCurrent = stepIndex == currentStep;

          return GestureDetector(
            onTap: () => onStepTap(stepIndex),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isCurrent ? 28 : 24,
                  height: isCurrent ? 28 : 24,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.vip
                        : isDark
                            ? Colors.grey[700]
                            : Colors.grey[300],
                    shape: BoxShape.circle,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.vip.withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${stepIndex + 1}',
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : isDark
                                ? Colors.grey[500]
                                : Colors.grey[500],
                        fontSize: isCurrent ? 13 : 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
