import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/business_config.dart';

/// Detect purchase platform for pricing display & payment validation.
///
/// - Web (Flutter Web): PurchasePlatform.web
/// - Android: PurchasePlatform.android
/// - iOS: PurchasePlatform.ios
/// - Others: default to web
PurchasePlatform getCurrentPurchasePlatform() {
  if (kIsWeb) return PurchasePlatform.web;
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return PurchasePlatform.ios;
    case TargetPlatform.android:
      return PurchasePlatform.android;
    default:
      return PurchasePlatform.web;
  }
}

/// Riverpod provider for the current purchase platform.
final purchasePlatformProvider = Provider<PurchasePlatform>((ref) {
  return getCurrentPurchasePlatform();
});
