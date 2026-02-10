import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/identity_verification_service.dart';

/// Button for initiating identity verification
///
/// SECURITY NOTE:
/// - This widget does NOT receive any PII (name, birthDate, gender)
/// - Only masked phone number (last 4 digits) is displayed
/// - All sensitive data is stored server-side only
class IdentityVerificationButton extends StatefulWidget {
  final VoidCallback? onVerificationComplete;
  final ValueChanged<IdentityVerificationResult>? onVerificationResult;
  final bool isVerified;
  final String? maskedPhone;  // Only last 4 digits: ***-****-1234
  final bool enabled;

  const IdentityVerificationButton({
    super.key,
    this.onVerificationComplete,
    this.onVerificationResult,
    this.isVerified = false,
    this.maskedPhone,
    this.enabled = true,
  });

  @override
  State<IdentityVerificationButton> createState() =>
      _IdentityVerificationButtonState();
}

class _IdentityVerificationButtonState
    extends State<IdentityVerificationButton> {
  bool _isLoading = false;

  Future<void> _startVerification() async {
    if (!widget.enabled || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      // In a real implementation, this would:
      // 1. Open PortOne SDK (web: popup, mobile: webview)
      // 2. User completes PASS verification
      // 3. Get imp_uid from callback
      // 4. Verify with backend

      // For now, show a mock dialog
      final result = await _showVerificationDialog();

      if (result != null && result.success) {
        widget.onVerificationResult?.call(result);
        widget.onVerificationComplete?.call();
      }
    } catch (e) {
      _showErrorSnackBar('본인인증 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<IdentityVerificationResult?> _showVerificationDialog() async {
    // This is a placeholder for the actual PortOne SDK integration
    // In production, this would open the PASS certification UI
    //
    // SECURITY NOTE:
    // - The mock result below only contains masked data
    // - Real PII (name, birthDate, gender) is NEVER returned to the client
    // - Server stores encrypted PII, client only receives verification flags

    return showDialog<IdentityVerificationResult>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('본인인증'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.phone_android,
                    size: 48,
                    color: AppColors.primary500,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'PASS 본인인증',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '휴대폰 본인인증을 진행합니다.\n통신사 앱 또는 인증 문자를 통해\n본인확인이 완료됩니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '현재 테스트 모드입니다.\n실제 인증은 PortOne 연동 후 가능합니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              // Return mock verification result for testing
              // NOTE: Only masked data is returned, no PII
              Navigator.pop(
                context,
                const IdentityVerificationResult(
                  success: true,
                  impUid: 'test_imp_uid_12345',
                  maskedPhone: '***-****-5678',  // Only last 4 digits
                  isAdult: true,                  // 19+ check
                  isAtLeast14: true,             // 14+ check
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              foregroundColor: Colors.white,
            ),
            child: const Text('테스트 인증 완료'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.isVerified) {
      return _buildVerifiedState(isDark);
    }

    return _buildUnverifiedState(isDark);
  }

  Widget _buildVerifiedState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_user,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '본인인증 완료',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '인증됨',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.maskedPhone != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      widget.maskedPhone!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnverifiedState(bool isDark) {
    return InkWell(
      onTap: widget.enabled ? _startVerification : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary500,
                      ),
                    )
                  : const Icon(
                      Icons.phone_android,
                      color: AppColors.primary500,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '휴대폰 본인인증',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PASS 인증으로 본인확인을 진행합니다',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact verification badge
class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final double size;

  const VerificationBadge({
    super.key,
    required this.isVerified,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check,
        size: size * 0.7,
        color: Colors.white,
      ),
    );
  }
}
