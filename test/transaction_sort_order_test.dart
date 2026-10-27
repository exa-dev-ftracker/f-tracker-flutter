import 'package:flutter_test/flutter_test.dart';
import 'package:f_tracker_mobile/modules/transactions/controllers/transaction_controller.dart';
import 'package:f_tracker_mobile/modules/transactions/models/transaction_model.dart';
import 'package:f_tracker_mobile/modules/transactions/repositories/transaction_repository.dart';
import 'package:f_tracker_mobile/core/services/storage_service.dart';
import 'package:get/get.dart';

// Minimal mock repository
class FakeTransactionRepository extends Fake implements TransactionRepository {}

// Minimal mock storage service
class FakeStorageService extends Fake implements StorageService {
  @override
  Map<String, dynamic>? get user => {'timezone': 'Asia/Jakarta'};

  @override
  List<dynamic> get cachedTransactions => [];

  @override
  List<dynamic> get cachedCategories => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Transaction Date & Sort Ordering Tests', () {
    late TransactionController controller;

    setUp(() {
      Get.reset();
      controller = TransactionController(
        repository: FakeTransactionRepository(),
        storageService: FakeStorageService(),
      );
    });

    tearDown(() {
      Get.reset();
    });

    test('groupedTransactions sorts date keys in descending order for newest sort', () {
      controller.selectedSort.value = 'newest';

      final txToday = TransactionModel(
        id: 'tx_today',
        amount: 50000,
        type: 'Expense',
        description: 'Today Lunch',
        date: DateTime(2026, 10, 27),
        createdAt: DateTime(2026, 10, 27, 12, 0),
      );

      final txYesterday = TransactionModel(
        id: 'tx_yesterday',
        amount: 30000,
        type: 'Expense',
        description: 'Yesterday Dinner',
        date: DateTime(2026, 10, 26),
        createdAt: DateTime(2026, 10, 26, 19, 0),
      );

      final txPast = TransactionModel(
        id: 'tx_past',
        amount: 100000,
        type: 'Expense',
        description: 'Past Groceries',
        date: DateTime(2026, 10, 20),
        createdAt: DateTime(2026, 10, 20, 10, 0),
      );

      // Even if inserted out of chronological order
      controller.transactions.assignAll([txYesterday, txToday, txPast]);
      controller.sortTransactions();

      // Check transactions list order
      expect(controller.transactions[0].id, equals('tx_today'));
      expect(controller.transactions[1].id, equals('tx_yesterday'));
      expect(controller.transactions[2].id, equals('tx_past'));

      // Check groupedTransactions date keys order
      final grouped = controller.groupedTransactions;
      final keys = grouped.keys.toList();

      expect(keys, equals(['2026-10-27', '2026-10-26', '2026-10-20']));
    });

    test('Adding an older past transaction does not jump to the top above newer dates', () {
      controller.selectedSort.value = 'newest';

      final txToday = TransactionModel(
        id: 'tx_today',
        amount: 50000,
        type: 'Expense',
        description: 'Today Coffee',
        date: DateTime(2026, 10, 27),
        createdAt: DateTime(2026, 10, 27, 8, 30),
      );

      controller.transactions.assignAll([txToday]);

      // Now user adds a transaction dated in the past (e.g. 2026-10-24)
      final pastAddedTx = TransactionModel(
        id: 'temp_past',
        amount: 25000,
        type: 'Expense',
        description: 'Past Snack',
        date: DateTime(2026, 10, 24),
        createdAt: DateTime.now(),
      );

      controller.transactions.add(pastAddedTx);
      controller.sortTransactions();

      final grouped = controller.groupedTransactions;
      final dateKeys = grouped.keys.toList();

      // 2026-10-27 must remain at index 0 (top), 2026-10-24 must be at index 1 (below)
      expect(dateKeys.first, equals('2026-10-27'));
      expect(dateKeys.last, equals('2026-10-24'));
      expect(controller.transactions.first.id, equals('tx_today'));
      expect(controller.transactions.last.id, equals('temp_past'));
    });

    test('Same-day transactions are sorted by createdAt descending for newest', () {
      controller.selectedSort.value = 'newest';

      final txMorning = TransactionModel(
        id: 'tx_morning',
        amount: 15000,
        type: 'Expense',
        description: 'Morning Coffee',
        date: DateTime(2026, 10, 27),
        createdAt: DateTime(2026, 10, 27, 8, 0),
      );

      final txEvening = TransactionModel(
        id: 'tx_evening',
        amount: 60000,
        type: 'Expense',
        description: 'Evening Dinner',
        date: DateTime(2026, 10, 27),
        createdAt: DateTime(2026, 10, 27, 20, 0),
      );

      controller.transactions.assignAll([txMorning, txEvening]);
      controller.sortTransactions();

      // Latest transaction (evening) should appear first
      expect(controller.transactions[0].id, equals('tx_evening'));
      expect(controller.transactions[1].id, equals('tx_morning'));

      final grouped = controller.groupedTransactions;
      expect(grouped['2026-10-27']![0].id, equals('tx_evening'));
      expect(grouped['2026-10-27']![1].id, equals('tx_morning'));
    });

    test('groupedTransactions sorts date keys in ascending order for oldest sort', () {
      controller.selectedSort.value = 'oldest';

      final tx1 = TransactionModel(
        id: 'tx_1',
        amount: 50000,
        type: 'Expense',
        description: 'Old',
        date: DateTime(2026, 10, 10),
        createdAt: DateTime(2026, 10, 10, 10, 0),
      );

      final tx2 = TransactionModel(
        id: 'tx_2',
        amount: 50000,
        type: 'Expense',
        description: 'New',
        date: DateTime(2026, 10, 25),
        createdAt: DateTime(2026, 10, 25, 10, 0),
      );

      controller.transactions.assignAll([tx2, tx1]);
      controller.sortTransactions();

      final grouped = controller.groupedTransactions;
      final keys = grouped.keys.toList();

      expect(keys, equals(['2026-10-10', '2026-10-25']));
      expect(controller.transactions.first.id, equals('tx_1'));
      expect(controller.transactions.last.id, equals('tx_2'));
    });
  });
}
