import 'package:get/get.dart';
import '../../../core/utils/app_haptics.dart';
import '../../analytics/controllers/analytics_controller.dart';
import '../../categories/controllers/category_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../transactions/controllers/transaction_controller.dart';

class NavigationController extends GetxController {
  final currentIndex = 0.obs;

  void changeTab(int index) {
    if (currentIndex.value != index) {
      AppHaptics.selection();
      currentIndex.value = index;
      refreshCurrentTab(index);
    }
  }

  void refreshCurrentTab(int index) {
    switch (index) {
      case 0:
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().fetchDashboard();
        }
        break;
      case 1:
        if (Get.isRegistered<TransactionController>()) {
          Get.find<TransactionController>().fetchTransactions();
        }
        break;
      case 2:
        if (Get.isRegistered<AnalyticsController>()) {
          Get.find<AnalyticsController>().fetchAnalytics();
        }
        break;
      case 3:
        if (Get.isRegistered<CategoryController>()) {
          Get.find<CategoryController>().fetchCategories();
        }
        break;
    }
  }
}
