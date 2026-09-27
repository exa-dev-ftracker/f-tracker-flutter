import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../constants/app_constants.dart';

class StorageService extends GetxService {
  late final GetStorage _box;

  Future<StorageService> init() async {
    await GetStorage.init();
    _box = GetStorage();
    return this;
  }

  String? get accessToken => _box.read<String>(AppConstants.keyAccessToken);
  String? get refreshToken => _box.read<String>(AppConstants.keyRefreshToken);
  bool get isLoggedIn => accessToken != null && accessToken!.isNotEmpty;

  Future<void> saveAccessToken(String token) =>
      _box.write(AppConstants.keyAccessToken, token);

  Future<void> saveRefreshToken(String token) =>
      _box.write(AppConstants.keyRefreshToken, token);

  Map<String, dynamic>? get user =>
      _box.read<Map<String, dynamic>>(AppConstants.keyUserData);

  Future<void> saveUser(Map<String, dynamic> userData) =>
      _box.write(AppConstants.keyUserData, userData);

  bool get isBiometricEnabled =>
      _box.read<bool>(AppConstants.keyBiometricEnabled) ?? false;

  Future<void> setBiometricEnabled(bool enabled) =>
      _box.write(AppConstants.keyBiometricEnabled, enabled);

  List<dynamic> get cachedTransactions =>
      _box.read<List<dynamic>>(AppConstants.keyCachedTransactions) ?? [];

  Future<void> saveCachedTransactions(List<dynamic> list) =>
      _box.write(AppConstants.keyCachedTransactions, list);

  List<dynamic> get cachedCategories =>
      _box.read<List<dynamic>>(AppConstants.keyCachedCategories) ?? [];

  Future<void> saveCachedCategories(List<dynamic> list) =>
      _box.write(AppConstants.keyCachedCategories, list);

  Map<String, dynamic>? get cachedDashboard =>
      _box.read<Map<String, dynamic>>(AppConstants.keyCachedDashboard);

  Future<void> saveCachedDashboard(Map<String, dynamic> data) =>
      _box.write(AppConstants.keyCachedDashboard, data);

  List<dynamic> get syncQueue =>
      _box.read<List<dynamic>>(AppConstants.keySyncQueue) ?? [];

  Future<void> saveSyncQueue(List<dynamic> list) =>
      _box.write(AppConstants.keySyncQueue, list);

  DateTime? get lastSyncedAt {
    final str = _box.read<String>(AppConstants.keyLastSyncedAt);
    return str != null ? DateTime.tryParse(str) : null;
  }

  Future<void> saveLastSyncedAt(DateTime dt) =>
      _box.write(AppConstants.keyLastSyncedAt, dt.toIso8601String());

  Future<void> clearAuth() async {
    await _box.remove(AppConstants.keyAccessToken);
    await _box.remove(AppConstants.keyRefreshToken);
    await _box.remove(AppConstants.keyUserData);
  }
}
