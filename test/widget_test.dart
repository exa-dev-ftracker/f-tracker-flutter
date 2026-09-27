import 'package:flutter_test/flutter_test.dart';
import 'package:f_tracker_mobile/core/constants/app_constants.dart';

void main() {
  test('AppConstants contains correct defaults and storage keys', () {
    expect(AppConstants.appName, 'F-Tracker');
    expect(AppConstants.defaultCurrency, 'IDR');
    expect(AppConstants.keySyncQueue, 'ftracker_sync_queue');
    expect(AppConstants.keyLastSyncedAt, 'ftracker_last_synced_at');
    expect(AppConstants.keyCachedTransactions, 'ftracker_cached_transactions');
  });
}
