/// Currency formatter utility for PKR (Pakistani Rupees)
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Format amount as PKR currency string
  /// Example: format(100.50) returns "Rs. 100.50"
  static String format(double amount, {int decimalPlaces = 2}) {
    return 'Rs. ${amount.toStringAsFixed(decimalPlaces)}';
  }

  /// Format amount as PKR currency string without decimals
  /// Example: formatInt(100) returns "Rs. 100"
  static String formatInt(double amount) {
    return 'Rs. ${amount.toInt()}';
  }

  /// Format amount as PKR currency string, showing "Free" if amount is 0
  /// Example: formatWithFree(0) returns "Free"
  /// Example: formatWithFree(100.50) returns "Rs. 100.50"
  static String formatWithFree(double amount, {int decimalPlaces = 2}) {
    if (amount == 0.0) {
      return 'Free';
    }
    return format(amount, decimalPlaces: decimalPlaces);
  }
}
