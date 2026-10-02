import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/category_icon_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../controllers/edit_transaction_controller.dart';
import '../models/transaction_model.dart';

class EditTransactionView extends StatelessWidget {
  const EditTransactionView({super.key});

  @override
  Widget build(BuildContext context) {
    final tx = Get.arguments as TransactionModel;
    final controller = Get.put(EditTransactionController(originalTransaction: tx));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Transaction'),
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

                        // Optional Linked Income Selector (Only for Expense)
                        Obx(() {
                          if (controller.isIncome) return const SizedBox.shrink();

                          final linkedId = controller.selectedLinkedIncomeId.value;
                          final linkedTitle = controller.selectedLinkedIncomeTitle.value;

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                            child: Material(
                              color: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: linkedId != null ? AppColors.income.withValues(alpha: 0.5) : AppColors.border,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => _showLinkedIncomeBottomSheet(context, controller),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: (linkedId != null ? AppColors.income : AppColors.primary).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          linkedId != null ? Icons.link_rounded : Icons.link_off_rounded,
                                          size: 16,
                                          color: linkedId != null ? AppColors.income : AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'Funded By (Linked Income)',
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              linkedTitle ?? 'General Balance (No link)',
                                              style: TextStyle(
                                                color: linkedId != null ? AppColors.income : AppColors.textSecondary,
                                                fontSize: 13,
                                                fontWeight: linkedId != null ? FontWeight.w600 : FontWeight.normal,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (linkedId != null)
                                        IconButton(
                                          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => controller.selectLinkedIncome(null),
                                        )
                                      else
                                        const Icon(
                                          Icons.arrow_drop_down_rounded,
                                          size: 20,
                                          color: AppColors.textMuted,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

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
                                _buildNumpadRow(controller, ['1', '2', '3']),
                                _buildNumpadRow(controller, ['4', '5', '6']),
                                _buildNumpadRow(controller, ['7', '8', '9']),
                                _buildNumpadRow(controller, ['000', '0', 'back']),
                                const SizedBox(height: 12),
                              ],
                              // Update Button
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
                                      : const Text('Update Transaction'),
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

  void _showLinkedIncomeBottomSheet(BuildContext context, EditTransactionController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Text(
                            'Select Funding Income',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textMuted),
                            onPressed: () => controller.loadAvailableIncomes(reset: true),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Optionally link this expense to deduct from a specific income',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Search Input
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: TextField(
                        controller: controller.incomeSearchController,
                        onChanged: controller.searchIncomes,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search income description...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          suffixIcon: Obx(() => controller.incomeSearchQuery.value.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  onPressed: () {
                                    controller.incomeSearchController.clear();
                                    controller.searchIncomes('');
                                  },
                                )
                              : const SizedBox.shrink()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: AppColors.border, height: 1),

                    // Option: No Link
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.link_off_rounded, color: AppColors.textMuted, size: 20),
                      ),
                      title: const Text(
                        'General Balance (No Link)',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Not linked to any specific income',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                      trailing: controller.selectedLinkedIncomeId.value == null
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                          : null,
                      onTap: () {
                        controller.selectLinkedIncome(null);
                        Navigator.pop(ctx);
                      },
                    ),

                    const Divider(color: AppColors.border, height: 1),

                    // Incomes list with infinite scroll pagination
                    Flexible(
                      child: Obx(() {
                        if (controller.isLoadingIncomes.value) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        if (controller.availableIncomes.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Text(
                                controller.incomeSearchQuery.value.isNotEmpty
                                    ? 'No matching incomes found.'
                                    : 'No income transactions found yet.',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ),
                          );
                        }

                        final extraLoading = controller.isLoadingMoreIncomes.value ? 1 : 0;
                        final totalItems = controller.availableIncomes.length + extraLoading;

                        return ListView.separated(
                          controller: controller.incomeScrollController,
                          shrinkWrap: false,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: totalItems,
                          separatorBuilder: (context, index) => const Divider(color: AppColors.border, height: 1),
                          itemBuilder: (context, idx) {
                            if (idx >= controller.availableIncomes.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            }

                            final inc = controller.availableIncomes[idx];
                            final isSelected = controller.selectedLinkedIncomeId.value == inc.id;
                            final remaining = inc.remainingAmount ?? inc.amount;
                            final usedPct = inc.percentageUsed ?? 0.0;

                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.income.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.income, size: 20),
                              ),
                              title: Text(
                                inc.description,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    'Remaining: ${CurrencyFormatter.format(remaining)} / ${CurrencyFormatter.format(inc.amount)}',
                                    style: TextStyle(
                                      color: remaining < 0 ? AppColors.expense : AppColors.income,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (usedPct / 100).clamp(0.0, 1.0),
                                      minHeight: 4,
                                      backgroundColor: AppColors.surfaceVariant,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        usedPct >= 100 ? AppColors.expense : AppColors.income,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 22)
                                  : null,
                              onTap: () {
                                controller.selectLinkedIncome(inc);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumpadRow(EditTransactionController controller, List<String> keys) {
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
