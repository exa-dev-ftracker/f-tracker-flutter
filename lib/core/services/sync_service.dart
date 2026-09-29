import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';
import 'logger_service.dart';
import 'snackbar_service.dart';
import 'storage_service.dart';
import '../../modules/transactions/models/transaction_model.dart';
import '../../modules/transactions/controllers/transaction_controller.dart';
import '../../modules/dashboard/controllers/dashboard_controller.dart';
import '../../modules/analytics/controllers/analytics_controller.dart';
import '../../modules/categories/controllers/category_controller.dart';

class SyncTask {
  final String id;
  final String action; // 'CREATE_TRANSACTION', 'DELETE_TRANSACTION', 'CREATE_CATEGORY'
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int retryCount;

  SyncTask({
    required this.id,
    required this.action,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  factory SyncTask.fromJson(Map<String, dynamic> json) {
    return SyncTask(
      id: json['id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      payload: Map<String, dynamic>.from(json['payload'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
  };
}

class SyncService extends GetxService {
  final StorageService storageService;
  final ApiClient apiClient;

  SyncService({
    required this.storageService,
    required this.apiClient,
  });

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  static const _uuid = Uuid();

  // Reactive state
  final isOnline = true.obs;
  final isSyncing = false.obs;
  final pendingCount = 0.obs;
  final lastSyncedAt = Rxn<DateTime>();

  Future<SyncService> init() async {
    // 1. Initial connectivity check
    try {
      final results = await _connectivity.checkConnectivity();
      isOnline.value = _hasActiveConnection(results);
    } catch (_) {
      isOnline.value = true;
    }

    // 2. Load pending queue state
    final queue = storageService.syncQueue;
    pendingCount.value = queue.length;
    lastSyncedAt.value = storageService.lastSyncedAt;

    // 3. Listen to network changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = isOnline.value;
      final nowOnline = _hasActiveConnection(results);
      isOnline.value = nowOnline;

      LoggerService.i('Connectivity changed: online=$nowOnline', tag: 'SyncService');

      if (!wasOnline && nowOnline) {
        // Just reconnected to internet -> auto trigger sync queue
        LoggerService.i('Internet reconnected. Triggering auto-sync...', tag: 'SyncService');
        processQueue();
      }
    });

    // 4. If online and has pending tasks on startup, process them
    if (isOnline.value && pendingCount.value > 0) {
      Future.delayed(const Duration(seconds: 2), () {
        processQueue();
      });
    }

    return this;
  }

  bool _hasActiveConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  // --- Outbox Queue Operations ---

  Future<void> enqueueCreateTransaction({
    required String tempId,
    required double amount,
    required String type,
    required String description,
    String? categoryId,
    DateTime? date,
    required DateTime createdAt,
  }) async {
    final task = SyncTask(
      id: _uuid.v4(),
      action: 'CREATE_TRANSACTION',
      payload: {
        'client_id': tempId,
        'amount': amount,
        'type': type,
        'description': description,
        if (categoryId != null && categoryId.isNotEmpty) 'category': categoryId,
        'date': date != null
            ? DateTime.utc(date.year, date.month, date.day).toIso8601String()
            : createdAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      },
      createdAt: DateTime.now(),
    );

    final queue = List<Map<String, dynamic>>.from(
      storageService.syncQueue.map((e) => Map<String, dynamic>.from(e)),
    );
    queue.add(task.toJson());
    await storageService.saveSyncQueue(queue);
    pendingCount.value = queue.length;
    LoggerService.i('Enqueued CREATE_TRANSACTION ($tempId). Pending: ${queue.length}', tag: 'SyncService');
  }

  Future<void> enqueueDeleteTransaction({required String id}) async {
    // If it's a temporary transaction, just cancel its pending create task
    if (id.startsWith('temp_')) {
      await removePendingCreate(id);
      return;
    }

    final task = SyncTask(
      id: _uuid.v4(),
      action: 'DELETE_TRANSACTION',
      payload: {'id': id},
      createdAt: DateTime.now(),
    );

    final queue = List<Map<String, dynamic>>.from(
      storageService.syncQueue.map((e) => Map<String, dynamic>.from(e)),
    );
    queue.add(task.toJson());
    await storageService.saveSyncQueue(queue);
    pendingCount.value = queue.length;
    LoggerService.i('Enqueued DELETE_TRANSACTION ($id). Pending: ${queue.length}', tag: 'SyncService');
  }

  Future<void> enqueueCreateCategory({
    required String name,
    required String type,
    String? color,
    String? icon,
  }) async {
    final task = SyncTask(
      id: _uuid.v4(),
      action: 'CREATE_CATEGORY',
      payload: {
        'name': name,
        'type': type,
        'color': color ?? '#10B981',
        'icon': icon ?? 'tag',
      },
      createdAt: DateTime.now(),
    );

    final queue = List<Map<String, dynamic>>.from(
      storageService.syncQueue.map((e) => Map<String, dynamic>.from(e)),
    );
    queue.add(task.toJson());
    await storageService.saveSyncQueue(queue);
    pendingCount.value = queue.length;
    LoggerService.i('Enqueued CREATE_CATEGORY ($name). Pending: ${queue.length}', tag: 'SyncService');
  }

  Future<void> enqueueUpdateTransaction({
    required String id,
    required double amount,
    required String type,
    required String description,
    String? categoryId,
    DateTime? date,
  }) async {
    final payloadData = {
      'amount': amount,
      'type': type,
      'description': description,
      if (categoryId != null && categoryId.isNotEmpty) 'category': categoryId,
      if (date != null) 'date': date.toIso8601String(),
    };

    final queue = List<Map<String, dynamic>>.from(
      storageService.syncQueue.map((e) => Map<String, dynamic>.from(e)),
    );

    // If still pending create, update that task's payload directly
    if (id.startsWith('temp_')) {
      final createIdx = queue.indexWhere((item) =>
          item['action'] == 'CREATE_TRANSACTION' &&
          item['payload'] != null &&
          item['payload']['client_id'] == id);
      if (createIdx != -1) {
        final currentPayload = Map<String, dynamic>.from(queue[createIdx]['payload'] ?? {});
        currentPayload.addAll(payloadData);
        queue[createIdx]['payload'] = currentPayload;
        await storageService.saveSyncQueue(queue);
        return;
      }
    }

    final task = SyncTask(
      id: _uuid.v4(),
      action: 'UPDATE_TRANSACTION',
      payload: {
        'id': id,
        'data': payloadData,
      },
      createdAt: DateTime.now(),
    );

    queue.add(task.toJson());
    await storageService.saveSyncQueue(queue);
    pendingCount.value = queue.length;
    LoggerService.i('Enqueued UPDATE_TRANSACTION ($id). Pending: ${queue.length}', tag: 'SyncService');
  }

  Future<void> enqueueUpdateCategory({
    required String id,
    required String name,
    required String type,
    String? color,
    String? icon,
  }) async {
    final payloadData = {
      'name': name,
      'type': type,
      'color': color,
      'icon': icon,
    };

    final queue = List<Map<String, dynamic>>.from(
      storageService.syncQueue.map((e) => Map<String, dynamic>.from(e)),
    );

    final task = SyncTask(
      id: _uuid.v4(),
      action: 'UPDATE_CATEGORY',
      payload: {
        'id': id,
        'data': payloadData,
      },
      createdAt: DateTime.now(),
    );

    queue.add(task.toJson());
    await storageService.saveSyncQueue(queue);
    pendingCount.value = queue.length;
    LoggerService.i('Enqueued UPDATE_CATEGORY ($id). Pending: ${queue.length}', tag: 'SyncService');
  }

  Future<void> removePendingCreate(String tempId) async {
    final queue = List<Map<String, dynamic>>.from(
      storageService.syncQueue.map((e) => Map<String, dynamic>.from(e)),
    );
    queue.removeWhere((item) =>
      item['action'] == 'CREATE_TRANSACTION' &&
      item['payload'] != null &&
      item['payload']['client_id'] == tempId,
    );
    await storageService.saveSyncQueue(queue);
    pendingCount.value = queue.length;
    LoggerService.i('Cancelled pending CREATE_TRANSACTION ($tempId). Pending: ${queue.length}', tag: 'SyncService');
  }

  // --- Queue Processor ---

  Future<void> processQueue() async {
    if (isSyncing.value) return;
    if (!isOnline.value) return;

    final rawQueue = storageService.syncQueue;
    if (rawQueue.isEmpty) {
      final now = DateTime.now();
      lastSyncedAt.value = now;
      await storageService.saveLastSyncedAt(now);
      return;
    }

    try {
      isSyncing.value = true;
      LoggerService.i('Starting sync queue processing (${rawQueue.length} tasks)...', tag: 'SyncService');

      final queue = rawQueue
          .map((e) => SyncTask.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final successfulTaskIds = <String>{};

      for (final task in queue) {
        if (!isOnline.value) break;

        try {
          if (task.action == 'CREATE_TRANSACTION') {
            await _syncCreateTransaction(task);
            successfulTaskIds.add(task.id);
          } else if (task.action == 'UPDATE_TRANSACTION') {
            await _syncUpdateTransaction(task);
            successfulTaskIds.add(task.id);
          } else if (task.action == 'DELETE_TRANSACTION') {
            await _syncDeleteTransaction(task);
            successfulTaskIds.add(task.id);
          } else if (task.action == 'CREATE_CATEGORY') {
            await _syncCreateCategory(task);
            successfulTaskIds.add(task.id);
          } else if (task.action == 'UPDATE_CATEGORY') {
            await _syncUpdateCategory(task);
            successfulTaskIds.add(task.id);
          }
        } catch (e) {
          LoggerService.w('Task ${task.id} (${task.action}) failed during sync: $e', tag: 'SyncService');
          task.retryCount++;
          // If connection error, break early and retain remaining queue
          if (e is DioException &&
              (e.type == DioExceptionType.connectionError ||
               e.type == DioExceptionType.connectionTimeout)) {
            break;
          }
        }
      }

      // Remove successful tasks from storage
      final remaining = queue
          .where((t) => !successfulTaskIds.contains(t.id))
          .map((t) => t.toJson())
          .toList();

      await storageService.saveSyncQueue(remaining);
      pendingCount.value = remaining.length;

      final now = DateTime.now();
      lastSyncedAt.value = now;
      await storageService.saveLastSyncedAt(now);

      if (successfulTaskIds.isNotEmpty) {
        LoggerService.i('Successfully synced ${successfulTaskIds.length} tasks.', tag: 'SyncService');
        // Refresh active views to ensure fresh server state
        _refreshActiveControllers();
        SnackbarService.success('Data synchronized successfully');
      }
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> _syncCreateTransaction(SyncTask task) async {
    final payload = task.payload;
    final clientId = payload['client_id']?.toString() ?? '';

    final response = await apiClient.post(
      ApiEndpoints.transactions,
      data: {
        'amount': payload['amount'],
        'type': payload['type'],
        'description': payload['description'],
        if (payload['category'] != null) 'category': payload['category'],
        'date': payload['date'] ?? payload['createdAt'],
      },
      options: Options(extra: {'silent': true}),
    );

    final data = response.data;
    final item = data is Map && data['data'] != null ? data['data'] : data;
    final serverTx = TransactionModel.fromJson(Map<String, dynamic>.from(item));

    // Reconcile local cache
    final cached = List<Map<String, dynamic>>.from(
      storageService.cachedTransactions.map((e) => Map<String, dynamic>.from(e)),
    );
    final idx = cached.indexWhere((c) => c['id'] == clientId);
    if (idx != -1) {
      cached[idx] = serverTx.copyWith(isPendingSync: false).toJson();
    } else {
      cached.insert(0, serverTx.copyWith(isPendingSync: false).toJson());
    }
    await storageService.saveCachedTransactions(cached);

    // Reconcile in-memory TransactionController if alive
    if (Get.isRegistered<TransactionController>()) {
      final txController = Get.find<TransactionController>();
      final localIdx = txController.transactions.indexWhere((t) => t.id == clientId);
      if (localIdx != -1) {
        txController.transactions[localIdx] = serverTx.copyWith(isPendingSync: false);
        txController.transactions.refresh();
      }
    }
  }

  Future<void> _syncDeleteTransaction(SyncTask task) async {
    final txId = task.payload['id']?.toString() ?? '';
    if (txId.isEmpty || txId.startsWith('temp_')) return;

    try {
      await apiClient.delete(
        ApiEndpoints.transactionDetail(txId),
        options: Options(extra: {'silent': true}),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        rethrow;
      }
    }
  }

  Future<void> _syncCreateCategory(SyncTask task) async {
    await apiClient.post(
      ApiEndpoints.categories,
      data: task.payload,
      options: Options(extra: {'silent': true}),
    );
  }

  Future<void> _syncUpdateTransaction(SyncTask task) async {
    final txId = task.payload['id']?.toString() ?? '';
    if (txId.isEmpty || txId.startsWith('temp_')) return;

    final response = await apiClient.put(
      ApiEndpoints.transactionDetail(txId),
      data: task.payload['data'],
      options: Options(extra: {'silent': true}),
    );

    final data = response.data;
    final item = data is Map && data['data'] != null ? data['data'] : data;
    final serverTx = TransactionModel.fromJson(Map<String, dynamic>.from(item));

    final cached = List<Map<String, dynamic>>.from(
      storageService.cachedTransactions.map((e) => Map<String, dynamic>.from(e)),
    );
    final idx = cached.indexWhere((c) => c['id'] == txId || c['_id'] == txId);
    if (idx != -1) {
      cached[idx] = serverTx.copyWith(isPendingSync: false).toJson();
      await storageService.saveCachedTransactions(cached);
    }
  }

  Future<void> _syncUpdateCategory(SyncTask task) async {
    final catId = task.payload['id']?.toString() ?? '';
    if (catId.isEmpty || catId.startsWith('temp_')) return;

    await apiClient.put(
      ApiEndpoints.categoryDetail(catId),
      data: task.payload['data'],
      options: Options(extra: {'silent': true}),
    );
  }

  void _refreshActiveControllers() {
    if (Get.isRegistered<TransactionController>()) {
      Get.find<TransactionController>().fetchTransactions();
    }
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().fetchDashboard();
    }
    if (Get.isRegistered<AnalyticsController>()) {
      Get.find<AnalyticsController>().fetchAnalytics();
    }
    if (Get.isRegistered<CategoryController>()) {
      Get.find<CategoryController>().fetchCategories();
    }
  }

  // --- Manual Sync Trigger ---

  Future<void> syncNow() async {
    if (!isOnline.value) {
      SnackbarService.warning('Device is offline. Connect to Wi-Fi or cellular data to sync.');
      return;
    }

    if (isSyncing.value) {
      SnackbarService.info('Sync process is already in progress...');
      return;
    }

    await processQueue();
    _refreshActiveControllers();

    if (pendingCount.value == 0) {
      final now = DateTime.now();
      lastSyncedAt.value = now;
      await storageService.saveLastSyncedAt(now);
      SnackbarService.success('Data is synchronized with the cloud server.');
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
