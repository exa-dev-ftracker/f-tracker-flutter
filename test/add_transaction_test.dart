import 'package:flutter_test/flutter_test.dart';
import 'package:f_tracker_mobile/modules/transactions/controllers/add_transaction_controller.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AddTransactionController Tests', () {
    late AddTransactionController controller;

    setUp(() {
      Get.reset();
      controller = AddTransactionController();
    });

    tearDown(() {
      controller.onClose();
      Get.reset();
    });

    test('Initial values are set correctly', () {
      expect(controller.selectedType.value, 'Expense');
      expect(controller.rawAmount.value, '0');
      expect(controller.amountValue, 0.0);
      expect(controller.isIncome, isFalse);
      expect(controller.selectedCategoryId.value, isNull);
    });

    test('Numpad operations update rawAmount and amountValue correctly', () {
      controller.onNumpadPress('5');
      expect(controller.rawAmount.value, '5');
      expect(controller.amountValue, 5.0);

      controller.onNumpadPress('0');
      expect(controller.rawAmount.value, '50');
      expect(controller.amountValue, 50.0);

      controller.onNumpadPress('000');
      expect(controller.rawAmount.value, '50000');
      expect(controller.amountValue, 50000.0);

      controller.onNumpadPress('back');
      expect(controller.rawAmount.value, '5000');
      expect(controller.amountValue, 5000.0);

      controller.onNumpadPress('back');
      controller.onNumpadPress('back');
      controller.onNumpadPress('back');
      controller.onNumpadPress('back');
      expect(controller.rawAmount.value, '0');
      expect(controller.amountValue, 0.0);
    });

    test('Type switching and category toggling work reactively', () {
      controller.selectCategory('cat_1');
      expect(controller.selectedCategoryId.value, 'cat_1');

      // Toggling category deselects it
      controller.selectCategory('cat_1');
      expect(controller.selectedCategoryId.value, isNull);

      // Switching type clears selected category
      controller.selectCategory('cat_2');
      expect(controller.selectedCategoryId.value, 'cat_2');

      controller.setType('Income');
      expect(controller.selectedType.value, 'Income');
      expect(controller.isIncome, isTrue);
      expect(controller.selectedCategoryId.value, isNull);
    });
  });
}
