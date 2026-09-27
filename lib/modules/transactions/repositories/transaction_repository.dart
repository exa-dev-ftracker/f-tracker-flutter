import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final ApiClient apiClient;

  TransactionRepository({required this.apiClient});

  Future<List<TransactionModel>> getTransactions({
    String? view,
    String? type,
    String? category,
    String? search,
  }) async {
    final query = <String, dynamic>{};
    if (view != null && view.isNotEmpty) query['view'] = view;
    if (type != null && type.isNotEmpty) query['type'] = type;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await apiClient.get(
      ApiEndpoints.transactions,
      queryParameters: query,
    );

    final data = response.data;
    List list = [];
    if (data is Map && data['data'] is List) {
      list = data['data'];
    } else if (data is List) {
      list = data;
    }

    return list
        .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<TransactionModel> createTransaction(Map<String, dynamic> payload) async {
    final response = await apiClient.post(ApiEndpoints.transactions, data: payload);
    final data = response.data;
    final item = data is Map && data['data'] != null ? data['data'] : data;
    return TransactionModel.fromJson(Map<String, dynamic>.from(item));
  }

  Future<TransactionModel> updateTransaction(String id, Map<String, dynamic> payload) async {
    final response = await apiClient.put(ApiEndpoints.transactionDetail(id), data: payload);
    final data = response.data;
    final item = data is Map && data['data'] != null ? data['data'] : data;
    return TransactionModel.fromJson(Map<String, dynamic>.from(item));
  }

  Future<bool> deleteTransaction(String id) async {
    final response = await apiClient.delete(ApiEndpoints.transactionDetail(id));
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> getSummary() async {
    final response = await apiClient.get(ApiEndpoints.transactionSummary);
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data']);
    }
    return {};
  }
}
