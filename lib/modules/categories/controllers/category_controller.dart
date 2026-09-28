import 'package:get/get.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/utils/app_haptics.dart';
import '../models/category_model.dart';
import '../repositories/category_repository.dart';

class CategoryController extends GetxController {
  final CategoryRepository repository;

  CategoryController({required this.repository});

  final categories = <CategoryModel>[].obs;
  final isLoading = false.obs;

  StorageService get storageService => Get.find<StorageService>();
  SyncService get syncService => Get.find<SyncService>();

  List<CategoryModel> get incomeCategories =>
      categories.where((c) => c.type == 'income').toList();

  List<CategoryModel> get expenseCategories =>
      categories.where((c) => c.type == 'expense').toList();

  @override
  void onInit() {
    super.onInit();
    _loadCachedCategories();
    fetchCategories();
  }

  void _loadCachedCategories() {
    final cached = storageService.cachedCategories;
    if (cached.isNotEmpty) {
      try {
        final list = cached
            .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        categories.assignAll(list);
      } catch (_) {}
    }
  }

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      if (!syncService.isOnline.value) {
        _loadCachedCategories();
        return;
      }

      final result = await repository.getCategories();
      categories.assignAll(result);
      storageService.saveCachedCategories(result.map((e) => e.toJson()).toList());
    } catch (e) {
      LoggerService.e('Failed to fetch categories, loading cache: $e', tag: 'CategoryController');
      _loadCachedCategories();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addCategory({
    required String name,
    required String type,
    String? color,
    String? icon,
  }) async {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final localCat = CategoryModel(
      id: tempId,
      name: name,
      type: type,
      color: color ?? '#10B981',
      icon: icon ?? 'tag',
    );

    categories.insert(0, localCat);
    storageService.saveCachedCategories(categories.map((e) => e.toJson()).toList());

    if (!syncService.isOnline.value) {
      await syncService.enqueueCreateCategory(
        name: name,
        type: type,
        color: color,
        icon: icon,
      );
      AppHaptics.light();
      SnackbarService.success('Category "$name" successfully added');
      return true;
    }

    try {
      AppHaptics.light();
      final newCat = await repository.createCategory({
        'name': name,
        'type': type,
        'color': color ?? '#10B981',
        'icon': icon ?? 'tag',
      });
      final idx = categories.indexWhere((c) => c.id == tempId);
      if (idx != -1) {
        categories[idx] = newCat;
      }
      storageService.saveCachedCategories(categories.map((e) => e.toJson()).toList());
      SnackbarService.success('Category "$name" successfully added');
      return true;
    } catch (e) {
      await syncService.enqueueCreateCategory(
        name: name,
        type: type,
        color: color,
        icon: icon,
      );
      SnackbarService.success('Category "$name" successfully added');
      return true;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      AppHaptics.heavy();
      final success = await repository.deleteCategory(id);
      if (success) {
        categories.removeWhere((c) => c.id == id);
        storageService.saveCachedCategories(categories.map((e) => e.toJson()).toList());
        SnackbarService.success('Category successfully deleted');
        return true;
      }
      return false;
    } catch (e) {
      SnackbarService.error('Failed to delete category');
      return false;
    }
  }
}
