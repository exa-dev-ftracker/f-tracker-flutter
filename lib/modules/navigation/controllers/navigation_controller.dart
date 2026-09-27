import 'package:get/get.dart';
import '../../../core/utils/app_haptics.dart';

class NavigationController extends GetxController {
  final currentIndex = 0.obs;

  void changeTab(int index) {
    if (currentIndex.value != index) {
      AppHaptics.selection();
      currentIndex.value = index;
    }
  }
}
