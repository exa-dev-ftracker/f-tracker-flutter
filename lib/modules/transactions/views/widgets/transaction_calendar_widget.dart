import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../controllers/transaction_controller.dart';

class TransactionCalendarWidget extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final Map<String, DailyCalendarSummary> dailySummaries;
  final ValueChanged<DateTime> onSelectDate;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;

  const TransactionCalendarWidget({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.dailySummaries,
    required this.onSelectDate,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onToday,
  });

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const _weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthTitle = '${_monthNames[focusedMonth.month - 1]} ${focusedMonth.year}';

    // Calculate monthly summary totals
    double monthlyIncome = 0.0;
    double monthlyExpense = 0.0;
    for (final summary in dailySummaries.values) {
      if (summary.date.year == focusedMonth.year && summary.date.month == focusedMonth.month) {
        monthlyIncome += summary.totalIncome;
        monthlyExpense += summary.totalExpense;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month navigation header
          _buildMonthHeader(monthTitle, today),
          const SizedBox(height: 12),

          // Monthly Inflow / Outflow KPI strip
          _buildMonthlyKpiStrip(monthlyIncome, monthlyExpense),
          const SizedBox(height: 14),

          // Weekday columns header (Sun - Sat)
          _buildWeekdayHeader(),
          const SizedBox(height: 8),

          // Days Grid
          _buildDaysGrid(today),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(String monthTitle, DateTime today) {
    final isCurrentMonth = focusedMonth.year == today.year && focusedMonth.month == today.month;

    return Row(
      children: [
        // Calendar icon indicator
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),

        // Month & Year title
        Expanded(
          child: Text(
            monthTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
        ),

        // "Today" quick button
        if (!isCurrentMonth)
          InkWell(
            onTap: onToday,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Today',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        // Previous month button
        IconButton(
          onPressed: onPrevMonth,
          icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary, size: 22),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: 'Previous Month',
        ),

        // Next month button
        IconButton(
          onPressed: onNextMonth,
          icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 22),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: 'Next Month',
        ),
      ],
    );
  }

  Widget _buildMonthlyKpiStrip(double income, double expense) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.income),
              const SizedBox(width: 4),
              Text(
                '+${CurrencyFormatter.formatCompact(income)}',
                style: const TextStyle(
                  color: AppColors.income,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.expense),
              const SizedBox(width: 4),
              Text(
                '-${CurrencyFormatter.formatCompact(expense)}',
                style: const TextStyle(
                  color: AppColors.expense,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                'Net: ',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              Text(
                CurrencyFormatter.formatCompact(income - expense),
                style: TextStyle(
                  color: (income - expense) >= 0 ? AppColors.income : AppColors.expense,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    return Row(
      children: _weekdayLabels.map((label) {
        return Expanded(
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDaysGrid(DateTime today) {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final weekdayOffset = firstDayOfMonth.weekday % 7; // 0 for Sun, 1 for Mon...
    final daysInCurrentMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final daysInPrevMonth = DateTime(focusedMonth.year, focusedMonth.month, 0).day;

    final totalDaysNeeded = weekdayOffset + daysInCurrentMonth;
    final totalCells = ((totalDaysNeeded + 6) ~/ 7) * 7; // Multiple of 7 (28, 35, or 42)

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        DateTime cellDate;
        bool isOutsideMonth = false;

        if (index < weekdayOffset) {
          // Days from previous month
          final dayNum = daysInPrevMonth - weekdayOffset + index + 1;
          cellDate = DateTime(focusedMonth.year, focusedMonth.month - 1, dayNum);
          isOutsideMonth = true;
        } else if (index < weekdayOffset + daysInCurrentMonth) {
          // Days in current month
          final dayNum = index - weekdayOffset + 1;
          cellDate = DateTime(focusedMonth.year, focusedMonth.month, dayNum);
        } else {
          // Days in next month
          final dayNum = index - (weekdayOffset + daysInCurrentMonth) + 1;
          cellDate = DateTime(focusedMonth.year, focusedMonth.month + 1, dayNum);
          isOutsideMonth = true;
        }

        final isToday = cellDate.year == today.year &&
            cellDate.month == today.month &&
            cellDate.day == today.day;

        final isSelected = cellDate.year == selectedDate.year &&
            cellDate.month == selectedDate.month &&
            cellDate.day == selectedDate.day;

        final dateKey = '${cellDate.year.toString().padLeft(4, '0')}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}';
        final summary = dailySummaries[dateKey];

        return _buildDayCell(
          date: cellDate,
          dayNum: cellDate.day,
          isOutsideMonth: isOutsideMonth,
          isToday: isToday,
          isSelected: isSelected,
          summary: summary,
        );
      },
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required int dayNum,
    required bool isOutsideMonth,
    required bool isToday,
    required bool isSelected,
    required DailyCalendarSummary? summary,
  }) {
    // Background and border styling
    Color bgColor = Colors.transparent;
    Border? border;

    if (isSelected) {
      bgColor = AppColors.primary.withValues(alpha: 0.18);
      border = Border.all(color: AppColors.primary, width: 1.5);
    } else if (isToday) {
      bgColor = AppColors.surfaceVariant.withValues(alpha: 0.6);
      border = Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1);
    } else {
      border = Border.all(color: Colors.white.withValues(alpha: 0.04));
    }

    // Text color
    Color textColor;
    if (isOutsideMonth) {
      textColor = AppColors.textMuted.withValues(alpha: 0.35);
    } else if (isSelected) {
      textColor = Colors.white;
    } else if (isToday) {
      textColor = AppColors.primaryLight;
    } else {
      textColor = AppColors.textPrimary;
    }

    final hasIncome = summary?.hasIncome ?? false;
    final hasExpense = summary?.hasExpense ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.light();
          onSelectDate(date);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: border,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Day number
              Text(
                '$dayNum',
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),

              // Micro Activity Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasIncome)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: const BoxDecoration(
                        color: AppColors.income,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (hasExpense)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: const BoxDecoration(
                        color: AppColors.expense,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (!hasIncome && !hasExpense)
                    const SizedBox(height: 5),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
