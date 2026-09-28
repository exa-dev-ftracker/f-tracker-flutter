import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../constants/api_endpoints.dart';
import '../../services/logger_service.dart';
import '../../services/snackbar_service.dart';
import '../../services/storage_service.dart';
import '../../../routes/app_routes.dart';

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
    // 1. Skip auth-specific endpoints to prevent infinite refresh loops
    final path = err.requestOptions.path;
    final isAuthEndpoint = path.contains('/auth/v1/');
    if (isAuthEndpoint) {
      return handler.next(err);
    }

    // 2. Only handle 401 Unauthorized errors
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final currentRefreshToken = storageService.refreshToken;
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      return handler.next(err);
    }

    final requestToken = _extractBearerToken(err.requestOptions.headers['Authorization']);
    final currentAccessToken = storageService.accessToken;

    // 3. Concurrency check: If another concurrent request already refreshed the access token,
    // immediately retry this request with the newly updated token without calling refresh again!
    if (currentAccessToken != null &&
        currentAccessToken.isNotEmpty &&
        requestToken != null &&
        requestToken != currentAccessToken) {
      try {
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $currentAccessToken';
        final clonedResponse = await dio.fetch(opts);
        return handler.resolve(clonedResponse);
      } catch (retryErr) {
        if (retryErr is DioException) {
          return handler.next(retryErr);
        }
        return handler.next(err);
      }
    }

    // 4. Perform refresh token request
    String? newAccessToken;
    try {
      LoggerService.i('Access token expired. Refreshing token...', tag: 'AuthInterceptor');
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await refreshDio.post(
        ApiEndpoints.refresh,
        data: {
          'refreshToken': currentRefreshToken,
          'refresh_token': currentRefreshToken,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $currentRefreshToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final resData = response.data;
        Map<String, dynamic>? dataMap;
        if (resData is Map) {
          if (resData['data'] is Map) {
            dataMap = Map<String, dynamic>.from(resData['data']);
          } else {
            dataMap = Map<String, dynamic>.from(resData);
          }
        }

        newAccessToken = dataMap?['accessToken']?.toString() ??
            dataMap?['access_token']?.toString() ??
            dataMap?['token']?.toString();

        final newRefreshToken = dataMap?['refreshToken']?.toString() ??
            dataMap?['refresh_token']?.toString();

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await storageService.saveAccessToken(newAccessToken);
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await storageService.saveRefreshToken(newRefreshToken);
          }
          LoggerService.i('Token refreshed successfully.', tag: 'AuthInterceptor');
        }
      }
    } catch (refreshErr) {
      LoggerService.w('Failed to refresh token: $refreshErr', tag: 'AuthInterceptor');
      await storageService.clearAuth();
      if (Get.context != null && Get.currentRoute != Routes.login) {
        Get.offAllNamed(Routes.login);
        SnackbarService.warning('Your session has expired. Please log in again.');
      }
      return handler.next(err);
    }

    // 5. If refreshed successfully, retry original request with new token
    if (newAccessToken != null && newAccessToken.isNotEmpty) {
      try {
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccessToken';
        final clonedResponse = await dio.fetch(opts);
        return handler.resolve(clonedResponse);
      } catch (retryErr) {
        if (retryErr is DioException) {
          return handler.next(retryErr);
        }
        return handler.next(err);
      }
    } else {
      await storageService.clearAuth();
      if (Get.context != null && Get.currentRoute != Routes.login) {
        Get.offAllNamed(Routes.login);
        SnackbarService.warning('Your session has expired. Please log in again.');
      }
      return handler.next(err);
    }
  }

  String? _extractBearerToken(dynamic header) {
    if (header == null) return null;
    final str = header.toString();
    if (str.startsWith('Bearer ')) {
      return str.substring(7).trim();
    }
    return str.trim();
  }
}
