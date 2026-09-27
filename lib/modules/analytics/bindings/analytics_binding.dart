import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../controllers/analytics_controller.dart';
import '../repositories/analytics_repository.dart';

class AnalyticsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AnalyticsRepository>(
      () => AnalyticsRepository(apiClient: Get.find<ApiClient>()),
    );
    Get.lazyPut<AnalyticsController>(
      () => AnalyticsController(repository: Get.find<AnalyticsRepository>()),
    );
  }
}
