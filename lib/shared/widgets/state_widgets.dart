/// Unified export for all state-related widgets
/// Use this file to import EmptyState, ErrorDisplay, LoadingState, etc.
///
/// Example usage:
/// ```dart
/// import 'package:unoa_g/shared/widgets/state_widgets.dart';
///
/// // Empty state
/// EmptyState.noMessages()
/// EmptyState.noSearchResults('query')
///
/// // Error state
/// ErrorDisplay.network(onRetry: _retry)
/// ErrorDisplay.server(onRetry: _retry)
///
/// // Loading state
/// LoadingState(message: '로딩 중...')
/// LoadingState.compact(message: '로딩 중...')
/// ```

export 'error_boundary.dart';
