import 'package:intl/intl.dart';

/// Standardized date formatter for the application.
class DateFormatter {
  static final DateFormat standard = DateFormat('MM/dd/yyyy');
  static final DateFormat withTime = DateFormat('MM/dd/yyyy HH:mm');

  static String format(DateTime date) {
    return standard.format(date);
  }

  static String formatTimestamp(DateTime? date) {
    if (date == null) return 'N/A';
    return withTime.format(date);
  }

  static DateTime? parse(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr.toLowerCase() == 'null') return null;
    
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

/// Legacy alias to maintain compatibility with existing code.
typedef AppDateFormatter = DateFormatter;

