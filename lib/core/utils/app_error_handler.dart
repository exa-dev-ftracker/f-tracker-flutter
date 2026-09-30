import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../services/logger_service.dart';
import '../services/snackbar_service.dart';

class AppErrorHandler {
  AppErrorHandler._();

  /// Determine if an error was caused by the user cancelling an action (e.g. Apple or Google Sign-In sheet dismissed)
  static bool isUserCancelled(dynamic error) {
    if (error == null) return false;

    if (error is SignInWithAppleAuthorizationException) {
      if (error.code == AuthorizationErrorCode.canceled) return true;
    }

    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      final msg = (error.message ?? '').toLowerCase();
      if (code == '1001' ||
          code == 'sign_in_canceled' ||
          code == 'canceled' ||
          code == 'cancelled') {
        return true;
      }
      if (msg.contains('canceled') ||
          msg.contains('cancelled') ||
          msg.contains('user canceled') ||
          msg.contains('the user canceled the authorization attempt')) {
        return true;
      }
    }

    final str = error.toString().toLowerCase();
    return str.contains('authorizationerrorcode.canceled') ||
        str.contains('sign_in_canceled') ||
        str.contains('user canceled') ||
        str.contains('user cancelled') ||
        str.contains('the user canceled the authorization attempt') ||
        str.contains('com.apple.authenticationservices.authorizationerror error 1001');
  }

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

    if (isUserCancelled(error)) {
      return 'Operation was cancelled.';
    }

    // 1. Apple Sign-In specific exceptions
    if (error is SignInWithAppleAuthorizationException) {
      switch (error.code) {
        case AuthorizationErrorCode.canceled:
          return 'Sign-in was cancelled.';
        case AuthorizationErrorCode.failed:
          return 'Apple authentication failed. Please try again.';
        case AuthorizationErrorCode.invalidResponse:
          return 'Received invalid response from Apple. Please try again.';
        case AuthorizationErrorCode.notHandled:
          return 'Apple authorization request was not handled.';
        case AuthorizationErrorCode.unknown:
        default:
          final cleanMsg = error.message.trim();
          return cleanMsg.isNotEmpty && !cleanMsg.contains('AuthorizationError')
              ? cleanMsg
              : 'Failed to authenticate with Apple. Please try again.';
      }
    }

    if (error is SignInWithAppleCredentialsException) {
      final cleanMsg = error.message.trim();
      return cleanMsg.isNotEmpty ? cleanMsg : 'Unable to verify Apple credentials.';
    }

    // 2. Dio / HTTP errors
    if (error is DioException) {
      // Check if backend returned structured error JSON in response body
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

      // Map DioException types
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
      if (error.code == '1001') {
        return 'Sign-in was cancelled.';
      }
      final msg = error.message?.trim();
      if (msg != null &&
          msg.isNotEmpty &&
          !msg.contains('AuthenticationServices') &&
          !msg.contains('AuthorizationError')) {
        return msg;
      }
    }

    // Clean up generic exception string prefixes
    var raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      raw = raw.substring('Exception: '.length).trim();
    } else if (raw.startsWith('Error: ')) {
      raw = raw.substring('Error: '.length).trim();
    }

    // Sanitize raw syntax signatures so code/class dumps are never shown to user
    if (raw.contains('AuthorizationErrorCode.canceled') || raw.contains('user canceled')) {
      return 'Operation was cancelled.';
    }
    if (raw.contains('com.apple.AuthenticationServices') || raw.contains('AuthorizationError')) {
      return 'Apple authentication was cancelled or interrupted.';
    }
    if (RegExp(r'^[A-Za-z0-9_]+Exception\(').hasMatch(raw) ||
        RegExp(r'^[A-Za-z0-9_]+Error\(').hasMatch(raw) ||
        raw.startsWith('Instance of ') ||
        raw.contains('StackTrace') ||
        raw.contains('closure')) {
      return fallback;
    }

    if (raw.isNotEmpty) {
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
    // If the user deliberately dismissed/cancelled the action, suppress error banner
    if (isUserCancelled(error)) {
      LoggerService.d('Action cancelled by user, suppressing error banner: $error', tag: tag);
      return;
    }

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
