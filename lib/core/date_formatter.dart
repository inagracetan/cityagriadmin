import 'package:intl/intl.dart';

class AppDateFormatter {
  static final DateFormat standard = DateFormat('MM/dd/yyyy');

  static String format(DateTime date) {
    return standard.format(date);
  }

  static DateTime? parse(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    
    // Try MM/dd/yyyy first as it is the new standard
    try {
      return standard.parse(dateStr);
    } catch (_) {}

    // Try ISO format (yyyy-MM-dd)
    try {
      return DateTime.tryParse(dateStr);
    } catch (_) {}

    // Try MM-dd-yyyy (old export format)
    try {
      return DateFormat('MM-dd-yyyy').parse(dateStr);
    } catch (_) {}

    return null;
  }
}
