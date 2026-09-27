class AnalyticsMetrics {
  final double incomeTotal;
  final double expenseTotal;
  final double netSavings;
  final int transactionCount;
  final double averageTransaction;
  final double largestTransaction;

  const AnalyticsMetrics({
    required this.incomeTotal,
    required this.expenseTotal,
    required this.netSavings,
    required this.transactionCount,
    required this.averageTransaction,
    required this.largestTransaction,
  });

  factory AnalyticsMetrics.fromJson(Map<String, dynamic> json) {
    return AnalyticsMetrics(
      incomeTotal: (json['incomeTotal'] as num?)?.toDouble() ?? 0.0,
      expenseTotal: (json['expenseTotal'] as num?)?.toDouble() ?? 0.0,
      netSavings: (json['netSavings'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
      averageTransaction: (json['averageTransaction'] as num?)?.toDouble() ?? 0.0,
      largestTransaction: (json['largestTransaction'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CategoryBreakdownItem {
  final String name;
  final double amount;
  final String color;
  final String icon;
  final int percentage;

  const CategoryBreakdownItem({
    required this.name,
    required this.amount,
    required this.color,
    required this.icon,
    required this.percentage,
  });

  factory CategoryBreakdownItem.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdownItem(
      name: json['name']?.toString() ?? 'Lain-lain',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      color: json['color']?.toString() ?? '#10B981',
      icon: json['icon']?.toString() ?? 'tag',
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
    );
  }
}

class AnalyticsData {
  final AnalyticsMetrics metrics;
  final List<CategoryBreakdownItem> incomeByCategory;
  final List<CategoryBreakdownItem> expenseByCategory;

  const AnalyticsData({
    required this.metrics,
    required this.incomeByCategory,
    required this.expenseByCategory,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    final metricsJson = json['metrics'] is Map ? json['metrics'] as Map<String, dynamic> : <String, dynamic>{};
    final incList = json['incomeByCategory'] is List ? json['incomeByCategory'] as List : [];
    final expList = json['expenseByCategory'] is List ? json['expenseByCategory'] as List : [];

    return AnalyticsData(
      metrics: AnalyticsMetrics.fromJson(metricsJson),
      incomeByCategory: incList
          .map((e) => CategoryBreakdownItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      expenseByCategory: expList
          .map((e) => CategoryBreakdownItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
