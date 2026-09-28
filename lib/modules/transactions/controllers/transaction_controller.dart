import 'package:f_tracker_mobile/core/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/logger_service.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/utils/app_haptics.dart';
import '../../analytics/controllers/analytics_controller.dart';
import '../../categories/models/category_model.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

class TransactionController extends GetxController {
  final TransactionRepository repository;
  final StorageService storageService;

  TransactionController({
    required this.repository,
    required this.storageService,
  });

  final transactions = <TransactionModel>[].obs;
  final isLoading = false.obs;

  // Filters
  final selectedView = 'Month'.obs; // 'Day', 'Week', 'Month', 'Year', 'All'
  final selectedType = ''.obs; // '', 'Income', 'Expense'
  final searchQuery = ''.obs;
  final searchController = TextEditingController();

  // Summary Metrics
  final incomeTotal = 0.0.obs;
  final expenseTotal = 0.0.obs;
  final balance = 0.0.obs;

  SyncService get syncService => Get.find<SyncService>();

  @override
  void onInit() {
    super.onInit();
    _loadCachedTransactions();
    fetchTransactions();
  }

  void _loadCachedTransactions() {
    final cached = storageService.cachedTransactions;
    if (cached.isNotEmpty) {
      try {
        final list = cached
            .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        transactions.assignAll(list);
        _recalculateSummary();
      } catch (_) {}
    }
  }

  Future<void> fetchTransactions() async {
    try {
      isLoading.value = true;
      if (!syncService.isOnline.value) {
        _loadCachedTransactions();
        return;
      }

      final result = await repository.getTransactions(
        view: selectedView.value,
        type: selectedType.value.isNotEmpty ? selectedType.value : null,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );

      // Preserve any pending local items awaiting sync
      final pendingItems = transactions.where((t) => t.isPendingSync).toList();
      final merged = <TransactionModel>[...pendingItems];
      for (final r in result) {
        if (!merged.any((m) => m.id == r.id)) {
          merged.add(r);
        }
      }

      transactions.assignAll(merged);
      _recalculateSummary();

      // Cache locally for offline availability
      storageService.saveCachedTransactions(
        merged.map((e) => e.toJson()).toList(),
      );
    } catch (e) {
      LoggerService.e(
        'Failed to fetch transactions, loading cache: $e',
        tag: 'TransactionController',
      );
      _loadCachedTransactions();
    } finally {
      isLoading.value = false;
    }
  }

  void _recalculateSummary() {
    double inc = 0;
    double exp = 0;
    for (final t in transactions) {
      if (t.isIncome) {
        inc += t.amount;
      } else {
        exp += t.amount;
      }
    }
    incomeTotal.value = inc;
    expenseTotal.value = exp;
    balance.value = inc - exp;
  }

  void setFilterType(String type) {
    AppHaptics.light();
    if (selectedType.value == type) {
      selectedType.value = '';
    } else {
      selectedType.value = type;
    }
    fetchTransactions();
  }

  void setViewPeriod(String period) {
    AppHaptics.selection();
    selectedView.value = period;
    fetchTransactions();
  }

  void onSearchChanged(String val) {
    searchQuery.value = val.trim();
    fetchTransactions();
  }

