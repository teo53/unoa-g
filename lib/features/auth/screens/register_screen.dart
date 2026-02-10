import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../widgets/auth_form.dart';

/// Registration screen for new users
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _birthMonthController = TextEditingController();
  final _birthDayController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;
  bool _agreedToMarketing = false;
  int _currentStep = 0; // 0 = credentials, 1 = DOB + terms

  // Password visibility toggles
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // Real-time validation state
  bool _emailValid = false;
  String _password = '';

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _birthYearController.dispose();
    _birthMonthController.dispose();
    _birthDayController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    final email = _emailController.text.trim();
    final valid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    if (valid != _emailValid) {
      setState(() => _emailValid = valid);
    }
  }

  void _onPasswordChanged() {
    setState(() => _password = _passwordController.text);
  }

  // Password requirement checks
  bool get _hasMinLength => _password.length >= 8;
  bool get _hasLetter => RegExp(r'[a-zA-Z]').hasMatch(_password);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_password);
  bool get _hasSpecialChar =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]').hasMatch(_password);
  bool get _allPasswordRequirementsMet =>
      _hasMinLength && _hasLetter && _hasNumber && _hasSpecialChar;

  DateTime? get _dateOfBirth {
    final year = int.tryParse(_birthYearController.text);
    final month = int.tryParse(_birthMonthController.text);
    final day = int.tryParse(_birthDayController.text);

    if (year != null && month != null && day != null) {
      try {
        return DateTime(year, month, day);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  int? get _age {
    final dob = _dateOfBirth;
    if (dob == null) return null;
    return DateTime.now().difference(dob).inDays ~/ 365;
  }

  bool get _isMinor {
    final age = _age;
    return age != null && age < 19;
  }

  bool get _isUnder14 {
    final age = _age;
    return age != null && age < 14;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms || !_agreedToPrivacy) {
      setState(() {
        _errorMessage = '필수 약관에 동의해주세요.';
      });
      return;
    }

    if (_isUnder14) {
      setState(() {
        _errorMessage = '만 14세 미만은 가입이 불가합니다.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _displayNameController.text.trim(),
            dateOfBirth: _dateOfBirth,
          );

      if (mounted) {
        // Check if minor needs guardian consent
        if (_isMinor) {
          context.push('/guardian-consent');
        } else {
          // Show verification email sent message
          _showEmailVerificationDialog();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('already registered') ||
        error.contains('already_exists')) {
      return '이미 가입된 이메일입니다.';
    }
    if (error.contains('Password should be') ||
        error.contains('weak_password')) {
      return '비밀번호가 너무 약합니다. 영문, 숫자, 특수문자를 포함해주세요.';
    }
    if (error.contains('invalid_email') || error.contains('invalid email')) {
      return '유효하지 않은 이메일 주소입니다.';
    }
    if (error.contains('network') ||
        error.contains('timeout') ||
        error.contains('SocketException')) {
      return '네트워크 오류입니다. 인터넷 연결을 확인하고 다시 시도해주세요.';
    }
    if (error.contains('rate_limit') || error.contains('too_many_requests')) {
      return '너무 많은 요청입니다. 잠시 후 다시 시도해주세요.';
    }
    return '회원가입 중 오류가 발생했습니다. 다시 시도해주세요.';
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _EmailVerificationDialog(
        email: _emailController.text.trim(),
        onResend: () async {
          try {
            await ref.read(authProvider.notifier).signUpWithEmail(
                  email: _emailController.text.trim(),
                  password: _passwordController.text,
                  displayName: _displayNameController.text.trim(),
                  dateOfBirth: _dateOfBirth,
                );
          } catch (_) {
            // Ignore errors on resend — the account already exists
          }
        },
        onDone: () {
          Navigator.of(dialogContext).pop();
          context.go('/login');
        },
      ),
    );
  }

  void _goToStep2() {
    if (!_formKey.currentState!.validate()) return;
    if (!_allPasswordRequirementsMet) {
      setState(() {
        _errorMessage = '비밀번호 요구사항을 모두 충족해주세요.';
      });
      return;
    }
    setState(() {
      _currentStep = 1;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep == 0 ? '회원가입' : '추가 정보'),
        leading: _currentStep == 1
            ? IconButton(
                onPressed: () => setState(() => _currentStep = 0),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step indicator
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: _currentStep >= 1
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _currentStep == 0 ? '1/2 기본 정보' : '2/2 추가 정보',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: AppRadius.mdBR,
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
                  const SizedBox(height: 24),
                ],

                // ===== STEP 1: Email, Nickname, Password =====
                if (_currentStep == 0) ...[
                  // Email with real-time validation icon
                  AuthTextField(
                    controller: _emailController,
                    label: '이메일',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    suffixIcon: _emailController.text.isEmpty
                        ? null
                        : _emailValid
                            ? Icons.check_circle
                            : Icons.cancel,
                    suffixIconColor: _emailController.text.isEmpty
                        ? null
                        : _emailValid
                            ? Colors.green
                            : Colors.red,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이메일을 입력해주세요';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return '올바른 이메일 형식이 아닙니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Display name
                  AuthTextField(
                    controller: _displayNameController,
                    label: '닉네임',
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '닉네임을 입력해주세요';
                      }
                      if (value.length < 2) {
                        return '닉네임은 2자 이상이어야 합니다';
                      }
                      if (value.length > 20) {
                        return '닉네임은 20자 이하여야 합니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password with visibility toggle
                  AuthTextField(
                    controller: _passwordController,
                    label: '비밀번호',
                    obscureText: !_showPassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon:
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                    onSuffixTap: () =>
                        setState(() => _showPassword = !_showPassword),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요';
                      }
                      if (value.length < 8) {
                        return '비밀번호는 8자 이상이어야 합니다';
                      }
                      return null;
                    },
                  ),

                  // Password requirements checklist
                  if (_password.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _PasswordRequirement(
                      label: '8자 이상',
                      met: _hasMinLength,
                    ),
                    _PasswordRequirement(
                      label: '영문 포함',
                      met: _hasLetter,
                    ),
                    _PasswordRequirement(
                      label: '숫자 포함',
                      met: _hasNumber,
                    ),
                    _PasswordRequirement(
                      label: '특수문자 포함',
                      met: _hasSpecialChar,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Confirm password with visibility toggle
                  AuthTextField(
                    controller: _confirmPasswordController,
                    label: '비밀번호 확인',
                    obscureText: !_showConfirmPassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: _showConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    onSuffixTap: () => setState(
                        () => _showConfirmPassword = !_showConfirmPassword),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 다시 입력해주세요';
                      }
                      if (value != _passwordController.text) {
                        return '비밀번호가 일치하지 않습니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Continue button
                  FilledButton(
                    onPressed: _goToStep2,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('계속'),
                  ),
                ],

                // ===== STEP 2: DOB + Terms =====
                if (_currentStep == 1) ...[
                  // Date of birth
                  Text(
                    '생년월일',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _birthYearController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: const InputDecoration(
                            hintText: 'YYYY',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_currentStep < 1) return null;
                            if (value == null || value.isEmpty) {
                              return '';
                            }
                            final year = int.tryParse(value);
                            if (year == null ||
                                year < 1900 ||
                                year > DateTime.now().year) {
                              return '';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _birthMonthController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: const InputDecoration(
                            hintText: 'MM',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_currentStep < 1) return null;
                            if (value == null || value.isEmpty) {
                              return '';
                            }
                            final month = int.tryParse(value);
                            if (month == null || month < 1 || month > 12) {
                              return '';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _birthDayController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: const InputDecoration(
                            hintText: 'DD',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_currentStep < 1) return null;
                            if (value == null || value.isEmpty) {
                              return '';
                            }
                            final day = int.tryParse(value);
                            if (day == null || day < 1 || day > 31) {
                              return '';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_isMinor && !_isUnder14) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: AppRadius.mdBR,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.tertiary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '만 19세 미만은 법정대리인 동의가 필요합니다.',
                              style: TextStyle(
                                color: theme.colorScheme.onTertiaryContainer,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Terms and conditions
                  Text(
                    '약관 동의',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),

                  // All agree
                  CheckboxListTile(
                    value: _agreedToTerms &&
                        _agreedToPrivacy &&
                        _agreedToMarketing,
                    onChanged: (value) {
                      setState(() {
                        _agreedToTerms = value ?? false;
                        _agreedToPrivacy = value ?? false;
                        _agreedToMarketing = value ?? false;
                      });
                    },
                    title: const Text('전체 동의'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),

                  // Terms of service (required)
                  CheckboxListTile(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreedToTerms = value ?? false;
                      });
                    },
                    title: Row(
                      children: [
                        Text(
                          '[필수]',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        const SizedBox(width: 4),
                        const Text('이용약관 동의'),
                      ],
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    secondary: TextButton(
                      onPressed: () => context.push('/terms'),
                      child: const Text('보기'),
                    ),
                  ),

                  // Privacy policy (required)
                  CheckboxListTile(
                    value: _agreedToPrivacy,
                    onChanged: (value) {
                      setState(() {
                        _agreedToPrivacy = value ?? false;
                      });
                    },
                    title: Row(
                      children: [
                        Text(
                          '[필수]',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        const SizedBox(width: 4),
                        const Text('개인정보처리방침 동의'),
                      ],
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    secondary: TextButton(
                      onPressed: () => context.push('/privacy'),
                      child: const Text('보기'),
                    ),
                  ),

                  // Marketing (optional)
                  CheckboxListTile(
                    value: _agreedToMarketing,
                    onChanged: (value) {
                      setState(() {
                        _agreedToMarketing = value ?? false;
                      });
                    },
                    title: const Row(
                      children: [
                        Text(
                          '[선택]',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(width: 4),
                        Text('마케팅 정보 수신 동의'),
                      ],
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),

                  // Register button
                  FilledButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('가입하기'),
                  ),
                ],

                const SizedBox(height: 16),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('이미 계정이 있으신가요?'),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('로그인'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Password requirement indicator row
class _PasswordRequirement extends StatelessWidget {
  final String label;
  final bool met;

  const _PasswordRequirement({
    required this.label,
    required this.met,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: met ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

/// Email verification dialog with resend functionality
class _EmailVerificationDialog extends StatefulWidget {
  final String email;
  final Future<void> Function() onResend;
  final VoidCallback onDone;

  const _EmailVerificationDialog({
    required this.email,
    required this.onResend,
    required this.onDone,
  });

  @override
  State<_EmailVerificationDialog> createState() =>
      _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<_EmailVerificationDialog> {
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendCooldown = 0);
      } else {
        if (mounted) setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _handleResend() async {
    await widget.onResend();
    _startCooldown();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 이메일을 재전송했습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('이메일 인증'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.mark_email_unread_outlined,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.email}로\n인증 이메일을 보냈습니다.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            '이메일의 링크를 클릭하여 가입을 완료해주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '메일이 오지 않으면 스팸 폴더를 확인해주세요.',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _resendCooldown > 0 ? null : _handleResend,
            child: Text(
              _resendCooldown > 0 ? '재전송 가능 ($_resendCooldown초)' : '인증 메일 재전송',
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: widget.onDone,
          child: const Text('확인'),
        ),
      ],
    );
  }
}
