import 'package:android_tools/features/logcat/data/repositories/logcat_repository_impl.dart';
import 'package:android_tools/features/logcat/domain/repositories/logcat_repository.dart';
import 'package:android_tools/features/logcat/domain/usecases/clear_logcat_usecase.dart';
import 'package:android_tools/features/logcat/domain/usecases/get_processes_usecase.dart';
import 'package:android_tools/features/logcat/domain/usecases/listen_logcat_usecase.dart';
import 'package:android_tools/main.dart';

class LogcatModule {
  static void configureDependencies() {
    _registerRepositories();
    _registerUseCases();
  }

  static void _registerRepositories() {
    getIt.registerLazySingleton<LogcatRepository>(
      () => LogcatRepositoryImpl(
        logger: getIt.get(),
        shellDatasource: getIt.get(),
      ),
    );
  }

  static void _registerUseCases() {
    getIt.registerLazySingleton(
      () => ListenLogcatUsecase(logcatRepository: getIt.get()),
    );
    getIt.registerLazySingleton(() => GetProcessesUsecase(getIt.get()));
    getIt.registerLazySingleton(
      () => ClearLogcatUsecase(logcatRepository: getIt.get()),
    );
  }
}
