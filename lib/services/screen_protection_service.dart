import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/utils/app_logger.dart';

/// Screen capture prevention service
///
/// Prevents screenshot and screen recording on mobile platforms.
/// Uses platform-native APIs:
/// - Android: FLAG_SECURE on WindowManager
/// - iOS: UITextField.isSecureTextEntry trick / notification listener
/// - Web: Limited (CSS user-select: none, no full prevention)
///
/// Note: Requires `screen_protector` package once added to pubspec.yaml.
/// Currently implements a no-op stub that logs intent for future activation.
class ScreenProtectionService {
  static final ScreenProtectionService _instance =
      ScreenProtectionService._internal();
  factory ScreenProtectionService() => _instance;
  ScreenProtectionService._internal();

  bool _isProtected = false;

  /// Whether screen protection is currently active
  bool get isProtected => _isProtected;

  /// Enable screen capture prevention
  ///
  /// Call in initState of screens that contain sensitive content
  /// (e.g., chat threads with screenshot_warning_enabled)
  Future<void> enableProtection() async {
    if (_isProtected) return;

    try {
      if (kIsWeb) {
        // Web: Limited - can only discourage via CSS, not prevent
        AppLogger.debug(
          'Web platform - screen protection limited to CSS hints',
          tag: 'ScreenProtection',
        );
        _isProtected = true;
        return;
      }

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // Native platforms: will use screen_protector package
        // For now, log and set flag (package not yet in pubspec)
        //
        // When screen_protector is added:
        // import 'package:screen_protector/screen_protector.dart';
        // await ScreenProtector.protectDataLeakageWithColor(Colors.black);
        // await ScreenProtector.preventScreenshotOn();

        AppLogger.debug(
          'Screen protection enabled (stub - awaiting screen_protector package)',
          tag: 'ScreenProtection',
        );
        _isProtected = true;
        return;
      }

      AppLogger.debug(
        'Screen protection not supported on this platform',
        tag: 'ScreenProtection',
      );
    } catch (e) {
      AppLogger.error(
        e,
        tag: 'ScreenProtection',
        message: 'Failed to enable screen protection',
      );
    }
  }

  /// Disable screen capture prevention
  ///
  /// Call in dispose of screens that enabled protection
  Future<void> disableProtection() async {
    if (!_isProtected) return;

    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // When screen_protector is added:
        // await ScreenProtector.preventScreenshotOff();

        AppLogger.debug(
          'Screen protection disabled (stub)',
          tag: 'ScreenProtection',
        );
      }

      _isProtected = false;
    } catch (e) {
      AppLogger.error(
        e,
        tag: 'ScreenProtection',
        message: 'Failed to disable screen protection',
      );
    }
  }
}
