import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes
/// Usage: ResponsiveUtils.width(context, 0.5) for 50% of screen width
class ResponsiveUtils {
  // Private constructor to prevent instantiation
  ResponsiveUtils._();

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get percentage of screen width
  /// Example: width(context, 0.5) returns 50% of screen width
  static double width(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  /// Get percentage of screen height
  /// Example: height(context, 0.3) returns 30% of screen height
  static double height(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * percentage;
  }

  /// Get responsive font size based on screen width
  /// Base size is for a 375px wide screen (iPhone SE)
  static double fontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    return baseSize * (screenWidth / 375);
  }

  /// Get responsive spacing based on screen width
  static double spacing(BuildContext context, double baseSpacing) {
    final screenWidth = MediaQuery.of(context).size.width;
    return baseSpacing * (screenWidth / 375);
  }

  /// Check if device is mobile (width < 600)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Check if device is tablet (600 <= width < 1024)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  /// Check if device is desktop (width >= 1024)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  /// Get responsive padding
  static EdgeInsets padding(BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 375;

    if (all != null) {
      return EdgeInsets.all(all * scale);
    }

    return EdgeInsets.only(
      left: (left ?? horizontal ?? 0) * scale,
      top: (top ?? vertical ?? 0) * scale,
      right: (right ?? horizontal ?? 0) * scale,
      bottom: (bottom ?? vertical ?? 0) * scale,
    );
  }

  /// Get responsive margin
  static EdgeInsets margin(BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return padding(
      context,
      all: all,
      horizontal: horizontal,
      vertical: vertical,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }

  /// Get responsive border radius
  static BorderRadius borderRadius(BuildContext context, double baseRadius) {
    final screenWidth = MediaQuery.of(context).size.width;
    final radius = baseRadius * (screenWidth / 375);
    return BorderRadius.circular(radius);
  }

  /// Get responsive icon size
  static double iconSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    return baseSize * (screenWidth / 375);
  }

  /// Get safe area padding
  static EdgeInsets safeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get bottom safe area padding (useful for buttons at bottom)
  static double bottomSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// Get top safe area padding (useful for status bar)
  static double topSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// Get responsive value based on device type
  /// Example: responsiveValue(context, mobile: 12, tablet: 16, desktop: 20)
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }
}

/// Extension on BuildContext for easier access to responsive utilities
extension ResponsiveExtension on BuildContext {
  double get screenWidth => ResponsiveUtils.screenWidth(this);
  double get screenHeight => ResponsiveUtils.screenHeight(this);
  
  double widthPercent(double percentage) => ResponsiveUtils.width(this, percentage);
  double heightPercent(double percentage) => ResponsiveUtils.height(this, percentage);
  
  double responsiveFontSize(double baseSize) => ResponsiveUtils.fontSize(this, baseSize);
  double responsiveSpacing(double baseSpacing) => ResponsiveUtils.spacing(this, baseSpacing);
  double responsiveIconSize(double baseSize) => ResponsiveUtils.iconSize(this, baseSize);
  
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  
  EdgeInsets responsivePadding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) => ResponsiveUtils.padding(
    this,
    all: all,
    horizontal: horizontal,
    vertical: vertical,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
  );
  
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) => ResponsiveUtils.responsiveValue(
    this,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
  );
}
