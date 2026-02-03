export 'colors/colors.dart';
export 'typography/typography.dart';
export 'layouts/layouts.dart';

import 'package:flutter/services.dart';

import '../styles/styles.dart';
import 'package:flutter/material.dart';

class Styles {
  static final ThemeData _lightTheme = ThemeData(
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        statusBarColor: CustomColors.backgroundColor,
      ),
      backgroundColor: CustomColors.backgroundColor,
      foregroundColor: CustomColors.primaryColor,
      elevation: 0,
    ),
    textTheme: FlutterTextTheme.lightTextTheme,
    scaffoldBackgroundColor: CustomColors.backgroundColor,
    colorScheme: const ColorScheme.light(
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
    ),
    dividerColor: CustomColors.borderColor,
    cardColor: CustomColors.backgroundColor,
  );

  static ThemeData get lightTheme => _lightTheme;

  static final ThemeData _darkTheme = ThemeData(
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        statusBarColor: Color(0xFF1A1A1A),
      ),
      backgroundColor: Color(0xFF1A1A1A),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: FlutterTextTheme.darkTextTheme,
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFF6B35),
      secondary: Color(0xFF15D2BC),
      surface: Color(0xFF2A2A2A),
      background: Color(0xFF1A1A1A),
      error: Color(0xFFE26CA5),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.white,
    ),
    dividerColor: Colors.grey.shade700,
    cardColor: const Color(0xFF2A2A2A),
  );

  static ThemeData get darkTheme => _darkTheme;
}
