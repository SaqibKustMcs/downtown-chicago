import 'package:flutter/material.dart';
import '../colors/custom_colors.dart';
import '../layouts/sizes.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String _fontFamily = 'Poppins';

  static const TextStyle heading1 = TextStyle(
    fontSize: Sizes.s28,
    fontWeight: FontWeight.bold,
    color: CustomColors.primaryColor,
    fontFamily: _fontFamily,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: Sizes.s18,
    fontWeight: FontWeight.w500,
    color: CustomColors.primaryColor,
    fontFamily: _fontFamily,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: Sizes.s16,
    fontWeight: FontWeight.w500,
    color: CustomColors.primaryColor,
    fontFamily: _fontFamily,
  );

  static const TextStyle heading4 = TextStyle(
    fontSize: Sizes.s14,
    fontWeight: FontWeight.w600,
    color: CustomColors.primaryColor,
    fontFamily: _fontFamily,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: Sizes.s14,
    fontWeight: FontWeight.w400,
    color: CustomColors.primaryColor,
    fontFamily: _fontFamily,
  );

  static const TextStyle bodyLargeSecondary = TextStyle(
    fontSize: Sizes.s14,
    fontWeight: FontWeight.w400,
    color: CustomColors.secondaryTextColor,
    fontFamily: _fontFamily,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: Sizes.s13,
    fontWeight: FontWeight.w400,
    color: CustomColors.primaryColor,
    fontFamily: _fontFamily,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: Sizes.s12,
    fontWeight: FontWeight.w400,
    color: CustomColors.primaryColor,
    fontFamily: _fontFamily,
  );

  static const TextStyle bodySmallSecondary = TextStyle(
    fontSize: Sizes.s12,
    fontWeight: FontWeight.w400,
    color: CustomColors.secondaryTextColor,
    fontFamily: _fontFamily,
  );

  static const TextStyle label = TextStyle(
    fontSize: Sizes.s12,
    fontWeight: FontWeight.w500,
    color: CustomColors.primaryColor,
    fontFamily: _fontFamily,
  );

  static const TextStyle labelSecondary = TextStyle(
    fontSize: Sizes.s12,
    fontWeight: FontWeight.w500,
    color: CustomColors.secondaryTextColor,
    fontFamily: _fontFamily,
  );

  static const TextStyle caption = TextStyle(
    fontSize: Sizes.s10,
    fontWeight: FontWeight.w400,
    color: CustomColors.secondaryTextColor,
    fontFamily: _fontFamily,
  );

  static const TextStyle captionTiny = TextStyle(
    fontSize: Sizes.s8,
    fontWeight: FontWeight.w600,
    color: CustomColors.secondaryTextColor,
    fontFamily: _fontFamily,
  );

  static const TextStyle button = TextStyle(
    fontSize: Sizes.s14,
    fontWeight: FontWeight.w600,
    color: CustomColors.appbarColor,
    fontFamily: _fontFamily,
  );

  static const TextStyle buttonLarge = TextStyle(
    fontSize: Sizes.s16,
    fontWeight: FontWeight.w400,
    color: CustomColors.appbarColor,
    fontFamily: _fontFamily,
  );

  static const TextStyle buttonLargeBold = TextStyle(
    fontSize: Sizes.s16,
    fontWeight: FontWeight.w600,
    color: CustomColors.appbarColor,
    fontFamily: _fontFamily,
  );

  static const TextStyle titleWhite = TextStyle(
    fontSize: Sizes.s16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    fontFamily: _fontFamily,
  );

  static const TextStyle titleLargeWhite = TextStyle(
    fontSize: Sizes.s18,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    fontFamily: _fontFamily,
  );

  static const TextStyle description = TextStyle(
    fontSize: Sizes.s12,
    fontWeight: FontWeight.w400,
    color: CustomColors.discriptionColor,
    fontFamily: _fontFamily,
    height: 1.6,
  );

  static TextStyle screenIndicator = TextStyle(
    fontSize: Sizes.s8,
    color: Colors.grey.shade500,
    fontWeight: FontWeight.w600,
    letterSpacing: 2,
    fontFamily: _fontFamily,
  );

  static const TextStyle seatLabel = TextStyle(
    fontSize: Sizes.s5,
    fontWeight: FontWeight.bold,
    color: Color(0xff202C43),
    fontFamily: _fontFamily,
  );

  static const TextStyle error = TextStyle(
    fontSize: Sizes.s14,
    fontWeight: FontWeight.w400,
    color: CustomColors.pinkColor,
    fontFamily: _fontFamily,
  );

  static const TextStyle searchResultCount = TextStyle(
    fontSize: Sizes.s12,
    fontWeight: FontWeight.w500,
    color: CustomColors.secondaryTextColor,
    fontFamily: _fontFamily,
  );

  static const TextStyle appBarTitle = TextStyle(
    fontSize: Sizes.s16,
    fontWeight: FontWeight.w500,
    color: CustomColors.primaryColor,
    fontFamily: _fontFamily,
  );

  static const TextStyle appBarSubtitle = TextStyle(
    fontSize: Sizes.s12,
    fontWeight: FontWeight.w500,
    color: CustomColors.buttonColor,
    fontFamily: _fontFamily,
  );
}
