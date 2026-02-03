import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

extension ContextExtension on BuildContext {
  MediaQueryData get mediaQ => MediaQuery.of(this);

  Size get screenSize => mediaQ.size;

  double get screenDensity => mediaQ.devicePixelRatio;

  EdgeInsets get screenPadding => mediaQ.padding;

  double get screenWidth => mediaQ.size.width;

  double get screenHeight => mediaQ.size.height;

  double get percentWidth => screenWidth / 100;

  double get percentHeight => screenHeight / 100;

  double get _safeAreaHorizontal => mediaQ.padding.left + mediaQ.padding.right;

  double get _safeAreaVertical => mediaQ.padding.top + mediaQ.padding.bottom;

  double get safePercentWidth => (screenWidth - _safeAreaHorizontal) / 100;

  double get safePercentHeight => (screenHeight - _safeAreaVertical) / 100;

  Orientation get orientation => mediaQ.orientation;

  bool get isLandscape => orientation == Orientation.landscape;

  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => theme.textTheme;

  CupertinoThemeData get cupertinoTheme => CupertinoTheme.of(this);

  ColorScheme get colors => theme.colorScheme;

  Color get accentColor => theme.colorScheme.secondary;

  Color get primaryColor => theme.primaryColor;

  Brightness get brightness => theme.brightness;

  bool get isDarkMode => theme.brightness == Brightness.dark;

  ScaffoldState get scaffold => Scaffold.of(this);
}
