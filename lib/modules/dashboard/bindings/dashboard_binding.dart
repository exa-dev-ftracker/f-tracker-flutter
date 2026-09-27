import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../controllers/dashboard_controller.dart';
import '../repositories/dashboard_repository.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardRepository>(
      () => DashboardRepository(apiClient: Get.find<ApiClient>()),
    );
    Get.lazyPut<DashboardController>(
      () => DashboardController(repository: Get.find<DashboardRepository>()),
    );
  }
}
