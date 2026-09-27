import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../controllers/category_controller.dart';
import '../repositories/category_repository.dart';

class CategoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoryRepository>(
      () => CategoryRepository(apiClient: Get.find<ApiClient>()),
    );
    Get.lazyPut<CategoryController>(
      () => CategoryController(repository: Get.find<CategoryRepository>()),
    );
  }
}
