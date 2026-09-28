import 'package:flutter_test/flutter_test.dart';
import 'package:f_tracker_mobile/modules/auth/models/auth_response_model.dart';
import 'package:f_tracker_mobile/core/constants/api_endpoints.dart';

void main() {
  group('Auth Model & Refresh Tests', () {
    test('AuthResponseModel parses camelCase tokens from backend response', () {
      final json = {
        'accessToken': 'jwt_access_123',
        'refreshToken': 'jwt_refresh_456',
      };

      final model = AuthResponseModel.fromJson(json);
      expect(model.accessToken, 'jwt_access_123');
      expect(model.refreshToken, 'jwt_refresh_456');
    });

    test('AuthResponseModel parses snake_case tokens fallback', () {
      final json = {
        'access_token': 'jwt_access_snake',
        'refresh_token': 'jwt_refresh_snake',
      };

      final model = AuthResponseModel.fromJson(json);
      expect(model.accessToken, 'jwt_access_snake');
      expect(model.refreshToken, 'jwt_refresh_snake');
    });

    test('ApiEndpoints.refresh matches backend auth v1 route', () {
      expect(ApiEndpoints.refresh, '/auth/v1/refresh');
      expect(ApiEndpoints.login, '/auth/v1/login');
      expect(ApiEndpoints.register, '/auth/v1/register');
    });
  });
}
