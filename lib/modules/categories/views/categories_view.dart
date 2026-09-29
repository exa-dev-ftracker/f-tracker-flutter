import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/category_icon_helper.dart';
import '../controllers/category_controller.dart';
import '../models/category_model.dart';

class CategoriesView extends GetView<CategoryController> {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Manage Categories'),
          backgroundColor: AppColors.surface,
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: 'Expense'),
              Tab(text: 'Income'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Category'),
          onPressed: () => _showAddCategoryDialog(context),
        ),
        body: TabBarView(
          children: [
            _buildCategoryList('expense'),
            _buildCategoryList('income'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(String type) {
    return Obx(() {
      if (controller.isLoading.value && controller.categories.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }

      final list = type == 'income'
          ? controller.incomeCategories
          : controller.expenseCategories;

      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category_outlined, size: 54, color: AppColors.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                'No ${type == "income" ? "income" : "expense"} categories yet',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final cat = list[index];
          final color = _parseColor(cat.color);

          return Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              onTap: () => _showEditCategoryDialog(context, cat),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CategoryIconHelper.getIconData(cat.icon, cat.name),
                  color: color,
                  size: 22,
                ),
              ),
              title: Text(
                cat.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                cat.type == 'income' ? 'Income Category' : 'Expense Category',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                    tooltip: 'Edit Category',
                    onPressed: () => _showEditCategoryDialog(context, cat),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                    tooltip: 'Delete Category',
                    onPressed: () => _confirmDelete(cat),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  void _showAddCategoryDialog(BuildContext context) {
    _showCategoryFormModal(
      context: context,
      title: 'Add New Category',
      submitLabel: 'Save Category',
      initialName: '',
      initialType: 'expense',
      initialColor: '#10B981',
      initialIcon: 'i-heroicons-tag',
      onSubmit: (name, type, color, icon) async {
        return await controller.addCategory(
          name: name,
          type: type,
          color: color,
          icon: icon,
        );
      },
    );
  }

  void _showEditCategoryDialog(BuildContext context, CategoryModel cat) {
    _showCategoryFormModal(
      context: context,
      title: 'Edit Category',
      submitLabel: 'Update Category',
      initialName: cat.name,
      initialType: cat.type,
      initialColor: cat.color,
      initialIcon: cat.icon,
      onSubmit: (name, type, color, icon) async {
        return await controller.updateCategory(
          id: cat.id,
          name: name,
          type: type,
          color: color,
          icon: icon,
        );
      },
    );
  }

  void _showCategoryFormModal({
    required BuildContext context,
    required String title,
    required String submitLabel,
    required String initialName,
    required String initialType,
    required String initialColor,
    required String initialIcon,
    required Future<bool> Function(String name, String type, String color, String icon) onSubmit,
  }) {
    final nameCtrl = TextEditingController(text: initialName);
    final selectedType = initialType.toLowerCase().obs;
    final selectedColor = initialColor.obs;
    final selectedIcon = initialIcon.obs;
    final isSubmitting = false.obs;
    final nameError = RxnString();

    // Clear error as user types
    nameCtrl.addListener(() {
      if (nameError.value != null) nameError.value = null;
    });

    final colorOptions = [
      '#10B981', '#3B82F6', '#8B5CF6', '#F59E0B',
      '#F43F5E', '#06B6D4', '#EC4899', '#6366F1',
    ];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Type Selector
              Obx(() => Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Expense')),
                      selected: selectedType.value == 'expense',
                      onSelected: (_) => selectedType.value = 'expense',
                      selectedColor: AppColors.expense.withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Income')),
                      selected: selectedType.value == 'income',
                      onSelected: (_) => selectedType.value = 'income',
                      selectedColor: AppColors.income.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              )),
              const SizedBox(height: 16),
              // Name Field
              Obx(() => TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Category name (e.g. Coffee, Cinema)',
                  labelText: 'Category Name',
                  errorText: nameError.value,
                ),
              )),
              const SizedBox(height: 16),
              // Color Picker Row
              const Text('Category Color', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: colorOptions.map((hex) {
                  final isSelected = selectedColor.value == hex;
                  final c = _parseColor(hex);
                  return GestureDetector(
                    onTap: () {
                      AppHaptics.selection();
                      selectedColor.value = hex;
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      ),
                    ),
                  );
                }).toList(),
              )),
              const SizedBox(height: 16),

              // Icon Picker Row
              const Text('Category Icon', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Obx(() {
                final currentColor = _parseColor(selectedColor.value);
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: CategoryIconHelper.availableIcons.map((item) {
                    final isSelected = selectedIcon.value == item.key;
                    return GestureDetector(
                      onTap: () {
                        AppHaptics.selection();
                        selectedIcon.value = item.key;
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? currentColor.withValues(alpha: 0.25) : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? currentColor : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            item.iconData,
                            color: isSelected ? currentColor : AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 24),

              // Submit Button
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting.value ? null : () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      nameError.value = 'Category name is required';
                      return;
                    }
                    nameError.value = null;
                    isSubmitting.value = true;
                    try {
                      final success = await onSubmit(
                        name,
                        selectedType.value,
                        selectedColor.value,
                        selectedIcon.value,
                      );
                      if (success) Get.back();
                    } finally {
                      isSubmitting.value = false;
                    }
                  },
                  child: isSubmitting.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(submitLabel),
                ),
              )),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _confirmDelete(CategoryModel cat) {
    AppHaptics.heavy();
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Category', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete category "${cat.name}"?',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'If this category is currently used by any transactions, deletion will be blocked until those transactions are reassigned or deleted.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Get.back();
              controller.deleteCategory(cat.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
