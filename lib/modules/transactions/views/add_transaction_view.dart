import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../controllers/add_transaction_controller.dart';

class AddTransactionView extends GetView<AddTransactionController> {
  const AddTransactionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Record Transaction'),
        backgroundColor: AppColors.surface,
        actions: [
          // Mobile Exclusive: Camera Receipt Scanner (ML Kit on-device)
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded, color: AppColors.primaryLight),
            tooltip: 'Scan Receipt with Camera (AI OCR)',
            onPressed: controller.scanReceipt,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Income / Expense Segmented Pill
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(4),
                child: Obx(() {
                  final isIncome = controller.isIncome;
                  return Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.setType('Expense'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isIncome ? AppColors.expense : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Expense',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: !isIncome ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.setType('Income'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isIncome ? AppColors.income : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Income',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isIncome ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),

            // Large Animated Amount Display
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Obx(() {
                final isIncome = controller.isIncome;
                return Column(
                  children: [
                    Text(
                      CurrencyFormatter.format(
                        controller.amountValue,
                        prefix: isIncome ? '+Rp ' : '-Rp ',
                      ),
                      style: TextStyle(
                        color: isIncome ? AppColors.income : AppColors.expense,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Transaction Amount',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                );
              }),
            ),

            // Category Chips Selector
            SizedBox(
              height: 42,
              child: Obx(() {
                final list = controller.currentCategories;
                final isIncome = controller.isIncome;
                final selectedId = controller.selectedCategoryId.value;

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = list[index];
                    final isSelected = selectedId == cat.id;

                    return ChoiceChip(
                      label: Text(cat.name),
                      selected: isSelected,
                      selectedColor: isIncome ? AppColors.income : AppColors.expense,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (_) => controller.selectCategory(cat.id),
                    );
                  },
                );
              }),
            ),

            // Note / Description Field & Date Picker
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: controller.descController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Transaction note (e.g. Lunch at bistro)...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textMuted),
                    tooltip: 'Select Date',
                    onPressed: () => controller.pickDate(context),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Custom FinTech Tactile Numeric Keypad
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNumpadRow(['1', '2', '3']),
                  _buildNumpadRow(['4', '5', '6']),
                  _buildNumpadRow(['7', '8', '9']),
                  _buildNumpadRow(['000', '0', 'back']),
                  const SizedBox(height: 12),
                  // Save Button
                  Obx(() {
                    final isIncome = controller.isIncome;
                    final isSubmitting = controller.isSubmitting.value;

                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isIncome ? AppColors.income : AppColors.expense,
                      ),
                      onPressed: isSubmitting ? null : controller.submit,
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Transaction'),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((key) {
          final isBack = key == 'back';
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => controller.onNumpadPress(key),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                child: isBack
                    ? const Icon(Icons.backspace_outlined, color: AppColors.textPrimary, size: 20)
                    : Text(
                        key,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
