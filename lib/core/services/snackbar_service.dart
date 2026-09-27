import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';

class SnackbarService {
  SnackbarService._();

  static void success(String message, {String title = 'Success'}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.95),
      colorText: AppColors.textPrimary,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      duration: const Duration(seconds: 3),
      borderColor: AppColors.success.withValues(alpha: 0.4),
      borderWidth: 1,
      icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
    );
  }

  static void error(String message, {String title = 'Failed'}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.95),
      colorText: AppColors.textPrimary,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      duration: const Duration(seconds: 4),
      borderColor: AppColors.error.withValues(alpha: 0.4),
      borderWidth: 1,
      icon: const Icon(Icons.error_outline_rounded, color: AppColors.error),
    );
  }

  static void warning(String message, {String title = 'Warning'}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.95),
      colorText: AppColors.textPrimary,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      duration: const Duration(seconds: 3),
      borderColor: AppColors.warning.withValues(alpha: 0.4),
      borderWidth: 1,
      icon: const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
    );
  }

  static void info(String message, {String title = 'Information'}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.95),
      colorText: AppColors.textPrimary,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      duration: const Duration(seconds: 3),
      borderColor: AppColors.secondary.withValues(alpha: 0.4),
      borderWidth: 1,
      icon: const Icon(Icons.info_outline_rounded, color: AppColors.secondary),
    );
  }
}
