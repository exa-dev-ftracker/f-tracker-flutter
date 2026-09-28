import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/receipt_scanner_service.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../categories/controllers/category_controller.dart';
import '../../categories/models/category_model.dart';
import '../../categories/repositories/category_repository.dart';
import 'transaction_controller.dart';

class AddTransactionController extends GetxController {
  TransactionController? _txController;
  CategoryController? _catController;

  AddTransactionController({
    TransactionController? txController,
    CategoryController? catController,
  }) {
    if (txController != null) _txController = txController;
    if (catController != null) _catController = catController;
  }

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
    final storage = Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;
    final userTz = storage?.user?['timezone']?.toString();
    selectedDate.value = CurrencyFormatter.nowInTimezone(userTz);

    final args = Get.arguments;
    if (args is Map && args['scanned'] is ScannedReceiptResult) {
      _applyScannedResult(args['scanned'] as ScannedReceiptResult);
    }
  }

  void _applyScannedResult(ScannedReceiptResult result) {
    if (result.estimatedAmount != null && result.estimatedAmount! > 0) {
      rawAmount.value = result.estimatedAmount!.toInt().toString();
    }
    if (result.merchantName != null && result.merchantName!.isNotEmpty) {
      descController.text = result.merchantName!;
    }
    if (result.date != null) {
      selectedDate.value = result.date!;
    }
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
      final current = selectedDate.value;
      selectedDate.value = DateTime(
        picked.year,
        picked.month,
        picked.day,
        current.hour,
        current.minute,
        current.second,
      );
    }
  }

  Future<void> scanReceipt() async {
    AppHaptics.medium();
    final result = await ReceiptScannerService.showScannerModal();
    if (result != null) {
      _applyScannedResult(result);

      if (result.estimatedAmount != null) {
        AppHaptics.success();
        SnackbarService.success(
          'Total detected: ${CurrencyFormatter.format(result.estimatedAmount!)}${result.merchantName != null ? " (${result.merchantName})" : ""}',
          title: 'Receipt Scanned Successfully',
        );
      } else {
        SnackbarService.info(
          'Receipt image processed. Please review or adjust transaction details.',
          title: 'Receipt Scan Result',
        );
      }
    }
  }

  void resetForm() {
    rawAmount.value = '0';
    descController.clear();
    selectedCategoryId.value = null;
    selectedType.value = 'Expense';
    final storage = Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;
    final userTz = storage?.user?['timezone']?.toString();
    selectedDate.value = CurrencyFormatter.nowInTimezone(userTz);
  }

  Future<void> submit() async {
    if (amountValue <= 0) {
      Get.snackbar('Attention', 'Amount must be greater than 0', snackPosition: SnackPosition.TOP);
      return;
    }

    isSubmitting.value = true;
    try {
      final desc = descController.text.trim().isNotEmpty
          ? descController.text.trim()
          : (selectedType.value == 'Income' ? 'Income' : 'Expense');

      final success = await txController.addTransaction(
        amount: amountValue,
        type: selectedType.value,
        description: desc,
        categoryId: selectedCategoryId.value,
        date: selectedDate.value,
      );

      if (success) {
        resetForm();
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
