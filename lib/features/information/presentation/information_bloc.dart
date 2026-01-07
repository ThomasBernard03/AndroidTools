import 'package:android_tools/features/information/domain/entities/device_battery_information_entity.dart';
import 'package:android_tools/features/information/domain/entities/device_information_entity.dart';
import 'package:android_tools/features/information/domain/usecases/get_device_battery_information_usecase.dart';
import 'package:android_tools/features/information/domain/usecases/get_device_information_usecase.dart';
import 'package:android_tools/main.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/shared/domain/usecases/install_application_usecase.dart';
import 'package:android_tools/shared/domain/usecases/listen_selected_device_usecase.dart';
import 'package:android_tools/shared/domain/usecases/refresh_connected_devices_usecase.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

part 'information_event.dart';
part 'information_state.dart';
part 'information_bloc.mapper.dart';

class InformationBloc extends Bloc<InformationEvent, InformationState> {
  final Logger _logger = getIt.get();
  final ListenSelectedDeviceUsecase _listenSelectedDeviceUsecase = getIt.get();
  final GetDeviceInformationUsecase _getDeviceInformationUsecase = getIt.get();
  final RefreshConnectedDevicesUsecase _refreshConnectedDevicesUsecase = getIt
      .get();
  final InstallApplicationUsecase _installApplicationUsecase = getIt.get();
  final GetDeviceBatteryInformationUsecase _getDeviceBatteryInformationUsecase =
      getIt.get();

  InformationBloc() : super(InformationState()) {
    on<OnAppearing>((event, emit) async {
      await emit.onEach<DeviceEntity?>(
        _listenSelectedDeviceUsecase(),
        onData: (device) async {
          if (device == null) {
            _logger.w("Selected device is null, can't get information");
            emit(state.copyWith(deviceInformation: null, device: null));
            return;
          }

          final information = await _getDeviceInformationUsecase(
            device.deviceId,
          );
          final batteryInformation = await _getDeviceBatteryInformationUsecase(
            device.deviceId,
          );
          emit(
            state.copyWith(
              deviceInformation: information,
              device: device,
              deviceBatteryInformation: batteryInformation,
            ),
          );
        },
      );
    });
    on<OnRefreshDevices>((event, emit) async {
      _logger.i("Refresing connected devices");
      await _refreshConnectedDevicesUsecase();
    });
    on<OnInstallApplication>((event, emit) {
      final device = state.device;
      if (device == null) {
        _logger.w("Selected device is null, can't install apk");
        return;
      }
      _installApplicationUsecase(event.applicationFilePath, device.deviceId);
    });
  }
}
