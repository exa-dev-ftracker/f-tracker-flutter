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

  Future<AuthResponseModel> loginWithGoogle({String? code, String? credential}) async {
    final payload = <String, dynamic>{};
    if (code != null) payload['code'] = code;
    if (credential != null) payload['credential'] = credential;

    final response = await apiClient.post(ApiEndpoints.googleAuth, data: payload);
    final data = response.data;
    final item = data is Map && data['data'] != null ? data['data'] : data;
    return AuthResponseModel.fromJson(Map<String, dynamic>.from(item));
  }

  Future<AuthResponseModel> loginWithApple({
    required String code,
    String? identityToken,
    String? userIdentifier,
    String? email,
    String? name,
  }) async {
    final response = await apiClient.post(ApiEndpoints.appleAuth, data: {
      'code': code,
      'identityToken': ?identityToken,
      'userIdentifier': ?userIdentifier,
      'email': ?email,
      'name': ?name,
    });
    final data = response.data;
    final item = data is Map && data['data'] != null ? data['data'] : data;
    return AuthResponseModel.fromJson(Map<String, dynamic>.from(item));
  }
}
