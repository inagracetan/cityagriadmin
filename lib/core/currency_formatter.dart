import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove all non-numeric characters except for the decimal point
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');

    // Handle multiple decimal points
    if (newText.split('.').length > 2) {
      return oldValue;
    }

    // If the new text starts with a dot, prepend a zero
    if (newText.startsWith('.')) {
      newText = '0$newText';
    }

    // Split into integer and decimal parts
    List<String> parts = newText.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // Limit decimal part to 2 digits
    if (decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2);
    }

    // Format the integer part with commas
    if (integerPart.isNotEmpty) {
      double? value = double.tryParse(integerPart);
      if (value != null) {
        final formatter = NumberFormat('#,###', 'en_US');
        integerPart = formatter.format(value);
      }
    }

    // Combine parts
    String finalString = integerPart;
    if (newText.contains('.')) {
      finalString += '.$decimalPart';
    }

    return TextEditingValue(
      text: finalString,
      selection: TextSelection.collapsed(offset: finalString.length),
    );
  }

  /// Static method to format a double value to currency string with commas
  static String formatDouble(double value) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(value);
  }

  /// Static method to parse a formatted string back to double
  static double parse(String value) {
    if (value.isEmpty) return 0.0;
    try {
      return double.parse(value.replaceAll(',', ''));
    } catch (_) {
      return 0.0;
    }
  }
}
