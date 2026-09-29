import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import '../services/logger_service.dart';
import '../services/snackbar_service.dart';

class AppErrorHandler {
  AppErrorHandler._();

  /// Determine if an error is network/offline related
  static bool isOfflineOrNetworkError(dynamic error) {
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return true;
      }
      if (error.error is SocketException || error.error is TimeoutException) {
        return true;
      }
    }
    final str = error.toString().toLowerCase();
    return str.contains('socketexception') ||
        str.contains('network is unreachable') ||
        str.contains('connection refused') ||
        str.contains('connection reset') ||
        str.contains('failed host lookup') ||
        str.contains('network error');
  }

  /// Extract clean human-readable error message from any error
  static String getMessage(dynamic error, {String fallback = 'An unexpected error occurred'}) {
    if (error == null) return fallback;

    if (error is DioException) {
      // 1. Check if backend returned structured error JSON in response body
      final responseData = error.response?.data;
      if (responseData is Map) {
        if (responseData['message'] != null && responseData['message'].toString().trim().isNotEmpty) {
          return responseData['message'].toString().trim();
        }
        if (responseData['error'] != null && responseData['error'].toString().trim().isNotEmpty) {
          return responseData['error'].toString().trim();
        }
        if (responseData['msg'] != null && responseData['msg'].toString().trim().isNotEmpty) {
          return responseData['msg'].toString().trim();
        }
        if (responseData['errors'] != null) {
          final errs = responseData['errors'];
          if (errs is List && errs.isNotEmpty) {
            return errs.map((e) => e.toString()).join(', ');
          }
          if (errs is Map && errs.isNotEmpty) {
            return errs.values.map((v) => v.toString()).join(', ');
          }
        }
      } else if (responseData is String && responseData.trim().isNotEmpty && !responseData.startsWith('<')) {
        return responseData.trim();
      }

      // 2. Map DioException types
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out. Please check your internet connection.';
        case DioExceptionType.connectionError:
          return 'Unable to connect to the server. Please check your network connection.';
        case DioExceptionType.cancel:
          return 'The request was cancelled.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 400) return 'Invalid request parameters.';
          if (statusCode == 401) return 'Session expired. Please log in again.';
          if (statusCode == 403) return 'You do not have permission to perform this action.';
          if (statusCode == 404) return 'Requested resource not found.';
          if (statusCode == 409) return 'Conflict with existing data.';
          if (statusCode == 422) return 'Validation failed. Please verify your input.';
          if (statusCode != null && statusCode >= 500) {
            return 'Server is temporarily unavailable. Please try again later.';
          }
          return 'Server returned an error (${statusCode ?? "Unknown"}).';
        default:
          if (isOfflineOrNetworkError(error)) {
            return 'No internet connection. Please check your network.';
          }
      }
    }

    if (error is SocketException) {
      return 'No internet connection. Please check your network.';
    }

    if (error is TimeoutException) {
      return 'The operation timed out. Please try again.';
    }

    if (error is PlatformException) {
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }

    // Clean up generic exception string prefixes
    var raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      raw = raw.substring('Exception: '.length).trim();
    } else if (raw.startsWith('Error: ')) {
      raw = raw.substring('Error: '.length).trim();
    }

    if (raw.isNotEmpty && !raw.startsWith('Instance of ')) {
      return raw;
    }

    return fallback;
  }

  /// Global centralized handler to log and optionally display snackbar error
  static void handle(
    dynamic error, {
    String? title,
    String? fallback,
    bool ignoreOffline = false,
    bool showSnackbar = true,
    String tag = 'ErrorHandler',
  }) {
    LoggerService.e('Error handled: $error', error: error, tag: tag);

    if (ignoreOffline && isOfflineOrNetworkError(error)) {
      // Suppress UI snackbar when offline fallback is intended
      return;
    }

    if (showSnackbar) {
      final message = getMessage(error, fallback: fallback ?? 'An unexpected error occurred');
      SnackbarService.error(message, title: title ?? 'Failed');
    }
  }
}
