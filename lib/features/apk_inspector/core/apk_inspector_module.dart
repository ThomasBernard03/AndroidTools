import 'package:android_tools/features/apk_inspector/data/repositories/apk_repository_impl.dart';
import 'package:android_tools/features/apk_inspector/data/repositories/recent_apk_repository_impl.dart';
import 'package:android_tools/features/apk_inspector/domain/repositories/apk_repository.dart';
import 'package:android_tools/features/apk_inspector/domain/repositories/recent_apk_repository.dart';
import 'package:android_tools/features/apk_inspector/domain/usecases/get_recent_apks_usecase.dart';
import 'package:android_tools/features/apk_inspector/domain/usecases/install_apk_usecase.dart';
import 'package:android_tools/features/apk_inspector/domain/usecases/parse_apk_usecase.dart';
import 'package:android_tools/features/apk_inspector/domain/usecases/save_recent_apk_usecase.dart';
import 'package:android_tools/main.dart';

/// Dependency injection module for the APK Inspector feature
class ApkInspectorModule {
  /// Configure all dependencies for the APK Inspector feature
  static void configureDependencies() {
    _registerRepositories();
    _registerUseCases();
  }

  static void _registerRepositories() {
    getIt.registerLazySingleton<ApkRepository>(
      () => ApkRepositoryImpl(
        getIt.get(), // AaptClient
        getIt.get(), // AdbClient
        getIt.get(), // Logger
      ),
    );

    getIt.registerLazySingleton<RecentApkRepository>(
      () => RecentApkRepositoryImpl(
        getIt.get(), // AppDatabase
        getIt.get(), // Logger
      ),
    );
  }

  static void _registerUseCases() {
    getIt.registerLazySingleton(() => ParseApkUsecase(getIt.get()));
    getIt.registerLazySingleton(() => InstallApkUsecase(getIt.get()));
    getIt.registerLazySingleton(() => GetRecentApksUsecase(getIt.get()));
    getIt.registerLazySingleton(() => SaveRecentApkUsecase(getIt.get()));
  }
}
