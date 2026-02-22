import 'dart:async';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/premium_effects.dart';
import '../../core/config/app_config.dart';
import '../../core/config/business_config.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/platform_pricing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/wallet_provider.dart';
import '../../services/iap_service.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/premium_shimmer.dart';

class DtChargeScreen extends ConsumerStatefulWidget {
  const DtChargeScreen({super.key});

  @override
  ConsumerState<DtChargeScreen> createState() => _DtChargeScreenState();
}

class _DtChargeScreenState extends ConsumerState<DtChargeScreen> {
  int? _selectedPackageIndex;
  bool _isProcessing = false;
  StreamSubscription<List<PurchaseDetails>>? _iapSubscription;
  List<ProductDetails>? _iapProducts;
  bool _iapAvailable = false;

  @override
  void initState() {
    super.initState();
    _initIap();
  }

  @override
  void dispose() {
    _iapSubscription?.cancel();
    super.dispose();
  }

  /// Initialize IAP: check availability, query products, listen to purchases.
  Future<void> _initIap() async {
    final iapService = ref.read(iapServiceProvider);
    final available = await iapService.isAvailable();

    if (!mounted) return;
    setState(() => _iapAvailable = available);

    if (!available) return;

    // Listen to purchase updates
    _iapSubscription = iapService.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        AppLogger.error('IAP stream error: $error', tag: 'IAP');
      },
    );

    // Query available products
    final products = await iapService.queryProducts();
    if (!mounted) return;
    setState(() => _iapProducts = products);
  }

  /// Handle purchase status updates from the store.
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Still processing — keep spinner
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // P0-3: Send receipt to iap-verify Edge Function for
          // server-side verification, then complete the purchase.
          _verifyAndCompletePurchase(purchase);
          break;

        case PurchaseStatus.error:
          if (!mounted) return;
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                purchase.error?.message ?? '결제 처리 중 오류가 발생했습니다.',
              ),
              backgroundColor: AppColors.danger,
            ),
          );
          // P0-2: Do NOT call completePurchase on error.
          // The store will retry the pending transaction on next app launch,
          // preserving the user's ability to complete the purchase.
          AppLogger.warning(
            'IAP error: leaving purchase pending for retry. '
            'productID=${purchase.productID}',
            tag: 'IAP',
          );
          break;

        case PurchaseStatus.canceled:
          if (!mounted) return;
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('결제가 취소되었습니다.'),
            ),
          );
          break;
      }
    }
  }

  /// P0-2/P0-3: Verify purchase server-side via iap-verify Edge Function,
  /// then complete the store transaction ONLY on success.
  Future<void> _verifyAndCompletePurchase(PurchaseDetails purchase) async {
    AppLogger.info(
      'IAP verifying: ${purchase.productID}, status=${purchase.status}',
      tag: 'IAP',
    );

    int creditedDt = 0;

    try {
      // Determine platform
      final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
      final platform = kIsWeb ? 'web' : (isIOS ? 'ios' : 'android');

      // Call iap-verify via repository
      final result =
          await ref.read(creatorChatRepositoryProvider).verifyIAPPurchase(
                platform: platform,
                productId: purchase.productID,
                purchaseToken: purchase.verificationData.serverVerificationData,
                transactionReceipt: isIOS
                    ? purchase.verificationData.serverVerificationData
                    : null,
                transactionId: isIOS ? purchase.purchaseID : null,
              );

      creditedDt = (result['creditedDt'] as num?)?.toInt() ?? 0;

      AppLogger.info(
        'IAP verified: ${purchase.productID}, credited=$creditedDt DT',
        tag: 'IAP',
      );
    } catch (e) {
      AppLogger.error('IAP verification failed: $e', tag: 'IAP');

      // P0-2: Do NOT call completePurchase on verification failure.
      // Leave the purchase pending so it can be retried on next app launch
      // via the store's pending transaction queue.
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '결제 검증 중 오류가 발생했습니다. 앱 재시작 시 자동으로 재시도됩니다.',
            ),
            backgroundColor: AppColors.danger,
            action: SnackBarAction(
              label: '재시도',
              textColor: Colors.white,
              onPressed: () => _verifyAndCompletePurchase(purchase),
            ),
          ),
        );
      }
      return; // Exit early — do NOT complete the purchase
    }

    // P0-2: Only complete the store transaction AFTER successful verification
    await ref.read(iapServiceProvider).completePurchase(purchase);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    // Reload wallet balance after purchase
    await ref.read(walletProvider.notifier).loadWallet();

    if (!mounted) return;
    _showSuccessDialog(context, creditedDt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final packages = ref.watch(dtPackagesProvider);
    const dtPurchaseEnabled = AppConfig.enableDtPurchase;

    return AppScaffold(
      showStatusBar: true,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const Expanded(
                  child: Text(
                    'DT 구매',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Balance Card
                  _CurrentBalanceCard(),

                  const SizedBox(height: 32),

                  // Package Selection
                  Text(
                    '구매할 금액을 선택하세요',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Packages Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: packages.length,
                    itemBuilder: (context, index) {
                      final package = packages[index];
                      final isSelected = _selectedPackageIndex == index;

                      return _PackageCard(
                        name: package.name,
                        amount: package.dtAmount,
                        bonus: package.bonusDt,
                        price: package.formattedPrice,
                        isPopular: package.isPopular,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedPackageIndex = index;
                          });
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Payment Method
                  Text(
                    '결제 수단',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _PaymentMethodCard(iapAvailable: _iapAvailable),

                  const SizedBox(height: 24),

                  // Terms
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceAltDark
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '이용약관',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• DT는 UNO A 앱 내에서만 사용 가능한 서비스 전용 디지털 이용권으로, 현금 또는 법정화폐가 아닙니다\n'
                          '• 구매 후 7일 이내 미사용 DT는 환불 요청이 가능합니다\n'
                          '• 사용된 DT 및 보너스 DT는 환불 대상에서 제외됩니다\n'
                          '• DT 유효기간: 구매일로부터 5년\n'
                          '• 환불 요청: 설정 > 고객센터 또는 거래내역에서 신청',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: isDark
                                ? AppColors.textSubDark
                                : AppColors.textSubLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom CTA
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  if (_selectedPackageIndex != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '결제 금액',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textSubDark
                                : AppColors.textSubLight,
                          ),
                        ),
                        Text(
                          packages[_selectedPackageIndex!].formattedPrice,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'DT 구매 시 별도의 수수료가 부과되지 않습니다',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!dtPurchaseEnabled) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '현재 결제가 비활성화되어 있습니다. 운영 준비 후 다시 열립니다.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton.premium(
                      label: !dtPurchaseEnabled
                          ? '결제 준비 중'
                          : _isProcessing
                              ? '처리 중...'
                              : (_selectedPackageIndex != null
                                  ? '${packages[_selectedPackageIndex!].formattedPrice} 결제하기'
                                  : '패키지를 선택하세요'),
                      isLoading: _isProcessing,
                      onPressed: dtPurchaseEnabled &&
                              _selectedPackageIndex != null &&
                              !_isProcessing
                          ? () => _processPayment()
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment() async {
    if (!AppConfig.enableDtPurchase) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('현재 결제가 비활성화되어 있습니다.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final isDemoMode = ref.read(isDemoModeProvider);
      final packages = ref.read(dtPackagesProvider);
      final package = packages[_selectedPackageIndex!];

      if (isDemoMode) {
        // Demo mode: simulate payment with 2-second delay
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        setState(() => _isProcessing = false);

        _showSuccessDialog(context, package.totalDt);
        return;
      }

      // Platform branching: mobile → IAP, web → PortOne/TossPayments
      final platform = ref.read(purchasePlatformProvider);
      if (platform == PurchasePlatform.ios ||
          platform == PurchasePlatform.android) {
        await _processIapPayment(package);
      } else {
        await _processWebPayment(package);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('결제 처리 중 오류가 발생했습니다. 다시 시도해주세요.'),
          backgroundColor: AppColors.danger,
          action: SnackBarAction(
            label: '재시도',
            textColor: Colors.white,
            onPressed: _processPayment,
          ),
        ),
      );
    }
  }

  /// Process payment via IAP (iOS/Android).
  ///
  /// Finds the matching store product for the selected DT package,
  /// then initiates the purchase. The purchase result is handled
  /// asynchronously via [_handlePurchaseUpdates].
  Future<void> _processIapPayment(DtPackage package) async {
    if (!_iapAvailable) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인앱 결제를 사용할 수 없습니다. 설정을 확인해주세요.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Find matching store product
    final storeProductId = IapService.productIdMap[package.id];
    if (storeProductId == null) {
      setState(() => _isProcessing = false);
      AppLogger.error(
        'IAP: no store product mapping for ${package.id}',
        tag: 'IAP',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('해당 패키지는 인앱 결제를 지원하지 않습니다.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final products = _iapProducts ?? [];
    final matchingProducts = products.where((p) => p.id == storeProductId);

    if (matchingProducts.isEmpty) {
      setState(() => _isProcessing = false);
      AppLogger.warning(
        'IAP: product $storeProductId not found in store',
        tag: 'IAP',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('스토어에서 상품 정보를 가져올 수 없습니다. 잠시 후 다시 시도해주세요.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // Initiate purchase — result comes via purchaseStream
    final iapService = ref.read(iapServiceProvider);
    final success = await iapService.buyProduct(matchingProducts.first);

    if (!success && mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('결제를 시작할 수 없습니다. 다시 시도해주세요.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
    // If success, _isProcessing stays true until _handlePurchaseUpdates fires
  }

  /// Process payment via web checkout (PortOne/TossPayments).
  ///
  /// Calls the payment-checkout Edge Function to get a Toss checkout URL,
  /// then opens it in an external browser.
  Future<void> _processWebPayment(DtPackage package) async {
    final walletNotifier = ref.read(walletProvider.notifier);
    final checkoutUrl = await walletNotifier.createPurchaseCheckout(package.id);

    if (!mounted) return;

    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      setState(() => _isProcessing = false);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('결제 세션 생성에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // Open Toss payment window
    final uri = Uri.parse(checkoutUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    // After returning from payment window, reload wallet to reflect changes
    // (confirm/webhook may have credited DT while user was in Toss window)
    setState(() => _isProcessing = false);

    // Reload wallet after a short delay to allow confirm/webhook to process
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    await walletNotifier.loadWallet();
  }

  void _showSuccessDialog(BuildContext context, int totalDt) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('구매 완료'),
          ],
        ),
        content: Text(
          '$totalDt DT 구매가 완료되었습니다!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.pop(true);
            },
            child: const Text(
              '확인',
              style: TextStyle(color: AppColors.primary600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentBalanceCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(currentBalanceProvider);

    return PremiumShimmer.balance(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.premiumGradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: PremiumEffects.premiumCardShadows,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.diamond,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '현재 잔액',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$balance DT',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final String name;
  final int amount;
  final int? bonus;
  final String price;
  final bool isPopular;
  final bool isSelected;
  final VoidCallback onTap;

  const _PackageCard({
    required this.name,
    required this.amount,
    this.bonus,
    required this.price,
    this.isPopular = false,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary100
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary600
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [PremiumEffects.subtleGlow] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
                if (isPopular)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary600,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'BEST',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(
                  Icons.diamond,
                  size: 18,
                  color: AppColors.primary500,
                ),
                const SizedBox(width: 4),
                Text(
                  '$amount',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
              ],
            ),
            if (bonus != null) ...[
              const SizedBox(height: 4),
              Text(
                '+$bonus 보너스',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary500,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
          ],
        ),
      ),
    );

    if (isPopular && isSelected) {
      card = PremiumShimmer.bestPackage(child: card);
    }

    return card;
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final bool iapAvailable;

  const _PaymentMethodCard({this.iapAvailable = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Platform-aware payment method display
    final IconData paymentIcon;
    final String paymentTitle;
    final String paymentSubtitle;

    if (iapAvailable) {
      // Mobile: show store-specific payment
      final isIos = Theme.of(context).platform == TargetPlatform.iOS;
      paymentIcon = isIos ? Icons.apple : Icons.shop;
      paymentTitle = isIos ? 'Apple Pay / App Store' : 'Google Play';
      paymentSubtitle = '인앱 결제';
    } else {
      // Web: show card payment
      paymentIcon = Icons.credit_card;
      paymentTitle = '신용/체크카드';
      paymentSubtitle = '기본 결제 수단';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              paymentIcon,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paymentTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  paymentSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: AppColors.primary600,
          ),
        ],
      ),
    );
  }
}