  void notifyGlobalStateChange() {
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().fetchDashboard();
    }
    if (Get.isRegistered<AnalyticsController>()) {
      Get.find<AnalyticsController>().fetchAnalytics();
    }
  }

  Future<bool> addTransaction({
    required double amount,
    required String type,
    required String description,
    String? categoryId,
    DateTime? date,
  }) async {
    final txDate = date ?? DateTime.now();

    // 1. Locate category for local display
    CategoryModel? selectedCat;
    if (categoryId != null && categoryId.isNotEmpty) {
      final cachedCats = storageService.cachedCategories;
      for (final c in cachedCats) {
        if (c is Map && (c['_id'] == categoryId || c['id'] == categoryId)) {
          selectedCat = CategoryModel.fromJson(Map<String, dynamic>.from(c));
          break;
        }
      }
    }

    // 2. Generate temporary client ID and optimistic model
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toUtc();
    final utcDate = CurrencyFormatter.toUtcFromUserTimezone(txDate);
    final localTx = TransactionModel(
      id: tempId,
      amount: amount,
      type: type,
      description: description,
      category: selectedCat,
      date: utcDate,
      createdAt: now,
      isPendingSync: true,
    );

    // Optimistic insert
    transactions.insert(0, localTx);
    _recalculateSummary();
    storageService.saveCachedTransactions(
      transactions.map((e) => e.toJson()).toList(),
    );

    // 3. If device is offline, enqueue sync task directly
    if (!syncService.isOnline.value) {
      await syncService.enqueueCreateTransaction(
        tempId: tempId,
        amount: amount,
        type: type,
        description: description,
        categoryId: categoryId,
        date: utcDate,
        createdAt: now,
      );
      AppHaptics.success();
      SnackbarService.success('Transaction recorded successfully!');
      notifyGlobalStateChange();
      return true;
    }

    // 4. If online, attempt direct POST
    try {
      AppHaptics.success();
      final newTx = await repository.createTransaction({
        'amount': amount,
        'type': type,
        'description': description,
        if (categoryId != null && categoryId.isNotEmpty) 'category': categoryId,
        'date': utcDate.toIso8601String(),
      });

      // Replace optimistic tempTx with server transaction
      final index = transactions.indexWhere((t) => t.id == tempId);
      if (index != -1) {
        transactions[index] = newTx.copyWith(isPendingSync: false);
        transactions.refresh();
      }
      storageService.saveCachedTransactions(
        transactions.map((e) => e.toJson()).toList(),
      );
      SnackbarService.success('Transaction recorded successfully!');
      notifyGlobalStateChange();
      return true;
    } catch (e) {
      // Network/server failure: fallback to offline sync queue
      LoggerService.w(
        'Online add failed, fallback to offline sync queue: $e',
        tag: 'TransactionController',
      );
      await syncService.enqueueCreateTransaction(
        tempId: tempId,
        amount: amount,
        type: type,
        description: description,
        categoryId: categoryId,
        date: utcDate,
        createdAt: now,
      );
      SnackbarService.success('Transaction recorded successfully!');
      notifyGlobalStateChange();
      return true;
    }
  }

  Future<bool> deleteTransaction(TransactionModel tx) async {
    AppHaptics.heavy();

    // 1. If it's a temporary transaction still pending sync, cancel from queue
    if (tx.id.startsWith('temp_') || tx.isPendingSync) {
      await syncService.removePendingCreate(tx.id);
      transactions.removeWhere((t) => t.id == tx.id);
      _recalculateSummary();
      storageService.saveCachedTransactions(
        transactions.map((e) => e.toJson()).toList(),
      );
      SnackbarService.success('Transaction deleted successfully');
      notifyGlobalStateChange();
      return true;
    }

    // 2. Optimistic local removal
    final previousList = List<TransactionModel>.from(transactions);
    transactions.removeWhere((t) => t.id == tx.id);
    _recalculateSummary();
    storageService.saveCachedTransactions(
      transactions.map((e) => e.toJson()).toList(),
    );

    // 3. If offline, enqueue delete task
    if (!syncService.isOnline.value) {
      await syncService.enqueueDeleteTransaction(id: tx.id);
      SnackbarService.success('Transaction deleted successfully');
      notifyGlobalStateChange();
      return true;
    }

    // 4. If online, attempt direct DELETE
    try {
      final success = await repository.deleteTransaction(tx.id);
      if (success) {
        SnackbarService.success('Transaction deleted successfully');
        notifyGlobalStateChange();
        return true;
      } else {
        // Rollback
        transactions.assignAll(previousList);
        _recalculateSummary();
        SnackbarService.error('Failed to delete transaction on server');
        return false;
      }
    } catch (e) {
      // Network issue: enqueue delete task
      LoggerService.w(
        'Online delete failed, enqueuing delete: $e',
        tag: 'TransactionController',
      );
      await syncService.enqueueDeleteTransaction(id: tx.id);
      SnackbarService.success('Transaction deleted successfully');
      notifyGlobalStateChange();
      return true;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
