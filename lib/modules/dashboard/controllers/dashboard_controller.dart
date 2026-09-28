import 'package:get/get.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/utils/app_haptics.dart';
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
