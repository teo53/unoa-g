import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/app_logger.dart';

/// Identity verification result from PASS
/// Note: Sensitive data (name, birthDate, gender) is stored server-side only
/// Client only receives verification status and masked phone number
class IdentityVerificationResult {
  final bool success;
  final String? impUid;
  final String? maskedPhone; // Only last 4 digits visible: ***-****-1234
  final bool? isAdult; // 19+ check result
  final bool? isAtLeast14; // 14+ check result
  final String? errorCode;
  final String? errorMessage;

  const IdentityVerificationResult({
    required this.success,
    this.impUid,
    this.maskedPhone,
    this.isAdult,
    this.isAtLeast14,
    this.errorCode,
    this.errorMessage,
  });

  factory IdentityVerificationResult.fromJson(Map<String, dynamic> json) {
    if (json['success'] != true) {
      return IdentityVerificationResult(
        success: false,
        errorCode: json['error_code'] as String?,
        errorMessage: json['error_message'] as String?,
      );
    }

    return IdentityVerificationResult(
      success: true,
      impUid: json['imp_uid'] as String?,
      maskedPhone: json['masked_phone'] as String?,
      isAdult: json['is_adult'] as bool?,
      isAtLeast14: json['is_at_least_14'] as bool?,
    );
  }

  factory IdentityVerificationResult.error(String message) {
    return IdentityVerificationResult(
      success: false,
      errorMessage: message,
    );
  }
}

/// Service for identity verification using PortOne V2 (PASS)
///
/// SECURITY: All sensitive operations are performed server-side via Edge Functions.
/// - Client NEVER has access to PortOne API secrets
/// - Client NEVER receives raw PII (name, birthdate, gender)
/// - Server stores encrypted PII in identity_verifications table
/// - Client only receives verification flags and masked data
class IdentityVerificationService {
  final SupabaseClient _supabase;

  IdentityVerificationService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  /// Verify identity certification result from PASS
  ///
  /// Flow:
  /// 1. Client receives impUid from PortOne SDK callback
  /// 2. Client sends impUid to Edge Function
  /// 3. Edge Function verifies with PortOne API (using server-side secrets)
  /// 4. Edge Function stores encrypted PII in identity_verifications table
  /// 5. Edge Function updates user_profiles with verification flags only
  /// 6. Client receives success/failure and masked data
  Future<IdentityVerificationResult> verifyCertification(String impUid) async {
    try {
      final response = await _supabase.functions.invoke(
        'verify-identity',
        body: {'impUid': impUid},
      );

      if (response.status != 200) {
        return IdentityVerificationResult.error(
          response.data?['error_message'] ?? '인증 서버 연결에 실패했습니다.',
        );
      }

      return IdentityVerificationResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      AppLogger.error(e,
          tag: 'IdentityVerification', message: 'verifyCertification failed');
      return IdentityVerificationResult.error('인증 처리 중 오류가 발생했습니다.');
    }
  }

  /// Get PortOne certification configuration for SDK initialization
  ///
  /// Note: This configuration is safe for client-side use.
  /// It only contains public identifiers, no secrets.
  Map<String, dynamic> getCertificationConfig({
    String? merchantUid,
    bool popup = true,
  }) {
    return {
      'merchant_uid':
          merchantUid ?? 'mid_${DateTime.now().millisecondsSinceEpoch}',
      'company': 'UNO A',
      'carrier': '', // 통신사 선택 화면 표시
      'name': '', // 이름 입력 화면 표시
      'phone': '', // 휴대폰번호 입력 화면 표시
      'popup': popup,
    };
  }

  /// Check if user has verified identity
  Future<bool> isIdentityVerified(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('identity_verified')
          .eq('id', userId)
          .single();

      return response['identity_verified'] == true;
    } catch (e) {
      AppLogger.error(e,
          tag: 'IdentityVerification',
          message: 'isIdentityVerified check failed');
      return false;
    }
  }

  /// Get verification status for current user
  Future<VerificationStatus> getVerificationStatus() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return VerificationStatus.notLoggedIn();
      }

      final response = await _supabase
          .from('user_profiles')
          .select('identity_verified, identity_verified_at, phone_verified')
          .eq('id', userId)
          .single();

      return VerificationStatus(
        isIdentityVerified: response['identity_verified'] == true,
        identityVerifiedAt: response['identity_verified_at'] != null
            ? DateTime.parse(response['identity_verified_at'] as String)
            : null,
        isPhoneVerified: response['phone_verified'] == true,
      );
    } catch (e) {
      AppLogger.error(e,
          tag: 'IdentityVerification', message: 'getVerificationStatus failed');
      return VerificationStatus.error();
    }
  }
}

/// Verification status for a user
class VerificationStatus {
  final bool isIdentityVerified;
  final DateTime? identityVerifiedAt;
  final bool isPhoneVerified;
  final bool isLoggedIn;
  final bool hasError;

  const VerificationStatus({
    this.isIdentityVerified = false,
    this.identityVerifiedAt,
    this.isPhoneVerified = false,
    this.isLoggedIn = true,
    this.hasError = false,
  });

  factory VerificationStatus.notLoggedIn() {
    return const VerificationStatus(isLoggedIn: false);
  }

  factory VerificationStatus.error() {
    return const VerificationStatus(hasError: true);
  }

  bool get isFullyVerified => isIdentityVerified && isPhoneVerified;
}

/// Configuration for identity verification
class IdentityVerificationConfig {
  /// Whether to require adult verification (19+)
  final bool requireAdult;

  /// Whether to require at least 14 years old
  final bool requireMinAge14;

  /// Custom merchant UID prefix
  final String? merchantUidPrefix;

  const IdentityVerificationConfig({
    this.requireAdult = false,
    this.requireMinAge14 = true,
    this.merchantUidPrefix,
  });

  /// Generate merchant UID
  String generateMerchantUid() {
    final prefix = merchantUidPrefix ?? 'unoa';
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Singleton instance
final identityVerificationService = IdentityVerificationService();
