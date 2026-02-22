import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/business_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/payment_service.dart';
import '../../providers/repository_providers.dart';
import '../../shared/widgets/auth_gate.dart';
import 'funding_result_screen.dart';

/// Checkout screen for funding pledge (KRW 결제)
///
/// 펀딩은 KRW 전용 - DT 지갑과 완전히 분리
/// 결제 플로우: PortOne SDK → 결제완료 → Edge Function 검증 → pledge 생성
class FundingCheckoutScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> campaign;
  final Map<String, dynamic> tier;

  const FundingCheckoutScreen({
    super.key,
    required this.campaign,
    required this.tier,
  });

  @override
  ConsumerState<FundingCheckoutScreen> createState() =>
      _FundingCheckoutScreenState();
}

class _FundingCheckoutScreenState extends ConsumerState<FundingCheckoutScreen> {
  final _messageController = TextEditingController();
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _refundRecognizer;

  bool _isAnonymous = false;
  bool _agreeTerms = false;
  bool _isLoading = false;
  String _selectedPaymentMethod =
      'card'; // card, bank_transfer, virtual_account

  // KRW 결제: DT 지갑이 아니라 원화 결제
  // ⚠️ 참고: 실제 결제 금액은 서버(Edge Function)에서 캠페인/티어 DB 조회 후 결정됨.
  // 이 값은 UI 표시용이며, 서버에서 최종 금액을 검증합니다.
  int get _totalAmount {
    final amount = widget.tier['price_krw'] as int? ??
        widget.tier['price_dt'] as int? ??
        0;
    if (amount <= 0) return 0;
    return amount;
  }

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push('/settings/funding-terms');
    _refundRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push('/settings/refund-policy');
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _refundRecognizer.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitPledge() async {
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('펀딩 이용약관에 동의해주세요')),
      );
      return;
    }

    AuthGate.guardAction(
      context,
      reason: '펀딩에 참여하려면 로그인이 필요해요',
      onAuthenticated: () => _initiateKrwPayment(),
    );
  }

  /// KRW 결제 시작 (PortOne SDK 연동)
  Future<void> _initiateKrwPayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authProvider);
      final userId = authState is AuthAuthenticated ? authState.user.id : null;
      if (userId == null) throw Exception('로그인이 필요합니다');

      if (_totalAmount <= 0) {
        throw Exception('유효하지 않은 결제 금액입니다');
      }

      // 주문번호 생성 (가맹점 고유)
      final orderId =
          'FUND_${widget.campaign['id']}_${DateTime.now().millisecondsSinceEpoch}';
      final idempotencyKey =
          'pledge:${userId}_${widget.campaign['id']}_${widget.tier['id'] ?? 'no_tier'}_${DateTime.now().millisecondsSinceEpoch}';

      // Request payment via payment service (handles demo vs production)
      final paymentService = ref.read(paymentServiceProvider);
      final paymentResult = await paymentService.requestPayment(
        PaymentRequest(
          merchantUid: orderId,
          name: '${widget.campaign['title']} - ${widget.tier['title']}',
          amount: _totalAmount,
          payMethod: _selectedPaymentMethod,
        ),
      );

      if (!paymentResult.success) {
        throw Exception(paymentResult.errorMessage ?? '결제에 실패했습니다');
      }

      final paymentId = paymentResult.paymentId ?? orderId;

      // Edge Function으로 결제 검증 + pledge 생성
      final data = await ref.read(fundingRepositoryProvider).submitPledge(
            campaignId: widget.campaign['id'] as String,
            tierId: widget.tier['id'] as String,
            amountKrw: widget.tier['price_krw'] as int? ??
                widget.tier['price_dt'] as int? ??
                0,
            paymentOrderId: orderId,
            paymentMethod: _selectedPaymentMethod,
            pgTransactionId: paymentId,
            idempotencyKey: idempotencyKey,
            isAnonymous: _isAnonymous,
            supportMessage: _messageController.text.isNotEmpty
                ? _messageController.text
                : null,
          );

      if (data['pledge_id'] != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FundingResultScreen(
              success: true,
              campaign: widget.campaign,
              tier: widget.tier,
              totalAmount: _totalAmount,
              pledgeId: data['pledge_id'] as String?,
            ),
          ),
        );
      } else {
        throw Exception(data['error'] ?? '후원에 실패했습니다');
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage = '후원 중 오류가 발생했습니다';
      final errorStr = e.toString();
      if (errorStr.contains('Payment verification failed') ||
          errorStr.contains('결제 검증')) {
        errorMessage = '결제 검증에 실패했습니다. 다시 시도해주세요.';
      } else if (errorStr.contains('sold out') || errorStr.contains('품절')) {
        errorMessage = '선택한 리워드가 품절되었습니다';
      } else if (errorStr.contains('Campaign is not active')) {
        errorMessage = '캠페인이 진행 중이 아닙니다';
      } else if (errorStr.contains('Campaign has ended')) {
        errorMessage = '캠페인이 종료되었습니다';
      } else if (errorStr.contains('Cannot pledge to your own')) {
        errorMessage = '본인 캠페인에는 후원할 수 없습니다';
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FundingResultScreen(
            success: false,
            campaign: widget.campaign,
            tier: widget.tier,
            totalAmount: _totalAmount,
            errorMessage: errorMessage,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        title: Text(
          '후원 확인',
          style: TextStyle(
            color: isDark ? AppColors.textDark : AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.textDark : AppColors.text,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Order summary
                _buildSection(
                  isDark,
                  '후원 내역',
                  Column(
                    children: [
                      _buildSummaryRow(
                        isDark,
                        widget.tier['title'] ?? '리워드',
                        '${_formatKrw(widget.tier['price_krw'] ?? widget.tier['price_dt'] ?? 0)}원',
                      ),
                      const Divider(height: 24),
                      _buildSummaryRow(
                        isDark,
                        '총 후원금액',
                        '${_formatKrw(_totalAmount)}원',
                        isBold: true,
                        valueColor: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceAltDark
                              : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              isDark,
                              '크리에이터 수령액 (${BusinessConfig.creatorPayoutPercent.toInt()}%)',
                              '${_formatKrw((_totalAmount * BusinessConfig.creatorPayoutPercent / 100).round())}원',
                              valueColor: AppColors.success,
                            ),
                            const SizedBox(height: 4),
                            _buildSummaryRow(
                              isDark,
                              '플랫폼 수수료 (${BusinessConfig.platformCommissionPercent.toInt()}%)',
                              '${_formatKrw((_totalAmount * BusinessConfig.platformCommissionPercent / 100).round())}원',
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '* 표시된 수수료는 정산 시 적용됩니다',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Payment method selection (KRW)
                _buildSection(
                  isDark,
                  '결제 수단',
                  Column(
                    children: [
                      _buildPaymentMethodTile(
                        isDark,
                        icon: Icons.credit_card_rounded,
                        title: '카드 결제',
                        subtitle: '신용카드/체크카드',
                        value: 'card',
                      ),
                      const SizedBox(height: 8),
                      _buildPaymentMethodTile(
                        isDark,
                        icon: Icons.account_balance_rounded,
                        title: '계좌이체',
                        subtitle: '실시간 계좌이체',
                        value: 'bank_transfer',
                      ),
                      const SizedBox(height: 8),
                      _buildPaymentMethodTile(
                        isDark,
                        icon: Icons.receipt_long_rounded,
                        title: '가상계좌',
                        subtitle: '무통장입금',
                        value: 'virtual_account',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Support message
                _buildSection(
                  isDark,
                  '응원 메시지 (선택)',
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText: '아티스트에게 응원 메시지를 남겨주세요',
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMuted,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              isDark ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              isDark ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.surfaceAltDark
                          : AppColors.surfaceAlt,
                    ),
                    style: TextStyle(
                      color: isDark ? AppColors.textDark : AppColors.text,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Anonymous toggle
                _buildSection(
                  isDark,
                  '',
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '익명으로 후원',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.textDark
                                    : AppColors.text,
                              ),
                            ),
                            Text(
                              '후원자 목록에 닉네임이 표시되지 않습니다',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isAnonymous,
                        onChanged: (value) {
                          setState(() {
                            _isAnonymous = value;
                          });
                        },
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Terms agreement
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _agreeTerms = !_agreeTerms;
                    });
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreeTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeTerms = value ?? false;
                          });
                        },
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text.rich(
                            TextSpan(
                              text: '펀딩 이용약관',
                              recognizer: _termsRecognizer,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                              children: [
                                TextSpan(
                                  text: ' 및 ',
                                  recognizer: null,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMuted,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                TextSpan(
                                  text: '환불 정책',
                                  recognizer: _refundRecognizer,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(
                                  text: '에 동의합니다',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMuted,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // KRW 결제 안내
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.verified.withValues(alpha: 0.1)
                        : AppColors.verified.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.verified.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppColors.verified),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '펀딩 결제는 원화(KRW)로 진행되며, DT 잔액과는 별개입니다.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Submit button
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isLoading || !_agreeTerms) ? null : _submitPledge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: AppColors.onPrimary,
                  disabledBackgroundColor:
                      isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        '${_formatKrw(_totalAmount)}원 결제하기',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.border),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.textMutedDark : AppColors.textMuted),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textDark : AppColors.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(bool isDark, String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    bool isDark,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: isDark ? AppColors.textDark : AppColors.text,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? (isDark ? AppColors.textDark : AppColors.text),
          ),
        ),
      ],
    );
  }

  /// 원화 포맷팅 (1,000 단위 콤마)
  String _formatKrw(int amount) {
    if (amount < 0) return '-${_formatKrw(-amount)}';
    if (amount < 1000) return amount.toString();
    final result = StringBuffer();
    final str = amount.toString();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) result.write(',');
      result.write(str[i]);
    }
    return result.toString();
  }
}
