import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/snackbar_service.dart';
import '../../../core/services/social_auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../routes/app_routes.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthController extends GetxController {
  final AuthRepository repository;
  final StorageService storageService;

  AuthController({required this.repository, required this.storageService});

  final isLoading = false.obs;
  final isAppleAvailable = false.obs;
  final currentUser = Rxn<UserModel>();

  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  final regNameController = TextEditingController();
  final regEmailController = TextEditingController();
  final regPasswordController = TextEditingController();

  // Inline field-level error messages
  final loginEmailError = RxnString();
  final loginPasswordError = RxnString();
  final regNameError = RxnString();
  final regEmailError = RxnString();
  final regPasswordError = RxnString();

  @override
  void onInit() {
    super.onInit();
    final saved = storageService.user;
    if (saved != null) {
      currentUser.value = UserModel.fromJson(saved);
    }
    _checkAppleAvailability();

    // Clear inline errors as user types
    loginEmailController.addListener(() => loginEmailError.value = null);
    loginPasswordController.addListener(() => loginPasswordError.value = null);
    regNameController.addListener(() => regNameError.value = null);
    regEmailController.addListener(() => regEmailError.value = null);
    regPasswordController.addListener(() => regPasswordError.value = null);
  }

  Future<void> _checkAppleAvailability() async {
    isAppleAvailable.value = await SocialAuthService.isAppleSignInAvailable();
  }

  // --- Validation Helpers ---

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool _validateLogin() {
    final email = loginEmailController.text.trim();
    final password = loginPasswordController.text;
    bool valid = true;

    if (email.isEmpty) {
      loginEmailError.value = 'Email is required';
      valid = false;
    } else if (!_emailRegex.hasMatch(email)) {
      loginEmailError.value = 'Please enter a valid email address';
      valid = false;
    } else {
      loginEmailError.value = null;
    }

    if (password.isEmpty) {
      loginPasswordError.value = 'Password is required';
      valid = false;
    } else {
      loginPasswordError.value = null;
    }

    return valid;
  }

  bool _validateRegister() {
    final name = regNameController.text.trim();
    final email = regEmailController.text.trim();
    final password = regPasswordController.text;
    bool valid = true;

    if (name.isEmpty) {
      regNameError.value = 'Full name is required';
      valid = false;
    } else if (name.length < 2) {
      regNameError.value = 'Name must be at least 2 characters';
      valid = false;
    } else {
      regNameError.value = null;
    }

    if (email.isEmpty) {
      regEmailError.value = 'Email is required';
      valid = false;
    } else if (!_emailRegex.hasMatch(email)) {
      regEmailError.value = 'Please enter a valid email address';
      valid = false;
    } else {
      regEmailError.value = null;
    }

    if (password.isEmpty) {
      regPasswordError.value = 'Password is required';
      valid = false;
    } else if (password.length < 6) {
      regPasswordError.value = 'Password must be at least 6 characters';
      valid = false;
    } else {
      regPasswordError.value = null;
    }

    return valid;
  }

  Future<void> login() async {
    if (!_validateLogin()) return;

    final email = loginEmailController.text.trim();
    final password = loginPasswordController.text;

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
        final fallback = UserModel(
          id: 'me',
          name: email.split('@').first,
          email: email,
        );
        currentUser.value = fallback;
        await storageService.saveUser(fallback.toJson());
      }

      AppHaptics.success();
      SnackbarService.success('Welcome back!');
      Get.offAllNamed(Routes.dashboard);
    } catch (e) {
      AppErrorHandler.handle(
        e,
        fallback: 'Login failed. Please check your credentials.',
        tag: 'AuthController',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    if (!_validateRegister()) return;

    final name = regNameController.text.trim();
    final email = regEmailController.text.trim();
    final password = regPasswordController.text;

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
      AppErrorHandler.handle(
        e,
        fallback: 'Registration failed. Please try again.',
        tag: 'AuthController',
      );
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
      if (!AppErrorHandler.isUserCancelled(e)) {
        AppErrorHandler.handle(
          e,
          fallback: 'Failed to sign in with Google',
          tag: 'AuthController',
        );
      }
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

      final fullName = [
        result.givenName,
        result.familyName,
      ].where((s) => s != null && s.isNotEmpty).join(' ');

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
      if (!AppErrorHandler.isUserCancelled(e)) {
        AppErrorHandler.handle(
          e,
          fallback: 'Failed to sign in with Apple',
          tag: 'AuthController',
        );
      }
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
