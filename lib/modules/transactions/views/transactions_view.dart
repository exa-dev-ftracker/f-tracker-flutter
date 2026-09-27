import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/offline_sync_banner.dart';
import '../../../routes/app_routes.dart';
import '../controllers/transaction_controller.dart';
import 'widgets/transaction_card.dart';

class TransactionsView extends GetView<TransactionController> {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daftar Transaksi'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan data',
            onPressed: () => controller.fetchTransactions(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'Catat Transaksi Baru',
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
                    hintText: 'Cari transaksi...',
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

                // Type Filter Pills
                Obx(() => Row(
                  children: [
                    _buildFilterChip('Semua', ''),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pengeluaran', 'Expense'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pemasukan', 'Income'),
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
                  '${controller.transactions.length} Transaksi',
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
                          'Belum ada transaksi',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ketuk tombol + untuk mulai mencatat keuangan',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
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
