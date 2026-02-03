import 'package:flutter/material.dart';
import '../../styles/styles.dart';

class FlutterColorScheme {
  static var light = ColorScheme.light(
    primary: CustomColors.purpleColor,
    secondary: CustomColors.tealColor,
    surface: CustomColors.backgroundColor,
    background: CustomColors.backgroundColor,
    error: CustomColors.pinkColor,
    onPrimary: CustomColors.backgroundColor,
    onSecondary: CustomColors.backgroundColor,
    onSurface: CustomColors.primaryColor,
    onBackground: CustomColors.primaryColor,
    onError: CustomColors.backgroundColor,
  );
}
