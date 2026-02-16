import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../core/theme/app_colors.dart';

/// Payment consent item for checkout
enum PaymentConsentItem {
  orderConfirmation(
    'order_confirmation',
    '주문 내용 확인',
    '위 상품을 확인하였으며, 주문에 동의합니다.',
    true,
  ),
  personalInfoCollection(
    'personal_info_collection',
    '개인정보 수집 동의',
    '성명, 연락처, 배송 주소 등 결제에 필요한 개인정보 수집에 동의합니다.',
    true,
  ),
  thirdPartyProvision(
    'third_party_provision_pg',
    '제3자 제공 동의 (PG사)',
    '결제 처리를 위해 토스페이먼츠에 개인정보를 제공하는 것에 동의합니다.',
    true,
  ),
  paymentServiceTerms(
    'payment_service_terms',
    '결제대행 서비스 이용약관',
    '토스페이먼츠 결제대행 서비스 이용약관에 동의합니다.',
    true,
  ),
  crossBorderTransfer(
    'cross_border_transfer',
    '개인정보 국외 이전 동의',
    '해외 결제사(Stripe 등)로의 개인정보 이전에 동의합니다.',
    false,
  ),
  creatorDataSharing(
    'creator_data_sharing',
    '제3자 제공 동의 (크리에이터)',
    '주문 처리를 위해 크리에이터에게 배송 정보를 제공하는 것에 동의합니다.',
    true,
  );

  final String id;
  final String title;
  final String description;
  final bool required;

  const PaymentConsentItem(
      this.id, this.title, this.description, this.required);
}

/// Payment consent form widget for checkout screen
class PaymentConsentForm extends StatefulWidget {
  final ValueChanged<bool> onAllConsentChanged;
  final VoidCallback? onViewTerms;
  final VoidCallback? onViewPrivacy;

  const PaymentConsentForm({
    super.key,
    required this.onAllConsentChanged,
    this.onViewTerms,
    this.onViewPrivacy,
  });

  @override
  State<PaymentConsentForm> createState() => _PaymentConsentFormState();
}

class _PaymentConsentFormState extends State<PaymentConsentForm> {
  final Map<PaymentConsentItem, bool> _consents = {};
  bool _allChecked = false;

  @override
  void initState() {
    super.initState();
    // Initialize all consents to false
    for (final item in PaymentConsentItem.values) {
      _consents[item] = false;
    }
  }

  bool get _allRequiredConsented {
    return PaymentConsentItem.values
        .where((item) => item.required)
        .every((item) => _consents[item] == true);
  }

  void _toggleAll(bool? value) {
    setState(() {
      _allChecked = value ?? false;
      for (final item in PaymentConsentItem.values) {
        _consents[item] = _allChecked;
      }
    });
    widget.onAllConsentChanged(_allRequiredConsented);
  }

  void _toggleItem(PaymentConsentItem item, bool? value) {
    setState(() {
      _consents[item] = value ?? false;
      _allChecked =
          PaymentConsentItem.values.every((i) => _consents[i] == true);
    });
    widget.onAllConsentChanged(_allRequiredConsented);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "All Agree" checkbox
          _AllAgreeCheckbox(
            value: _allChecked,
            onChanged: _toggleAll,
            isDark: isDark,
          ),

          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // Individual consent items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: PaymentConsentItem.values.map((item) {
                return _ConsentCheckbox(
                  item: item,
                  value: _consents[item] ?? false,
                  onChanged: (value) => _toggleItem(item, value),
                  isDark: isDark,
                  onViewTerms: item == PaymentConsentItem.paymentServiceTerms
                      ? widget.onViewTerms
                      : null,
                );
              }).toList(),
            ),
          ),

          // Legal notice
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                  children: [
                    const TextSpan(text: '* 필수 항목에 동의하지 않으면 결제를 진행할 수 없습니다.\n'),
                    const TextSpan(text: '자세한 내용은 '),
                    TextSpan(
                      text: '개인정보 처리방침',
                      style: const TextStyle(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = widget.onViewPrivacy,
                    ),
                    const TextSpan(text: '을 확인하세요.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllAgreeCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final bool isDark;

  const _AllAgreeCheckbox({
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '전체 동의하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
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

class _ConsentCheckbox extends StatelessWidget {
  final PaymentConsentItem item;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final bool isDark;
  final VoidCallback? onViewTerms;

  const _ConsentCheckbox({
    required this.item,
    required this.value,
    required this.onChanged,
    required this.isDark,
    this.onViewTerms,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.required)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            '필수',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                        ),
                      ),
                      if (onViewTerms != null)
                        GestureDetector(
                          onTap: onViewTerms,
                          child: const Text(
                            '보기',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
