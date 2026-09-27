import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final ApiClient apiClient;

  CategoryRepository({required this.apiClient});

  Future<List<CategoryModel>> getCategories() async {
    final response = await apiClient.get(ApiEndpoints.categories);
    final data = response.data;

    List list = [];
    if (data is Map && data['data'] is List) {
      list = data['data'];
    } else if (data is List) {
      list = data;
    }

    return list
        .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<CategoryModel> createCategory(Map<String, dynamic> payload) async {
    final response = await apiClient.post(ApiEndpoints.categories, data: payload);
    final data = response.data;
    final item = data is Map && data['data'] != null ? data['data'] : data;
    return CategoryModel.fromJson(Map<String, dynamic>.from(item));
  }

  Future<CategoryModel> updateCategory(String id, Map<String, dynamic> payload) async {
    final response = await apiClient.put(ApiEndpoints.categoryDetail(id), data: payload);
    final data = response.data;
    final item = data is Map && data['data'] != null ? data['data'] : data;
    return CategoryModel.fromJson(Map<String, dynamic>.from(item));
  }

  Future<bool> deleteCategory(String id) async {
    final response = await apiClient.delete(ApiEndpoints.categoryDetail(id));
    return response.statusCode == 200;
  }
}
