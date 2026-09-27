import 'package:get/get.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/utils/app_haptics.dart';
import '../models/analytics_model.dart';
import '../repositories/analytics_repository.dart';

class AnalyticsController extends GetxController {
  final AnalyticsRepository repository;

  AnalyticsController({required this.repository});

  final analyticsData = Rxn<AnalyticsData>();
  final isLoading = false.obs;
  final selectedView = 'Month'.obs;
  final activeTab = 'expense'.obs; // 'expense' or 'income'
  final touchedPieIndex = (-1).obs;

  @override
  void onInit() {
    super.onInit();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    try {
      isLoading.value = true;
      final result = await repository.getAnalytics(view: selectedView.value);
      analyticsData.value = result;
    } catch (e) {
      LoggerService.e('Failed to fetch analytics: $e', tag: 'AnalyticsController');
    } finally {
      isLoading.value = false;
    }
  }

  void setView(String view) {
    AppHaptics.selection();
    selectedView.value = view;
    fetchAnalytics();
  }

  void setActiveTab(String tab) {
    AppHaptics.light();
    activeTab.value = tab;
    touchedPieIndex.value = -1;
  }
}
