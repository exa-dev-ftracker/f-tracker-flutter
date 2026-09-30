import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/logger_service.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/currency_formatter.dart';
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

  // Custom month/year filter
  final filterYear = Rxn<int>();
  final filterMonth = Rxn<int>();

  // Category & Sort filters
  final selectedCategory = ''.obs; // '' or 'all' = all, or categoryId
  final selectedCategoryName = ''.obs;
  final selectedSort = 'newest'.obs; // 'newest', 'oldest', 'highest', 'lowest'

  // Summary Metrics
  final incomeTotal = 0.0.obs;
  final expenseTotal = 0.0.obs;
  final balance = 0.0.obs;

  SyncService get syncService => Get.find<SyncService>();

  List<CategoryModel> get availableCategories {
    final cached = storageService.cachedCategories;
    return cached
        .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }


  void _loadCachedTransactions() {
    final cached = storageService.cachedTransactions;
    var list = <TransactionModel>[];
    if (cached.isNotEmpty) {
      try {
        list = cached
            .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    }

    // Preserve any in-memory pending sync items
    final inMemoryPending = transactions.where((t) => t.isPendingSync).toList();
    for (final p in inMemoryPending) {
      if (!list.any((item) => item.id == p.id)) {
        list.insert(0, p);
      }
    }

    if (list.isEmpty) {
      transactions.clear();
      _recalculateSummary();
      return;
    }

    // 1. Local period / date filter
    final userTz = storageService.user?['timezone']?.toString();
    final now = CurrencyFormatter.nowInTimezone(userTz);
    if (selectedView.value == 'Day') {

      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      list = list.where((t) => !t.date.isBefore(start) && !t.date.isAfter(end)).toList();
    } else if (selectedView.value == 'Week') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      final end = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59, 999);
      list = list.where((t) => !t.date.isBefore(start) && !t.date.isAfter(end)).toList();
    } else if (selectedView.value == 'Month') {
      final start = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      final end = DateTime(now.year, now.month, lastDay, 23, 59, 59, 999);
      list = list.where((t) => !t.date.isBefore(start) && !t.date.isAfter(end)).toList();
    } else if (selectedView.value == 'Year') {
      final start = DateTime(now.year, 1, 1);
      final end = DateTime(now.year, 12, 31, 23, 59, 59, 999);
      list = list.where((t) => !t.date.isBefore(start) && !t.date.isAfter(end)).toList();
    } else if (selectedView.value == 'Custom') {
      if (filterYear.value != null && filterMonth.value != null) {
        final y = filterYear.value!;
        final m = filterMonth.value!;
        final start = DateTime(y, m, 1);
        final lastDay = DateTime(y, m + 1, 0).day;
        final end = DateTime(y, m, lastDay, 23, 59, 59, 999);
        list = list.where((t) => !t.date.isBefore(start) && !t.date.isAfter(end)).toList();
      } else if (filterYear.value != null) {
        final y = filterYear.value!;
        final start = DateTime(y, 1, 1);
        final end = DateTime(y, 12, 31, 23, 59, 59, 999);
        list = list.where((t) => !t.date.isBefore(start) && !t.date.isAfter(end)).toList();
      }
    }

    // 2. Local type filter
    if (selectedType.value.isNotEmpty) {
      list = list.where((t) => t.type.toLowerCase() == selectedType.value.toLowerCase()).toList();
    }

    // 3. Local category filter
    if (selectedCategory.value.isNotEmpty && selectedCategory.value != 'all') {
      list = list.where((t) => t.category?.id == selectedCategory.value).toList();
    }

    // 4. Local search filter
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      list = list.where((t) => t.description.toLowerCase().contains(q)).toList();
    }

    // 5. Local sort
    switch (selectedSort.value) {
      case 'oldest':
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'highest':
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'lowest':
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'newest':
      default:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
    }

    transactions.assignAll(list);
    _recalculateSummary();
  }

  @override
  void onInit() {
    super.onInit();
    _loadCachedTransactions();
    fetchTransactions();
    // Background full sync so local cache contains all historical data for offline filtering
    fetchFullHistory();
  }

  Future<void> fetchFullHistory() async {
    if (!syncService.isOnline.value) return;
    try {
      final allResult = await repository.getTransactions(view: 'All');
      final existingCached = storageService.cachedTransactions;
      final cachedMap = <String, Map<String, dynamic>>{};
      for (final item in existingCached) {
        final id = item['id']?.toString() ?? item['_id']?.toString();
        if (id != null) cachedMap[id] = Map<String, dynamic>.from(item);
      }
      for (final r in allResult) {
        cachedMap[r.id] = r.toJson();
      }
      await storageService.saveCachedTransactions(cachedMap.values.toList());
      LoggerService.i(
        'Full transaction history synchronized to local cache (${cachedMap.length} items)',
        tag: 'TransactionController',
      );
    } catch (e) {
      LoggerService.w('Background full history sync deferred: $e', tag: 'TransactionController');
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
        category: selectedCategory.value.isNotEmpty && selectedCategory.value != 'all'
            ? selectedCategory.value
            : null,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        sort: selectedSort.value,
        year: filterYear.value,
        month: filterMonth.value,
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

      // Smart cache merge: update/insert fetched items into the full cached transaction pool
      // so other months/years previously stored in cache are NOT wiped!
      final existingCached = storageService.cachedTransactions;
      final cachedMap = <String, Map<String, dynamic>>{};
      for (final item in existingCached) {
        final id = item['id']?.toString() ?? item['_id']?.toString();
        if (id != null) cachedMap[id] = Map<String, dynamic>.from(item);
      }
      for (final item in merged) {
        cachedMap[item.id] = item.toJson();
      }
      await storageService.saveCachedTransactions(cachedMap.values.toList());
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
    // Clear custom month/year filter when switching to a preset period
    if (period != 'Custom') {
      filterYear.value = null;
      filterMonth.value = null;
    }
    fetchTransactions();
  }

  void setCustomMonthYear(int year, int month) {
    AppHaptics.selection();
    selectedView.value = 'Custom';
    filterYear.value = year;
    filterMonth.value = month;
    fetchTransactions();
  }

  void setCustomYear(int year) {
    AppHaptics.selection();
    selectedView.value = 'Custom';
    filterYear.value = year;
    filterMonth.value = null;
    fetchTransactions();
  }

  void clearCustomFilter() {
    AppHaptics.light();
    filterYear.value = null;
    filterMonth.value = null;
    selectedView.value = 'Month';
    fetchTransactions();
  }

  void setCategoryFilter(String categoryId, [String categoryName = '']) {
    AppHaptics.selection();
    selectedCategory.value = categoryId;
    selectedCategoryName.value = categoryName;
    fetchTransactions();
  }

  void clearCategoryFilter() {
    AppHaptics.light();
    selectedCategory.value = '';
    selectedCategoryName.value = '';
    fetchTransactions();
  }

  void setSort(String sort) {
    AppHaptics.selection();
    selectedSort.value = sort;
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
    final txDate = date ?? CurrencyFormatter.nowInTimezone(storageService.user?['timezone']?.toString());


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
    final calendarDate = DateTime(txDate.year, txDate.month, txDate.day);
    final dateIso = DateTime.utc(txDate.year, txDate.month, txDate.day).toIso8601String();
    final localTx = TransactionModel(
      id: tempId,
      amount: amount,
      type: type,
      description: description,
      category: selectedCat,
      date: calendarDate,
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
        date: calendarDate,
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
        'date': dateIso,
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
        date: calendarDate,
        createdAt: now,
      );
      SnackbarService.success('Transaction recorded successfully!');
      notifyGlobalStateChange();
      return true;
    }
  }

  Future<bool> updateTransaction({
    required String id,
    required double amount,
    required String type,
    required String description,
    String? categoryId,
    DateTime? date,
  }) async {
    final oldTransactions = List<TransactionModel>.from(transactions);
    final idx = transactions.indexWhere((t) => t.id == id);
    if (idx == -1) return false;

    // Locate category for local display
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

    final txDate = date ?? transactions[idx].date;
    final calendarDate = DateTime(txDate.year, txDate.month, txDate.day);

    // Optimistic update
    transactions[idx] = transactions[idx].copyWith(
      amount: amount,
      type: type,
      description: description,
      category: selectedCat,
      date: calendarDate,
    );
    transactions.refresh();
    _recalculateSummary();
    storageService.saveCachedTransactions(
      transactions.map((e) => e.toJson()).toList(),
    );

    // If offline or temp item, enqueue
    if (!syncService.isOnline.value || id.startsWith('temp_')) {
      await syncService.enqueueUpdateTransaction(
        id: id,
        amount: amount,
        type: type,
        description: description,
        categoryId: categoryId,
        date: calendarDate,
      );
      AppHaptics.success();
      SnackbarService.success('Transaction updated successfully!');
      notifyGlobalStateChange();
      return true;
    }

    try {
      AppHaptics.success();
      final dateIso = DateTime.utc(calendarDate.year, calendarDate.month, calendarDate.day).toIso8601String();
      final updatedTx = await repository.updateTransaction(id, {
        'amount': amount,
        'type': type,
        'description': description,
        if (categoryId != null && categoryId.isNotEmpty) 'category': categoryId,
        'date': dateIso,
      });

      final newIdx = transactions.indexWhere((t) => t.id == id);
      if (newIdx != -1) {
        transactions[newIdx] = updatedTx.copyWith(isPendingSync: false);
        transactions.refresh();
      }
      storageService.saveCachedTransactions(
        transactions.map((e) => e.toJson()).toList(),
      );
      SnackbarService.success('Transaction updated successfully!');
      notifyGlobalStateChange();
      return true;
    } catch (e) {
      if (AppErrorHandler.isOfflineOrNetworkError(e)) {
        await syncService.enqueueUpdateTransaction(
          id: id,
          amount: amount,
          type: type,
          description: description,
          categoryId: categoryId,
          date: calendarDate,
        );
        SnackbarService.success('Transaction updated successfully!');
        notifyGlobalStateChange();
        return true;
      }
      // Rollback on server validation error
      transactions.assignAll(oldTransactions);
      _recalculateSummary();
      storageService.saveCachedTransactions(
        transactions.map((e) => e.toJson()).toList(),
      );
      AppErrorHandler.handle(e, fallback: 'Failed to update transaction');
      return false;
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
        AppErrorHandler.handle(
          Exception('Server rejected delete'),
          fallback: 'Failed to delete transaction',
        );
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
