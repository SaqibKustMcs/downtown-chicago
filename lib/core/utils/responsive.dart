import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Responsive breakpoints for different device types
class ResponsiveBreakpoints {
  // Mobile breakpoint (phones)
  static const double mobile = 600;
  
  // Tablet breakpoint
  static const double tablet = 900;
  
  // Desktop breakpoint
  static const double desktop = 1200;
  
  // Large desktop breakpoint
  static const double largeDesktop = 1920;
}

/// Device type enum
enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Platform type enum
enum PlatformType {
  android,
  ios,
  web,
  windows,
  macos,
  linux,
  fuchsia,
}

/// Responsive utility class for handling different screen sizes and platforms
class Responsive {
  final BuildContext context;
  final MediaQueryData mediaQuery;

  Responsive(this.context) : mediaQuery = MediaQuery.of(context);

  /// Get screen width
  double get width => mediaQuery.size.width;

  /// Get screen height
  double get height => mediaQuery.size.height;

  /// Get device pixel ratio
  double get devicePixelRatio => mediaQuery.devicePixelRatio;

  /// Get orientation
  Orientation get orientation => mediaQuery.orientation;

  /// Check if device is in landscape mode
  bool get isLandscape => orientation == Orientation.landscape;

  /// Check if device is in portrait mode
  bool get isPortrait => orientation == Orientation.portrait;

  /// Get device type based on screen width
  DeviceType get deviceType {
    if (width >= ResponsiveBreakpoints.largeDesktop) {
      return DeviceType.largeDesktop;
    } else if (width >= ResponsiveBreakpoints.desktop) {
      return DeviceType.desktop;
    } else if (width >= ResponsiveBreakpoints.tablet) {
      return DeviceType.tablet;
    } else {
      return DeviceType.mobile;
    }
  }

  /// Check if device is mobile
  bool get isMobile => deviceType == DeviceType.mobile;

  /// Check if device is tablet
  bool get isTablet => deviceType == DeviceType.tablet;

  /// Check if device is desktop
  bool get isDesktop => deviceType == DeviceType.desktop || deviceType == DeviceType.largeDesktop;

  /// Get platform type
  PlatformType get platformType {
    if (kIsWeb) {
      return PlatformType.web;
    } else if (Platform.isAndroid) {
      return PlatformType.android;
    } else if (Platform.isIOS) {
      return PlatformType.ios;
    } else if (Platform.isWindows) {
      return PlatformType.windows;
    } else if (Platform.isMacOS) {
      return PlatformType.macos;
    } else if (Platform.isLinux) {
      return PlatformType.linux;
    } else {
      return PlatformType.fuchsia;
    }
  }

  /// Check if platform is Android
  bool get isAndroid => platformType == PlatformType.android;

  /// Check if platform is iOS
  bool get isIOS => platformType == PlatformType.ios;

  /// Check if platform is Web
  bool get isWeb => platformType == PlatformType.web;

  /// Check if platform is Desktop (Windows, macOS, Linux)
  bool get isDesktopPlatform => 
      platformType == PlatformType.windows ||
      platformType == PlatformType.macos ||
      platformType == PlatformType.linux;

  /// Get responsive value based on device type
  /// Returns different values for mobile, tablet, and desktop
  T value<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    switch (deviceType) {
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }

  /// Get responsive double value (scales based on screen width)
  double responsiveSize({
    required double mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return value<double>(
      mobile: mobile,
      tablet: tablet ?? mobile * 1.2,
      desktop: desktop ?? mobile * 1.5,
      largeDesktop: largeDesktop ?? mobile * 2.0,
    );
  }

  /// Get responsive padding
  EdgeInsets responsivePadding({
    required EdgeInsets mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
    EdgeInsets? largeDesktop,
  }) {
    return value<EdgeInsets>(
      mobile: mobile,
      tablet: tablet ?? mobile * 1.2,
      desktop: desktop ?? mobile * 1.5,
      largeDesktop: largeDesktop ?? mobile * 2.0,
    );
  }

  /// Get responsive margin
  EdgeInsets responsiveMargin({
    required EdgeInsets mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
    EdgeInsets? largeDesktop,
  }) {
    return responsivePadding(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  /// Get responsive font size
  double responsiveFontSize({
    required double mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return responsiveSize(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  /// Get responsive width (percentage of screen width)
  double widthPercent(double percent) {
    return width * (percent / 100);
  }

  /// Get responsive height (percentage of screen height)
  double heightPercent(double percent) {
    return height * (percent / 100);
  }

  /// Get safe area padding
  EdgeInsets get safeAreaPadding => mediaQuery.padding;

  /// Get safe area insets
  EdgeInsets get safeAreaInsets => mediaQuery.viewInsets;

  /// Get text scale factor
  double get textScaleFactor => mediaQuery.textScaleFactor;

  /// Get responsive column count for grid layouts
  int responsiveColumns({
    required int mobile,
    int? tablet,
    int? desktop,
    int? largeDesktop,
  }) {
    return value<int>(
      mobile: mobile,
      tablet: tablet ?? (mobile + 1),
      desktop: desktop ?? (mobile + 2),
      largeDesktop: largeDesktop ?? (mobile + 3),
    );
  }

  /// Get responsive spacing
  double responsiveSpacing({
    required double mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return responsiveSize(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }
}

/// Extension on BuildContext for easy access to Responsive
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
  
  // Quick access to common responsive properties
  bool get isMobile => responsive.isMobile;
  bool get isTablet => responsive.isTablet;
  bool get isDesktop => responsive.isDesktop;
  DeviceType get deviceType => responsive.deviceType;
  PlatformType get platformType => responsive.platformType;
  
  // Quick responsive value getter
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    return responsive.value<T>(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }
  
  // Quick responsive size getter
  double responsiveSize({
    required double mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return responsive.responsiveSize(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }
  
  // Quick responsive padding getter
  EdgeInsets responsivePadding({
    required EdgeInsets mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
    EdgeInsets? largeDesktop,
  }) {
    return responsive.responsivePadding(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }
  
  // Quick responsive font size getter
  double responsiveFontSize({
    required double mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return responsive.responsiveFontSize(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }
}

/// Extension on EdgeInsets for multiplication
extension EdgeInsetsExtension on EdgeInsets {
  EdgeInsets operator *(double factor) {
    return EdgeInsets.only(
      left: left * factor,
      top: top * factor,
      right: right * factor,
      bottom: bottom * factor,
    );
  }
}
