import 'package:flutter/material.dart';

/// Styled text field for auth forms
class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Color? suffixIconColor;
  final VoidCallback? onSuffixTap;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final bool autofocus;
  final bool enabled;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixIconColor,
    this.onSuffixTap,
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  @override
  Widget build(BuildContext context) {
    Widget? suffixWidget;

    if (widget.suffixIcon != null) {
      // Custom suffix icon provided (e.g., password toggle, validation icon)
      suffixWidget = IconButton(
        icon: Icon(
          widget.suffixIcon,
          color: widget.suffixIconColor,
        ),
        onPressed: widget.onSuffixTap,
      );
    }

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        border: const OutlineInputBorder(),
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixIcon: suffixWidget,
      ),
    );
  }
}

/// OTP input field for verification codes
class OtpInputField extends StatefulWidget {
  final int length;
  final void Function(String) onCompleted;
  final void Function(String)? onChanged;

  const OtpInputField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onChanged(int index) {
    final value = _controllers[index].text;

    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    widget.onChanged?.call(_otp);

    if (_otp.length == widget.length) {
      widget.onCompleted(_otp);
    }
  }

  void _onKeyDown(int index, KeyEvent event) {
    if (event.logicalKey.keyLabel == 'Backspace' &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        widget.length,
        (index) => SizedBox(
          width: 45,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) => _onKeyDown(index, event),
            child: TextFormField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              maxLength: 1,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (_) => _onChanged(index),
            ),
          ),
        ),
      ),
    );
  }
}

/// Password strength indicator
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  int get _strength {
    if (password.isEmpty) return 0;

    int score = 0;

    // Length checks
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Contains uppercase
    if (password.contains(RegExp(r'[A-Z]'))) score++;

    // Contains lowercase
    if (password.contains(RegExp(r'[a-z]'))) score++;

    // Contains number
    if (password.contains(RegExp(r'[0-9]'))) score++;

    // Contains special character
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    return score;
  }

  String get _label {
    if (password.isEmpty) return '';
    if (_strength <= 2) return '약함';
    if (_strength <= 4) return '보통';
    return '강함';
  }

  Color get _color {
    if (_strength <= 2) return Colors.red;
    if (_strength <= 4) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: _strength / 6,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(_color),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _label,
              style: TextStyle(
                color: _color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
