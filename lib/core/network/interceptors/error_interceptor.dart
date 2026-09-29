import 'package:dio/dio.dart';
import '../../services/crash_reporter_service.dart';
import '../../services/logger_service.dart';
import '../../utils/app_error_handler.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    LoggerService.e('HTTP Error: ${err.type} -> ${err.message}', error: err, tag: 'Network');

    final message = AppErrorHandler.getMessage(err);

    // Record HTTP error to Loki / CrashReporter
    try {
      CrashReporterService.instance.recordHttpError(
        method: err.requestOptions.method,
        path: err.requestOptions.path,
        statusCode: err.response?.statusCode,
        errorMessage: message,
        responseBody: err.response?.data,
      );
    } catch (_) {}

    // Pass error to calling controller/repository for contextual handling
    return handler.next(err);
  }
}
