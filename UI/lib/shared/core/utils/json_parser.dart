// lib/shared/core/utils/json_parser.dart
class JsonParser {
  static int readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double readDouble(dynamic value, {double fallback = 0.0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static String readString(dynamic value, {String fallback = ''}) {
    if (value is String) return value;
    if (value == null) return fallback;
    return value.toString();
  }

  static String? readNullableString(dynamic value) {
    if (value == null) return null;
    final parsed = value.toString().trim();
    return parsed.isEmpty ? null : parsed;
  }

  static String readFirstString(List<dynamic> options, {String fallback = ''}) {
    for (final opt in options) {
      if (opt != null) {
        final parsed = opt.toString().trim();
        if (parsed.isNotEmpty) return parsed;
      }
    }
    return fallback;
  }
}