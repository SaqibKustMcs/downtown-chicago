import 'package:flutter/material.dart';
import 'responsive.dart';

/// Predefined responsive sizes for common UI elements
/// These sizes automatically adjust based on device type
class ResponsiveSizes {
  /// Get responsive padding for screens
  static EdgeInsets screenPadding(BuildContext context) {
    return context.responsivePadding(
      mobile: const EdgeInsets.all(16.0),
      tablet: const EdgeInsets.all(24.0),
      desktop: const EdgeInsets.all(32.0),
      largeDesktop: const EdgeInsets.all(48.0),
    );
  }

  /// Get responsive horizontal padding
  static EdgeInsets horizontalPadding(BuildContext context) {
    return context.responsivePadding(
      mobile: const EdgeInsets.symmetric(horizontal: 16.0),
      tablet: const EdgeInsets.symmetric(horizontal: 24.0),
      desktop: const EdgeInsets.symmetric(horizontal: 32.0),
      largeDesktop: const EdgeInsets.symmetric(horizontal: 48.0),
    );
  }

  /// Get responsive vertical padding
  static EdgeInsets verticalPadding(BuildContext context) {
    return context.responsivePadding(
      mobile: const EdgeInsets.symmetric(vertical: 16.0),
      tablet: const EdgeInsets.symmetric(vertical: 24.0),
      desktop: const EdgeInsets.symmetric(vertical: 32.0),
      largeDesktop: const EdgeInsets.symmetric(vertical: 48.0),
    );
  }

  /// Get responsive spacing between elements
  static double spacing(BuildContext context) {
    return context.responsiveSize(
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
      largeDesktop: 48.0,
    );
  }

  /// Get responsive small spacing
  static double spacingSmall(BuildContext context) {
    return context.responsiveSize(
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
      largeDesktop: 20.0,
    );
  }

  /// Get responsive large spacing
  static double spacingLarge(BuildContext context) {
    return context.responsiveSize(
      mobile: 24.0,
      tablet: 32.0,
      desktop: 48.0,
      largeDesktop: 64.0,
    );
  }

  /// Get responsive icon size
  static double iconSize(BuildContext context) {
    return context.responsiveSize(
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
      largeDesktop: 40.0,
    );
  }

  /// Get responsive small icon size
  static double iconSizeSmall(BuildContext context) {
    return context.responsiveSize(
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
      largeDesktop: 28.0,
    );
  }

  /// Get responsive large icon size
  static double iconSizeLarge(BuildContext context) {
    return context.responsiveSize(
      mobile: 32.0,
      tablet: 40.0,
      desktop: 48.0,
      largeDesktop: 56.0,
    );
  }

  /// Get responsive button height
  static double buttonHeight(BuildContext context) {
    return context.responsiveSize(
      mobile: 48.0,
      tablet: 52.0,
      desktop: 56.0,
      largeDesktop: 64.0,
    );
  }

  /// Get responsive card padding
  static EdgeInsets cardPadding(BuildContext context) {
    return context.responsivePadding(
      mobile: const EdgeInsets.all(12.0),
      tablet: const EdgeInsets.all(16.0),
      desktop: const EdgeInsets.all(20.0),
      largeDesktop: const EdgeInsets.all(24.0),
    );
  }

  /// Get responsive border radius
  static double borderRadius(BuildContext context) {
    return context.responsiveSize(
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
      largeDesktop: 20.0,
    );
  }

  /// Get responsive app bar height
  static double appBarHeight(BuildContext context) {
    return context.responsiveSize(
      mobile: 56.0,
      tablet: 64.0,
      desktop: 72.0,
      largeDesktop: 80.0,
    );
  }

  /// Get responsive bottom navigation bar height
  static double bottomNavHeight(BuildContext context) {
    return context.responsiveSize(
      mobile: 56.0,
      tablet: 64.0,
      desktop: 72.0,
      largeDesktop: 80.0,
    );
  }

  /// Get responsive grid column count
  static int gridColumns(BuildContext context) {
    return context.responsiveValue<int>(
      mobile: 2,
      tablet: 3,
      desktop: 4,
      largeDesktop: 5,
    );
  }

  /// Get responsive list item height
  static double listItemHeight(BuildContext context) {
    return context.responsiveSize(
      mobile: 80.0,
      tablet: 100.0,
      desktop: 120.0,
      largeDesktop: 140.0,
    );
  }

  /// Get responsive image height
  static double imageHeight(BuildContext context) {
    return context.responsiveSize(
      mobile: 200.0,
      tablet: 250.0,
      desktop: 300.0,
      largeDesktop: 400.0,
    );
  }

  /// Get responsive container max width
  static double containerMaxWidth(BuildContext context) {
    return context.responsiveValue<double>(
      mobile: double.infinity,
      tablet: 768.0,
      desktop: 1200.0,
      largeDesktop: 1600.0,
    );
  }
}

/// Responsive text styles
class ResponsiveTextStyles {
  /// Get responsive headline text style
  static TextStyle headline(BuildContext context) {
    return TextStyle(
      fontSize: context.responsiveFontSize(
        mobile: 24.0,
        tablet: 28.0,
        desktop: 32.0,
        largeDesktop: 40.0,
      ),
      fontWeight: FontWeight.bold,
    );
  }

  /// Get responsive title text style
  static TextStyle title(BuildContext context) {
    return TextStyle(
      fontSize: context.responsiveFontSize(
        mobile: 20.0,
        tablet: 24.0,
        desktop: 28.0,
        largeDesktop: 32.0,
      ),
      fontWeight: FontWeight.w600,
    );
  }

  /// Get responsive body text style
  static TextStyle body(BuildContext context) {
    return TextStyle(
      fontSize: context.responsiveFontSize(
        mobile: 14.0,
        tablet: 16.0,
        desktop: 18.0,
        largeDesktop: 20.0,
      ),
    );
  }

  /// Get responsive caption text style
  static TextStyle caption(BuildContext context) {
    return TextStyle(
      fontSize: context.responsiveFontSize(
        mobile: 12.0,
        tablet: 14.0,
        desktop: 16.0,
        largeDesktop: 18.0,
      ),
    );
  }
}
