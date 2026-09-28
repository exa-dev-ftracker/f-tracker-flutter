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

  /// Formats transaction: date is the fixed calendar date (Year, Month, Day),
  /// while time comes from createdAt converted to the user's timezone.
  static String formatTransactionDateTime(dynamic txDate, dynamic createdAt, [String? timezone]) {
    if (txDate == null && createdAt == null) return '';

    // 1. Resolve calendar date
    DateTime calendarDate;
    if (txDate is DateTime) {
      calendarDate = txDate;
    } else if (txDate != null && txDate.toString().isNotEmpty) {
      final str = txDate.toString();
      final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(str);
      if (match != null) {
        calendarDate = DateTime(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      } else {
        calendarDate = DateTime.tryParse(str) ?? DateTime.now();
      }
    } else {
      calendarDate = DateTime.now();
    }

    // 2. Compare against "Today" and "Yesterday" in user's timezone
    final nowInTz = toUserTimezone(DateTime.now().toUtc(), timezone);
    final today = DateTime(nowInTz.year, nowInTz.month, nowInTz.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final calOnly = DateTime(calendarDate.year, calendarDate.month, calendarDate.day);

    String datePart;
    if (calOnly.year == today.year && calOnly.month == today.month && calOnly.day == today.day) {
      datePart = 'Today';
    } else if (calOnly.year == yesterday.year && calOnly.month == yesterday.month && calOnly.day == yesterday.day) {
      datePart = 'Yesterday';
    } else {
      datePart = DateFormat('d MMM yyyy', 'en_US').format(calOnly);
    }

    // 3. Format the creation time from createdAt in user's timezone
    if (createdAt != null) {
      final createdInTz = toUserTimezone(createdAt, timezone);
      final timePart = DateFormat('HH:mm').format(createdInTz);
      return '$datePart, $timePart';
    }

    return datePart;
  }

  static String formatDate(dynamic date, [String? timezone]) {
    return formatTransactionDateTime(date, date, timezone);
  }

  static String formatShortDate(dynamic date, [String? timezone]) {
    if (date == null) return '';
    DateTime dt;
    if (date is DateTime) {
      dt = date;
    } else {
      final str = date.toString();
      final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(str);
      if (match != null) {
        dt = DateTime(int.parse(match.group(1)!), int.parse(match.group(2)!), int.parse(match.group(3)!));
      } else {
        dt = DateTime.tryParse(str) ?? DateTime.now();
      }
    }
    return DateFormat('d MMM', 'en_US').format(dt);
  }

  static String formatDisplayDate(dynamic date, [String? timezone]) {
    return formatTransactionDateTime(date, null, timezone);
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
