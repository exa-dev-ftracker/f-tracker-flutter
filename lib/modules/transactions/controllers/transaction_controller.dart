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

  // Pagination & Infinite Scroll
  final currentPage = 1.obs;
  final nextCursor = Rxn<String>();
  final hasMore = true.obs;
  final isLoadingMore = false.obs;
  final scrollController = ScrollController();

  // Selected Detail Transaction (for bottom sheet)
  final selectedDetailTx = Rxn<TransactionModel>();
  final isLoadingDetail = false.obs;

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
    scrollController.addListener(_onScroll);
    _loadCachedTransactions();
    fetchTransactions();
    // Background full sync so local cache contains historical data
    fetchFullHistory();
  }

  void _onScroll() {
    if (scrollController.hasClients &&
        scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
      loadMoreTransactions();
    }
  }

  Future<void> fetchFullHistory({bool force = false}) async {
    if (!syncService.isOnline.value) return;
    try {
      final allResult = await repository.fetchAllTransactions();
      final existingCached = force ? <dynamic>[] : storageService.cachedTransactions;
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

  Future<void> fetchTransactions({bool isRefresh = true}) async {
    try {
      if (isRefresh) {
        isLoading.value = true;
        currentPage.value = 1;
        nextCursor.value = null;
        hasMore.value = true;
      }
      if (!syncService.isOnline.value) {
        _loadCachedTransactions();
        return;
      }

      // Fetch summary in parallel for accurate KPI cards
      _fetchSummary();

      final res = await repository.getTransactionsPaginated(
        view: selectedView.value,
        type: selectedType.value.isNotEmpty ? selectedType.value : null,
        category: selectedCategory.value.isNotEmpty && selectedCategory.value != 'all'
            ? selectedCategory.value
            : null,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        sort: selectedSort.value,
        year: filterYear.value,
        month: filterMonth.value,
        page: 1,
        limit: 20,
      );

      currentPage.value = 1;
      nextCursor.value = res.nextCursor;
      hasMore.value = res.hasMore;

      // Preserve any pending local items awaiting sync
      final pendingItems = transactions.where((t) => t.isPendingSync).toList();
      final merged = <TransactionModel>[...pendingItems];
      for (final r in res.items) {
        if (!merged.any((m) => m.id == r.id)) {
          merged.add(r);
        }
      }

      transactions.assignAll(merged);

      // Smart cache merge
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
      if (isRefresh) {
        isLoading.value = false;
      }
    }
  }

  Future<void> loadMoreTransactions() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) {
      return;
    }

    try {
      isLoadingMore.value = true;
      final nextPage = currentPage.value + 1;
      final res = await repository.getTransactionsPaginated(
        view: selectedView.value,
        type: selectedType.value.isNotEmpty ? selectedType.value : null,
        category: selectedCategory.value.isNotEmpty && selectedCategory.value != 'all'
            ? selectedCategory.value
            : null,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        sort: selectedSort.value,
        year: filterYear.value,
        month: filterMonth.value,
        page: nextPage,
        limit: 20,
      );

      currentPage.value = nextPage;
      nextCursor.value = res.nextCursor;
      hasMore.value = res.hasMore;

      // Deduplicate before appending
      final existingIds = transactions.map((t) => t.id).toSet();
      final uniqueNew = res.items.where((t) => !existingIds.contains(t.id)).toList();
      transactions.addAll(uniqueNew);

      // Cache merge
      final existingCached = storageService.cachedTransactions;
      final cachedMap = <String, Map<String, dynamic>>{};
      for (final item in existingCached) {
        final id = item['id']?.toString() ?? item['_id']?.toString();
        if (id != null) cachedMap[id] = Map<String, dynamic>.from(item);
      }
      for (final item in uniqueNew) {
        cachedMap[item.id] = item.toJson();
      }
      await storageService.saveCachedTransactions(cachedMap.values.toList());
    } catch (e) {
      LoggerService.e('Failed to load more transactions: $e', tag: 'TransactionController');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> _fetchSummary() async {
    try {
      final summary = await repository.getSummary(
        view: selectedView.value,
        type: selectedType.value.isNotEmpty ? selectedType.value : null,
        category: selectedCategory.value.isNotEmpty && selectedCategory.value != 'all'
            ? selectedCategory.value
            : null,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        year: filterYear.value,
        month: filterMonth.value,
      );
      if (summary.isNotEmpty) {
        incomeTotal.value = (summary['incomeTotal'] as num?)?.toDouble() ?? 0.0;
        expenseTotal.value = (summary['expenseTotal'] as num?)?.toDouble() ?? 0.0;
        balance.value = (summary['balance'] as num?)?.toDouble() ?? 0.0;
        return;
      }
    } catch (_) {}
    _recalculateSummary();
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
      try {
        Get.find<DashboardController>().fetchDashboard();
      } catch (_) {}
    }
    if (Get.isRegistered<AnalyticsController>()) {
      try {
        Get.find<AnalyticsController>().fetchAnalytics();
      } catch (_) {}
    }
  }

  Map<String, List<TransactionModel>> get groupedTransactions {
    final groups = <String, List<TransactionModel>>{};
    for (final t in transactions) {
      final key = '${t.date.year.toString().padLeft(4, '0')}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
      groups.putIfAbsent(key, () => []).add(t);
    }
    return groups;
  }

  Map<String, double> getDailySummary(List<TransactionModel> dailyTxs) {
    double inc = 0.0;
    double exp = 0.0;
    for (final t in dailyTxs) {
      if (t.isIncome) {
        inc += t.amount;
      } else {
        exp += t.amount;
      }
    }
    return {
      'income': inc,
      'expense': exp,
      'net': inc - exp,
    };
  }

  void _upsertCachedTransaction(TransactionModel tx) {
    final cached = storageService.cachedTransactions;
    final map = <String, Map<String, dynamic>>{};
    for (final item in cached) {
      final id = item['id']?.toString() ?? item['_id']?.toString();
      if (id != null) map[id] = Map<String, dynamic>.from(item);
    }
    map[tx.id] = tx.toJson();
    storageService.saveCachedTransactions(map.values.toList());
  }

  void _removeCachedTransaction(String id) {
    final cached = storageService.cachedTransactions;
    final updated = cached.where((item) {
      final itemId = item['id']?.toString() ?? item['_id']?.toString();
      return itemId != id;
    }).toList();
    storageService.saveCachedTransactions(updated);
  }

  void _adjustParentIncomeBalance(String? parentIncomeId, double expenseDiff) {
    if (parentIncomeId == null || parentIncomeId.isEmpty) return;
    final cached = List<dynamic>.from(storageService.cachedTransactions);
    for (int i = 0; i < cached.length; i++) {
      final item = Map<String, dynamic>.from(cached[i]);
      final id = item['id']?.toString() ?? item['_id']?.toString();
      if (id == parentIncomeId) {
        final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
        final currentUsed = (item['totalUsed'] as num?)?.toDouble() ?? 0.0;
        final newUsed = (currentUsed + expenseDiff).clamp(0.0, double.infinity);
        final newRemaining = amount - newUsed;
        final newPct = amount > 0 ? (newUsed / amount) * 100 : 0.0;
        item['totalUsed'] = newUsed;
        item['remainingAmount'] = newRemaining;
        item['percentageUsed'] = newPct;
        cached[i] = item;
        storageService.saveCachedTransactions(cached);

        final memIdx = transactions.indexWhere((t) => t.id == parentIncomeId);
        if (memIdx != -1) {
          transactions[memIdx] = transactions[memIdx].copyWith(
            totalUsed: newUsed,
            remainingAmount: newRemaining,
            percentageUsed: newPct,
          );
          transactions.refresh();
        }
        break;
      }
    }
  }

  Future<TransactionModel?> getTransactionDetail(String id) async {
    if (syncService.isOnline.value && !id.startsWith('temp_')) {
      try {
        final detail = await repository.getTransactionDetail(id);
        _upsertCachedTransaction(detail);
        return detail;
      } catch (e) {
        LoggerService.w('Online fetch transaction detail failed, fallback to cache: $e', tag: 'TransactionController');
      }
    }

    // Offline / fallback from local cache
    final cached = storageService.cachedTransactions;
    final allTxs = cached
        .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final match = allTxs.firstWhereOrNull((t) => t.id == id);
    if (match == null) return null;

    if (match.isIncome) {
      final linkedExps = allTxs.where((t) => !t.isIncome && t.linkedIncomeId == match.id).toList();
      linkedExps.sort((a, b) => b.date.compareTo(a.date));
      final totalUsed = linkedExps.fold<double>(0.0, (sum, e) => sum + e.amount);
      final remaining = match.amount - totalUsed;
      final pct = match.amount > 0 ? (totalUsed / match.amount) * 100 : 0.0;
      return match.copyWith(
        linkedExpenses: linkedExps,
        totalUsed: totalUsed,
        remainingAmount: remaining,
        percentageUsed: pct,
        expenseCount: linkedExps.length,
      );
    } else if (match.linkedIncomeId != null) {
      final parent = allTxs.firstWhereOrNull((t) => t.id == match.linkedIncomeId);
      if (parent != null) {
        final siblingExps = allTxs.where((t) => !t.isIncome && t.linkedIncomeId == parent.id).toList();
        final totalUsed = siblingExps.fold<double>(0.0, (sum, e) => sum + e.amount);
        final remaining = parent.amount - totalUsed;
        final pct = parent.amount > 0 ? (totalUsed / parent.amount) * 100 : 0.0;
        return match.copyWith(
          linkedIncomeDescription: parent.description,
          linkedIncomeDetails: {
            '_id': parent.id,
            'description': parent.description,
            'amount': parent.amount,
            'date': parent.date.toIso8601String(),
            'totalUsed': totalUsed,
            'remainingAmount': remaining,
            'expenseCount': siblingExps.length,
            'percentageUsed': pct,
          },
        );
      }
    }
    return match;
  }

  Future<void> loadTransactionDetail(TransactionModel tx) async {
    selectedDetailTx.value = tx;
    isLoadingDetail.value = true;
    try {
      final detail = await getTransactionDetail(tx.id);
      if (detail != null) {
        selectedDetailTx.value = detail;
      }
    } catch (e) {
      LoggerService.e('Failed to load transaction detail: $e', tag: 'TransactionController');
    } finally {
      isLoadingDetail.value = false;
    }
  }

  Future<Map<String, dynamic>> getAvailableIncomes({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    if (syncService.isOnline.value) {
      try {
        final res = await repository.getAvailableIncomes(
          page: page,
          limit: limit,
          search: search,
        );
        return res;
      } catch (e) {
        LoggerService.w('Online fetch available incomes failed, fallback to cache: $e', tag: 'TransactionController');
      }
    }

    // Offline fallback from local cached transactions
    try {
      final cached = storageService.cachedTransactions;
      final allTxs = cached
          .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final incomes = allTxs.where((t) => t.isIncome).toList();
      final q = (search ?? '').trim().toLowerCase();

      final available = <TransactionModel>[];
      for (final inc in incomes) {
        if (q.isNotEmpty && !inc.description.toLowerCase().contains(q)) {
          continue;
        }

        final linkedExps = allTxs.where((t) => !t.isIncome && t.linkedIncomeId == inc.id);
        final computedUsed = linkedExps.fold<double>(0.0, (sum, e) => sum + e.amount);
        final remaining = inc.amount - computedUsed;

        if (remaining > 0) {
          available.add(inc.copyWith(
            remainingAmount: remaining,
            totalUsed: computedUsed,
            percentageUsed: inc.amount > 0 ? (computedUsed / inc.amount) * 100 : 0.0,
            expenseCount: linkedExps.length,
          ));
        }
      }

      available.sort((a, b) => b.date.compareTo(a.date));

      final startIndex = (page - 1) * limit;
      final pagedList = available.skip(startIndex).take(limit).toList();
      final hasMore = startIndex + limit < available.length;

      return {
        'incomes': pagedList,
        'hasMore': hasMore,
        'total': available.length,
      };
    } catch (e) {
      LoggerService.e('Offline available incomes calculation failed: $e', tag: 'TransactionController');
      return {'incomes': <TransactionModel>[], 'hasMore': false, 'total': 0};
    }
  }

  Future<bool> addTransaction({
    required double amount,
    required String type,
    required String description,
    String? categoryId,
    String? linkedIncomeId,
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
      linkedIncomeId: linkedIncomeId,
    );

    // Optimistic insert
    transactions.insert(0, localTx);
    _recalculateSummary();
    _upsertCachedTransaction(localTx);
    if (linkedIncomeId != null && linkedIncomeId.isNotEmpty) {
      _adjustParentIncomeBalance(linkedIncomeId, amount);
    }

    // 3. If device is offline, enqueue sync task directly
    if (!syncService.isOnline.value) {
      await syncService.enqueueCreateTransaction(
        tempId: tempId,
        amount: amount,
        type: type,
        description: description,
        categoryId: categoryId,
        linkedIncomeId: linkedIncomeId,
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
        if (linkedIncomeId != null && linkedIncomeId.isNotEmpty) 'linkedIncomeId': linkedIncomeId,
        'date': dateIso,
      });

      // Replace optimistic tempTx with server transaction
      final index = transactions.indexWhere((t) => t.id == tempId);
      if (index != -1) {
        transactions[index] = newTx.copyWith(isPendingSync: false);
        transactions.refresh();
      }
      _removeCachedTransaction(tempId);
      _upsertCachedTransaction(newTx.copyWith(isPendingSync: false));

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
        linkedIncomeId: linkedIncomeId,
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
    String? linkedIncomeId,
    DateTime? date,
  }) async {
    final oldTransactions = List<TransactionModel>.from(transactions);
    final idx = transactions.indexWhere((t) => t.id == id);
    if (idx == -1) return false;

    final oldTx = transactions[idx];

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
    final updatedLocal = transactions[idx].copyWith(
      amount: amount,
      type: type,
      description: description,
      category: selectedCat,
      date: calendarDate,
      linkedIncomeId: linkedIncomeId,
    );
    transactions[idx] = updatedLocal;
    transactions.refresh();
    _recalculateSummary();
    _upsertCachedTransaction(updatedLocal);

    // Adjust parent income balance
    if (oldTx.linkedIncomeId != null && oldTx.linkedIncomeId != linkedIncomeId) {
      _adjustParentIncomeBalance(oldTx.linkedIncomeId, -oldTx.amount);
    }
    if (linkedIncomeId != null && linkedIncomeId.isNotEmpty) {
      final diff = (oldTx.linkedIncomeId == linkedIncomeId) ? (amount - oldTx.amount) : amount;
      _adjustParentIncomeBalance(linkedIncomeId, diff);
    }

    // If offline or temp item, enqueue
    if (!syncService.isOnline.value || id.startsWith('temp_')) {
      await syncService.enqueueUpdateTransaction(
        id: id,
        amount: amount,
        type: type,
        description: description,
        categoryId: categoryId,
        linkedIncomeId: linkedIncomeId,
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
        'linkedIncomeId': linkedIncomeId ?? '',
        'date': dateIso,
      });

      final newIdx = transactions.indexWhere((t) => t.id == id);
      if (newIdx != -1) {
        transactions[newIdx] = updatedTx.copyWith(isPendingSync: false);
        transactions.refresh();
      }
      _upsertCachedTransaction(updatedTx.copyWith(isPendingSync: false));
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
          linkedIncomeId: linkedIncomeId,
          date: calendarDate,
        );
        SnackbarService.success('Transaction updated successfully!');
        notifyGlobalStateChange();
        return true;
      }
      // Rollback on server validation error
      transactions.assignAll(oldTransactions);
      _recalculateSummary();
      _upsertCachedTransaction(oldTx);
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
      _removeCachedTransaction(tx.id);
      if (tx.linkedIncomeId != null) {
        _adjustParentIncomeBalance(tx.linkedIncomeId, -tx.amount);
      }
      SnackbarService.success('Transaction deleted successfully');
      notifyGlobalStateChange();
      return true;
    }

    // 2. Optimistic local removal
    final previousList = List<TransactionModel>.from(transactions);
    transactions.removeWhere((t) => t.id == tx.id);
    _recalculateSummary();
    _removeCachedTransaction(tx.id);
    if (tx.linkedIncomeId != null) {
      _adjustParentIncomeBalance(tx.linkedIncomeId, -tx.amount);
    }

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
        _upsertCachedTransaction(tx);
        if (tx.linkedIncomeId != null) {
          _adjustParentIncomeBalance(tx.linkedIncomeId, tx.amount);
        }
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
    scrollController.dispose();
    searchController.dispose();
    super.onClose();
  }
}
