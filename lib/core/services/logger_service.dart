import 'package:logger/logger.dart';

class LoggerService {
  LoggerService._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  static void d(String message, {String? tag}) =>
      _logger.d('${tag != null ? "[$tag] " : ""}$message');

  static void i(String message, {String? tag}) =>
      _logger.i('${tag != null ? "[$tag] " : ""}$message');

  static void w(String message, {String? tag}) =>
      _logger.w('${tag != null ? "[$tag] " : ""}$message');

  static void e(String message, {dynamic error, StackTrace? stackTrace, String? tag}) =>
      _logger.e('${tag != null ? "[$tag] " : ""}$message', error: error, stackTrace: stackTrace);
}
