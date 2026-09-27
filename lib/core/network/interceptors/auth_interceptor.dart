import 'package:dio/dio.dart';
import '../../constants/api_endpoints.dart';
import '../../services/logger_service.dart';
import '../../services/storage_service.dart';

class AuthInterceptor extends QueuedInterceptor {
  final StorageService storageService;
  final Dio dio;

  AuthInterceptor({
    required this.storageService,
    required this.dio,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = storageService.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized -> Refresh Token Flow
    if (err.response?.statusCode == 401 && storageService.refreshToken != null) {
      try {
        LoggerService.i('Access token expired. Refreshing token...', tag: 'AuthInterceptor');
        final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
        final response = await refreshDio.post(
          ApiEndpoints.refresh,
          data: {'refresh_token': storageService.refreshToken},
        );

        if (response.statusCode == 200) {
          final resData = response.data;
          String? newAccessToken;
          if (resData is Map) {
            newAccessToken = resData['access_token'] ??
                resData['data']?['access_token'] ??
                resData['token'];
          }

          if (newAccessToken != null) {
            await storageService.saveAccessToken(newAccessToken);

            // Retry original request with newly acquired token
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';
            final clonedResponse = await dio.fetch(opts);
            return handler.resolve(clonedResponse);
          }
        }
      } catch (refreshErr) {
        LoggerService.w('Failed to refresh token: $refreshErr', tag: 'AuthInterceptor');
        await storageService.clearAuth();
      }
    }
    return handler.next(err);
  }
}
