import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Enterprise-grade accessibility utilities
/// Ensures WCAG 2.1 AA compliance for screen readers

/// Semantic wrapper for interactive elements
class SemanticButton extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final bool enabled;

  const SemanticButton({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      hint: hint,
      onTap: enabled ? onTap : null,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: child,
      ),
    );
  }
}

/// Semantic wrapper for images
class SemanticImage extends StatelessWidget {
  final Widget child;
  final String label;
  final bool excludeFromSemantics;

  const SemanticImage({
    super.key,
    required this.child,
    required this.label,
    this.excludeFromSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    if (excludeFromSemantics) {
      return ExcludeSemantics(child: child);
    }

    return Semantics(
      image: true,
      label: label,
      child: child,
    );
  }
}

/// Semantic wrapper for text fields
class SemanticTextField extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final bool isRequired;

  const SemanticTextField({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: isRequired ? '$label (필수)' : label,
      hint: hint,
      child: child,
    );
  }
}

/// Screen reader announcement helper
class ScreenReaderAnnouncement {
  /// Announce a message to screen readers
  static void announce(BuildContext context, String message, {bool assertive = false}) {
    SemanticsService.announce(
      message,
      assertive ? TextDirection.ltr : TextDirection.ltr,
    );
  }

  /// Announce loading state
  static void announceLoading(BuildContext context) {
    announce(context, '로딩 중입니다');
  }

  /// Announce loading complete
  static void announceLoadingComplete(BuildContext context) {
    announce(context, '로딩이 완료되었습니다');
  }

  /// Announce error
  static void announceError(BuildContext context, String error) {
    announce(context, '오류: $error', assertive: true);
  }

  /// Announce success
  static void announceSuccess(BuildContext context, String message) {
    announce(context, message);
  }
}

/// Focus management for accessibility
class FocusHelper {
  /// Request focus on a specific node
  static void requestFocus(FocusNode node) {
    node.requestFocus();
  }

  /// Move focus to next element
  static void nextFocus(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// Move focus to previous element
  static void previousFocus(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// Unfocus all
  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}

/// Accessibility-friendly tap target size
/// Ensures minimum 48x48 touch target per WCAG guidelines
class AccessibleTapTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double minSize;

  const AccessibleTapTarget({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.minSize = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget tappable = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minSize,
          minHeight: minSize,
        ),
        child: Center(child: child),
      ),
    );

    if (semanticLabel != null) {
      return Semantics(
        button: true,
        label: semanticLabel,
        child: tappable,
      );
    }

    return tappable;
  }
}

/// Live region for dynamic content updates
class LiveRegion extends StatelessWidget {
  final Widget child;
  final bool isLive;
  final bool isPolite;

  const LiveRegion({
    super.key,
    required this.child,
    this.isLive = true,
    this.isPolite = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: isLive,
      child: child,
    );
  }
}

/// Skip navigation link for keyboard users
class SkipToContentLink extends StatelessWidget {
  final FocusNode contentFocusNode;
  final String label;

  const SkipToContentLink({
    super.key,
    required this.contentFocusNode,
    this.label = '본문으로 건너뛰기',
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          if (!hasFocus) {
            return const SizedBox.shrink();
          }
          return TextButton(
            onPressed: () => contentFocusNode.requestFocus(),
            child: Text(label),
          );
        },
      ),
    );
  }
}

/// Extension for easier semantic wrapping
extension SemanticExtensions on Widget {
  /// Wrap with button semantics
  Widget withButtonSemantics(String label, {String? hint, bool enabled = true}) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      hint: hint,
      child: this,
    );
  }

  /// Wrap with image semantics
  Widget withImageSemantics(String label) {
    return Semantics(
      image: true,
      label: label,
      child: this,
    );
  }

  /// Wrap with header semantics
  Widget withHeaderSemantics(String label, {int level = 1}) {
    return Semantics(
      header: true,
      label: label,
      child: this,
    );
  }

  /// Exclude from semantics (decorative elements)
  Widget excludeSemantics() {
    return ExcludeSemantics(child: this);
  }

  /// Merge semantics from descendants
  Widget mergeSemantics() {
    return MergeSemantics(child: this);
  }
}
