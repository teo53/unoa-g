import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/premium_effects.dart';
import '../../data/mock/mock_data.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/premium_shimmer.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = MockData.currentUser;

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
                    'Wallet',
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
                  // Balance Card with Premium Effects (shimmer + strongGlow)
                  PremiumShimmer.balance(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.premiumGradient,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: PremiumEffects.premiumCardShadows,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.diamond,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'DreamTime (DT)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '${user.dtBalance}',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'DT',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: GlowWrapper.cta(
                                  child: ElevatedButton(
                                    onPressed: () => context.push('/wallet/charge'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.primary600,
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      '충전하기',
                                      style: TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => context.push('/wallet/history'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    '사용내역',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // DT Packages
                  Text(
                    'DT 충전',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: MockData.dtPackages.length,
                      itemBuilder: (context, index) {
                        final package = MockData.dtPackages[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            right:
                                index < MockData.dtPackages.length - 1 ? 12 : 0,
                          ),
                          child: _PackageCard(
                            name: package.name,
                            amount: package.dtAmount,
                            bonus: package.bonusDt,
                            price: package.formattedPrice,
                            isPopular: package.isPopular,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Transaction History
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '최근 거래 내역',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/wallet/history'),
                        child: Text(
                          '전체보기',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      children: MockData.transactions.asMap().entries.map((e) {
                        final index = e.key;
                        final txn = e.value;
                        return Column(
                          children: [
                            _TransactionTile(
                              description: txn.description,
                              amount: txn.formattedAmount,
                              date: txn.formattedDate,
                              isCredit: txn.type.name == 'credit',
                            ),
                            if (index < MockData.transactions.length - 1)
                              Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Package Card with BEST shimmer effect
class _PackageCard extends StatelessWidget {
  final String name;
  final int amount;
  final int? bonus;
  final String price;
  final bool isPopular;

  const _PackageCard({
    required this.name,
    required this.amount,
    this.bonus,
    required this.price,
    this.isPopular = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPopular
            ? AppColors.primary100
            : (isDark ? AppColors.surfaceDark : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular
              ? AppColors.primary600
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: isPopular ? 1.5 : 1,
        ),
        boxShadow: isPopular ? [PremiumEffects.subtleGlow] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ),
              if (isPopular) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary600,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'BEST',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                Icons.diamond,
                size: 16,
                color: AppColors.primary500,
              ),
              const SizedBox(width: 4),
              Text(
                '$amount',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ],
          ),
          if (bonus != null) ...[
            const SizedBox(height: 4),
            Text(
              '+$bonus 보너스',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.primary500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const Spacer(),
          Text(
            price,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
        ],
      ),
    );

    // Add shimmer effect to popular (BEST) package
    if (isPopular) {
      card = PremiumShimmer.bestPackage(child: card);
    }

    return card;
  }
}

/// Transaction Tile using semantic colors
class _TransactionTile extends StatelessWidget {
  final String description;
  final String amount;
  final String date;
  final bool isCredit;

  const _TransactionTile({
    required this.description,
    required this.amount,
    required this.date,
    required this.isCredit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCredit
                  ? AppColors.success100
                  : AppColors.danger100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.add : Icons.remove,
              color: isCredit ? AppColors.success : AppColors.danger,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isCredit ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
