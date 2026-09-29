import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Safe navigation utilities that prevent GetX 4's `Get.back()` from
/// being hijacked by active snackbar overlays.
class AppNav {
  AppNav._();

  /// Safely pops the current dialog, modal bottom sheet, or route.
  ///
  /// Unlike `Get.back()`, which closes any open snackbar instead of popping the
  /// route when `Get.isSnackbarOpen` is true, [pop] directly pops the Navigator
  /// stack so dialogs and bottom sheets close reliably even if a snackbar is active.
  static void pop<T>([BuildContext? context, T? result]) {
    if (context != null && Navigator.canPop(context)) {
      Navigator.of(context).pop<T>(result);
      return;
    }
    final ctx = Get.context;
    if (ctx != null && Navigator.canPop(ctx)) {
      Navigator.of(ctx).pop<T>(result);
      return;
    }
    if (Get.key.currentState?.canPop() ?? false) {
      Get.key.currentState?.pop<T>(result);
      return;
    }
    Get.back<T>(result: result);
  }
}
