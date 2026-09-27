import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';
import 'snackbar_service.dart';

class PermissionService {
  PermissionService._();

  static Future<bool> requestCamera({String reason = 'scanning receipts'}) async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      _showSettingsDialog(title: 'Camera Permission', message: 'Camera permission is required for $reason.');
      return false;
    }

    final result = await Permission.camera.request();
    if (!result.isGranted) {
      SnackbarService.warning('Camera permission is required for $reason.');
      return false;
    }
    return true;
  }

  static Future<bool> requestPhotos({String reason = 'uploading receipts'}) async {
    final status = await Permission.photos.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      _showSettingsDialog(title: 'Photo Gallery Permission', message: 'Gallery permission is required for $reason.');
      return false;
    }

    final result = await Permission.photos.request();
    if (!result.isGranted) {
      SnackbarService.warning('Photo permission is required for $reason.');
      return false;
    }
    return true;
  }

  static void _showSettingsDialog({required String title, required String message}) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
