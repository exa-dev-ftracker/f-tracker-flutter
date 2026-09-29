import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/offline_sync_banner.dart';
import '../../../routes/app_routes.dart';
import '../../navigation/controllers/navigation_controller.dart';
import '../controllers/transaction_controller.dart';
import 'widgets/transaction_card.dart';

class TransactionsView extends GetView<TransactionController> {
  const TransactionsView({super.key});

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        title: const Text('Transactions'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh data',
            onPressed: () => controller.fetchTransactions(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: Get.isRegistered<NavigationController>()
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              tooltip: 'Record New Transaction',
              onPressed: () => Get.toNamed(Routes.addTransaction),
              child: const Icon(Icons.add_rounded, size: 28),
            ),
      body: Column(
        children: [
          // Offline & Sync Status Banner
          const OfflineSyncBanner(),

          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: AppColors.surface,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: controller.searchController,
                  onChanged: controller.onSearchChanged,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              controller.searchController.clear();
                              controller.onSearchChanged('');
                            },
                          )
                        : const SizedBox.shrink()),
                  ),
                ),
                const SizedBox(height: 10),

                // Period View Pills
                SizedBox(
                  height: 34,
                  child: Obx(() => ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final period in ['Day', 'Week', 'Month', 'Year', 'All'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildViewChip(period, controller.selectedView.value == period),
                        ),
                      // Custom Month/Year picker button
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildCustomDateChip(context),
                      ),
                    ],
                  )),
                ),
                const SizedBox(height: 10),

                // Custom date indicator banner
                Obx(() {
                  if (controller.filterYear.value == null) {
                    return const SizedBox.shrink();
                  }
                  final year = controller.filterYear.value!;
                  final month = controller.filterMonth.value;
                  final label = month != null
                      ? '${_monthNames[month - 1]} $year'
                      : 'Year $year';
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_alt_rounded, size: 16, color: AppColors.primary.withValues(alpha: 0.8)),
                        const SizedBox(width: 8),
                        Text(
                          'Filtered: $label',
                          style: TextStyle(
                            color: AppColors.primary.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: controller.clearCustomFilter,
                          child: Icon(Icons.close_rounded, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  );
                }),

                // Type Filter Pills
                Obx(() => Row(
                  children: [
                    _buildFilterChip('All', ''),
                    const SizedBox(width: 8),
                    _buildFilterChip('Expense', 'Expense'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Income', 'Income'),
                  ],
                )),
              ],
            ),
          ),

          // Total Overview Strip
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surfaceVariant.withValues(alpha: 0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${controller.transactions.length} Transactions',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                Row(
                  children: [
                    Text(
                      '+${CurrencyFormatter.formatCompact(controller.incomeTotal.value)}',
                      style: const TextStyle(color: AppColors.income, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '-${CurrencyFormatter.formatCompact(controller.expenseTotal.value)}',
                      style: const TextStyle(color: AppColors.expense, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          )),

          // Transactions List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.fetchTransactions(),
              color: AppColors.primary,
              child: Obx(() {
                if (controller.isLoading.value && controller.transactions.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (controller.transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 54, color: AppColors.textMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 14),
                        const Text(
                          'No transactions yet',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap the + button to record a transaction',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  itemCount: controller.transactions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tx = controller.transactions[index];
                    return TransactionCard(
                      transaction: tx,
                      onDelete: () => controller.deleteTransaction(tx),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => controller.setViewPeriod(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateChip(BuildContext context) {
    return Obx(() {
      final isActive = controller.filterYear.value != null;
      return GestureDetector(
        onTap: () => _showMonthYearPicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: isActive ? null : Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.date_range_rounded,
                size: 14,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Custom',
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showMonthYearPicker(BuildContext context) {
    final now = DateTime.now();
    final pickerYear = (controller.filterYear.value ?? now.year).obs;
    final pickerMonth = RxnInt(controller.filterMonth.value);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter by Month & Year',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Year Picker Row
            Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
                  onPressed: () => pickerYear.value--,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${pickerYear.value}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onPressed: () {
                    if (pickerYear.value < now.year + 1) pickerYear.value++;
                  },
                ),
              ],
            )),
            const SizedBox(height: 16),

            // Month Grid
            Obx(() => GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: List.generate(12, (i) {
                final m = i + 1;
                final isSelected = pickerMonth.value == m;
                final isFuture = pickerYear.value == now.year && m > now.month;
                return GestureDetector(
                  onTap: isFuture ? null : () {
                    if (pickerMonth.value == m) {
                      pickerMonth.value = null; // Deselect for year-only filter
                    } else {
                      pickerMonth.value = m;
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : isFuture
                              ? AppColors.surfaceVariant.withValues(alpha: 0.3)
                              : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: AppColors.primary)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _monthNames[i].substring(0, 3),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isFuture
                                ? AppColors.textMuted.withValues(alpha: 0.4)
                                : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
            )),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Get.back();
                      controller.clearCustomFilter();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Reset', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      Get.back();
                      if (pickerMonth.value != null) {
                        controller.setCustomMonthYear(pickerYear.value, pickerMonth.value!);
                      } else {
                        controller.setCustomYear(pickerYear.value);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Obx(() {
                      final month = pickerMonth.value;
                      final label = month != null
                          ? 'Show ${_monthNames[month - 1]} ${pickerYear.value}'
                          : 'Show Year ${pickerYear.value}';
                      return Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = controller.selectedType.value == type;
    return GestureDetector(
      onTap: () => controller.setFilterType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
