import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_logger.dart';

/// Safe URL launcher with scheme validation and error handling.
///
/// Blocks dangerous schemes (javascript:, data:, intent:, blob:, file:)
/// and only allows [_allowedSchemes]. Automatically adds https:// if missing.
class SafeUrlLauncher {
  SafeUrlLauncher._();

  static const _allowedSchemes = {'https', 'http', 'mailto', 'tel'};

  /// Launch a URL safely with scheme validation.
  /// Returns true if launched successfully.
  static Future<bool> launch(
    String url, {
    BuildContext? context,
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      AppLogger.warning('Invalid URL: $url', tag: 'SafeUrlLauncher');
      _showError(context, '유효하지 않은 링크입니다.');
      return false;
    }

    return launchUri(uri, context: context, mode: mode);
  }

  /// Launch a pre-parsed [Uri] safely.
  static Future<bool> launchUri(
    Uri uri, {
    BuildContext? context,
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    // Validate scheme
    if (uri.scheme.isNotEmpty &&
        !_allowedSchemes.contains(uri.scheme.toLowerCase())) {
      AppLogger.warning(
        'Blocked URL launch with scheme: ${uri.scheme}',
        tag: 'SafeUrlLauncher',
      );
      _showError(context, '지원하지 않는 링크 형식입니다.');
      return false;
    }

    // Add https if no scheme
    final effectiveUri =
        uri.scheme.isEmpty ? Uri.parse('https://${uri.toString()}') : uri;

    try {
      if (await canLaunchUrl(effectiveUri)) {
        await launchUrl(effectiveUri, mode: mode);
        return true;
      } else {
        _showError(context, '링크를 열 수 없습니다.');
        return false;
      }
    } catch (e) {
      AppLogger.error(
        e,
        tag: 'SafeUrlLauncher',
        message: 'Failed to launch: $effectiveUri',
      );
      _showError(context, '링크를 열 수 없습니다.');
      return false;
    }
  }

  static void _showError(BuildContext? context, String message) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
