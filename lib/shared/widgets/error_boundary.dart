import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Enterprise-grade error boundary widget
/// Catches and displays errors gracefully with retry functionality
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, VoidCallback retry)? errorBuilder;
  final void Function(Object error, StackTrace stackTrace)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
  }

  void _retry() {
    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!, _retry) ??
          ErrorDisplay(
            error: _error!,
            onRetry: _retry,
          );
    }

    return widget.child;
  }
}

/// Standard error display widget with error reference codes
class ErrorDisplay extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final String? title;
  final String? message;
  final IconData? icon;
  final bool compact;
  final String errorCode;

  /// Generates a unique error reference code for customer support
  /// Format: ERR-{timestamp_base36}-{random3digits}
  static String generateErrorCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
    final random = Random().nextInt(999).toString().padLeft(3, '0');
    return 'ERR-$timestamp-$random';
  }

  ErrorDisplay({
    super.key,
    required this.error,
    this.onRetry,
    this.title,
    this.message,
    this.icon,
    this.compact = false,
    String? errorCode,
  }) : errorCode = errorCode ?? generateErrorCode();

  /// Preset: Network error
  factory ErrorDisplay.network({VoidCallback? onRetry}) => ErrorDisplay(
        error: NetworkException(),
        onRetry: onRetry,
        title: '네트워크 오류',
        message: '인터넷 연결을 확인하고 다시 시도해주세요',
        icon: Icons.wifi_off_rounded,
      );

  /// Preset: Server error
  factory ErrorDisplay.server({VoidCallback? onRetry}) => ErrorDisplay(
        error: Exception('Server error'),
        onRetry: onRetry,
        title: '서버 오류',
        message: '일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
        icon: Icons.cloud_off_rounded,
      );

  /// Preset: Not found error
  factory ErrorDisplay.notFound({String? itemName}) => ErrorDisplay(
        error: const NotFoundException(),
        title: '찾을 수 없음',
        message: '${itemName ?? '요청한 내용'}을 찾을 수 없습니다',
        icon: Icons.search_off_rounded,
      );

  /// Preset: Permission denied
  factory ErrorDisplay.permissionDenied() => ErrorDisplay(
        error: const UnauthorizedException(),
        title: '접근 권한 없음',
        message: '이 내용을 볼 수 있는 권한이 없습니다',
        icon: Icons.lock_outline_rounded,
      );

  /// Preset: Session expired
  factory ErrorDisplay.sessionExpired({VoidCallback? onLogin}) => ErrorDisplay(
        error: const UnauthorizedException('Session expired'),
        title: '세션 만료',
        message: '다시 로그인해주세요',
        icon: Icons.timer_off_rounded,
        onRetry: onLogin,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (compact) {
      return _CompactErrorDisplay(
        error: error,
        onRetry: onRetry,
        isDark: isDark,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title ?? '문제가 발생했습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message ?? _getErrorMessage(error),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.baseBR,
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text(
                  '다시 시도',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            // Error Code Display for Customer Support
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '오류 코드: $errorCode',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: errorCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('오류 코드가 복사되었습니다'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.copy,
                      size: 16,
                      color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '문제가 지속되면 고객센터에 문의해 주세요',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(Object error) {
    if (error is NetworkException) {
      return '네트워크 연결을 확인해주세요';
    }
    if (error is TimeoutException) {
      return '요청 시간이 초과되었습니다';
    }
    if (error is NotFoundException) {
      return '요청한 내용을 찾을 수 없습니다';
    }
    return '일시적인 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
  }
}

class _CompactErrorDisplay extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final bool isDark;

  const _CompactErrorDisplay({
    required this.error,
    this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: AppRadius.baseBR,
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '로드에 실패했습니다',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('재시도'),
            ),
        ],
      ),
    );
  }
}

/// Empty state widget for when there's no data
class EmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final Widget? action;
  final bool compact;

  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.action,
    this.compact = false,
  });

  /// Preset: No messages
  factory EmptyState.noMessages({VoidCallback? onAction}) => EmptyState(
        title: '아직 메시지가 없어요',
        message: '첫 메시지를 보내보세요',
        icon: Icons.chat_bubble_outline_rounded,
        action: onAction != null
            ? ElevatedButton(
                onPressed: onAction,
                child: const Text('메시지 보내기'),
              )
            : null,
      );

  /// Preset: No notifications
  factory EmptyState.noNotifications() => const EmptyState(
        title: '알림이 없어요',
        message: '새로운 소식이 있으면 여기에 표시됩니다',
        icon: Icons.notifications_none_rounded,
      );

  /// Preset: No search results
  factory EmptyState.noSearchResults(String query) => EmptyState(
        title: '검색 결과가 없어요',
        message: '"$query"에 대한 결과를 찾을 수 없습니다',
        icon: Icons.search_off_rounded,
      );

  /// Preset: No subscriptions
  factory EmptyState.noSubscriptions({VoidCallback? onExplore}) => EmptyState(
        title: '구독 중인 아티스트가 없어요',
        message: '좋아하는 아티스트를 찾아보세요',
        icon: Icons.person_search_rounded,
        action: onExplore != null
            ? ElevatedButton(
                onPressed: onExplore,
                child: const Text('아티스트 찾기'),
              )
            : null,
      );

  /// Preset: No wallet transactions
  factory EmptyState.noTransactions() => const EmptyState(
        title: '거래 내역이 없어요',
        message: 'DT를 충전하거나 사용하면 여기에 표시됩니다',
        icon: Icons.receipt_long_outlined,
      );

  /// Preset: No blocked users
  factory EmptyState.noBlockedUsers() => const EmptyState(
        title: '차단한 사용자가 없어요',
        message: '차단한 사용자가 있으면 여기에 표시됩니다',
        icon: Icons.block_outlined,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (compact) {
      return _CompactEmptyState(
        title: title,
        message: message,
        icon: icon,
        isDark: isDark,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceAltDark
                    : AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.inbox_outlined,
                size: 40,
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact empty state for inline use
class _CompactEmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final bool isDark;

  const _CompactEmptyState({
    required this.title,
    this.message,
    this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.inbox_outlined,
            size: 24,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading state widget
class LoadingState extends StatelessWidget {
  final String? message;
  final bool compact;

  const LoadingState({
    super.key,
    this.message,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
            ),
          ),
          if (message != null) ...[
            const SizedBox(width: 12),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ],
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom exception types for better error handling
class NetworkException implements Exception {
  final String? message;
  NetworkException([this.message]);

  @override
  String toString() => message ?? 'Network error occurred';
}

class TimeoutException implements Exception {
  final String? message;
  TimeoutException([this.message]);

  @override
  String toString() => message ?? 'Request timed out';
}

class NotFoundException implements Exception {
  final String? message;
  const NotFoundException([this.message]);

  @override
  String toString() => message ?? 'Resource not found';
}

class UnauthorizedException implements Exception {
  final String? message;
  const UnauthorizedException([this.message]);

  @override
  String toString() => message ?? 'Unauthorized access';
}
