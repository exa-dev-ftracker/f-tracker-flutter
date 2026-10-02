import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/snackbar_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/category_icon_helper.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../models/transaction_model.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final catColor = _parseColor(transaction.category?.color ?? (isIncome ? '#10B981' : '#F43F5E'));
    final catIcon = CategoryIconHelper.getIconData(
      transaction.category?.icon,
      transaction.category?.name ?? (isIncome ? 'Income' : 'Expense'),
    );

    return Dismissible(
      key: ValueKey('tx_${transaction.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        AppHaptics.heavy();
        SnackbarService.dismissAll();
        final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete Transaction', style: TextStyle(color: AppColors.textPrimary)),
            content: Text(
              'Are you sure you want to delete "${transaction.description}" of ${CurrencyFormatter.format(transaction.amount)}?',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm == true && onDelete != null) {
          onDelete!();
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap ?? () => _showDetailModal(context),
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Category Icon Capsule
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: catColor.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Icon(
                      catIcon,
                      color: catColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Description & Category / Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description.isNotEmpty
                            ? transaction.description
                            : (transaction.category?.name ?? 'Transaction'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (transaction.category != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    catIcon,
                                    size: 11,
                                    color: catColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    transaction.category!.name,
                                    style: TextStyle(
                                      color: catColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            CurrencyFormatter.formatTransactionDate(transaction.date),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          if (transaction.linkedIncomeDescription != null && transaction.linkedIncomeDescription!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.income.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.link_rounded, size: 10, color: AppColors.income),
                                  const SizedBox(width: 3),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 90),
                                    child: Text(
                                      transaction.linkedIncomeDescription!,
                                      style: const TextStyle(
                                        color: AppColors.income,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (transaction.isPendingSync) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cloud_upload_outlined, size: 10, color: AppColors.warning),
                                  SizedBox(width: 3),
                                  Text(
                                    'Offline',
                                    style: TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount
                Text(
                  '${isIncome ? "+" : "-"}${CurrencyFormatter.format(transaction.amount)}',
                  style: TextStyle(
                    color: isIncome ? AppColors.income : AppColors.expense,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  void _showDetailModal(BuildContext context) {
    AppHaptics.selection();
    final isIncome = transaction.isIncome;
    final catColor = _parseColor(transaction.category?.color ?? (isIncome ? '#10B981' : '#F43F5E'));
    final catIcon = CategoryIconHelper.getIconData(
      transaction.category?.icon,
      transaction.category?.name ?? (isIncome ? 'Income' : 'Expense'),
    );

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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

            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaction Details',
                  style: TextStyle(
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
            const SizedBox(height: 12),

            // Hero Amount Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isIncome ? AppColors.income : AppColors.expense).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      transaction.type.toUpperCase(),
                      style: TextStyle(
                        color: isIncome ? AppColors.income : AppColors.expense,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${isIncome ? "+" : "-"}${CurrencyFormatter.format(transaction.amount)}',
                    style: TextStyle(
                      color: isIncome ? AppColors.income : AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (transaction.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      transaction.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detail items
            _buildDetailRow(
              icon: catIcon,
              label: 'Category',
              value: transaction.category?.name ?? 'General',
              color: catColor,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'Transaction Date',
              value: CurrencyFormatter.formatDisplayDate(transaction.date),
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              icon: Icons.access_time_rounded,
              label: 'Created At',
              value: CurrencyFormatter.formatFullTimestamp(transaction.createdAt),
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              icon: transaction.isPendingSync ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
              label: 'Status',
              value: transaction.isPendingSync ? 'Offline (Pending Sync)' : 'Synced',
              color: transaction.isPendingSync ? AppColors.warning : AppColors.success,
            ),
            if (transaction.linkedIncomeDescription != null && transaction.linkedIncomeDescription!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.link_rounded,
                label: 'Funded By',
                value: transaction.linkedIncomeDescription!,
                color: AppColors.income,
              ),
            ],
            if (isIncome && transaction.remainingAmount != null) ...[
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.savings_outlined,
                label: 'Remaining Balance',
                value: '${CurrencyFormatter.format(transaction.remainingAmount!)} (${(transaction.percentageUsed ?? 0).toStringAsFixed(1)}% used)',
                color: transaction.remainingAmount! < 0 ? AppColors.expense : AppColors.income,
              ),
            ],
            if (onDelete != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Get.back();
                        Get.toNamed('/transactions/edit', arguments: transaction);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error.withValues(alpha: 0.15),
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Get.back();
                        onDelete!();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.textMuted),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
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
