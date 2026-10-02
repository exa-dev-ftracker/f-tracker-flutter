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
  final selectedLinkedIncomeId = RxnString();
  final selectedLinkedIncomeTitle = RxnString();
  final availableIncomes = <TransactionModel>[].obs;
  final isLoadingIncomes = false.obs;
  final isLoadingMoreIncomes = false.obs;
  final hasMoreIncomes = true.obs;
  final incomePage = 1.obs;
  final incomeSearchQuery = ''.obs;
  final selectedDate = Rx<DateTime>(DateTime.now());
  final isSubmitting = false.obs;

  final TextEditingController descController = TextEditingController();
  final TextEditingController incomeSearchController = TextEditingController();
  final ScrollController incomeScrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    // Pre-populate from original transaction
    selectedType.value = originalTransaction.type;
    rawAmount.value = originalTransaction.amount.toInt().toString();
    selectedCategoryId.value = originalTransaction.category?.id;
    selectedLinkedIncomeId.value = originalTransaction.linkedIncomeId;
    selectedLinkedIncomeTitle.value = originalTransaction.linkedIncomeDescription;
    selectedDate.value = originalTransaction.date;
    descController.text = originalTransaction.description;
    loadAvailableIncomes(reset: true);

    incomeScrollController.addListener(_onIncomeScroll);
  }

  void _onIncomeScroll() {
    if (incomeScrollController.position.pixels >=
        incomeScrollController.position.maxScrollExtent - 100) {
      loadMoreIncomes();
    }
  }

  Future<void> loadAvailableIncomes({bool reset = false}) async {
    if (reset) {
      incomePage.value = 1;
      hasMoreIncomes.value = true;
      availableIncomes.clear();
    }
    if (isLoadingIncomes.value || isLoadingMoreIncomes.value) return;

    if (incomePage.value == 1) {
      isLoadingIncomes.value = true;
    } else {
      isLoadingMoreIncomes.value = true;
    }

    try {
      final res = await txController.getAvailableIncomes(
        page: incomePage.value,
        limit: 10,
        search: incomeSearchQuery.value,
      );
      final rawList = (res['incomes'] as List<TransactionModel>?) ?? [];
      final bool more = res['hasMore'] == true;

      // Exclude self if this is an income
      final filtered = rawList.where((t) => t.id != originalTransaction.id).toList();

      if (incomePage.value == 1) {
        availableIncomes.assignAll(filtered);
      } else {
        availableIncomes.addAll(filtered);
      }
      hasMoreIncomes.value = more;

      // If we have a linkedIncomeId and missing title, try to populate title from list
      if (selectedLinkedIncomeId.value != null && selectedLinkedIncomeTitle.value == null) {
        final match = availableIncomes.firstWhereOrNull((t) => t.id == selectedLinkedIncomeId.value);
        if (match != null) {
          selectedLinkedIncomeTitle.value = match.description;
        }
      }
    } finally {
      isLoadingIncomes.value = false;
      isLoadingMoreIncomes.value = false;
    }
  }

  void loadMoreIncomes() {
    if (!hasMoreIncomes.value || isLoadingIncomes.value || isLoadingMoreIncomes.value) return;
    incomePage.value++;
    loadAvailableIncomes();
  }

  void searchIncomes(String query) {
    incomeSearchQuery.value = query;
    loadAvailableIncomes(reset: true);
  }

  void selectLinkedIncome(TransactionModel? income) {
    AppHaptics.selection();
    if (income == null) {
      selectedLinkedIncomeId.value = null;
      selectedLinkedIncomeTitle.value = null;
    } else {
      selectedLinkedIncomeId.value = income.id;
      selectedLinkedIncomeTitle.value = income.description;
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
    if (type == 'Income') {
      selectedLinkedIncomeId.value = null;
      selectedLinkedIncomeTitle.value = null;
    } else {
      loadAvailableIncomes();
    }
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
        linkedIncomeId: isIncome ? null : selectedLinkedIncomeId.value,
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
    incomeSearchController.dispose();
    incomeScrollController.dispose();
    super.onClose();
  }
}
