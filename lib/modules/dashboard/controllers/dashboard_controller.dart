import 'package:get/get.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../transactions/controllers/transaction_controller.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/repositories/transaction_repository.dart';
import '../models/dashboard_model.dart';
import '../repositories/dashboard_repository.dart';

class DashboardController extends GetxController {
  final DashboardRepository repository;

  DashboardController({required this.repository});

  final dashboardData = Rxn<DashboardData>();
  final isLoading = false.obs;
  final selectedView = 'Month'.obs; // 'Day', 'Week', 'Month', 'Year', 'All'

  StorageService get storageService => Get.find<StorageService>();
  SyncService get syncService => Get.find<SyncService>();

  @override
  void onInit() {
    super.onInit();
    _loadCachedDashboard();
    fetchDashboard();
  }

  void _loadCachedDashboard() {
    final cachedTxs = storageService.cachedTransactions;
    if (cachedTxs.isNotEmpty) {
      try {
        final allTxs = cachedTxs
            .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        final userTz = storageService.user?['timezone']?.toString();
        final now = CurrencyFormatter.nowInTimezone(userTz);
        var filtered = allTxs;

        if (selectedView.value == 'Day') {
          final start = DateTime(now.year, now.month, now.day);
          final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          filtered = allTxs.where((t) => !t.date.isBefore(start) && !t.date.isAfter(end)).toList();
        } else if (selectedView.value == 'Week') {
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          final end = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59, 999);
          filtered = allTxs.where((t) => !t.date.isBefore(start) && !t.date.isAfter(end)).toList();
        } else if (selectedView.value == 'Month') {
          final start = DateTime(now.year, now.month, 1);
          final lastDay = DateTime(now.year, now.month + 1, 0).day;
          final end = DateTime(now.year, now.month, lastDay, 23, 59, 59, 999);
          filtered = allTxs.where((t) => !t.date.isBefore(start) && !t.date.isAfter(end)).toList();
        } else if (selectedView.value == 'Year') {
          final start = DateTime(now.year, 1, 1);
          final end = DateTime(now.year, 12, 31, 23, 59, 59, 999);
          filtered = allTxs.where((t) => !t.date.isBefore(start) && !t.date.isAfter(end)).toList();
        }

        double income = 0;
        double expense = 0;
        final categoryExpenses = <String, Map<String, dynamic>>{};

        for (final t in filtered) {
          if (t.isIncome) {
            income += t.amount;
          } else {
            expense += t.amount;
            final catName = t.category?.name ?? 'Other';
            final existing = categoryExpenses[catName] ?? {
              'name': catName,
              'amount': 0.0,
              'color': t.category?.color ?? '#F43F5E',
              'icon': t.category?.icon ?? 'tag',
            };
            existing['amount'] = (existing['amount'] as double) + t.amount;
            categoryExpenses[catName] = existing;
          }
        }

        final topExpenses = categoryExpenses.values.map((v) {
          final amt = v['amount'] as double;
          final pct = expense > 0 ? ((amt / expense) * 100).round() : 0;
          return TopExpenseItem(
            name: v['name'] as String,
            amount: amt,
            color: v['color'] as String,
            icon: v['icon'] as String,
            percentage: pct,
          );
        }).toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

        final recent = List<TransactionModel>.from(allTxs)
          ..sort((a, b) => b.date.compareTo(a.date));

        dashboardData.value = DashboardData(
          metrics: DashboardMetrics(
            balance: income - expense,
            incomeTotal: income,
            expenseTotal: expense,
            transactionCount: filtered.length,
          ),
          recentTransactions: recent.take(5).toList(),
          topExpenses: topExpenses.take(5).toList(),
        );
        return;
      } catch (_) {}
    }

    final cached = storageService.cachedDashboard;
    if (cached != null) {
      try {
        dashboardData.value = DashboardData.fromJson(cached);
      } catch (_) {}
    }
  }

  Future<void> fetchDashboard() async {
    try {
      isLoading.value = true;
      if (!syncService.isOnline.value) {
        _loadCachedDashboard();
        return;
      }

      final result = await repository.getDashboard(view: selectedView.value);
      dashboardData.value = result;
      storageService.saveCachedDashboard(result.toJson());
    } catch (e) {
      LoggerService.e('Failed to fetch dashboard data, loading cache: $e', tag: 'DashboardController');
      _loadCachedDashboard();
    } finally {
      isLoading.value = false;
    }
  }

  void setView(String view) {
    AppHaptics.selection();
    selectedView.value = view;
    fetchDashboard();
  }

  Future<bool> deleteTransaction(TransactionModel tx) async {
    // Optimistic removal from recent transactions
    final currentData = dashboardData.value;
    if (currentData != null) {
      final updatedRecent = currentData.recentTransactions
          .where((t) => t.id != tx.id)
          .toList();
      final diff = tx.isIncome ? -tx.amount : tx.amount;
      final newIncome = tx.isIncome
          ? (currentData.metrics.incomeTotal - tx.amount)
          : currentData.metrics.incomeTotal;
      final newExpense = !tx.isIncome
          ? (currentData.metrics.expenseTotal - tx.amount)
          : currentData.metrics.expenseTotal;
      final newBalance = currentData.metrics.balance + diff;
      final newCount = currentData.metrics.transactionCount > 0
          ? currentData.metrics.transactionCount - 1
          : 0;

      dashboardData.value = DashboardData(
        metrics: DashboardMetrics(
          balance: newBalance,
          incomeTotal: newIncome,
          expenseTotal: newExpense,
          transactionCount: newCount,
        ),
        recentTransactions: updatedRecent,
        topExpenses: currentData.topExpenses,
      );
    }

    if (Get.isRegistered<TransactionController>()) {
      return await Get.find<TransactionController>().deleteTransaction(tx);
    } else {
      final txController = Get.put(
        TransactionController(
          repository: Get.find<TransactionRepository>(),
          storageService: Get.find<StorageService>(),
        ),
      );
      return await txController.deleteTransaction(tx);
    }
  }
}
