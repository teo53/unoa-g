import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/wallet_provider.dart';
import '../../shared/widgets/app_scaffold.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    '거래 내역',
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

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary600,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.white,
              unselectedLabelColor:
                  isDark ? AppColors.textSubDark : AppColors.textSubLight,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: '전체'),
                Tab(text: '충전'),
                Tab(text: '사용'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _TransactionList(filter: null),
                _TransactionList(filter: 'credit'),
                _TransactionList(filter: 'debit'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'completed':
      return AppColors.success;
    case 'pending':
      return AppColors.warning;
    case 'failed':
    case 'cancelled':
      return AppColors.danger;
    case 'refunded':
      return Colors.blue;
    default:
      return Colors.grey;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'completed':
      return '완료';
    case 'pending':
      return '처리 중';
    case 'failed':
      return '실패';
    case 'cancelled':
      return '취소';
    case 'refunded':
      return '환불';
    default:
      return status;
  }
}

class _TransactionList extends ConsumerWidget {
  final String? filter;

  const _TransactionList({this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter transactions based on type
    final allTransactions = ref.watch(recentTransactionsProvider);
    final transactions = allTransactions.where((txn) {
      if (filter == null) return true;
      if (filter == 'credit') return txn.isCredit;
      if (filter == 'debit') return txn.isDebit;
      return true;
    }).toList();

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
            ),
            const SizedBox(height: 16),
            Text(
              '거래 내역이 없습니다',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ],
        ),
      );
    }

    // Group transactions by date
    final groupedTransactions = <String, List<LedgerEntry>>{};
    for (final txn in transactions) {
      final dateKey =
          '${txn.createdAt.year}.${txn.createdAt.month.toString().padLeft(2, '0')}.${txn.createdAt.day.toString().padLeft(2, '0')}';
      groupedTransactions.putIfAbsent(dateKey, () => []).add(txn);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final date = groupedTransactions.keys.elementAt(index);
        final txns = groupedTransactions[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                date,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                children: txns.asMap().entries.map((entry) {
                  final i = entry.key;
                  final txn = entry.value;
                  final isCredit = txn.isCredit;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () =>
                            _showRefundDialog(context, txn, isCredit, isDark),
                        child: Padding(
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
                                  color: isCredit
                                      ? AppColors.success
                                      : AppColors.danger,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      txn.description ?? txn.typeDisplayName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? AppColors.textMainDark
                                            : AppColors.textMainLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          '${txn.createdAt.hour.toString().padLeft(2, '0')}:${txn.createdAt.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.textSubDark
                                                : AppColors.textSubLight,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Status Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusColor(txn.status)
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _statusLabel(txn.status),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: _statusColor(txn.status),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                txn.formattedAmount,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isCredit
                                      ? AppColors.success
                                      : AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ), // Close InkWell
                      if (i < txns.length - 1)
                        Divider(
                          height: 1,
                          indent: 68,
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _showRefundDialog(
      BuildContext context, LedgerEntry txn, bool isCredit, bool isDark) {
    // Only credit transactions (charges) can be refunded
    if (!isCredit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DT 사용 내역은 환불할 수 없습니다.')),
      );
      return;
    }

    // Check 7-day refund window
    final daysSinceTransaction =
        DateTime.now().difference(txn.createdAt).inDays;
    final canRefund = daysSinceTransaction <= 7 && txn.status == 'completed';

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
                const SizedBox(width: 12),
                Text(
                  '거래 상세',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(
                label: '거래 내용',
                value: txn.description ?? txn.typeDisplayName,
                isDark: isDark),
            _DetailRow(label: '금액', value: txn.formattedAmount, isDark: isDark),
            _DetailRow(
                label: '거래일',
                value:
                    '${txn.createdAt.year}.${txn.createdAt.month.toString().padLeft(2, '0')}.${txn.createdAt.day.toString().padLeft(2, '0')}',
                isDark: isDark),
            _DetailRow(label: '상태', value: txn.status, isDark: isDark),
            const SizedBox(height: 20),
            if (canRefund) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '충전 후 7일 이내에만 환불이 가능합니다.\n환불 시 보너스 DT는 회수됩니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.pop();
                    _confirmRefund(context, txn);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('환불 요청',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        daysSinceTransaction > 7
                            ? '충전 후 7일이 경과하여 환불이 불가능합니다.'
                            : '이미 처리된 거래는 환불할 수 없습니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmRefund(BuildContext context, LedgerEntry txn) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('환불 요청'),
        content: Text(
          '${txn.amountDt} DT 구매 내역을 환불 요청하시겠습니까?\n\n'
          '• 환불은 영업일 기준 3-5일 소요됩니다.\n'
          '• 보너스 DT는 회수됩니다.\n'
          '• 환불 수수료가 발생할 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('환불 요청이 접수되었습니다. 영업일 기준 3-5일 내 처리됩니다.'),
                ),
              );
            },
            child:
                const Text('환불 요청', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
        ],
      ),
    );
  }
}
