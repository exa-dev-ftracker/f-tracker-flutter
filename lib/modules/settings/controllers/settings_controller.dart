import 'package:get/get.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../routes/app_routes.dart';

class SettingsController extends GetxController {
  final ApiClient apiClient;
  final StorageService storageService;

  SettingsController({
    required this.apiClient,
    required this.storageService,
  });

  final isBiometricEnabled = false.obs;
  final isLoading = false.obs;
  final currentTimezone = 'UTC'.obs;

  SyncService get syncService => Get.find<SyncService>();
  Map<String, dynamic>? get user => storageService.user;

  int get localTransactionCount => storageService.cachedTransactions.length;

  @override
  void onInit() {
    super.onInit();
    isBiometricEnabled.value = storageService.isBiometricEnabled;
    currentTimezone.value = user?['timezone']?.toString() ?? 'UTC';
    _fetchUserSettings();
  }

  Future<void> _fetchUserSettings() async {
    try {
      final res = await apiClient.get(ApiEndpoints.userSettings);
      final data = res.data;
      if (data != null && data['data'] != null && data['data']['timezone'] != null) {
        currentTimezone.value = data['data']['timezone'].toString();
      }
    } catch (_) {}
  }

  Future<void> updateTimezone(String newTimezone) async {
    try {
      AppHaptics.selection();
      isLoading.value = true;
      await apiClient.patch(
        ApiEndpoints.userTimezone,
        data: {'timezone': newTimezone},
      );
      currentTimezone.value = newTimezone;

      // Update storage user if exists
      if (storageService.user != null) {
        final updatedUser = Map<String, dynamic>.from(storageService.user!);
        updatedUser['timezone'] = newTimezone;
        await storageService.saveUser(updatedUser);
      }

      AppHaptics.success();
      SnackbarService.success('Timezone updated to $newTimezone');
    } catch (e) {
      LoggerService.e('Failed to update timezone: $e', tag: 'SettingsController');
      SnackbarService.error('Failed to update timezone');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> triggerManualSync() async {
    AppHaptics.medium();
    await syncService.syncNow();
  }

  void toggleBiometric(bool val) {
    AppHaptics.selection();
    isBiometricEnabled.value = val;
    storageService.setBiometricEnabled(val);
    SnackbarService.success(val ? 'Biometric lock enabled' : 'Biometric lock disabled');
  }

  Future<void> logout() async {
    try {
      AppHaptics.heavy();
      if (syncService.isOnline.value) {
        await apiClient.post(ApiEndpoints.logout);
      }
    } catch (e) {
      LoggerService.w('Logout API error: $e', tag: 'SettingsController');
    } finally {
      // Clear auth tokens and user profile
      await storageService.clearAuth();
      // Clear cached data and sync queue so subsequent logins start completely clean
      await storageService.saveCachedTransactions([]);
      await storageService.saveCachedCategories([]);
      await storageService.saveCachedDashboard({});
      await storageService.saveSyncQueue([]);
      syncService.pendingCount.value = 0;

      Get.offAllNamed(Routes.login);
      SnackbarService.success('Successfully logged out');
    }
  }

  Future<bool> deleteAccount() async {
    if (!syncService.isOnline.value) {
      SnackbarService.error(
        'Cannot delete account while offline. Please connect to the internet to delete your account.',
        title: 'Offline',
      );
      return false;
    }

    try {
      AppHaptics.heavy();
      isLoading.value = true;
      final response = await apiClient.delete(ApiEndpoints.deleteAccount);
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Clear all local auth, caches, and sync queue
        await storageService.clearAuth();
        await storageService.saveCachedTransactions([]);
        await storageService.saveCachedCategories([]);
        await storageService.saveCachedDashboard({});
        await storageService.saveSyncQueue([]);
        syncService.pendingCount.value = 0;

        Get.offAllNamed(Routes.login);
        SnackbarService.success('Your account and all associated data have been permanently deleted.');
        return true;
      } else {
        SnackbarService.error('Failed to delete account. Please try again.');
        return false;
      }
    } catch (e) {
      LoggerService.e('Delete account API error: $e', tag: 'SettingsController');
      AppErrorHandler.handle(e, fallback: 'Failed to delete account. Please try again.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
