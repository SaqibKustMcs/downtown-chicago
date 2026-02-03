import 'package:flutter/material.dart';

import '../../styles/styles.dart';

class FlutterTextTheme {
  static TextTheme lightTextTheme = const TextTheme(
    displayMedium: TextStyle(fontSize: FontSize.f34, color: CustomColors.primaryColor, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
    displaySmall: TextStyle(fontSize: FontSize.f24, color: CustomColors.primaryColor, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
    headlineMedium: TextStyle(fontSize: FontSize.f20, color: CustomColors.primaryColor, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
    headlineSmall: TextStyle(fontSize: FontSize.f18, color: CustomColors.primaryColor, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
    titleLarge: TextStyle(fontSize: FontSize.f16, color: CustomColors.primaryColor, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
    titleMedium: TextStyle(fontSize: FontSize.f16, fontWeight: FontWeight.w400, color: CustomColors.primaryColor, fontFamily: 'Poppins'),
    titleSmall: TextStyle(fontSize: FontSize.f14, fontWeight: FontWeight.w400, color: CustomColors.secondaryTextColor, fontFamily: 'Poppins'),
    bodyLarge: TextStyle(fontSize: FontSize.f14, fontWeight: FontWeight.w500, color: CustomColors.secondaryTextColor, fontFamily: 'Poppins'),
    bodyMedium: TextStyle(fontSize: FontSize.f14, fontWeight: FontWeight.w400, color: CustomColors.primaryColor, fontFamily: 'Poppins'),
    labelLarge: TextStyle(fontSize: FontSize.f16, fontWeight: FontWeight.bold, color: CustomColors.backgroundColor, fontFamily: 'Poppins'),
    bodySmall: TextStyle(fontSize: FontSize.f12, fontWeight: FontWeight.w400, color: CustomColors.secondaryTextColor, fontFamily: 'Poppins'),
  );

  static TextTheme darkTextTheme = const TextTheme(
    displayMedium: TextStyle(fontSize: FontSize.f34, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
    displaySmall: TextStyle(fontSize: FontSize.f24, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
    headlineMedium: TextStyle(fontSize: FontSize.f20, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
    headlineSmall: TextStyle(fontSize: FontSize.f18, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
    titleLarge: TextStyle(fontSize: FontSize.f16, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
    titleMedium: TextStyle(fontSize: FontSize.f16, fontWeight: FontWeight.w400, color: Colors.white, fontFamily: 'Poppins'),
    titleSmall: TextStyle(fontSize: FontSize.f14, fontWeight: FontWeight.w400, color: Colors.grey, fontFamily: 'Poppins'),
    bodyLarge: TextStyle(fontSize: FontSize.f14, fontWeight: FontWeight.w500, color: Colors.grey, fontFamily: 'Poppins'),
    bodyMedium: TextStyle(fontSize: FontSize.f14, fontWeight: FontWeight.w400, color: Colors.white, fontFamily: 'Poppins'),
    labelLarge: TextStyle(fontSize: FontSize.f16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins'),
    bodySmall: TextStyle(fontSize: FontSize.f12, fontWeight: FontWeight.w400, color: Colors.grey, fontFamily: 'Poppins'),
  );
}
