import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
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
    if (error.contains('already registered')) {
      return '이미 가입된 이메일입니다.';
    }
    if (error.contains('Password should be')) {
      return '비밀번호는 8자 이상이어야 합니다.';
    }
    return '회원가입 중 오류가 발생했습니다.';
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
              '${_emailController.text}로\n인증 이메일을 보냈습니다.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '이메일의 링크를 클릭하여 가입을 완료해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  const SizedBox(height: 24),
                ],

                // Email
                AuthTextField(
                  controller: _emailController,
                  label: '이메일',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
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

                // Password
                AuthTextField(
                  controller: _passwordController,
                  label: '비밀번호',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
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
                const SizedBox(height: 16),

                // Confirm password
                AuthTextField(
                  controller: _confirmPasswordController,
                  label: '비밀번호 확인',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
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
                          if (value == null || value.isEmpty) {
                            return '';
                          }
                          final year = int.tryParse(value);
                          if (year == null || year < 1900 || year > DateTime.now().year) {
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
                      borderRadius: BorderRadius.circular(8),
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
                  value: _agreedToTerms && _agreedToPrivacy && _agreedToMarketing,
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
