import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _idrFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(num amount, {String? prefix}) {
    final formatted = _idrFormat.format(amount.abs());
    if (prefix != null) {
      return '$prefix$formatted';
    }
    if (amount < 0) {
      return '-$formatted';
    }
    return formatted;
  }

  static String formatCompact(num amount) {
    if (amount.abs() >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}M';
    }
    if (amount.abs() >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    }
    if (amount.abs() >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return format(amount);
  }

  static String formatDate(dynamic date) {
    if (date == null) return '';
    DateTime dt;
    if (date is DateTime) {
      dt = date;
    } else {
      dt = DateTime.tryParse(date.toString()) ?? DateTime.now();
    }

    final local = dt.toLocal();
    final now = DateTime.now();
    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return 'Hari ini, ${DateFormat('HH:mm').format(local)}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year && local.month == yesterday.month && local.day == yesterday.day) {
      return 'Kemarin, ${DateFormat('HH:mm').format(local)}';
    }
    return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(local);
  }

  static String formatShortDate(dynamic date) {
    if (date == null) return '';
    DateTime dt;
    if (date is DateTime) {
      dt = date;
    } else {
      dt = DateTime.tryParse(date.toString()) ?? DateTime.now();
    }
    return DateFormat('d MMM', 'id_ID').format(dt.toLocal());
  }
}
