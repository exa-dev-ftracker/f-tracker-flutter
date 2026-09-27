import 'package:get/get.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/utils/app_haptics.dart';
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
}
