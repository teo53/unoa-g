import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Report reasons matching the database enum
enum ReportReason {
  spam('spam', '스팸', '광고, 홍보, 반복 메시지 등'),
  harassment('harassment', '괴롭힘/폭언', '욕설, 비방, 혐오 표현 등'),
  inappropriateContent('inappropriate_content', '부적절한 콘텐츠', '성인물, 폭력적 콘텐츠 등'),
  fraud('fraud', '사기/허위 정보', '사기, 피싱, 허위 정보 유포 등'),
  copyright('copyright', '저작권 침해', '무단 복제, 저작권 침해 콘텐츠'),
  other('other', '기타', '위 항목에 해당하지 않는 문제');

  final String value;
  final String label;
  final String description;
  const ReportReason(this.value, this.label, this.description);
}

/// Dialog for reporting content or users
class ReportDialog extends StatefulWidget {
  /// User ID being reported (for user reports)
  final String? reportedUserId;

  /// Content ID being reported (for content reports)
  final String? reportedContentId;

  /// Type of content being reported
  final String reportedContentType;

  /// Callback when report is submitted
  final Future<void> Function(ReportReason reason, String? description)
      onSubmit;

  const ReportDialog({
    super.key,
    this.reportedUserId,
    this.reportedContentId,
    required this.reportedContentType,
    required this.onSubmit,
  });

  /// Show the report dialog
  static Future<bool?> show({
    required BuildContext context,
    String? reportedUserId,
    String? reportedContentId,
    required String reportedContentType,
    required Future<void> Function(ReportReason reason, String? description)
        onSubmit,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ReportDialog(
        reportedUserId: reportedUserId,
        reportedContentId: reportedContentId,
        reportedContentType: reportedContentType,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  ReportReason? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) {
      setState(() => _errorMessage = '신고 사유를 선택해주세요');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmit(
        _selectedReason!,
        _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.flag_outlined,
            color: AppColors.danger,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text('신고하기'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '신고 사유를 선택해주세요',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 12),

            // Report reason options
            ...ReportReason.values.map((reason) => _ReasonTile(
                  reason: reason,
                  isSelected: _selectedReason == reason,
                  isLoading: _isLoading,
                  onTap: () => setState(() => _selectedReason = reason),
                )),

            const SizedBox(height: 16),

            // Additional description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 500,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: '추가 설명 (선택사항)',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.textSubDark
                      : AppColors.textSubLight,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.danger,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Info text
            Text(
              '허위 신고는 제재 대상이 될 수 있습니다.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(
            '취소',
            style: TextStyle(
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('신고하기'),
        ),
      ],
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final ReportReason reason;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.reason,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.danger.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.danger.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? AppColors.danger
                  : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.danger
                          : (isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight),
                    ),
                  ),
                  Text(
                    reason.description,
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
          ],
        ),
      ),
    );
  }
}
