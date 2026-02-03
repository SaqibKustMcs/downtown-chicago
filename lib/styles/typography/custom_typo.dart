import 'package:flutter/material.dart';

import '../colors/custom_colors.dart';
import '../layouts/font.dart';

class CustomTextStyle {
  static const TextStyle unfilledButtonTextStyle = TextStyle(
    fontSize: FontSize.f16,
    color: CustomColors.purpleColor,
    fontWeight: FontWeight.w500,
    height: 1.18,
    fontFamily: "Poppins",
  );
  static const TextStyle filledButtonTextStyle = TextStyle(
    fontSize: FontSize.f16,
    color: CustomColors.backgroundColor,
    fontWeight: FontWeight.w500,
    height: 1.18,
    fontFamily: "Poppins",
  );
  static const TextStyle lightFilledButtonTextStyle = TextStyle(
    fontSize: FontSize.f14,
    color: CustomColors.purpleColor,
    fontWeight: FontWeight.w500,
    height: 1.143,
    fontFamily: "Poppins",
  );
}
