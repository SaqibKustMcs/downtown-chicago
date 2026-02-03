import 'package:flutter/material.dart';

/// Helper class to get theme-aware colors
class ThemeHelper {
  ThemeHelper._();

  /// Get background color based on theme
  static Color backgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  /// Get surface color based on theme
  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  /// Get primary text color based on theme
  static Color primaryTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  /// Get secondary text color based on theme
  static Color secondaryTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.grey.shade400
        : const Color(0xFF827D88);
  }

  /// Get card color based on theme
  static Color cardColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  /// Get border color based on theme
  static Color borderColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade200;
  }

  /// Get container color based on theme
  static Color containerColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.grey.shade100;
  }
}
