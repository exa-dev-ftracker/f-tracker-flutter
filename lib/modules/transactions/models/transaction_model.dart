import '../../categories/models/category_model.dart';

class TransactionModel {
  final String id;
  final double amount;
  final String type; // 'Income' or 'Expense'
  final String description;
  final CategoryModel? category;
  final DateTime createdAt;
  final bool isPendingSync;

  const TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    this.category,
    required this.createdAt,
    this.isPendingSync = false,
  });

  bool get isIncome => type.toLowerCase() == 'income';

  TransactionModel copyWith({
    String? id,
    double? amount,
    String? type,
    String? description,
    CategoryModel? category,
    DateTime? createdAt,
    bool? isPendingSync,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    CategoryModel? cat;
    if (json['category'] is Map) {
      cat = CategoryModel.fromJson(Map<String, dynamic>.from(json['category']));
    }

    DateTime dt = DateTime.now();
    if (json['createdAt'] != null) {
      dt = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    }

    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final isPending = json['isPendingSync'] == true || id.startsWith('temp_');

    return TransactionModel(
      id: id,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type']?.toString() ?? 'Expense',
      description: json['description']?.toString() ?? '',
      category: cat,
      createdAt: dt,
      isPendingSync: isPending,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'type': type,
    'description': description,
    'category': category?.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'isPendingSync': isPendingSync,
  };
}
