import 'package:flutter_test/flutter_test.dart';
import 'package:f_tracker_mobile/core/services/sync_service.dart';
import 'package:f_tracker_mobile/modules/transactions/models/transaction_model.dart';
import 'package:f_tracker_mobile/modules/categories/models/category_model.dart';

void main() {
  group('Offline Sync & Models Test', () {
    test('TransactionModel handles offline temporary ID and isPendingSync', () {
      final tempTx = TransactionModel(
        id: 'temp_1727400000000',
        amount: 50000,
        type: 'Expense',
        description: 'Beli Kopi Offline',
        createdAt: DateTime.now(),
        isPendingSync: true,
      );

      expect(tempTx.isPendingSync, isTrue);
      expect(tempTx.isIncome, isFalse);

      final json = tempTx.toJson();
      expect(json['isPendingSync'], isTrue);
      expect(json['id'], startsWith('temp_'));

      final restored = TransactionModel.fromJson(json);
      expect(restored.isPendingSync, isTrue);
      expect(restored.description, 'Beli Kopi Offline');
    });

    test('SyncTask serializes and deserializes properly', () {
      final task = SyncTask(
        id: 'uuid-1234-5678',
        action: 'CREATE_TRANSACTION',
        payload: {
          'client_id': 'temp_999',
          'amount': 25000,
          'type': 'Expense',
          'description': 'Makan Siang',
        },
        createdAt: DateTime.now(),
      );

      final json = task.toJson();
      expect(json['id'], 'uuid-1234-5678');
      expect(json['action'], 'CREATE_TRANSACTION');
      expect(json['payload']['client_id'], 'temp_999');

      final fromJson = SyncTask.fromJson(json);
      expect(fromJson.id, task.id);
      expect(fromJson.action, 'CREATE_TRANSACTION');
      expect(fromJson.payload['amount'], 25000);
    });

    test('CategoryModel retains category attributes', () {
      const cat = CategoryModel(
        id: 'cat_1',
        name: 'Makanan',
        type: 'expense',
        color: '#EF4444',
        icon: 'utensils',
      );

      final json = cat.toJson();
      final restored = CategoryModel.fromJson(json);
      expect(restored.name, 'Makanan');
      expect(restored.color, '#EF4444');
    });
  });
}
