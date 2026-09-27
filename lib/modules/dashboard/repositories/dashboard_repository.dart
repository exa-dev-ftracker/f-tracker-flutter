import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  final ApiClient apiClient;

  DashboardRepository({required this.apiClient});

  Future<DashboardData> getDashboard({String view = 'Month'}) async {
    final response = await apiClient.get(
      ApiEndpoints.dashboard,
      queryParameters: {'view': view},
    );

    final data = response.data;
    final item = data is Map && data['data'] != null ? data['data'] : data;
    return DashboardData.fromJson(Map<String, dynamic>.from(item));
  }
}
