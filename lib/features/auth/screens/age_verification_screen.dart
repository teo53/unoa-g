import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';

/// Screen for age verification and guardian consent for minors
class AgeVerificationScreen extends ConsumerStatefulWidget {
  const AgeVerificationScreen({super.key});

  @override
  ConsumerState<AgeVerificationScreen> createState() =>
      _AgeVerificationScreenState();
}

class _AgeVerificationScreenState
    extends ConsumerState<AgeVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _guardianRelationController = TextEditingController();

  bool _isLoading = false;
  bool _consentVerified = false;
  String? _errorMessage;

  @override
  void dispose() {
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _guardianRelationController.dispose();
    super.dispose();
  }

  Future<void> _handleVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // In production, this would:
      // 1. Send SMS verification to guardian's phone
      // 2. Verify guardian's identity via phone authentication
      // 3. Record consent with timestamp

      // Simulate verification
      await Future.delayed(const Duration(seconds: 2));

      // Record guardian consent
      await ref.read(authProvider.notifier).recordGuardianConsent();

      setState(() {
        _consentVerified = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '인증 중 오류가 발생했습니다.';
      });
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
    final theme = Theme.of(context);

    if (_consentVerified) {
      return _buildSuccessView(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('법정대리인 동의'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '만 19세 미만 이용자 안내',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '정보통신망 이용촉진 및 정보보호 등에 관한 법률에 따라, '
                        '만 19세 미만의 이용자는 법정대리인(부모님 등)의 동의가 필요합니다.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Guardian info form
                Text(
                  '법정대리인 정보',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Guardian name
                TextFormField(
                  controller: _guardianNameController,
                  decoration: const InputDecoration(
                    labelText: '법정대리인 성명',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '법정대리인 성명을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Guardian relationship
                DropdownButtonFormField<String>(
                  initialValue: _guardianRelationController.text.isEmpty
                      ? null
                      : _guardianRelationController.text,
                  decoration: const InputDecoration(
                    labelText: '관계',
                    prefixIcon: Icon(Icons.family_restroom),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '부', child: Text('부')),
                    DropdownMenuItem(value: '모', child: Text('모')),
                    DropdownMenuItem(value: '기타', child: Text('기타 법정대리인')),
                  ],
                  onChanged: (value) {
                    _guardianRelationController.text = value ?? '';
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '관계를 선택해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Guardian phone
                TextFormField(
                  controller: _guardianPhoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                    _PhoneNumberFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: '법정대리인 연락처',
                    hintText: '010-0000-0000',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '연락처를 입력해주세요';
                    }
                    final digits = value.replaceAll('-', '');
                    if (digits.length < 10) {
                      return '올바른 연락처를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Consent checkboxes
                Text(
                  '동의 사항',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '아래 내용에 동의합니다:',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '1. 본인은 상기 미성년자의 법정대리인임을 확인합니다.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '2. 해당 미성년자의 UNO A 서비스 가입 및 이용에 동의합니다.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '3. 미성년자의 개인정보 수집 및 이용에 동의합니다.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Verification method notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sms_outlined,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '입력하신 연락처로 본인확인 SMS가 발송됩니다.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
                FilledButton(
                  onPressed: _isLoading ? null : _handleVerification,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('동의 및 인증하기'),
                ),
                const SizedBox(height: 16),

                // Cancel
                OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('가입 취소'),
                        content: const Text(
                          '법정대리인 동의 없이는 서비스 이용이 불가합니다.\n가입을 취소하시겠습니까?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('아니오'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context.go('/login');
                            },
                            child: const Text('예'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('나중에 하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '인증 완료!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '법정대리인 동의가 완료되었습니다.\n이제 UNO A 서비스를 이용하실 수 있습니다.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              FilledButton(
                onPressed: () => context.go('/'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('시작하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Phone number formatter (010-0000-0000)
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('-', '');
    if (digits.isEmpty) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 7) {
        buffer.write('-');
      }
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
