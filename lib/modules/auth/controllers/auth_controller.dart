import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../routes/app_routes.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthController extends GetxController {
  final AuthRepository repository;
  final StorageService storageService;

  AuthController({
    required this.repository,
    required this.storageService,
  });

  final isLoading = false.obs;
  final currentUser = Rxn<UserModel>();

  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  final regNameController = TextEditingController();
  final regEmailController = TextEditingController();
  final regPasswordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final saved = storageService.user;
    if (saved != null) {
      currentUser.value = UserModel.fromJson(saved);
    }
  }

  Future<void> login() async {
    final email = loginEmailController.text.trim();
    final password = loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      SnackbarService.warning('Please enter your email and password.');
      return;
    }

    try {
      AppHaptics.light();
      isLoading.value = true;
      final auth = await repository.login(email, password);

      await storageService.saveAccessToken(auth.accessToken);
      await storageService.saveRefreshToken(auth.refreshToken);

      // Fetch profile
      try {
        final profile = await repository.getProfile();
        currentUser.value = profile;
        await storageService.saveUser(profile.toJson());
      } catch (_) {
        // Fallback user data
        final fallback = UserModel(id: 'me', name: email.split('@').first, email: email);
        currentUser.value = fallback;
        await storageService.saveUser(fallback.toJson());
      }

      AppHaptics.success();
      SnackbarService.success('Welcome back!');
      Get.offAllNamed(Routes.dashboard);
    } catch (e) {
      LoggerService.e('Login failed: $e', tag: 'AuthController');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    final name = regNameController.text.trim();
    final email = regEmailController.text.trim();
    final password = regPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      SnackbarService.warning('Please fill in all registration fields.');
      return;
    }

    try {
      AppHaptics.light();
      isLoading.value = true;
      final auth = await repository.register(name, email, password);

      await storageService.saveAccessToken(auth.accessToken);
      await storageService.saveRefreshToken(auth.refreshToken);

      final user = UserModel(id: 'new', name: name, email: email);
      currentUser.value = user;
      await storageService.saveUser(user.toJson());

      AppHaptics.success();
      SnackbarService.success('Registration successful!');
      Get.offAllNamed(Routes.dashboard);
    } catch (e) {
      LoggerService.e('Registration failed: $e', tag: 'AuthController');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    regNameController.dispose();
    regEmailController.dispose();
    regPasswordController.dispose();
    super.onClose();
  }
}
