import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class Helpers {
  static void unFocus() {
    WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
  }

  static Future<bool> checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.none) && results.length == 1) {
      return false;
    }
    // Has at least one connection type (wifi, mobile, ethernet, vpn, etc.)
    return true;
  }

  static String getServerTimeFromMillis(int? timeInMillis, {DateFormat? format}) {
    if (timeInMillis != null) {
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timeInMillis);
      return format != null ? format.format(dateTime) : DateFormat('yyyy-MM-dd').format(dateTime);
    } else {
      return '';
    }
  }

  static String getDateTimeFromMillis(String? timeInMillis) {
    if (timeInMillis == null) {
      return '';
    }
    try {
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timeInMillis));

      String? day;
      if (dateTime.day < 10) {
        day = '0${dateTime.day}';
      } else {
        day = '${dateTime.day}';
      }

      String? month;
      if (dateTime.month < 10) {
        month = '0${dateTime.month}';
      } else {
        month = '${dateTime.month}';
      }

      String? hour;
      if (dateTime.hour == 0) {
        hour = '12';
      } else if (dateTime.hour < 10) {
        hour = '0${dateTime.hour}';
      } else if (dateTime.hour > 12) {
        hour = '${dateTime.hour - 12}';
      } else {
        hour = '${dateTime.hour}';
      }

      String? minute;
      if (dateTime.minute < 10) {
        minute = '0${dateTime.minute}';
      } else {
        minute = '${dateTime.minute}';
      }

      String ampm = dateTime.hour >= 12 ? 'PM' : 'AM';

      return '${dateTime.year}-$month-$day $hour:$minute $ampm';
    } catch (_) {
      return '';
    }
  }

  static String getMillisFromDate(String date) {
    try {
      return DateTime.parse(date).millisecondsSinceEpoch.toString();
    } catch (e) {
      return '';
    }
  }

  static DateTime getDateTimeFromDate(String? date) {
    try {
      if (date != null) {
        int year = int.parse(date.split("-")[0]);
        int month = int.parse(date.split("-")[1]);
        int day = int.parse(date.split("-")[2]);
        return DateTime(year, month, day);
      } else {
        return DateTime.now();
      }
    } catch (e) {
      return DateTime.now();
    }
  }

  static String? formattedDateTime(String? date, {String format = 'yyyy-MM-dd hh:mm a'}) {
    if (date != null) {
      DateTime? dateTime = DateTime.tryParse(date);
      if (dateTime != null) {
        return DateFormat(format).format(dateTime);
      }
    }
    return null;
  }

  static Widget assetImage(String? path, {Color? color, double? width, double? height, BoxFit boxFit = BoxFit.contain, BlendMode? blendMode}) {
    if (path != null) {
      if (path.endsWith('.svg')) {
        return SvgPicture.asset(path, width: width, height: height, fit: boxFit, color: color);
      } else if (path.endsWith('.png') || path.endsWith('.jpg') || path.endsWith('.gif')) {
        return Image.asset(path, width: width, height: height, fit: boxFit, color: color, colorBlendMode: blendMode);
      }
    }
    return const SizedBox.shrink();
  }
}
