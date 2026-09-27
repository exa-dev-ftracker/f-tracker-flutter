import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'core/constants/app_constants.dart';
import 'core/network/api_client.dart';
import 'core/services/logger_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load Environment Variables
  try {
    await dotenv.load(fileName: '.env');
    LoggerService.i('.env loaded successfully', tag: 'Bootstrap');
  } catch (e) {
    LoggerService.w('.env could not be loaded, using defaults: $e', tag: 'Bootstrap');
  }

  // 2. Initialize Singletons / Core Services
  final storageService = await StorageService().init();
  Get.put<StorageService>(storageService, permanent: true);

  final apiClient = ApiClient(storageService: storageService);
  Get.put<ApiClient>(apiClient, permanent: true);

  final syncService = await SyncService(
    storageService: storageService,
    apiClient: apiClient,
  ).init();
  Get.put<SyncService>(syncService, permanent: true);

  LoggerService.i('F-Tracker Core & Sync Services initialized', tag: 'Bootstrap');

  // 3. Run Application
  runApp(const FTrackerApp());
}

class FTrackerApp extends StatelessWidget {
  const FTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.cupertino,
    );
  }
}
