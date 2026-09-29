import 'package:get/get.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/utils/app_error_handler.dart';
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
      SnackbarService.success('Category "$name" added successfully');
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
      SnackbarService.success('Category "$name" added successfully');
      return true;
    } catch (e) {
      if (AppErrorHandler.isOfflineOrNetworkError(e)) {
        await syncService.enqueueCreateCategory(
          name: name,
          type: type,
          color: color,
          icon: icon,
        );
        SnackbarService.success('Category "$name" added successfully');
        return true;
      }
      // Rollback on server validation error
      categories.removeWhere((c) => c.id == tempId);
      storageService.saveCachedCategories(categories.map((e) => e.toJson()).toList());
      AppErrorHandler.handle(e, fallback: 'Failed to add category');
      return false;
    }
  }

  Future<bool> updateCategory({
    required String id,
    required String name,
    required String type,
    String? color,
    String? icon,
  }) async {
    final oldCategories = List<CategoryModel>.from(categories);
    final idx = categories.indexWhere((c) => c.id == id);
    if (idx == -1) return false;

    final updatedCat = categories[idx].copyWith(
      name: name,
      type: type,
      color: color ?? categories[idx].color,
      icon: icon ?? categories[idx].icon,
    );

    categories[idx] = updatedCat;
    categories.refresh();
    storageService.saveCachedCategories(categories.map((e) => e.toJson()).toList());

    if (!syncService.isOnline.value || id.startsWith('temp_')) {
      await syncService.enqueueUpdateCategory(
        id: id,
        name: name,
        type: type,
        color: color,
        icon: icon,
      );
      AppHaptics.light();
      SnackbarService.success('Category "$name" updated successfully');
      return true;
    }

    try {
      AppHaptics.light();
      final serverCat = await repository.updateCategory(id, {
        'name': name,
        'type': type,
        'color': color,
        'icon': icon,
      });
      final newIdx = categories.indexWhere((c) => c.id == id);
      if (newIdx != -1) {
        categories[newIdx] = serverCat;
        categories.refresh();
      }
      storageService.saveCachedCategories(categories.map((e) => e.toJson()).toList());
      SnackbarService.success('Category "$name" updated successfully');
      return true;
    } catch (e) {
      if (AppErrorHandler.isOfflineOrNetworkError(e)) {
        await syncService.enqueueUpdateCategory(
          id: id,
          name: name,
          type: type,
          color: color,
          icon: icon,
        );
        SnackbarService.success('Category "$name" updated successfully');
        return true;
      }
      // Rollback on server validation error
      categories.assignAll(oldCategories);
      storageService.saveCachedCategories(categories.map((e) => e.toJson()).toList());
      AppErrorHandler.handle(e, fallback: 'Failed to update category');
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      AppHaptics.heavy();
      final success = await repository.deleteCategory(id);
      if (success) {
        categories.removeWhere((c) => c.id == id);
        storageService.saveCachedCategories(categories.map((e) => e.toJson()).toList());
        SnackbarService.success('Category deleted successfully');
        return true;
      }
      SnackbarService.error('Failed to delete category');
      return false;
    } catch (e) {
      AppErrorHandler.handle(e, fallback: 'Failed to delete category');
      return false;
    }
  }
}
