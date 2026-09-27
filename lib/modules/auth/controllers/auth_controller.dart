import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/services/social_auth_service.dart';
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
  final isAppleAvailable = false.obs;
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
    _checkAppleAvailability();
  }

  Future<void> _checkAppleAvailability() async {
    isAppleAvailable.value = await SocialAuthService.isAppleSignInAvailable();
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

  Future<void> loginWithGoogle() async {
    try {
      AppHaptics.light();
      isLoading.value = true;

      final result = await SocialAuthService.signInWithGoogle();
      if (result == null) {
        isLoading.value = false;
        return; // User cancelled
      }

      // Send authorization code (or credential fallback) to backend for verification
      final auth = await repository.loginWithGoogle(
        code: result.serverAuthCode,
        credential: result.idToken,
      );

      await storageService.saveAccessToken(auth.accessToken);
      await storageService.saveRefreshToken(auth.refreshToken);

      try {
        final profile = await repository.getProfile();
        currentUser.value = profile;
        await storageService.saveUser(profile.toJson());
      } catch (_) {
        final fallback = UserModel(
          id: 'me',
          name: result.displayName ?? result.email?.split('@').first ?? 'User',
          email: result.email ?? '',
        );
        currentUser.value = fallback;
        await storageService.saveUser(fallback.toJson());
      }

      AppHaptics.success();
      SnackbarService.success('Logged in with Google successfully!');
      Get.offAllNamed(Routes.dashboard);
    } catch (e) {
      LoggerService.e('Google login failed: $e', tag: 'AuthController');
      SnackbarService.error('Failed to log in with Google: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithApple() async {
    try {
      AppHaptics.light();
      isLoading.value = true;

      final result = await SocialAuthService.signInWithApple();
      if (result == null) {
        isLoading.value = false;
        return; // User cancelled
      }

      final fullName = [result.givenName, result.familyName].where((s) => s != null && s.isNotEmpty).join(' ');

      final auth = await repository.loginWithApple(
        code: result.authorizationCode,
        identityToken: result.identityToken,
        userIdentifier: result.userIdentifier,
        email: result.email,
        name: fullName.isNotEmpty ? fullName : null,
      );

      await storageService.saveAccessToken(auth.accessToken);
      await storageService.saveRefreshToken(auth.refreshToken);

      try {
        final profile = await repository.getProfile();
        currentUser.value = profile;
        await storageService.saveUser(profile.toJson());
      } catch (_) {
        final fallback = UserModel(
          id: 'me',
          name: fullName.isNotEmpty ? fullName : 'Apple User',
          email: result.email ?? '',
        );
        currentUser.value = fallback;
        await storageService.saveUser(fallback.toJson());
      }

      AppHaptics.success();
      SnackbarService.success('Logged in with Apple successfully!');
      Get.offAllNamed(Routes.dashboard);
    } catch (e) {
      LoggerService.e('Apple login failed: $e', tag: 'AuthController');
      SnackbarService.error('Failed to log in with Apple: $e');
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
