class AppConstants {
  AppConstants._();

  static const String appName = 'F-Tracker';
  static const String appTagline = 'Smart Financial & Expense Tracker';

  // Storage Keys
  static const String keyAccessToken = 'ftracker_access_token';
  static const String keyRefreshToken = 'ftracker_refresh_token';
  static const String keyUserData = 'ftracker_user_data';
  static const String keySelectedCurrency = 'ftracker_currency';
  static const String keyBiometricEnabled = 'ftracker_biometric_enabled';
  static const String keyCachedTransactions = 'ftracker_cached_transactions';
  static const String keyCachedCategories = 'ftracker_cached_categories';
  static const String keyCachedDashboard = 'ftracker_cached_dashboard';
  static const String keySyncQueue = 'ftracker_sync_queue';
  static const String keyLastSyncedAt = 'ftracker_last_synced_at';

  // Defaults
  static const String defaultCurrency = 'IDR';
  static const String defaultLocale = 'id_ID';
}
