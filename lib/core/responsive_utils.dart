import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Standard Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static bool isMobileOrTablet(BuildContext context) =>
      MediaQuery.of(context).size.width < tabletBreakpoint;

  /// Returns the appropriate value for the current screen size
  static T valueByScreen<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= tabletBreakpoint) return desktop;
    if (width >= mobileBreakpoint) return tablet ?? mobile;
    return mobile;
  }

  /// Responsive padding based on screen size
  static EdgeInsets screenPadding(BuildContext context) {
    return valueByScreen(
      context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.fromLTRB(32, 32, 96, 32),
    );
  }

  /// Responsive grid cross axis count
  static int gridCrossAxisCount(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 3}) {
    return valueByScreen(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}
