import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/utils/app_haptics.dart';
import '../../categories/controllers/category_controller.dart';
import '../../categories/models/category_model.dart';
import '../../categories/repositories/category_repository.dart';
import '../models/transaction_model.dart';
import 'transaction_controller.dart';

class EditTransactionController extends GetxController {
  final TransactionModel originalTransaction;

  TransactionController? _txController;
  CategoryController? _catController;

  EditTransactionController({required this.originalTransaction});

  TransactionController get txController =>
      _txController ??= Get.find<TransactionController>();

  CategoryController get catController {
    if (_catController != null) return _catController!;
    if (Get.isRegistered<CategoryController>()) {
      return _catController = Get.find<CategoryController>();
    }
    if (!Get.isRegistered<CategoryRepository>()) {
      Get.lazyPut<CategoryRepository>(
        () => CategoryRepository(apiClient: Get.find<ApiClient>()),
      );
    }
    final cat = Get.put(
      CategoryController(repository: Get.find<CategoryRepository>()),
    );
    _catController = cat;
    return cat;
  }

  final selectedType = 'Expense'.obs;
  final rawAmount = '0'.obs;
  final selectedCategoryId = RxnString();
  final selectedDate = Rx<DateTime>(DateTime.now());
  final isSubmitting = false.obs;

  final TextEditingController descController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Pre-populate from original transaction
    selectedType.value = originalTransaction.type;
    rawAmount.value = originalTransaction.amount.toInt().toString();
    selectedCategoryId.value = originalTransaction.category?.id;
    selectedDate.value = originalTransaction.date;
    descController.text = originalTransaction.description;
  }

  double get amountValue => double.tryParse(rawAmount.value) ?? 0.0;
  bool get isIncome => selectedType.value == 'Income';

  List<CategoryModel> get currentCategories =>
      isIncome ? catController.incomeCategories : catController.expenseCategories;

  void setType(String type) {
    AppHaptics.selection();
    selectedType.value = type;
    selectedCategoryId.value = null;
  }

  void selectCategory(String? categoryId) {
    AppHaptics.selection();
    if (selectedCategoryId.value == categoryId) {
      selectedCategoryId.value = null;
    } else {
      selectedCategoryId.value = categoryId;
    }
  }

  void onNumpadPress(String val) {
    AppHaptics.light();
    if (val == 'back') {
      if (rawAmount.value.length > 1) {
        rawAmount.value = rawAmount.value.substring(0, rawAmount.value.length - 1);
      } else {
        rawAmount.value = '0';
      }
    } else if (val == '000') {
      if (rawAmount.value != '0' && rawAmount.value.length < 12) {
        rawAmount.value += '000';
      }
    } else {
      if (rawAmount.value == '0') {
        rawAmount.value = val;
      } else if (rawAmount.value.length < 12) {
        rawAmount.value += val;
      }
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      selectedDate.value = DateTime(
        picked.year,
        picked.month,
        picked.day,
      );
    }
  }

  Future<void> submit() async {
    if (amountValue <= 0) {
      SnackbarService.warning('Amount must be greater than 0');
      return;
    }

    isSubmitting.value = true;
    try {
      final desc = descController.text.trim().isNotEmpty
          ? descController.text.trim()
          : (selectedType.value == 'Income' ? 'Income' : 'Expense');

      final success = await txController.updateTransaction(
        id: originalTransaction.id,
        amount: amountValue,
        type: selectedType.value,
        description: desc,
        categoryId: selectedCategoryId.value,
        date: selectedDate.value,
      );

      if (success) {
        if (Get.context != null && Navigator.canPop(Get.context!)) {
          Navigator.pop(Get.context!);
        } else if (Get.key.currentState?.canPop() ?? false) {
          Get.key.currentState?.pop();
        } else {
          Get.back();
        }
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    descController.dispose();
    super.onClose();
  }
}
