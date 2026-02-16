import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/agency.dart';

/// Displays the creator's active agency contract info as a read-only card.
/// Shown on the creator profile screen when agency_id is NOT NULL.
class AgencyInfoCard extends StatelessWidget {
  final AgencyContract contract;

  const AgencyInfoCard({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: agency logo + name + badge
          Row(
            children: [
              _buildAgencyLogo(isDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contract.agencyName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '소속사',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(isDark),
            ],
          ),

          const SizedBox(height: 16),

          // Contract details grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  isDark,
                  icon: Icons.calendar_today_outlined,
                  label: '계약 기간',
                  value: contract.contractPeriodLabel,
                ),
                const SizedBox(height: 10),
                _buildDetailRow(
                  isDark,
                  icon: Icons.percent,
                  label: '수수료율',
                  value:
                      '소속사 ${(contract.revenueShareRate * 100).toStringAsFixed(0)}%',
                ),
                const SizedBox(height: 10),
                _buildDetailRow(
                  isDark,
                  icon: Icons.account_balance_outlined,
                  label: '정산 방식',
                  value: contract.settlementModeLabel,
                ),
                const SizedBox(height: 10),
                _buildDetailRow(
                  isDark,
                  icon: Icons.schedule_outlined,
                  label: '정산 기준',
                  value: contract.settlementPeriodLabel,
                ),
              ],
            ),
          ),

          // Power of attorney notice
          if (contract.hasPowerOfAttorney) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.indigo[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '정산금은 소속사를 통해 일괄 지급됩니다',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.indigo[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAgencyLogo(bool isDark) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: contract.agencyLogoUrl != null
            ? CachedNetworkImage(
                imageUrl: contract.agencyLogoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Icon(
                  Icons.business,
                  size: 20,
                  color: Colors.grey,
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.business,
                  size: 20,
                  color: Colors.grey,
                ),
              )
            : Icon(
                Icons.business,
                size: 20,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isDark) {
    Color bgColor;
    Color textColor;

    switch (contract.status) {
      case 'active':
        bgColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        break;
      case 'pending':
        bgColor = Colors.amber.withValues(alpha: 0.1);
        textColor = Colors.amber[700]!;
        break;
      case 'paused':
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey[600]!;
        break;
      default:
        bgColor = AppColors.danger.withValues(alpha: 0.1);
        textColor = AppColors.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        contract.statusLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
        ),
      ],
    );
  }
}

/// Card for agency invitation (pending contract) with accept/reject buttons.
class AgencyInvitationCard extends StatelessWidget {
  final AgencyInvitation invitation;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isProcessing;

  const AgencyInvitationCard({
    super.key,
    required this.invitation,
    required this.onAccept,
    required this.onReject,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.indigo.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '소속 계약 초대',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${invitation.agencyName}에서 소속 계약을 신청했습니다',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '수수료율 ${(invitation.revenueShareRate * 100).toStringAsFixed(0)}% · ${invitation.settlementPeriod == 'monthly' ? '월간' : '격주'} 정산',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          if (invitation.contractStartDate != null) ...[
            const SizedBox(height: 4),
            Text(
              '계약 기간: ${invitation.contractStartDate}${invitation.contractEndDate != null ? ' ~ ${invitation.contractEndDate}' : ' ~ 무기한'}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isProcessing ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    '거절',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isProcessing ? null : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '수락',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
