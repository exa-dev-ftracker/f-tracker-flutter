import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  Future<AuthResponseModel> login(String email, String password) async {
    final response = await apiClient.post(ApiEndpoints.login, data: {
      'email': email,
      'password': password,
    });
    final data = response.data;
    final item = data is Map && data['data'] != null ? data['data'] : data;
    return AuthResponseModel.fromJson(Map<String, dynamic>.from(item));
  }

  Future<AuthResponseModel> register(String name, String email, String password) async {
    final response = await apiClient.post(ApiEndpoints.register, data: {
      'name': name,
      'email': email,
      'password': password,
    });
    final data = response.data;
    final item = data is Map && data['data'] != null ? data['data'] : data;
    return AuthResponseModel.fromJson(Map<String, dynamic>.from(item));
  }

  Future<UserModel> getProfile() async {
    final response = await apiClient.get(ApiEndpoints.userMe);
    final data = response.data;
    final item = data is Map && data['data'] != null ? data['data'] : data;
    return UserModel.fromJson(Map<String, dynamic>.from(item));
  }
}
