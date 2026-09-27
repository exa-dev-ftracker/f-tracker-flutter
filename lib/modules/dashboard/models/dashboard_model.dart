import '../../transactions/models/transaction_model.dart';

class DashboardMetrics {
  final double balance;
  final double incomeTotal;
  final double expenseTotal;
  final int transactionCount;

  const DashboardMetrics({
    required this.balance,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.transactionCount,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      incomeTotal: (json['incomeTotal'] as num?)?.toDouble() ?? 0.0,
      expenseTotal: (json['expenseTotal'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'balance': balance,
    'incomeTotal': incomeTotal,
    'expenseTotal': expenseTotal,
    'transactionCount': transactionCount,
  };
}

class TopExpenseItem {
  final String name;
  final double amount;
  final String color;
  final String icon;
  final int percentage;

  const TopExpenseItem({
    required this.name,
    required this.amount,
    required this.color,
    required this.icon,
    required this.percentage,
  });

  factory TopExpenseItem.fromJson(Map<String, dynamic> json) {
    return TopExpenseItem(
      name: json['name']?.toString() ?? 'Lain-lain',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      color: json['color']?.toString() ?? '#F43F5E',
      icon: json['icon']?.toString() ?? 'tag',
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'color': color,
    'icon': icon,
    'percentage': percentage,
  };
}

class DashboardData {
  final DashboardMetrics metrics;
  final List<TransactionModel> recentTransactions;
  final List<TopExpenseItem> topExpenses;

  const DashboardData({
    required this.metrics,
    required this.recentTransactions,
    required this.topExpenses,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final metricsJson = json['metrics'] is Map ? json['metrics'] as Map<String, dynamic> : <String, dynamic>{};
    final recentList = json['recentTransactions'] is List ? json['recentTransactions'] as List : [];
    final topList = json['topExpenses'] is List ? json['topExpenses'] as List : [];

    return DashboardData(
      metrics: DashboardMetrics.fromJson(metricsJson),
      recentTransactions: recentList
          .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      topExpenses: topList
          .map((e) => TopExpenseItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'metrics': metrics.toJson(),
    'recentTransactions': recentTransactions.map((e) => e.toJson()).toList(),
    'topExpenses': topExpenses.map((e) => e.toJson()).toList(),
  };
}
