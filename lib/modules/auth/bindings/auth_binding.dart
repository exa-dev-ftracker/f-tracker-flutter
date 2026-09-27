import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../controllers/auth_controller.dart';
import '../repositories/auth_repository.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthRepository>(
      () => AuthRepository(apiClient: Get.find<ApiClient>()),
    );
    Get.lazyPut<AuthController>(
      () => AuthController(
        repository: Get.find<AuthRepository>(),
        storageService: Get.find<StorageService>(),
      ),
    );
  }
}
