import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';
import '../core/config/app_config.dart';
import '../core/utils/app_logger.dart';

/// Abstract IAP service interface.
///
/// Implementations:
/// - [IapService]: Real IAP for iOS/Android via `in_app_purchase` plugin.
/// - [StubIapService]: Web/demo stub that always returns unavailable.
abstract class IIapService {
  /// Check if IAP is available on the current platform.
  Future<bool> isAvailable();

  /// Query available products from the store.
  Future<List<ProductDetails>> queryProducts();

  /// Initiate a purchase for the given product.
  Future<bool> buyProduct(ProductDetails product);

  /// Stream of purchase updates (completed, pending, error).
  Stream<List<PurchaseDetails>> get purchaseStream;

  /// Complete a purchase after server-side verification.
  Future<void> completePurchase(PurchaseDetails purchase);

  /// Restore previous purchases (iOS requirement).
  Future<void> restorePurchases();

  /// Release resources.
  void dispose();
}

/// Real IAP implementation using `in_app_purchase` plugin.
///
/// P0-1: Fail-closed gates:
///   1. `kIsWeb` → unavailable (web must use PortOne)
///   2. `AppConfig.enableIap == false` → unavailable
///   3. `InAppPurchase.instance.isAvailable()` → platform check
///
/// Product IDs follow reverse-domain convention:
///   `com.unoa.dt.{amount}` for consumable DT packages.
class IapService implements IIapService {
  final InAppPurchase _iap = InAppPurchase.instance;

  /// Maps internal package IDs to store product IDs.
  static const Map<String, String> productIdMap = {
    'dt_10': 'com.unoa.dt.10',
    'dt_50': 'com.unoa.dt.50',
    'dt_100': 'com.unoa.dt.100',
    'dt_500': 'com.unoa.dt.500',
    'dt_1000': 'com.unoa.dt.1000',
    'dt_5000': 'com.unoa.dt.5000',
  };

  /// Maps subscription tier to store product IDs (auto-renewable subscriptions).
  /// Must match SUBSCRIPTION_PRODUCT_MAP in iap-verify Edge Function
  /// and BusinessConfig.subscriptionSkuByTier.
  static const Map<String, String> subscriptionProductIdMap = {
    'BASIC': 'com.unoa.sub.basic.monthly',
    'STANDARD': 'com.unoa.sub.standard.monthly',
    'VIP': 'com.unoa.sub.vip.monthly',
  };

  /// Reverse mapping: store product ID → internal package ID.
  static final Map<String, String> _reverseProductIdMap = {
    for (final entry in productIdMap.entries) entry.value: entry.key,
  };

  /// Get internal package ID from store product ID.
  static String? getPackageId(String storeProductId) {
    return _reverseProductIdMap[storeProductId];
  }

  /// Check if a store product ID is a subscription (not a DT consumable).
  static bool isSubscriptionProduct(String storeProductId) {
    return subscriptionProductIdMap.values.contains(storeProductId);
  }

  /// All store product IDs (DT consumables + subscriptions) for querying.
  static Set<String> get allProductIds => {
        ...productIdMap.values,
        ...subscriptionProductIdMap.values,
      };

  @override
  Future<bool> isAvailable() async {
    // FAIL-CLOSED 1: Web platform → IAP not available
    if (kIsWeb) {
      AppLogger.debug('IAP unavailable: web platform', tag: 'IAP');
      return false;
    }

    // FAIL-CLOSED 2: Feature flag disabled
    if (!AppConfig.enableIap) {
      AppLogger.debug('IAP unavailable: ENABLE_IAP=false', tag: 'IAP');
      return false;
    }

    // FAIL-CLOSED 3: Platform store check
    try {
      final available = await _iap.isAvailable();
      AppLogger.debug('IAP store available: $available', tag: 'IAP');
      return available;
    } catch (e) {
      AppLogger.error('IAP availability check failed: $e', tag: 'IAP');
      return false;
    }
  }

  @override
  Future<List<ProductDetails>> queryProducts() async {
    if (!await isAvailable()) {
      AppLogger.debug('IAP query skipped: not available', tag: 'IAP');
      return [];
    }

    try {
      final response = await _iap.queryProductDetails(allProductIds);

      if (response.notFoundIDs.isNotEmpty) {
        AppLogger.warning(
          'IAP products not found: ${response.notFoundIDs.join(", ")}',
          tag: 'IAP',
        );
      }

      if (response.error != null) {
        AppLogger.error(
          'IAP query error: ${response.error!.message}',
          tag: 'IAP',
        );
        return [];
      }

      AppLogger.info(
        'IAP queried ${response.productDetails.length} products',
        tag: 'IAP',
      );
      return response.productDetails;
    } catch (e) {
      AppLogger.error('IAP query failed: $e', tag: 'IAP');
      return [];
    }
  }

  @override
  Future<bool> buyProduct(ProductDetails product) async {
    if (!await isAvailable()) {
      AppLogger.error('IAP buy rejected: not available', tag: 'IAP');
      return false;
    }

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      final bool success;

      if (isSubscriptionProduct(product.id)) {
        // Subscriptions are non-consumable (auto-renewable)
        success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        // DT packages are consumable (one-time purchase)
        success = await _iap.buyConsumable(
          purchaseParam: purchaseParam,
          autoConsume: false, // We verify server-side before consuming
        );
      }

      AppLogger.info(
        'IAP buy initiated: ${product.id}, success=$success',
        tag: 'IAP',
      );
      return success;
    } catch (e) {
      AppLogger.error('IAP buy failed: $e', tag: 'IAP');
      return false;
    }
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    try {
      await _iap.completePurchase(purchase);
      AppLogger.info(
        'IAP purchase completed: ${purchase.productID}',
        tag: 'IAP',
      );
    } catch (e) {
      AppLogger.error('IAP complete purchase failed: $e', tag: 'IAP');
    }
  }

  @override
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      AppLogger.info('IAP restore initiated', tag: 'IAP');
    } catch (e) {
      AppLogger.error('IAP restore failed: $e', tag: 'IAP');
    }
  }

  @override
  void dispose() {
    // InAppPurchase.instance is a singleton; nothing to dispose
  }
}

/// Stub IAP service for web and demo mode.
///
/// Always returns unavailable. Used when:
/// - Running on web platform (PortOne handles web payments)
/// - Running in demo mode (simulated payments)
/// - IAP feature flag is disabled
class StubIapService implements IIapService {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<List<ProductDetails>> queryProducts() async => [];

  @override
  Future<bool> buyProduct(ProductDetails product) async => false;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  Future<void> restorePurchases() async {}

  @override
  void dispose() {}
}
