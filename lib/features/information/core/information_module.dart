import 'package:android_tools/features/information/data/repositories/device_information_repository_impl.dart';
import 'package:android_tools/features/information/domain/repositories/device_information_repository.dart';
import 'package:android_tools/features/information/domain/usecases/get_device_battery_information_usecase.dart';
import 'package:android_tools/features/information/domain/usecases/get_device_display_information_usecase.dart';
import 'package:android_tools/features/information/domain/usecases/get_device_information_usecase.dart';
import 'package:android_tools/features/information/domain/usecases/get_device_network_information_usecase.dart';
import 'package:android_tools/features/information/domain/usecases/get_device_storage_information_usecase.dart';
import 'package:android_tools/main.dart';

class InformationModule {
  static void configureDependencies() {
    getIt.registerLazySingleton(() => GetDeviceInformationUsecase(getIt.get()));
    getIt.registerLazySingleton(
      () => GetDeviceStorageInformationUsecase(getIt.get()),
    );
    getIt.registerLazySingleton(
      () => GetDeviceBatteryInformationUsecase(getIt.get()),
    );
    getIt.registerLazySingleton(
      () => GetDeviceDisplayInformationUsecase(getIt.get()),
    );
    getIt.registerLazySingleton(
      () => GetDeviceNetworkInformationUsecase(getIt.get()),
    );
    getIt.registerLazySingleton<DeviceInformationRepository>(
      () => DeviceInformationRepositoryImpl(getIt.get()),
    );
  }
}
