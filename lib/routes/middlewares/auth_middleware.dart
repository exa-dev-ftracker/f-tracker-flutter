import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/storage_service.dart';
import '../app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final storage = Get.find<StorageService>();
    final isAuth = storage.isLoggedIn;

    if (!isAuth && route != Routes.login && route != Routes.register) {
      return const RouteSettings(name: Routes.login);
    }
    if (isAuth && (route == Routes.login || route == Routes.register)) {
      return const RouteSettings(name: Routes.dashboard);
    }
    return null;
  }
}
