import 'package:android_tools/features/screenshot/data/repositories/screenshot_repository_impl.dart';
import 'package:android_tools/features/screenshot/domain/repositories/screenshot_repository.dart';
import 'package:android_tools/features/screenshot/domain/usecases/copy_screenshot_usecase.dart';
import 'package:android_tools/features/screenshot/domain/usecases/save_screenshot_usecase.dart';
import 'package:android_tools/features/screenshot/domain/usecases/take_screenshot_usecase.dart';
import 'package:android_tools/main.dart';

class ScreenshotModule {
  static void configureDependencies() {
    _registerRepositories();
    _registerUseCases();
  }

  static void _registerRepositories() {
    getIt.registerLazySingleton<ScreenshotRepository>(
      () => ScreenshotRepositoryImpl(getIt.get(), getIt.get()),
    );
  }

  static void _registerUseCases() {
    getIt.registerLazySingleton(() => TakeScreenshotUsecase(getIt.get()));
    getIt.registerLazySingleton(() => SaveScreenshotUsecase(getIt.get()));
    getIt.registerLazySingleton(() => CopyScreenshotUsecase(getIt.get()));
  }
}
