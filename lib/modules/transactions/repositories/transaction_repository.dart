import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/transaction_model.dart';

class PaginatedTransactionsResponse {
  final List<TransactionModel> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;
  final String? nextCursor;

  PaginatedTransactionsResponse({
    required this.items,
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 1,
    this.hasMore = false,
    this.nextCursor,
  });
}

class TransactionRepository {
  final ApiClient apiClient;

  TransactionRepository({required this.apiClient});

  Future<PaginatedTransactionsResponse> getTransactionsPaginated({
    String? view,
    String? type,
    String? category,
    String? search,
    String? sort,
    int? year,
    int? month,
    int page = 1,
    int limit = 20,
    int? offset,
    String? cursor,
  }) async {
    final query = <String, dynamic>{};
    if (view != null && view.isNotEmpty) query['view'] = view;
    if (type != null && type.isNotEmpty) query['type'] = type;
    if (category != null && category.isNotEmpty && category != 'all') query['category'] = category;
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (sort != null && sort.isNotEmpty) query['sort'] = sort;
    if (year != null) query['year'] = year.toString();
    if (month != null) query['month'] = month.toString();
    if (offset != null) {
      query['offset'] = offset.toString();
    } else {
      query['page'] = page.toString();
    }
    query['limit'] = limit.toString();
    if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;

    final response = await apiClient.get(
      ApiEndpoints.transactions,
      queryParameters: query,
    );

    final data = response.data;
    List list = [];
    String? nextCursor;
    bool hasMore = false;
    int respPage = page;
    int respLimit = limit;
    int respTotal = 0;
    int respTotalPages = 1;

    if (data is Map && data['data'] != null) {
      final d = data['data'];
      if (d is Map) {
        if (d['items'] is List) {
          list = d['items'];
        }
        if (d['pagination'] is Map) {
          hasMore = d['pagination']['hasMore'] == true;
          respPage = (d['pagination']['page'] as num?)?.toInt() ?? page;
          respLimit = (d['pagination']['limit'] as num?)?.toInt() ?? limit;
          respTotal = (d['pagination']['total'] as num?)?.toInt() ?? 0;
          respTotalPages = (d['pagination']['totalPages'] as num?)?.toInt() ?? 1;
          nextCursor = d['pagination']['nextCursor'];
        } else {
          hasMore = list.length >= limit;
        }
      } else if (d is List) {
        list = d;
        hasMore = list.length >= limit;
      }
    } else if (data is List) {
      list = data;
      hasMore = list.length >= limit;
    }

    final items = list
        .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return PaginatedTransactionsResponse(
      items: items,
      page: respPage,
      limit: respLimit,
      total: respTotal,
      totalPages: respTotalPages,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  Future<List<TransactionModel>> getTransactions({
    String? view,
    String? type,
    String? category,
    String? search,
    String? sort,
    int? year,
    int? month,
    int page = 1,
    int? limit,
    int? offset,
    String? cursor,
  }) async {
    final res = await getTransactionsPaginated(
      view: view,
      type: type,
      category: category,
      search: search,
      sort: sort,
      year: year,
      month: month,
      page: page,
      limit: limit ?? 20,
      offset: offset,
      cursor: cursor,
    );
    return res.items;
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

  Future<Map<String, dynamic>> getSummary({
    String? view,
    String? type,
    String? category,
    String? search,
    int? year,
    int? month,
  }) async {
    final query = <String, dynamic>{};
    if (view != null && view.isNotEmpty) query['view'] = view;
    if (type != null && type.isNotEmpty) query['type'] = type;
    if (category != null && category.isNotEmpty && category != 'all') query['category'] = category;
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (year != null) query['year'] = year.toString();
    if (month != null) query['month'] = month.toString();

    final response = await apiClient.get(
      ApiEndpoints.transactionSummary,
      queryParameters: query,
    );
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data']);
    }
    return {};
  }

  Future<Map<String, dynamic>> getAvailableIncomes({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final response = await apiClient.get(
      ApiEndpoints.availableIncomes,
      queryParameters: query,
    );
    final data = response.data;
    List list = [];
    bool hasMore = false;
    int total = 0;

    if (data is Map && data['data'] != null) {
      final inner = data['data'];
      if (inner is Map) {
        if (inner['incomes'] is List) {
          list = inner['incomes'];
        }
        if (inner['pagination'] is Map) {
          hasMore = inner['pagination']['hasMore'] == true;
          total = (inner['pagination']['total'] as num?)?.toInt() ?? 0;
        }
      } else if (inner is List) {
        list = inner;
      }
    } else if (data is List) {
      list = data;
    }

    final models = list
        .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return {
      'incomes': models,
      'hasMore': hasMore,
      'total': total,
    };
  }
}
