import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../controllers/analytics_controller.dart';
import '../models/analytics_model.dart';

class AnalyticsView extends GetView<AnalyticsController> {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Financial Analytics'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh data',
            onPressed: () => controller.fetchAnalytics(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => controller.fetchAnalytics(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Selector
                _buildPeriodSelector(),
                const SizedBox(height: 16),

                // Cashflow Metrics Cards Grid
                _buildMetricsGrid(),
                const SizedBox(height: 24),

                // Category Breakdown Chart Section
                _buildCategoryChartSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = [
      {'key': 'Day', 'label': 'Today'},
      {'key': 'Week', 'label': 'This Week'},
      {'key': 'Month', 'label': 'This Month'},
      {'key': 'Year', 'label': 'This Year'},
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

  Widget _buildMetricsGrid() {
    return Obx(() {
      final metrics = controller.analyticsData.value?.metrics;
      final income = metrics?.incomeTotal ?? 0.0;
      final expense = metrics?.expenseTotal ?? 0.0;
      final savings = metrics?.netSavings ?? 0.0;
      final avg = metrics?.averageTransaction ?? 0.0;

      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Total Income',
                  value: CurrencyFormatter.format(income),
                  color: AppColors.income,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Total Expenses',
                  value: CurrencyFormatter.format(expense),
                  color: AppColors.expense,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Net Savings',
                  value: CurrencyFormatter.format(savings),
                  color: savings >= 0 ? AppColors.accent : AppColors.error,
                  icon: Icons.savings_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Average Transaction',
                  value: CurrencyFormatter.formatCompact(avg),
                  color: AppColors.secondary,
                  icon: Icons.query_stats_rounded,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChartSection() {
    return Obx(() {
      final isExpense = controller.activeTab.value == 'expense';
      final breakdownList = isExpense
          ? (controller.analyticsData.value?.expenseByCategory ?? [])
          : (controller.analyticsData.value?.incomeByCategory ?? []);

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Expense / Income Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Category Distribution',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    children: [
                      _buildTabToggle('Expense', 'expense'),
                      _buildTabToggle('Income', 'income'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (breakdownList.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Text('No data for this period', style: TextStyle(color: AppColors.textMuted)),
                ),
              )
            else ...[
              // Interactive Donut Chart using fl_chart
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, pieTouchResponse) {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          controller.touchedPieIndex.value = -1;
                          return;
                        }
                        controller.touchedPieIndex.value =
                            pieTouchResponse.touchedSection!.touchedSectionIndex;
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 3,
                    centerSpaceRadius: 55,
                    sections: _generatePieSections(breakdownList),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Breakdown Legend List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: breakdownList.length,
                separatorBuilder: (_, _) => const Divider(color: AppColors.border, height: 16),
                itemBuilder: (context, index) {
                  final item = breakdownList[index];
                  final color = _parseColor(item.color);

                  return Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '${item.percentage}%',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        CurrencyFormatter.format(item.amount),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildTabToggle(String label, String tabKey) {
    final isSelected = controller.activeTab.value == tabKey;
    return GestureDetector(
      onTap: () => controller.setActiveTab(tabKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _generatePieSections(List<CategoryBreakdownItem> list) {
    return List.generate(list.length, (i) {
      final isTouched = i == controller.touchedPieIndex.value;
      final item = list[i];
      final color = _parseColor(item.color);
      final radius = isTouched ? 32.0 : 26.0;

      return PieChartSectionData(
        color: color,
        value: item.amount > 0 ? item.amount : 1.0,
        title: isTouched ? '${item.percentage}%' : '',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
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
