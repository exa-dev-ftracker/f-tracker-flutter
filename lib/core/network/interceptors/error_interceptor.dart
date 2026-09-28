import 'package:dio/dio.dart';
import '../../services/crash_reporter_service.dart';
import '../../services/logger_service.dart';
import '../../services/snackbar_service.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    LoggerService.e('HTTP Error: ${err.type} -> ${err.message}', error: err, tag: 'Network');

    String message = 'Terjadi kesalahan pada jaringan';
    if (err.response != null && err.response?.data is Map) {
      final data = err.response!.data as Map;
      message = data['message'] ?? data['error'] ?? message;
    } else if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      message = 'Koneksi ke server timeout. Silakan periksa jaringan Anda.';
    } else if (err.type == DioExceptionType.connectionError) {
      message = 'Tidak dapat terhubung ke server backend F-Tracker.';
    }

    // Record HTTP error to Loki
    try {
      CrashReporterService.instance.recordHttpError(
        method: err.requestOptions.method,
        path: err.requestOptions.path,
        statusCode: err.response?.statusCode,
        errorMessage: message,
        responseBody: err.response?.data,
      );
    } catch (_) {}

    // Do not show snackbar for 401 or if request was marked as silent
    final isSilent = err.requestOptions.extra['silent'] == true;
    if (err.response?.statusCode != 401 && !isSilent) {
      SnackbarService.error(message);
    }

    return handler.next(err);
  }
}
