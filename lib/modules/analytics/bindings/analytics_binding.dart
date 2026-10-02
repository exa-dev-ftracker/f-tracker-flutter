import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../controllers/analytics_controller.dart';
import '../repositories/analytics_repository.dart';

class AnalyticsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AnalyticsRepository>()) {
      Get.lazyPut<AnalyticsRepository>(
        () => AnalyticsRepository(apiClient: Get.find<ApiClient>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<AnalyticsController>()) {
      Get.lazyPut<AnalyticsController>(
        () => AnalyticsController(repository: Get.find<AnalyticsRepository>()),
        fenix: true,
      );
    }
  }
}
