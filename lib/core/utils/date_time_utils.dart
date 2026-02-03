import 'package:intl/intl.dart';

class DateTimeUtils {
  static int weeksInYear({
    required int currentYear,
  }) {
    DateTime dec28 = DateTime(currentYear, 12, 28);
    int dayOfDec28 = int.parse(DateFormat("D").format(dec28));
    int weeks = ((dayOfDec28 - dec28.weekday + 10) / 7).floor();
    return weeks;
  }

  static List<String> getWeekStartEndDates({
    required int weekNo,
    required int currentYear,
  }) {
    var days = ((weekNo - 1) * 7) + 0;
    final firstDay = DateTime.utc(currentYear, 1, 1);
    final firstMonday = _getMonday(firstDay.weekday);
    var date = DateTime.utc(currentYear, 1, days + firstMonday);
    return [
      date.toIso8601String(),
      date.add(const Duration(days: 6)).toIso8601String()
    ];
  }

  static int _getMonday(
    int weekday,
  ) {
    int count = 1;
    while (weekday <= 7) {
      count++;
      weekday++;
    }
    return count;
  }

  static sortDaysDateList(daysList) {
    List<DateTime> daysListDate = [];
    for (final item in daysList) {
      daysListDate.add(DateTime.parse(item));
    }
    daysListDate.sort((a, b) => a.compareTo(b));
    List<String> daysListString = [];
    for (final item in daysListDate) {
      daysListString.add(DateFormat('yyyy-MM-dd').format(item));
    }
    return daysListString;
  }

  static int? getAgeInMonth({required String dateOfBirth}) {
    int? ageInMonths;
    if (dateOfBirth != '') {
      var birthDate = DateTime.tryParse(dateOfBirth);
      if (birthDate != null) {
        final now = DateTime.now();

        int years = now.year - birthDate.year;
        int months = now.month - birthDate.month;
        int days = now.day - birthDate.day;

        if (months < 0 || (months == 0 && days < 0)) {
          years--;
          months += (days < 0 ? 11 : 12);
        }
        ageInMonths = (years * 12) + months;
      }
    }
    return ageInMonths;
  }

  static int getCurrentWeekNumber() {
    var date = DateTime.now();
    int dayOfYear = int.parse(DateFormat("D").format(date));
    int woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) {
      woy = weeksInYear(currentYear: date.year - 1);
    } else if (woy > weeksInYear(currentYear: date.year)) {
      woy = 1;
    }
    return woy;
  }

  static String getMonthNameByNumber(String date) {
    DateTime dateTime = DateTime.parse('$date-01');
    String formattedDate = DateFormat.yMMM().format(dateTime);
    return formattedDate;
  }

  static String formatDateTime(String date) {
    DateTime dateTime = DateTime.parse(date);
    String formattedDate = DateFormat("dd MMM, yyyy").format(dateTime);

    return formattedDate;
  }

  static String formattedTime(String date) {
    DateTime dateTime = DateTime.parse(date);
    String formattedTime = DateFormat('h:mm a').format(dateTime);

    return formattedTime;
  }

  static String formateDate(DateTime datetime) {
    String formattedDate = DateFormat('dd MMM yyyy').format(datetime);
    return formattedDate;
  }

  static String formateMonth(DateTime datetime) {
    String formattedDate = DateFormat('yyyy-MM').format(datetime);
    return formattedDate;
  }

  static String formatVisitDate(DateTime datetime) {
    String formattedVisitDate = DateFormat('MM/dd/yyyy').format(datetime);
    return formattedVisitDate;
  }

  static String getNextMonth(int months){
    DateTime datetime = DateTime.now();
    DateTime oneMonthLater = _addMonths(datetime, months);
    return DateFormat('yyyy-MM').format(oneMonthLater);
  }

  static DateTime _addMonths(DateTime date, int months) {
    int newYear = date.year;
    int newMonth = date.month + months;
    int newDay = date.day;

    if (newMonth > 12) {
      newYear += newMonth ~/ 12;
      newMonth = newMonth % 12;
      if (newMonth == 0) {
        newMonth = 12;
        newYear -= 1;
      }
    }

    int daysInNewMonth = DateTime(newYear, newMonth + 1, 0).day;
    if (newDay > daysInNewMonth) {
      newDay = daysInNewMonth;
    }

    return DateTime(newYear, newMonth, newDay, date.hour, date.minute, date.second, date.millisecond, date.microsecond);
  }
}
