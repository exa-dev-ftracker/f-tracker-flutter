import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
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
            borderRadius: BorderRadius.circular(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.label_rounded, color: color, size: 22),
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
                cat.type == 'income' ? 'Income' : 'Expense',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                onPressed: () => _confirmDelete(cat),
              ),
            ),
          );
        },
      );
    });
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final selectedType = 'expense'.obs;
    final selectedColor = '#10B981'.obs;

    final colorOptions = [
      '#10B981', '#3B82F6', '#8B5CF6', '#F59E0B',
      '#F43F5E', '#06B6D4', '#EC4899', '#6366F1'
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
              const Text(
                'Add New Category',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Category name (e.g. Coffee, Cinema)',
                  labelText: 'Category Name',
                ),
              ),
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
              const SizedBox(height: 24),
              // Submit Button
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final success = await controller.addCategory(
                    name: name,
                    type: selectedType.value,
                    color: selectedColor.value,
                  );
                  if (success) Get.back();
                },
                child: const Text('Save Category'),
              ),
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
        title: const Text('Delete Category', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Are you sure you want to delete category "${cat.name}"?', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
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
