import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../controllers/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(
      () => SettingsController(
        apiClient: Get.find<ApiClient>(),
        storageService: Get.find<StorageService>(),
      ),
    );
  }
}
