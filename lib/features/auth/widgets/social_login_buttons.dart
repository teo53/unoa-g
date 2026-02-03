import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';

/// Social login buttons (Kakao, Apple, Google)
class SocialLoginButtons extends ConsumerStatefulWidget {
  const SocialLoginButtons({super.key});

  @override
  ConsumerState<SocialLoginButtons> createState() => _SocialLoginButtonsState();
}

class _SocialLoginButtonsState extends ConsumerState<SocialLoginButtons> {
  String? _loadingProvider;

  Future<void> _handleSocialLogin(String provider) async {
    if (_loadingProvider != null) return;

    setState(() {
      _loadingProvider = provider;
    });

    try {
      switch (provider) {
        case 'kakao':
          await ref.read(authProvider.notifier).signInWithKakao();
          break;
        case 'apple':
          await ref.read(authProvider.notifier).signInWithApple();
          break;
        case 'google':
          await ref.read(authProvider.notifier).signInWithGoogle();
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(provider, e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingProvider = null;
        });
      }
    }
  }

  String _getErrorMessage(String provider, String error) {
    final providerName = switch (provider) {
      'kakao' => '카카오',
      'apple' => 'Apple',
      'google' => 'Google',
      _ => provider,
    };
    return '$providerName 로그인에 실패했습니다.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Kakao Login
        _SocialLoginButton(
          onPressed: () => _handleSocialLogin('kakao'),
          isLoading: _loadingProvider == 'kakao',
          backgroundColor: const Color(0xFFFEE500),
          textColor: const Color(0xFF191919),
          icon: _KakaoIcon(),
          label: '카카오로 시작하기',
        ),
        const SizedBox(height: 12),

        // Apple Login (iOS only in production)
        _SocialLoginButton(
          onPressed: () => _handleSocialLogin('apple'),
          isLoading: _loadingProvider == 'apple',
          backgroundColor: Colors.black,
          textColor: Colors.white,
          icon: const Icon(Icons.apple, color: Colors.white),
          label: 'Apple로 시작하기',
        ),
        const SizedBox(height: 12),

        // Google Login
        _SocialLoginButton(
          onPressed: () => _handleSocialLogin('google'),
          isLoading: _loadingProvider == 'google',
          backgroundColor: Colors.white,
          textColor: Colors.black87,
          borderColor: Colors.grey[300],
          icon: _GoogleIcon(),
          label: 'Google로 시작하기',
        ),
      ],
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final Widget icon;
  final String label;

  const _SocialLoginButton({
    required this.onPressed,
    required this.isLoading,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(
            color: borderColor ?? backgroundColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 24, height: 24, child: icon),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Kakao logo icon
class _KakaoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFF191919),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.chat_bubble,
          color: Color(0xFFFEE500),
          size: 14,
        ),
      ),
    );
  }
}

/// Google logo icon (simplified)
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Compact social login row for use in dialogs, etc.
class CompactSocialLoginButtons extends ConsumerStatefulWidget {
  const CompactSocialLoginButtons({super.key});

  @override
  ConsumerState<CompactSocialLoginButtons> createState() =>
      _CompactSocialLoginButtonsState();
}

class _CompactSocialLoginButtonsState
    extends ConsumerState<CompactSocialLoginButtons> {
  String? _loadingProvider;

  Future<void> _handleSocialLogin(String provider) async {
    if (_loadingProvider != null) return;

    setState(() {
      _loadingProvider = provider;
    });

    try {
      switch (provider) {
        case 'kakao':
          await ref.read(authProvider.notifier).signInWithKakao();
          break;
        case 'apple':
          await ref.read(authProvider.notifier).signInWithApple();
          break;
        case 'google':
          await ref.read(authProvider.notifier).signInWithGoogle();
          break;
      }
    } catch (e) {
      // Error handling
    } finally {
      if (mounted) {
        setState(() {
          _loadingProvider = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Kakao
        _CompactSocialButton(
          onPressed: () => _handleSocialLogin('kakao'),
          isLoading: _loadingProvider == 'kakao',
          backgroundColor: const Color(0xFFFEE500),
          icon: _KakaoIcon(),
        ),
        const SizedBox(width: 16),

        // Apple
        _CompactSocialButton(
          onPressed: () => _handleSocialLogin('apple'),
          isLoading: _loadingProvider == 'apple',
          backgroundColor: Colors.black,
          icon: const Icon(Icons.apple, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 16),

        // Google
        _CompactSocialButton(
          onPressed: () => _handleSocialLogin('google'),
          isLoading: _loadingProvider == 'google',
          backgroundColor: Colors.white,
          borderColor: Colors.grey[300],
          icon: _GoogleIcon(),
        ),
      ],
    );
  }
}

class _CompactSocialButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final Color backgroundColor;
  final Color? borderColor;
  final Widget icon;

  const _CompactSocialButton({
    required this.onPressed,
    required this.isLoading,
    required this.backgroundColor,
    this.borderColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: CircleBorder(
        side: BorderSide(
          color: borderColor ?? backgroundColor,
        ),
      ),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : icon,
          ),
        ),
      ),
    );
  }
}
