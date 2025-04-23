import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Format a number as Indonesian Rupiah
  static String format(double amount) {
    return _formatter.format(amount);
  }

  // Format as compact (e.g., 1.5M, 2.3K)
  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return 'Rp ${amount.toInt()}';
    }
  }

  // Parse a formatted string back to a number
  static double parse(String formatted) {
    try {
      // Remove currency symbol and any non-numeric characters except decimal point
      String cleaned = formatted.replaceAll('Rp', '')
                               .replaceAll('.', '')
                               .replaceAll(',', '.')
                               .trim();
      return double.parse(cleaned);
    } catch (e) {
      print('Error parsing currency: $e');
      return 0.0;
    }
  }
}