import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../services/storage_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

class ApiClient {
  late final Dio dio;
  final StorageService storageService;

  ApiClient({required this.storageService}) {
    dio = Dio(
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

    dio.interceptors.addAll([
      AuthInterceptor(storageService: storageService, dio: dio),
      ErrorInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) {
    return dio.get(path, queryParameters: queryParameters, options: options, cancelToken: cancelToken);
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) {
    return dio.post(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken);
  }

  Future<Response> put(String path, {dynamic data, Options? options, CancelToken? cancelToken}) {
    return dio.put(path, data: data, options: options, cancelToken: cancelToken);
  }

  Future<Response> patch(String path, {dynamic data, Options? options, CancelToken? cancelToken}) {
    return dio.patch(path, data: data, options: options, cancelToken: cancelToken);
  }

  Future<Response> delete(String path, {dynamic data, Options? options, CancelToken? cancelToken}) {
    return dio.delete(path, data: data, options: options, cancelToken: cancelToken);
  }
}
