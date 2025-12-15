import 'package:android_tools/main.dart';
import 'package:android_tools/shared/data/datasources/shell/shell_datasource.dart';
import 'package:android_tools/shared/data/repositories/device_repository_impl.dart';
import 'package:android_tools/shared/domain/repositories/device_repository.dart';
import 'package:android_tools/shared/domain/usecases/listen_connected_devices_usecase.dart';
import 'package:android_tools/shared/domain/usecases/listen_selected_device_usecase.dart';
import 'package:android_tools/shared/domain/usecases/refresh_connected_devices_usecase.dart';
import 'package:android_tools/shared/domain/usecases/set_selected_device_usecase.dart';
import 'package:logger/logger.dart';

class SharedModule {
  static void configureDependencies() {
    getIt.registerLazySingleton<Logger>(() => Logger(printer: SimplePrinter()));
    getIt.registerLazySingleton(() => ShellDatasource());

    _registerRepositories();
    _registerUseCases();
  }

  static void _registerRepositories() {
    getIt.registerLazySingleton<DeviceRepository>(
      () => DeviceRepositoryImpl(getIt.get(), getIt.get()),
    );
  }

  static void _registerUseCases() {
    getIt.registerLazySingleton(() => SetSelectedDeviceUsecase(getIt.get()));
    getIt.registerLazySingleton(() => ListenSelectedDeviceUsecase(getIt.get()));
    getIt.registerLazySingleton(
      () => RefreshConnectedDevicesUsecase(getIt.get()),
    );
    getIt.registerLazySingleton(
      () => ListenConnectedDevicesUsecase(getIt.get()),
    );
  }
}
