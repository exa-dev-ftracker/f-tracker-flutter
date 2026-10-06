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
  final String? linkedIncomeId;
  final String? linkedIncomeDescription;
  final DateTime? linkedIncomeDate;
  final double? remainingAmount;
  final double? totalUsed;
  final double? percentageUsed;
  final int? expenseCount;
  final List<TransactionModel>? linkedExpenses;
  final Map<String, dynamic>? linkedIncomeDetails;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    this.category,
    DateTime? date,
    required this.createdAt,
    this.isPendingSync = false,
    this.linkedIncomeId,
    this.linkedIncomeDescription,
    this.linkedIncomeDate,
    this.remainingAmount,
    this.totalUsed,
    this.percentageUsed,
    this.expenseCount,
    this.linkedExpenses,
    this.linkedIncomeDetails,
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
    String? linkedIncomeId,
    String? linkedIncomeDescription,
    DateTime? linkedIncomeDate,
    double? remainingAmount,
    double? totalUsed,
    double? percentageUsed,
    int? expenseCount,
    List<TransactionModel>? linkedExpenses,
    Map<String, dynamic>? linkedIncomeDetails,
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
      linkedIncomeId: linkedIncomeId ?? this.linkedIncomeId,
      linkedIncomeDescription: linkedIncomeDescription ?? this.linkedIncomeDescription,
      linkedIncomeDate: linkedIncomeDate ?? this.linkedIncomeDate,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      totalUsed: totalUsed ?? this.totalUsed,
      percentageUsed: percentageUsed ?? this.percentageUsed,
      expenseCount: expenseCount ?? this.expenseCount,
      linkedExpenses: linkedExpenses ?? this.linkedExpenses,
      linkedIncomeDetails: linkedIncomeDetails ?? this.linkedIncomeDetails,
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

    // The 'date' column represents a fixed business/calendar date (YYYY-MM-DD).
    // If 'date' is provided, keep it fixed to its exact calendar day and do NOT convert by timezone.
    DateTime txDate;
    final dateStr = json['date']?.toString();
    if (dateStr != null && dateStr.trim().isNotEmpty) {
      final str = dateStr.trim();
      final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(str);
      if (match != null) {
        txDate = DateTime(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      } else {
        final parsed = DateTime.tryParse(str) ?? createdDt;
        txDate = DateTime(parsed.year, parsed.month, parsed.day);
      }
    } else {
      // Fallback only if the 'date' column is missing from older records: convert createdAt to user timezone
      final parsed = CurrencyFormatter.toUserTimezone(createdStr ?? createdDt);
      txDate = DateTime(parsed.year, parsed.month, parsed.day);
    }

    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final isPending = json['isPendingSync'] == true || id.startsWith('temp_');

    String? linkedIncId;
    String? linkedIncDesc;
    DateTime? linkedIncDate;
    if (json['linkedIncomeId'] is Map) {
      linkedIncId = json['linkedIncomeId']['_id']?.toString() ?? json['linkedIncomeId']['id']?.toString();
      linkedIncDesc = json['linkedIncomeId']['description']?.toString();
      final incDateRaw = json['linkedIncomeId']['date'] ?? json['linkedIncomeId']['createdAt'];
      if (incDateRaw != null) {
        final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(incDateRaw.toString());
        if (match != null) {
          linkedIncDate = DateTime(
            int.parse(match.group(1)!),
            int.parse(match.group(2)!),
            int.parse(match.group(3)!),
          );
        }
      }
    } else if (json['linkedIncomeId'] != null) {
      linkedIncId = json['linkedIncomeId'].toString();
    }

    final remaining = (json['remainingAmount'] as num?)?.toDouble();
    final used = (json['totalUsed'] as num?)?.toDouble() ?? (json['totalLinkedExpense'] as num?)?.toDouble();
    final pctUsed = (json['percentageUsed'] as num?)?.toDouble();
    final expCount = (json['expenseCount'] as num?)?.toInt();

    List<TransactionModel>? linkedExps;
    if (json['linkedExpenses'] is List) {
      linkedExps = (json['linkedExpenses'] as List)
          .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    Map<String, dynamic>? linkedIncDetails;
    if (json['linkedIncomeDetails'] is Map) {
      linkedIncDetails = Map<String, dynamic>.from(json['linkedIncomeDetails']);
      if (linkedIncDate == null && linkedIncDetails['date'] != null) {
        final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(linkedIncDetails['date'].toString());
        if (match != null) {
          linkedIncDate = DateTime(
            int.parse(match.group(1)!),
            int.parse(match.group(2)!),
            int.parse(match.group(3)!),
          );
        }
      }
    }

    if (linkedIncDate == null && json['linkedIncomeDate'] != null) {
      final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(json['linkedIncomeDate'].toString());
      if (match != null) {
        linkedIncDate = DateTime(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      }
    }

    return TransactionModel(
      id: id,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type']?.toString() ?? 'Expense',
      description: json['description']?.toString() ?? '',
      category: cat,
      date: txDate,
      createdAt: createdDt,
      isPendingSync: isPending,
      linkedIncomeId: linkedIncId,
      linkedIncomeDescription: linkedIncDesc,
      linkedIncomeDate: linkedIncDate,
      remainingAmount: remaining,
      totalUsed: used,
      percentageUsed: pctUsed,
      expenseCount: expCount,
      linkedExpenses: linkedExps,
      linkedIncomeDetails: linkedIncDetails,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'type': type,
    'description': description,
    'category': category?.toJson(),
    'date': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T00:00:00.000Z',
    'createdAt': createdAt.toIso8601String(),
    'isPendingSync': isPendingSync,
    if (linkedIncomeId != null) 'linkedIncomeId': linkedIncomeId,
    if (linkedIncomeDescription != null) 'linkedIncomeDescription': linkedIncomeDescription,
    if (linkedIncomeDate != null)
      'linkedIncomeDate': '${linkedIncomeDate!.year.toString().padLeft(4, '0')}-${linkedIncomeDate!.month.toString().padLeft(2, '0')}-${linkedIncomeDate!.day.toString().padLeft(2, '0')}T00:00:00.000Z',
    if (remainingAmount != null) 'remainingAmount': remainingAmount,
    if (totalUsed != null) 'totalUsed': totalUsed,
    if (percentageUsed != null) 'percentageUsed': percentageUsed,
    if (expenseCount != null) 'expenseCount': expenseCount,
    if (linkedExpenses != null)
      'linkedExpenses': linkedExpenses!.map((e) => e.toJson()).toList(),
    if (linkedIncomeDetails != null) 'linkedIncomeDetails': linkedIncomeDetails,
  };
}
