import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/offline_sync_banner.dart';
import '../../../routes/app_routes.dart';
import '../../transactions/views/widgets/transaction_card.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<StorageService>();
    final user = storage.user;
    final userName = user?['name'] ?? 'Pengguna';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => controller.fetchDashboard(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar Greeting
                _buildTopBar(userName),
                const SizedBox(height: 12),

                // Offline & Sync Status Banner
                const OfflineSyncBanner(),

                // Period Selector Tabs
                _buildPeriodSelector(),
                const SizedBox(height: 16),

                // Hero FinTech Balance Card
                _buildBalanceCard(),
                const SizedBox(height: 20),

                // Quick Action Buttons Grid
                _buildQuickActionsGrid(),
                const SizedBox(height: 24),

                // Top Spending Categories
                _buildTopCategoriesSection(),
                const SizedBox(height: 24),

                // Recent Transactions List
                _buildRecentTransactionsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(String userName) {
    return Row(
      children: [
        // User Avatar
        GestureDetector(
          onTap: () => Get.toNamed(Routes.settings),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.emeraldGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Greeting Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, $userName 👋',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Pantau & kendalikan finansialmu',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        // Settings Button
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
          tooltip: 'Pengaturan & Akun',
          onPressed: () => Get.toNamed(Routes.settings),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    final periods = [
      {'key': 'Day', 'label': 'Hari Ini'},
      {'key': 'Week', 'label': 'Minggu Ini'},
      {'key': 'Month', 'label': 'Bulan Ini'},
      {'key': 'Year', 'label': 'Tahun Ini'},
      {'key': 'All', 'label': 'Semua'},
    ];

    return Obx(() {
      return SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: periods.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final p = periods[index];
            final isSelected = controller.selectedView.value == p['key'];

            return GestureDetector(
              onTap: () => controller.setView(p['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    p['label']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildBalanceCard() {
    return Obx(() {
      final metrics = controller.dashboardData.value?.metrics;
      final balance = metrics?.balance ?? 0.0;
      final income = metrics?.incomeTotal ?? 0.0;
      final expense = metrics?.expenseTotal ?? 0.0;

      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: AppColors.balanceCardGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saldo Bersih',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Obx(() {
                  final syncService = Get.isRegistered<SyncService>() ? Get.find<SyncService>() : null;
                  final isOnline = syncService?.isOnline.value ?? true;
                  final isSyncing = syncService?.isSyncing.value ?? false;
                  final pending = syncService?.pendingCount.value ?? 0;

                  Color badgeColor = AppColors.income;
                  IconData badgeIcon = Icons.cloud_done_rounded;
                  String badgeText = 'Tersinkron';

                  if (isSyncing) {
                    badgeColor = AppColors.secondary;
                    badgeIcon = Icons.sync_rounded;
                    badgeText = 'Menyinkronkan...';
                  } else if (!isOnline) {
                    badgeColor = AppColors.warning;
                    badgeIcon = Icons.wifi_off_rounded;
                    badgeText = 'Offline';
                  } else if (pending > 0) {
                    badgeColor = AppColors.warning;
                    badgeIcon = Icons.cloud_upload_outlined;
                    badgeText = '$pending Tertunda';
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, color: badgeColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          badgeText,
                          style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              CurrencyFormatter.format(balance),
              style: TextStyle(
                color: balance >= 0 ? AppColors.textPrimary : AppColors.expense,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),

            // Income & Expense Sub-Capsules
            Row(
              children: [
                // Income Capsule
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.incomeBg.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.income.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.arrow_downward_rounded, color: AppColors.income, size: 14),
                            SizedBox(width: 4),
                            Text('Pemasukan', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.formatCompact(income),
                          style: const TextStyle(
                            color: AppColors.income,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Expense Capsule
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.expenseBg.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.expense.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.arrow_upward_rounded, color: AppColors.expense, size: 14),
                            SizedBox(width: 4),
                            Text('Pengeluaran', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.formatCompact(expense),
                          style: const TextStyle(
                            color: AppColors.expense,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQuickActionsGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionTile(
          icon: Icons.add_rounded,
          color: AppColors.primary,
          label: 'Catat Baru',
          onTap: () => Get.toNamed(Routes.addTransaction),
        ),
        _buildActionTile(
          icon: Icons.document_scanner_rounded,
          color: AppColors.secondary,
          label: 'Scan Struk',
          onTap: () => Get.toNamed(Routes.addTransaction),
        ),
        _buildActionTile(
          icon: Icons.bar_chart_rounded,
          color: AppColors.accent,
          label: 'Analitik',
          onTap: () => Get.toNamed(Routes.analytics),
        ),
        _buildActionTile(
          icon: Icons.category_rounded,
          color: AppColors.warning,
          label: 'Kategori',
          onTap: () => Get.toNamed(Routes.categories),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        AppHaptics.light();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategoriesSection() {
    return Obx(() {
      final topList = controller.dashboardData.value?.topExpenses ?? [];
      if (topList.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengeluaran Terbesar',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: topList.map((item) {
                final catColor = _parseColor(item.color);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(item.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Text(
                            CurrencyFormatter.format(item.amount),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Linear progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (item.percentage / 100).clamp(0.0, 1.0),
                          backgroundColor: AppColors.surfaceVariant,
                          color: catColor,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildRecentTransactionsSection() {
    return Obx(() {
      final recent = controller.dashboardData.value?.recentTransactions ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transaksi Terkini',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed(Routes.transactions),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.receipt_outlined, size: 40, color: AppColors.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    const Text('Belum ada transaksi di periode ini', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return TransactionCard(transaction: recent[index]);
              },
            ),
        ],
      );
    });
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.expense;
    }
  }
}
