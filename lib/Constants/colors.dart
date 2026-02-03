import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

var primaryColor = Color(0xffe82643).obs;
var textHeadingColor = Color(0xff2D2E4A).obs;
var hintColor = Color(0xffA7A6B4).obs;
var lightGrey = Color(0xFFF5F5F5).obs;
var grey2 = Color(0xFFA7A6B4).obs;
var grey3 = Color(0xFF676767).obs;
var darkGrey = Color(0xFF2D2E4A).obs;
var background = Color(0xFFFFFFFF).obs;

var primaryBackgroundColor = Color(0xFFEF643F).obs;
var primaryColorDull = Color(0xFF0C9D7D).obs;
var dividerColor = Color(0xFFF2F2F2).obs;
Color nonActiveInputColor = const Color(0xFFEDEDED);
Color activeInputColor = const Color(0xFFFCFCFC);
Color activeInputBorderColor = const Color(0xFF03314B);
Color nonActiveInputBorderColor = Colors.transparent;
Color filledInputColor = const Color(0xFFEDEDED);
var headingColor = const Color(0xFF030319).obs;
var labelColor = Color(0xFF8F92A1).obs;
var dashLabelColor = Color(0xFFB4B6DB).obs;
var dashBtnColor = Color(0xFF292E9A).obs;
Color placeholderColor = Color(0xff8F92A1);
var inputFieldTextColor = Color(0xFF0F001C).obs;
var inputFieldBackgroundColor = Color(0xFFFAFAFA).obs;
var listCardColor = Color(0xFFFAFAFA).obs;

var appBarColor = Color(0xff462D81).obs;
var chatBoxBg = Color(0xffF8F8F8).obs;

var btnTxtColor = Color(0xFFFCFCFC).obs;
var errorTxtColor = const Color(0xFFFF0E41).obs;
var lightColor = const Color(0xFFFCFCFC).obs;
var cardColor = Color(0xFFFFFFFF).obs;
var greenCardColor = Color(0xFF39B171).obs;
var redCardColor = Color(0xFFF16464).obs;
var chipChoiceColor = Color(0xFF27C19F).withOpacity(0.1).obs;
var bSheetbtnColor = Color(0x0D27C19F).withOpacity(0.10).obs;

///////////history screen colors//////////////
var bgCintainerColor = Color(0xff27C19F).obs;
var bg2CintainerColor = Color(0xffFED5D5).obs;
var iconUpColor = Color(0xffE34446).obs;

var iconDownColor = Color(0xff0C9D7D).obs;

//////////////history/////////

var appShadow = [
  BoxShadow(
    color: Color.fromRGBO(155, 155, 155, 15).withOpacity(0.15),
    spreadRadius: 5,
    blurRadius: 7,
    offset: Offset(0, 3), // changes position of shadow
  ),
].obs;

var homeCardBgShadow = [BoxShadow(color: Color(0x00000000), offset: Offset(0.0, 4.0), blurRadius: 20.0)].obs;

// Additional colors for shop detail screen
var borderColor = Color(0xFFF5F5F5).obs;
var grey1 = Color(0xFFE0E0E0).obs;
var yellowColor = Color(0xFFFFC107).obs;
var primaryColorOpacity = Color(0xFFEF643F).withOpacity(0.3).obs;
