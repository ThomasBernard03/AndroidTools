import 'package:android_tools/main.dart';
import 'package:android_tools/shared/core/constants.dart';
import 'package:android_tools/shared/data/datasources/shell/shell_datasource.dart';
import 'package:android_tools/shared/data/repositories/application_repository_impl.dart';
import 'package:android_tools/shared/data/repositories/device_repository_impl.dart';
import 'package:android_tools/shared/data/repositories/package_repository_impl.dart';
import 'package:android_tools/shared/domain/repositories/application_repository.dart';
import 'package:android_tools/shared/domain/repositories/device_repository.dart';
import 'package:android_tools/shared/domain/repositories/package_repository.dart';
import 'package:android_tools/shared/domain/usecases/get_packages_usecase.dart';
import 'package:android_tools/shared/domain/usecases/install_application_usecase.dart';
import 'package:android_tools/shared/domain/usecases/listen_connected_devices_usecase.dart';
import 'package:android_tools/shared/domain/usecases/listen_selected_device_usecase.dart';
import 'package:android_tools/shared/domain/usecases/refresh_connected_devices_usecase.dart';
import 'package:android_tools/shared/domain/usecases/set_selected_device_usecase.dart';
import 'package:logger/logger.dart';

class SharedModule {
  static void configureDependencies() {
    getIt.registerSingletonAsync<Logger>(() => _createLogger());
    getIt.registerLazySingleton(() => ShellDatasource());

    _registerRepositories();
    _registerUseCases();
  }

  static void _registerRepositories() {
    getIt.registerLazySingleton<DeviceRepository>(
      () => DeviceRepositoryImpl(getIt.get(), getIt.get()),
    );
    getIt.registerLazySingleton<ApplicationRepository>(
      () => ApplicationRepositoryImpl(getIt.get()),
    );
    getIt.registerLazySingleton<PackageRepository>(
      () => PackageRepositoryImpl(getIt.get()),
    );
  }

  static void _registerUseCases() {
    getIt.registerLazySingleton(() => SetSelectedDeviceUsecase(getIt.get()));
    getIt.registerLazySingleton(() => ListenSelectedDeviceUsecase(getIt.get()));
    getIt.registerLazySingleton(() => GetPackagesUsecase(getIt.get()));
    getIt.registerLazySingleton(
      () => RefreshConnectedDevicesUsecase(getIt.get()),
    );
    getIt.registerLazySingleton(
      () => ListenConnectedDevicesUsecase(getIt.get()),
    );
    getIt.registerLazySingleton(() => InstallApplicationUsecase(getIt.get()));
  }

  static Future<Logger> _createLogger() async {
    final logDirectory = await Constants.getApplicationLogsDirectory();
    return Logger(
      filter: ProductionFilter(),
      printer: SimplePrinter(printTime: true, colors: false),
      output: MultiOutput([
        AdvancedFileOutput(
          path: logDirectory.path,
          maxRotatedFilesCount: 7,
          maxFileSizeKB: 1024,
        ),
        ConsoleOutput(),
      ]),
    );
  }
}
