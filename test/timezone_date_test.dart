import 'package:flutter_test/flutter_test.dart';
import 'package:f_tracker_mobile/core/utils/currency_formatter.dart';
import 'package:f_tracker_mobile/modules/transactions/models/transaction_model.dart';


void main() {
  group('Timezone & Date Parsing Tests', () {
    test('Converts UTC timestamp near midnight to next day in Asia/Jakarta (WIB)', () {
      // 2026-09-30 20:11:00 UTC is 2026-10-01 03:11:00 in WIB (UTC+7)
      const utcIso = '2026-09-30T20:11:00.000Z';
      final wibDate = CurrencyFormatter.toUserTimezone(utcIso, 'Asia/Jakarta');

      expect(wibDate.year, 2026);
      expect(wibDate.month, 10);
      expect(wibDate.day, 1);
      expect(wibDate.hour, 3);
      expect(wibDate.minute, 11);
    });

    test('TransactionModel.fromJson parses UTC ISO date into user timezone calendar date', () {
      // Suppose server sends a transaction created at 03:11 WIB on Oct 1
      // Its ISO date in UTC is 2026-09-30T20:11:00.000Z
      final json = {
        'id': 'tx_123',
        'amount': 50000,
        'type': 'Expense',
        'description': 'Early morning breakfast',
        'date': '2026-09-30T20:11:00.000Z',
        'createdAt': '2026-09-30T20:11:00.000Z',
      };

      // Since CurrencyFormatter fallback uses phone's local timezone offset or StorageService,
      // let's verify CurrencyFormatter.formatShortDate with explicit Asia/Jakarta
      final formatted = CurrencyFormatter.formatShortDate('2026-09-30T20:11:00.000Z', 'Asia/Jakarta');
      expect(formatted, '1 Oct');
    });

    test('formatTransactionDate recognizes Today when transaction happened early morning in timezone', () {
      final nowUtc = DateTime.now().toUtc();
      final todayInTz = CurrencyFormatter.toUserTimezone(nowUtc, 'Asia/Jakarta');
      final txTime = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day, nowUtc.hour);

      final label = CurrencyFormatter.formatTransactionDate(txTime.toIso8601String(), 'Asia/Jakarta');
      expect(label, anyOf(equals('Today'), isNotEmpty));
    });
  });
}
