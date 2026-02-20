import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/app_logger.dart';

/// 공유 URL base 소스.
///
/// 우선순위:
/// 1. ops_config.flags['share_links'].payload.base_url
/// 2. 데모 모드: Firebase Hosting URL
/// 3. 비데모 + 설정 없음: null (공유 차단)
///
/// 호출 측에서 [OpsConfig.getFlagPayload]로 값을 전달한다.
class ShareUtils {
  ShareUtils._();

  static const String _demoBaseUrl = 'https://unoa-app-demo.web.app';

  /// 공유 URL base 반환.
  /// [flagPayload]: ops_config의 'share_links' flag payload (nullable).
  static String? resolveBaseUrl(Map<String, dynamic>? flagPayload) {
    final fromFlag = flagPayload?['base_url'] as String?;
    if (fromFlag != null && fromFlag.isNotEmpty) return fromFlag;
    if (AppConfig.isDevelopment || AppConfig.enableDemoMode) {
      return _demoBaseUrl;
    }
    return null; // 비데모에서 설정 없으면 공유 차단
  }

  /// 아티스트 프로필 공유.
  static Future<void> shareArtistProfile({
    required BuildContext context,
    required String artistId,
    required String artistName,
    Map<String, dynamic>? flagPayload,
  }) async {
    final base = resolveBaseUrl(flagPayload);
    if (base == null) {
      _showNotConfiguredSnackbar(context);
      return;
    }
    final url = '$base/artist/${Uri.encodeComponent(artistId)}';
    final text = '$artistName 프로필을 확인해보세요!\n$url';
    try {
      await Share.share(text, subject: '$artistName 프로필');
    } catch (e) {
      AppLogger.error('ShareUtils.shareArtistProfile: $e', tag: 'Share');
    }
  }

  /// 펀딩 캠페인 공유.
  /// [slug]가 있으면 /p/{slug} 사용, 없으면 /funding/{campaignId} fallback.
  static Future<void> shareFundingCampaign({
    required BuildContext context,
    required String campaignId,
    String? campaignTitle,
    String? slug,
    Map<String, dynamic>? flagPayload,
  }) async {
    final base = resolveBaseUrl(flagPayload);
    if (base == null) {
      _showNotConfiguredSnackbar(context);
      return;
    }
    final path = slug != null && slug.isNotEmpty
        ? '/p/${Uri.encodeComponent(slug)}'
        : '/funding/${Uri.encodeComponent(campaignId)}';
    final url = '$base$path';
    final label = campaignTitle ?? '펀딩 캠페인';
    final text = '$label를 확인해보세요!\n$url';
    try {
      await Share.share(text, subject: label);
    } catch (e) {
      AppLogger.error('ShareUtils.shareFundingCampaign: $e', tag: 'Share');
    }
  }

  static void _showNotConfiguredSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('공유 기능을 준비 중입니다')),
      );
  }
}
