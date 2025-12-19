import 'package:android_tools/main.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/shared/domain/usecases/listen_connected_devices_usecase.dart';
import 'package:android_tools/shared/domain/usecases/listen_selected_device_usecase.dart';
import 'package:android_tools/shared/domain/usecases/refresh_connected_devices_usecase.dart';
import 'package:android_tools/shared/domain/usecases/set_selected_device_usecase.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'home_event.dart';
part 'home_state.dart';
part 'home_bloc.mapper.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final Logger _logger = getIt.get();
  final ListenConnectedDevicesUsecase _listenConnectedDevicesUsecase = getIt
      .get();
  final ListenSelectedDeviceUsecase _listenSelectedDeviceUsecase = getIt.get();
  final SetSelectedDeviceUsecase _setSelectedDeviceUsecase = getIt.get();
  final RefreshConnectedDevicesUsecase _refreshConnectedDevicesUsecase = getIt
      .get();

  HomeBloc() : super(HomeState()) {
    on<OnGetVersion>((event, emit) async {
      final packageInfo = await PackageInfo.fromPlatform();
      emit(state.copyWith(version: packageInfo.version));
    });
    on<OnListenConnectedDevices>((event, emit) async {
      await _refreshConnectedDevicesUsecase();

      final packageInfo = await PackageInfo.fromPlatform();
      emit(state.copyWith(version: packageInfo.version));

      await emit.forEach<List<DeviceEntity>>(
        _listenConnectedDevicesUsecase(),
        onData: (devices) {
          return state.copyWith(devices: devices);
        },
      );
    });
    on<OnListenSelectedDevice>((event, emit) async {
      await emit.forEach<DeviceEntity?>(
        _listenSelectedDeviceUsecase(),
        onData: (device) {
          return state.copyWith(selectedDevice: device);
        },
      );
    });
    on<OnDeviceSelected>((event, emit) async {
      _logger.i("Device selected : ${event.device.deviceId}");
      await _setSelectedDeviceUsecase(event.device);
    });
    on<OnRefreshDevices>((event, emit) async {
      await _refreshConnectedDevicesUsecase();
    });
  }
}
