import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/business_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Admin Settlements Screen
/// 정산 리스트, 필터, 승인/반려 관리
class AdminSettlementsScreen extends ConsumerStatefulWidget {
  const AdminSettlementsScreen({super.key});

  @override
  ConsumerState<AdminSettlementsScreen> createState() =>
      _AdminSettlementsScreenState();
}

class _AdminSettlementsScreenState
    extends ConsumerState<AdminSettlementsScreen> {
  String _filter = 'all'; // all, pending_review, approved, paid

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filtered = _filter == 'all'
        ? _mockSettlements
        : _mockSettlements.where((s) => s['status'] == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('정산 관리'),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                    label: '전체',
                    value: 'all',
                    active: _filter,
                    onTap: _setFilter),
                const SizedBox(width: 8),
                _FilterChip(
                    label: '심사 대기',
                    value: 'pending_review',
                    active: _filter,
                    onTap: _setFilter),
                const SizedBox(width: 8),
                _FilterChip(
                    label: '승인됨',
                    value: 'approved',
                    active: _filter,
                    onTap: _setFilter),
                const SizedBox(width: 8),
                _FilterChip(
                    label: '지급 완료',
                    value: 'paid',
                    active: _filter,
                    onTap: _setFilter),
              ],
            ),
          ),

          // Settlement list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('해당 상태의 정산이 없습니다',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[500])),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final settlement = filtered[index];
                      return _SettlementCard(
                        settlement: settlement,
                        isDark: isDark,
                        onApprove: () => _handleApprove(settlement),
                        onReject: () => _handleReject(settlement),
                        onViewDetail: () => _showDetail(settlement),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _setFilter(String value) {
    setState(() => _filter = value);
  }

  void _handleApprove(Map<String, dynamic> settlement) {
    setState(() {
      settlement['status'] = 'approved';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${settlement['creatorName']} 정산이 승인되었습니다')),
    );
  }

  void _handleReject(Map<String, dynamic> settlement) {
    setState(() {
      settlement['status'] = 'rejected';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${settlement['creatorName']} 정산이 반려되었습니다')),
    );
  }

  void _showDetail(Map<String, dynamic> settlement) {
    final commissionRate = BusinessConfig.platformCommissionPercent;
    final totalRevenue = settlement['totalRevenue'] as int;
    final platformFee = (totalRevenue * commissionRate / 100).round();
    final taxableIncome = totalRevenue - platformFee;
    final taxRate = 3.3;
    final tax = (taxableIncome * taxRate / 100).round();
    final netPayout = taxableIncome - tax;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${settlement['creatorName']} 정산 상세',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '기간: ${settlement['period']}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const Divider(height: 24),
            _detailRow(
                '구독 수익', _formatKrw(settlement['subscriptionRevenue'] as int)),
            _detailRow('DT 수익', _formatKrw(settlement['dtRevenue'] as int)),
            _detailRow(
                '펀딩 수익', _formatKrw(settlement['fundingRevenue'] as int)),
            const Divider(height: 16),
            _detailRow('총 매출', _formatKrw(totalRevenue), bold: true),
            _detailRow('플랫폼 수수료 (${commissionRate.toStringAsFixed(0)}%)',
                '-${_formatKrw(platformFee)}'),
            _detailRow('과세소득', _formatKrw(taxableIncome)),
            _detailRow(
                '원천징수 (${taxRate.toStringAsFixed(1)}%)', '-${_formatKrw(tax)}'),
            const Divider(height: 16),
            _detailRow('순 지급액', _formatKrw(netPayout),
                bold: true, color: Colors.indigo),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatKrw(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return '₩$buffer';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String active;
  final Function(String) onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = active == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.indigo : Colors.transparent,
          borderRadius: AppRadius.xlBR,
          border: Border.all(
            color: isActive ? Colors.indigo : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  final Map<String, dynamic> settlement;
  final bool isDark;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewDetail;

  const _SettlementCard({
    required this.settlement,
    required this.isDark,
    required this.onApprove,
    required this.onReject,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = settlement['status'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: AppRadius.lgBR,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settlement['creatorName'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      settlement['period'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 12),

          // Revenue breakdown
          Row(
            children: [
              _revenueItem('구독', settlement['subscriptionRevenue'] as int),
              _revenueItem('DT', settlement['dtRevenue'] as int),
              _revenueItem('펀딩', settlement['fundingRevenue'] as int),
              _revenueItem('합계', settlement['totalRevenue'] as int, bold: true),
            ],
          ),
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewDetail,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('상세'),
                ),
              ),
              if (status == 'pending_review') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: onApprove,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('승인'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('반려'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending_review':
        color = Colors.orange;
        label = '심사 대기';
      case 'approved':
        color = Colors.green;
        label = '승인됨';
      case 'paid':
        color = Colors.blue;
        label = '지급 완료';
      case 'rejected':
        color = Colors.red;
        label = '반려됨';
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.smBR,
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _revenueItem(String label, int amount, {bool bold = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
          const SizedBox(height: 2),
          Text(
            _shortKrw(amount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _shortKrw(int amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(1)}만';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}천';
    }
    return '$amount';
  }
}

// Mock settlement data with subscription revenue
final List<Map<String, dynamic>> _mockSettlements = [
  {
    'id': 'stl_001',
    'creatorName': 'WAKER (하늘달)',
    'period': '2026-01-01 ~ 2026-01-31',
    'subscriptionRevenue': 212400, // BASIC 15 + STANDARD 8 + VIP 3
    'dtRevenue': 85000,
    'fundingRevenue': 150000,
    'totalRevenue': 447400,
    'status': 'pending_review',
  },
  {
    'id': 'stl_002',
    'creatorName': 'MOONLIGHT (별빛)',
    'period': '2026-01-01 ~ 2026-01-31',
    'subscriptionRevenue': 326300, // BASIC 22 + STANDARD 12 + VIP 5
    'dtRevenue': 62000,
    'fundingRevenue': 200000,
    'totalRevenue': 588300,
    'status': 'pending_review',
  },
  {
    'id': 'stl_003',
    'creatorName': 'STARLIGHT (민서)',
    'period': '2026-01-01 ~ 2026-01-31',
    'subscriptionRevenue': 458500,
    'dtRevenue': 120000,
    'fundingRevenue': 350000,
    'totalRevenue': 928500,
    'status': 'approved',
  },
  {
    'id': 'stl_004',
    'creatorName': 'WAKER (하늘달)',
    'period': '2025-12-01 ~ 2025-12-31',
    'subscriptionRevenue': 198700,
    'dtRevenue': 78000,
    'fundingRevenue': 130000,
    'totalRevenue': 406700,
    'status': 'paid',
  },
  {
    'id': 'stl_005',
    'creatorName': 'MOONLIGHT (별빛)',
    'period': '2025-12-01 ~ 2025-12-31',
    'subscriptionRevenue': 310200,
    'dtRevenue': 55000,
    'fundingRevenue': 180000,
    'totalRevenue': 545200,
    'status': 'paid',
  },
];
