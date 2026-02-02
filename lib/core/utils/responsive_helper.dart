import 'package:flutter/material.dart';

/// Enterprise-grade responsive design utilities
/// Handles phone, tablet, and landscape orientations

/// Device type enumeration
enum DeviceType {
  phone,
  tablet,
  desktop,
}

/// Screen size breakpoints (Material Design 3)
class Breakpoints {
  static const double phoneMax = 599;
  static const double tabletMax = 839;
  static const double desktopMin = 840;

  // Compact (phone portrait)
  static const double compact = 600;
  // Medium (tablet portrait, phone landscape)
  static const double medium = 840;
  // Expanded (tablet landscape, desktop)
  static const double expanded = 1200;
  // Large (large desktop)
  static const double large = 1600;
}

/// Responsive helper for adaptive layouts
class ResponsiveHelper {
  final BuildContext context;

  ResponsiveHelper(this.context);

  /// Get the current screen width
  double get screenWidth => MediaQuery.of(context).size.width;

  /// Get the current screen height
  double get screenHeight => MediaQuery.of(context).size.height;

  /// Get the current device type
  DeviceType get deviceType {
    if (screenWidth <= Breakpoints.phoneMax) {
      return DeviceType.phone;
    } else if (screenWidth <= Breakpoints.tabletMax) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Check if the device is a phone
  bool get isPhone => deviceType == DeviceType.phone;

  /// Check if the device is a tablet
  bool get isTablet => deviceType == DeviceType.tablet;

  /// Check if the device is a desktop
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// Check if the device is in landscape orientation
  bool get isLandscape =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  /// Check if the device is in portrait orientation
  bool get isPortrait =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  /// Get adaptive padding based on screen size
  EdgeInsets get adaptivePadding {
    if (isPhone) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else if (isTablet) {
      return const EdgeInsets.symmetric(horizontal: 24);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32);
    }
  }

  /// Get adaptive content width for centered content
  double get adaptiveContentWidth {
    if (isDesktop) {
      return Breakpoints.tabletMax;
    }
    return screenWidth;
  }

  /// Get number of grid columns based on screen size
  int get gridColumns {
    if (isPhone) {
      return isLandscape ? 3 : 2;
    } else if (isTablet) {
      return isLandscape ? 4 : 3;
    } else {
      return isLandscape ? 6 : 4;
    }
  }

  /// Get adaptive font scale
  double get fontScale {
    if (isPhone) return 1.0;
    if (isTablet) return 1.1;
    return 1.15;
  }

  /// Get safe area padding
  EdgeInsets get safeArea => MediaQuery.of(context).padding;

  /// Get keyboard height
  double get keyboardHeight => MediaQuery.of(context).viewInsets.bottom;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => keyboardHeight > 0;
}

/// Widget that adapts to screen size
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveHelper helper) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, ResponsiveHelper(context));
  }
}

/// Responsive layout that shows different widgets based on device type
class ResponsiveLayout extends StatelessWidget {
  final Widget phone;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.phone,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final helper = ResponsiveHelper(context);

    if (helper.isDesktop && desktop != null) {
      return desktop!;
    }

    if (helper.isTablet && tablet != null) {
      return tablet!;
    }

    return phone;
  }
}

/// Centered content container for larger screens
class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final Alignment alignment;

  const AdaptiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final helper = ResponsiveHelper(context);
    final effectiveMaxWidth = maxWidth ?? helper.adaptiveContentWidth;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: Padding(
          padding: padding ?? helper.adaptivePadding,
          child: child,
        ),
      ),
    );
  }
}

/// Responsive grid view
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? columns;
  final double childAspectRatio;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.columns,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final helper = ResponsiveHelper(context);
    final effectiveColumns = columns ?? helper.gridColumns;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: effectiveColumns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Responsive two-pane layout (master-detail)
class ResponsiveTwoPane extends StatelessWidget {
  final Widget master;
  final Widget? detail;
  final double masterWidth;
  final bool showDetailOnPhone;

  const ResponsiveTwoPane({
    super.key,
    required this.master,
    this.detail,
    this.masterWidth = 320,
    this.showDetailOnPhone = false,
  });

  @override
  Widget build(BuildContext context) {
    final helper = ResponsiveHelper(context);

    // On phone, show only master or detail
    if (helper.isPhone) {
      if (showDetailOnPhone && detail != null) {
        return detail!;
      }
      return master;
    }

    // On tablet/desktop, show side by side
    return Row(
      children: [
        SizedBox(
          width: masterWidth,
          child: master,
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: detail ?? const _EmptyDetailPane(),
        ),
      ],
    );
  }
}

class _EmptyDetailPane extends StatelessWidget {
  const _EmptyDetailPane();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('항목을 선택하세요'),
    );
  }
}

/// Extension for responsive values
extension ResponsiveExtensions on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);

  /// Get value based on device type
  T responsiveValue<T>({
    required T phone,
    T? tablet,
    T? desktop,
  }) {
    final helper = ResponsiveHelper(this);
    if (helper.isDesktop && desktop != null) return desktop;
    if (helper.isTablet && tablet != null) return tablet;
    return phone;
  }
}
