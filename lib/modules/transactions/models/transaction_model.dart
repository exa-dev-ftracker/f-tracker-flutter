import '../../../core/utils/currency_formatter.dart';
import '../../categories/models/category_model.dart';

class TransactionModel {
  final String id;
  final double amount;
  final String type; // 'Income' or 'Expense'
  final String description;
  final CategoryModel? category;
  final DateTime date; // The actual date the transaction occurred
  final DateTime createdAt; // Real system insertion timestamp
  final bool isPendingSync;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    this.category,
    DateTime? date,
    required this.createdAt,
    this.isPendingSync = false,
  }) : date = date ?? createdAt;

  bool get isIncome => type.toLowerCase() == 'income';
  DateTime get transactionDate => date;

  TransactionModel copyWith({
    String? id,
    double? amount,
    String? type,
    String? description,
    CategoryModel? category,
    DateTime? date,
    DateTime? createdAt,
    bool? isPendingSync,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    CategoryModel? cat;
    if (json['category'] is Map) {
      cat = CategoryModel.fromJson(Map<String, dynamic>.from(json['category']));
    }

    final createdStr = json['createdAt']?.toString();
    DateTime createdDt = DateTime.now();
    if (createdStr != null) {
      createdDt = DateTime.tryParse(createdStr) ?? DateTime.now();
    }

    final dateCandidate = (json['date'] != null && json['date'].toString().isNotEmpty)
        ? json['date'].toString()
        : createdStr;
    DateTime txDate = createdDt;
    if (dateCandidate != null) {
      final str = dateCandidate.trim();
      if (str.contains('T') || str.endsWith('Z')) {
        final parsed = CurrencyFormatter.toUserTimezone(str);
        txDate = DateTime(parsed.year, parsed.month, parsed.day);
      } else {
        final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(str);
        if (match != null) {
          txDate = DateTime(
            int.parse(match.group(1)!),
            int.parse(match.group(2)!),
            int.parse(match.group(3)!),
          );
        } else {
          final parsed = CurrencyFormatter.toUserTimezone(str);
          txDate = DateTime(parsed.year, parsed.month, parsed.day);
        }
      }
    }


    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final isPending = json['isPendingSync'] == true || id.startsWith('temp_');

    return TransactionModel(
      id: id,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type']?.toString() ?? 'Expense',
      description: json['description']?.toString() ?? '',
      category: cat,
      date: txDate,
      createdAt: createdDt,
      isPendingSync: isPending,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'type': type,
    'description': description,
    'category': category?.toJson(),
    'date': date.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'isPendingSync': isPendingSync,
  };
}
