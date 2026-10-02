import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../analytics/controllers/analytics_controller.dart';
import '../../analytics/repositories/analytics_repository.dart';
import '../../categories/controllers/category_controller.dart';
import '../../categories/repositories/category_repository.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/repositories/dashboard_repository.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../transactions/controllers/transaction_controller.dart';
import '../../transactions/repositories/transaction_repository.dart';
import '../controllers/navigation_controller.dart';

class NavigationBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Navigation Shell Controller
    Get.lazyPut<NavigationController>(() => NavigationController(), fenix: true);

    final apiClient = Get.find<ApiClient>();
    final storageService = Get.find<StorageService>();

    // 2. Categories
    if (!Get.isRegistered<CategoryRepository>()) {
      Get.lazyPut<CategoryRepository>(() => CategoryRepository(apiClient: apiClient), fenix: true);
    }
    if (!Get.isRegistered<CategoryController>()) {
      Get.lazyPut<CategoryController>(() => CategoryController(repository: Get.find<CategoryRepository>()), fenix: true);
    }

    // 3. Dashboard
    if (!Get.isRegistered<DashboardRepository>()) {
      Get.lazyPut<DashboardRepository>(() => DashboardRepository(apiClient: apiClient), fenix: true);
    }
    if (!Get.isRegistered<DashboardController>()) {
      Get.lazyPut<DashboardController>(() => DashboardController(repository: Get.find<DashboardRepository>()), fenix: true);
    }

    // 4. Transactions
    if (!Get.isRegistered<TransactionRepository>()) {
      Get.lazyPut<TransactionRepository>(() => TransactionRepository(apiClient: apiClient), fenix: true);
    }
    if (!Get.isRegistered<TransactionController>()) {
      Get.lazyPut<TransactionController>(() => TransactionController(
        repository: Get.find<TransactionRepository>(),
        storageService: storageService,
      ), fenix: true);
    }

    // 5. Analytics
    if (!Get.isRegistered<AnalyticsRepository>()) {
      Get.lazyPut<AnalyticsRepository>(() => AnalyticsRepository(apiClient: apiClient), fenix: true);
    }
    if (!Get.isRegistered<AnalyticsController>()) {
      Get.lazyPut<AnalyticsController>(() => AnalyticsController(repository: Get.find<AnalyticsRepository>()), fenix: true);
    }

    // 6. Settings
    if (!Get.isRegistered<SettingsController>()) {
      Get.lazyPut<SettingsController>(() => SettingsController(
        apiClient: apiClient,
        storageService: storageService,
      ), fenix: true);
    }
  }
}
