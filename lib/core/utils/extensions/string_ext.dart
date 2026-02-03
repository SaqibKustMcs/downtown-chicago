import 'dart:convert';

import 'package:intl/intl.dart' as intl;

extension StringExtension on String {
  String get capitalized => this[0].toUpperCase() + substring(1);

  String get capitalizeAllWords => toLowerCase().split(' ').map((word) {
        final leftText = (word.length > 1) ? word.substring(1, word.length) : '';
        return word[0].toUpperCase() + leftText;
      }).join(' ');

  String get removeAllWhiteSpace => replaceAll(RegExp(r'\s+\b|\b\s'), '');

  bool get isNumber => RegExp('[0-9]').hasMatch(this);

  bool get isLetter => RegExp('[A-Za-z]').hasMatch(this);

  String insert(String other, int index) => (StringBuffer()
        ..write(substring(0, index))
        ..write(other)
        ..write(substring(index)))
      .toString();

  String append(String other) => this + other;

  String get numCurrency => intl.NumberFormat.currency(
        customPattern: '#,##0',
        locale: 'en_US',
        decimalDigits: 0,
      ).format(
        double.tryParse(this),
      );

  bool get isJsonDecodable {
    try {
      jsonDecode(this) as Map<String, dynamic>;
    } on FormatException catch (_) {
      return false;
    }
    return true;
  }

  String get toLowerCamelCase {
    final out = StringBuffer();
    final parts = split('_');
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isNotEmpty) out.write(i == 0 ? part.toLowerCase() : part.capitalized);
    }
    return out.toString();
  }

  String get toUpperCamelCase {
    final out = StringBuffer();
    final parts = split('_');
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isNotEmpty) {
        out.write(part.capitalized);
      }
    }
    return out.toString();
  }

  String get toSnakeCase => replaceAllMapped(
        RegExp('[A-Z][a-z]*'),
        (match) => '${match.start == 0 ? '' : '_'}${match[0]!.toLowerCase()}',
      );

  String get toEncodedBase64 => base64Encode(utf8.encode(this));

  String get toDecodedBase64 => String.fromCharCodes(base64Decode(this));

  List<int> get utf8Encode => utf8.encode(this);
}

extension AssetExtension on String {
  String get pngIcon => 'lib/assets/icons/$this.png';

  String get svgIcon => 'lib/assets/icons/$this.svg';

  String get jsonIcon => 'lib/assets/icons/$this.json';

  String get pngImage => 'lib/assets/images/$this.png';

  String get svgImage => 'lib/assets/images/$this.svg';

  String get jsonImage => 'lib/assets/images/$this.json';

  String get json => 'lib/assets/jsons/$this.json';
}

extension NullOrEmptyExtension on String? {
  bool get isNullOrEmpty => this?.isEmpty ?? true;

  bool get isNotNullAndEmpty => this != null && this!.isNotEmpty;
}
