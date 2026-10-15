import 'package:flutter_test/flutter_test.dart';
import 'package:f_tracker_mobile/core/constants/api_endpoints.dart';
import 'package:f_tracker_mobile/modules/transactions/controllers/transaction_controller.dart';
import 'package:f_tracker_mobile/modules/transactions/models/transaction_model.dart';
import 'package:f_tracker_mobile/modules/transactions/repositories/transaction_repository.dart';

void main() {
  group('DailyCalendarSummary Tests', () {
    test('Calculates financial summary metrics correctly', () {
      final summary = DailyCalendarSummary(
        date: DateTime(2026, 10, 15),
        totalIncome: 150000,
        totalExpense: 50000,
        count: 2,
        transactions: const [],
      );

      expect(summary.netBalance, 100000);
      expect(summary.hasIncome, isTrue);
      expect(summary.hasExpense, isTrue);
      expect(summary.hasTransactions, isTrue);
    });

    test('Handles zero and negative net balance correctly', () {
      final zeroSummary = DailyCalendarSummary(
        date: DateTime(2026, 10, 15),
      );
      expect(zeroSummary.netBalance, 0);
      expect(zeroSummary.hasIncome, isFalse);
      expect(zeroSummary.hasExpense, isFalse);
      expect(zeroSummary.hasTransactions, isFalse);

      final negativeSummary = DailyCalendarSummary(
        date: DateTime(2026, 10, 15),
        totalIncome: 0,
        totalExpense: 75000,
        count: 1,
      );
      expect(negativeSummary.netBalance, -75000);
      expect(negativeSummary.hasIncome, isFalse);
      expect(negativeSummary.hasExpense, isTrue);
    });
  });

  group('Calendar Grouping & Aggregation Logic', () {
    test('Groups transactions by yyyy-MM-dd date key accurately', () {
      final now = DateTime(2026, 10, 15, 14, 30);
      final tx1 = TransactionModel(
        id: 'tx_1',
        amount: 200000,
        type: 'Income',
        description: 'Salary Bonus',
        date: now,
        createdAt: now,
      );
      final tx2 = TransactionModel(
        id: 'tx_2',
        amount: 45000,
        type: 'Expense',
        description: 'Coffee & Snack',
        date: now,
        createdAt: now,
      );
      final txYesterday = TransactionModel(
        id: 'tx_3',
        amount: 60000,
        type: 'Expense',
        description: 'Dinner',
        date: DateTime(2026, 10, 14, 19, 0),
        createdAt: DateTime(2026, 10, 14, 19, 0),
      );

      final txList = [tx1, tx2, txYesterday];

      // Simulate grouping logic
      final groups = <String, List<TransactionModel>>{};
      for (final t in txList) {
        final key = '${t.date.year.toString().padLeft(4, '0')}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
        groups.putIfAbsent(key, () => []).add(t);
      }

      expect(groups.containsKey('2026-10-15'), isTrue);
      expect(groups['2026-10-15']!.length, 2);
      expect(groups.containsKey('2026-10-14'), isTrue);
      expect(groups['2026-10-14']!.length, 1);

      // Verify daily totals
      final todayTxs = groups['2026-10-15']!;
      double inc = 0.0;
      double exp = 0.0;
      for (final t in todayTxs) {
        if (t.isIncome) {
          inc += t.amount;
        } else {
          exp += t.amount;
        }
      }

      expect(inc, 200000);
      expect(exp, 45000);
      expect(inc - exp, 155000);
    });
  });

  group('Calendar API Endpoint & Response Tests', () {
    test('ApiEndpoints defines dedicated transactionsCalendar path', () {
      expect(
        ApiEndpoints.transactionsCalendar,
        equals('/api/v1/transactions/calendar'),
      );
    });

    test('CalendarTransactionsResponse maps items, bounds and financial summary', () {
      final now = DateTime(2026, 10, 15);
      final item1 = TransactionModel(
        id: 'cal_1',
        amount: 500000,
        type: 'Income',
        description: 'Salary',
        date: now,
        createdAt: now,
      );
      final item2 = TransactionModel(
        id: 'cal_2',
        amount: 150000,
        type: 'Expense',
        description: 'Groceries',
        date: now,
        createdAt: now,
      );

      final response = CalendarTransactionsResponse(
        items: [item1, item2],
        total: 2,
        from: '2026-10-01',
        to: '2026-10-31',
        totalIncome: 500000,
        totalExpense: 150000,
        balance: 350000,
        count: 2,
      );

      expect(response.items.length, 2);
      expect(response.total, 2);
      expect(response.from, '2026-10-01');
      expect(response.to, '2026-10-31');
      expect(response.totalIncome, 500000);
      expect(response.totalExpense, 150000);
      expect(response.balance, 350000);
      expect(response.count, 2);
    });
  });
}
