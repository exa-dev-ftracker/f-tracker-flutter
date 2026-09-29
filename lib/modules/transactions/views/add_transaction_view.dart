import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/category_icon_helper.dart';
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
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
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
                                    prefix: isIncome ? '+' : '-',
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
                                  avatar: Icon(
                                    CategoryIconHelper.getIconData(cat.icon, cat.name),
                                    size: 16,
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                  ),
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

                        // Transaction Date Selector
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                          child: Obx(() {
                            final date = controller.selectedDate.value;
                            final dateText = CurrencyFormatter.formatDisplayDate(date);

                            return Material(
                              color: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => controller.pickDate(context),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 16,
                                          color: AppColors.primaryLight,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Transaction Date',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            dateText,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.edit_calendar_rounded,
                                        size: 18,
                                        color: AppColors.textMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        // Note / Description Field
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: TextField(
                            controller: controller.descController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => FocusScope.of(context).unfocus(),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Transaction note (e.g. Lunch at bistro)...',
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
                            ),
                          ),
                        ),

                        if (!isKeyboardOpen)
                          const Spacer()
                        else
                          const SizedBox(height: 16),

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
                              if (!isKeyboardOpen) ...[
                                _buildNumpadRow(['1', '2', '3']),
                                _buildNumpadRow(['4', '5', '6']),
                                _buildNumpadRow(['7', '8', '9']),
                                _buildNumpadRow(['000', '0', 'back']),
                                const SizedBox(height: 12),
                              ],
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
                ),
              );
            },
          ),
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
