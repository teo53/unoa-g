import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/business_config.dart';
import '../../shared/widgets/auth_gate.dart';
import 'funding_result_screen.dart';

/// Checkout screen for funding pledge
class FundingCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> campaign;
  final Map<String, dynamic> tier;
  final int extraSupport;

  const FundingCheckoutScreen({
    super.key,
    required this.campaign,
    required this.tier,
    required this.extraSupport,
  });

  @override
  State<FundingCheckoutScreen> createState() => _FundingCheckoutScreenState();
}

class _FundingCheckoutScreenState extends State<FundingCheckoutScreen> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();

  bool _isAnonymous = false;
  bool _agreeTerms = false;
  bool _isLoading = false;
  int? _walletBalance;

  int get _totalAmount => (widget.tier['price_dt'] as int? ?? 0) + widget.extraSupport;

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletBalance() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('wallets')
          .select('balance_dt')
          .eq('user_id', userId)
          .single();

      setState(() {
        _walletBalance = response['balance_dt'] as int?;
      });
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _submitPledge() async {
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('펀딩 이용약관에 동의해주세요')),
      );
      return;
    }

    if (_walletBalance != null && _walletBalance! < _totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DT 잔액이 부족합니다')),
      );
      return;
    }

    AuthGate.guardAction(
      context,
      reason: '펀딩에 참여하려면 로그인이 필요해요',
      onAuthenticated: () => _doSubmitPledge(),
    );
  }

  Future<void> _doSubmitPledge() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _supabase.functions.invoke(
        'funding-pledge',
        body: {
          'campaignId': widget.campaign['id'],
          'tierId': widget.tier['id'],
          'amountDt': widget.tier['price_dt'],
          'extraSupportDt': widget.extraSupport,
          'isAnonymous': _isAnonymous,
          'supportMessage': _messageController.text.isNotEmpty
              ? _messageController.text
              : null,
        },
      );

      final data = response.data as Map<String, dynamic>?;

      if (data?['success'] == true) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FundingResultScreen(
              success: true,
              campaign: widget.campaign,
              tier: widget.tier,
              totalAmount: _totalAmount,
              pledgeId: data?['pledgeId'],
              newBalance: data?['newBalance'],
            ),
          ),
        );
      } else {
        throw Exception(data?['message'] ?? '후원에 실패했습니다');
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage = '후원 중 오류가 발생했습니다';
      if (e.toString().contains('Insufficient DT balance') ||
          e.toString().contains('DT 잔액')) {
        errorMessage = 'DT 잔액이 부족합니다';
      } else if (e.toString().contains('sold out') ||
          e.toString().contains('품절')) {
        errorMessage = '선택한 리워드가 품절되었습니다';
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
    final hasInsufficientBalance =
        _walletBalance != null && _walletBalance! < _totalAmount;

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
                        '${_formatNumber(widget.tier['price_dt'] ?? 0)} DT',
                      ),
                      if (widget.extraSupport > 0) ...[
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          isDark,
                          '추가 후원',
                          '+${_formatNumber(widget.extraSupport)} DT',
                        ),
                      ],
                      const Divider(height: 24),
                      _buildSummaryRow(
                        isDark,
                        '총 후원금액',
                        '${_formatNumber(_totalAmount)} DT',
                        isBold: true,
                        valueColor: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              isDark,
                              '크리에이터 수령액 (${BusinessConfig.creatorPayoutPercent.toInt()}%)',
                              '${_formatNumber((_totalAmount * BusinessConfig.creatorPayoutPercent / 100).round())} DT',
                              valueColor: AppColors.success,
                            ),
                            const SizedBox(height: 4),
                            _buildSummaryRow(
                              isDark,
                              '플랫폼 수수료 (${BusinessConfig.platformCommissionPercent.toInt()}%)',
                              '${_formatNumber((_totalAmount * BusinessConfig.platformCommissionPercent / 100).round())} DT',
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '* 표시된 수수료는 정산 시 적용됩니다',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
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

                // Wallet balance
                _buildSection(
                  isDark,
                  '결제 수단',
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DT 지갑',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.textDark : AppColors.text,
                              ),
                            ),
                            Text(
                              _walletBalance != null
                                  ? '잔액: ${_formatNumber(_walletBalance!)} DT'
                                  : '잔액 확인 중...',
                              style: TextStyle(
                                fontSize: 13,
                                color: hasInsufficientBalance
                                    ? AppColors.danger
                                    : (isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasInsufficientBalance)
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to DT purchase
                          },
                          child: const Text('충전하기'),
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
                        color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
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
                                color: isDark ? AppColors.textDark : AppColors.text,
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
                        activeColor: AppColors.primary,
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
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                              children: [
                                TextSpan(
                                  text: ' 및 ',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMuted,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                TextSpan(
                                  text: '환불 정책',
                                  style: TextStyle(
                                    color: AppColors.primary,
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
                onPressed: (_isLoading || !_agreeTerms || hasInsufficientBalance)
                    ? null
                    : _submitPledge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: AppColors.onPrimary,
                  disabledBackgroundColor: isDark
                      ? AppColors.surfaceAltDark
                      : AppColors.surfaceAlt,
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        hasInsufficientBalance
                            ? 'DT 잔액 부족'
                            : '${_formatNumber(_totalAmount)} DT 후원하기',
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

  String _formatNumber(int number) {
    if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(0)}만';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}천';
    }
    return number.toString();
  }
}
