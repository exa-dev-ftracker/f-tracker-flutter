import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/analytics_model.dart';

class AnalyticsRepository {
  final ApiClient apiClient;

  AnalyticsRepository({required this.apiClient});

  Future<AnalyticsData> getAnalytics({String view = 'Month'}) async {
    final response = await apiClient.get(
      ApiEndpoints.analytics,
      queryParameters: {'view': view},
    );

    final data = response.data;
    final item = data is Map && data['data'] != null ? data['data'] : data;
    return AnalyticsData.fromJson(Map<String, dynamic>.from(item));
  }
}
