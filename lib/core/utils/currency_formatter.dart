import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';

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
      if (prefix.contains('Rp')) {
        return '$prefix${formatted.replaceFirst('Rp ', '')}';
      }
      return '$prefix$formatted';
    }
    if (amount < 0) {
      return '-$formatted';
    }
    return formatted;
  }

  static String formatCompact(num amount) {
    if (amount.abs() >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}B';
    }
    if (amount.abs() >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount.abs() >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}k';
    }
    return format(amount);
  }

  static String? _getUserTimezone() {
    try {
      if (Get.isRegistered<StorageService>()) {
        return Get.find<StorageService>().user?['timezone']?.toString();
      }
    } catch (_) {}
    return null;
  }

  /// Converts a UTC DateTime (e.g. from server/database) to the user's configured timezone
  static DateTime toUserTimezone(dynamic date, [String? timezone]) {
    if (date == null) return DateTime.now();
    DateTime dt;
    if (date is DateTime) {
      dt = date;
    } else {
      String str = date.toString();
      if (!str.endsWith('Z') && !str.contains('+') && !RegExp(r'-\d\d:\d\d$').hasMatch(str)) {
        str = '${str}Z';
      }
      dt = DateTime.tryParse(str) ?? DateTime.now();
    }

    final utc = dt.toUtc();
    final tz = timezone ?? _getUserTimezone();
    if (tz == null || tz.isEmpty) {
      return dt.toLocal();
    }
    if (tz == 'UTC') {
      return utc;
    }
    final offsetHours = getTimezoneOffsetHours(tz);
    final shifted = utc.add(Duration(minutes: (offsetHours * 60).round()));
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
    );
  }

  /// Converts wall-clock DateTime in user's timezone to pure UTC for sending to API/DB
  static DateTime toUtcFromUserTimezone(DateTime date, [String? timezone]) {
    final tz = timezone ?? _getUserTimezone();
    if (tz == null || tz.isEmpty || tz == 'UTC') {
      return date.toUtc();
    }
    final offsetHours = getTimezoneOffsetHours(tz);
    return DateTime.utc(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
    ).subtract(Duration(minutes: (offsetHours * 60).round()));
  }

  static String formatDate(dynamic date, [String? timezone]) {
    if (date == null) return '';
    final local = toUserTimezone(date, timezone);
    final now = toUserTimezone(DateTime.now().toUtc(), timezone);

    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return 'Today, ${DateFormat('HH:mm').format(local)}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year && local.month == yesterday.month && local.day == yesterday.day) {
      return 'Yesterday, ${DateFormat('HH:mm').format(local)}';
    }
    return DateFormat('d MMM yyyy, HH:mm', 'en_US').format(local);
  }

  static String formatShortDate(dynamic date, [String? timezone]) {
    if (date == null) return '';
    final local = toUserTimezone(date, timezone);
    return DateFormat('d MMM', 'en_US').format(local);
  }

  static String formatDisplayDate(dynamic date, [String? timezone]) {
    if (date == null) return '';
    final local = toUserTimezone(date, timezone);
    final now = toUserTimezone(DateTime.now().toUtc(), timezone);

    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return 'Today, ${DateFormat('d MMM yyyy').format(local)}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year && local.month == yesterday.month && local.day == yesterday.day) {
      return 'Yesterday, ${DateFormat('d MMM yyyy').format(local)}';
    }
    return DateFormat('EEE, d MMM yyyy').format(local);
  }

  static DateTime nowInTimezone([String? timezone]) {
    return toUserTimezone(DateTime.now().toUtc(), timezone);
  }

  static double getTimezoneOffsetHours(String? tz) {
    if (tz == null || tz.isEmpty) {
      return DateTime.now().timeZoneOffset.inMinutes / 60.0;
    }
    switch (tz) {
      case 'Asia/Jakarta':
        return 7.0;
      case 'Asia/Makassar':
      case 'Asia/Singapore':
        return 8.0;
      case 'Asia/Jayapura':
      case 'Asia/Tokyo':
        return 9.0;
      case 'Europe/London':
        return 0.0;
      case 'America/New_York':
        return -5.0;
      case 'America/Los_Angeles':
        return -8.0;
      case 'UTC':
        return 0.0;
      default:
        return DateTime.now().timeZoneOffset.inMinutes / 60.0;
    }
  }
}
