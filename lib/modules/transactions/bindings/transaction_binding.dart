import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../categories/controllers/category_controller.dart';
import '../../categories/repositories/category_repository.dart';
import '../controllers/add_transaction_controller.dart';
import '../controllers/transaction_controller.dart';
import '../repositories/transaction_repository.dart';

class TransactionBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CategoryRepository>()) {
      Get.lazyPut<CategoryRepository>(
        () => CategoryRepository(apiClient: Get.find<ApiClient>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<CategoryController>()) {
      Get.lazyPut<CategoryController>(
        () => CategoryController(repository: Get.find<CategoryRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<TransactionRepository>()) {
      Get.lazyPut<TransactionRepository>(
        () => TransactionRepository(apiClient: Get.find<ApiClient>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<TransactionController>()) {
      Get.lazyPut<TransactionController>(
        () => TransactionController(
          repository: Get.find<TransactionRepository>(),
          storageService: Get.find<StorageService>(),
        ),
        fenix: true,
      );
    }
    Get.lazyPut<AddTransactionController>(
      () => AddTransactionController(),
      fenix: true,
    );
  }
}

