import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../providers/repository_providers.dart';

/// 크리에이터가 팬을 숨김 처리하는 확인 다이얼로그
///
/// hidden_fans 테이블 (migration 009)에 레코드를 upsert하여
/// 해당 팬의 메시지를 크리에이터 채팅방에서 숨긴다.
///
/// - 숨김은 차단과 다름: 팬은 여전히 메시지를 보낼 수 있으나
///   크리에이터 타임라인에 표시되지 않음
/// - 숨김 해제는 설정에서 가능
class HideFanDialog extends ConsumerStatefulWidget {
  final String fanId;
  final String fanName;
  final VoidCallback? onHidden;

  const HideFanDialog({
    super.key,
    required this.fanId,
    required this.fanName,
    this.onHidden,
  });

  /// 다이얼로그를 표시하고 숨김 결과를 반환
  static Future<bool> show(
    BuildContext context, {
    required String fanId,
    required String fanName,
    VoidCallback? onHidden,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => HideFanDialog(
        fanId: fanId,
        fanName: fanName,
        onHidden: onHidden,
      ),
    );
    return result ?? false;
  }

  @override
  ConsumerState<HideFanDialog> createState() => _HideFanDialogState();
}

class _HideFanDialogState extends ConsumerState<HideFanDialog> {
  bool _isLoading = false;

  Future<void> _hideFan() async {
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(moderationRepositoryProvider);
      await repo.hideFan(widget.fanId);

      widget.onHidden?.call();

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.fanName}님을 숨겼습니다'),
            action: SnackBarAction(
              label: '취소',
              onPressed: () => _unhideFan(),
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.error(e, message: 'Failed to hide fan: ${widget.fanId}');
      if (mounted) {
        Navigator.of(context).pop(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('숨김 처리에 실패했습니다')),
        );
      }
    }
  }

  Future<void> _unhideFan() async {
    try {
      final repo = ref.read(moderationRepositoryProvider);
      await repo.unhideFan(widget.fanId);
    } catch (e) {
      AppLogger.error(e, message: 'Failed to unhide fan: ${widget.fanId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.visibility_off_outlined,
            color: Colors.orange[700],
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            '팬 숨기기',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: widget.fanName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: '님의 메시지를 내 채널에서 숨기시겠습니까?'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.orange.withValues(alpha: 0.1)
                  : Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? Colors.orange.withValues(alpha: 0.3)
                    : Colors.orange[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '숨김은 차단과 다릅니다. 팬은 여전히 메시지를 보낼 수 있지만, '
                    '내 채널 타임라인에 표시되지 않습니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[800],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(
            '취소',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _hideFan,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('숨기기'),
        ),
      ],
    );
  }
}
