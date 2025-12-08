import 'package:android_tools/main.dart';
import 'package:android_tools/shared/data/datasources/shell/shell_datasource.dart';
import 'package:android_tools/shared/data/repositories/device_repository_impl.dart';
import 'package:android_tools/shared/domain/repositories/device_repository.dart';
import 'package:android_tools/shared/domain/usecases/get_connected_devices_usecase.dart';
import 'package:logger/logger.dart';

class SharedModule {
  static void configureDependencies() {
    getIt.registerLazySingleton<Logger>(() => Logger());
    getIt.registerLazySingleton(() => ShellDatasource());

    _registerRepositories();
    _registerUseCases();
  }

  static void _registerRepositories() {
    getIt.registerLazySingleton<DeviceRepository>(
      () => DeviceRepositoryImpl(
        logger: getIt.get(),
        shellDatasource: getIt.get(),
      ),
    );
  }

  static void _registerUseCases() {
    getIt.registerLazySingleton(
      () => GetConnectedDevicesUsecase(deviceRepository: getIt.get()),
    );
  }
}
