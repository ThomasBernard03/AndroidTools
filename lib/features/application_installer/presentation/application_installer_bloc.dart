import 'package:android_tools/main.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/shared/domain/usecases/install_application_usecase.dart';
import 'package:android_tools/shared/domain/usecases/listen_selected_device_usecase.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

part 'application_installer_event.dart';
part 'application_installer_state.dart';
part 'application_installer_bloc.mapper.dart';

class ApplicationInstallerBloc
    extends Bloc<ApplicationInstallerEvent, ApplicationInstallerState> {
  final Logger _logger = getIt.get();
  final InstallApplicationUsecase _installApplicationUsecase = getIt.get();
  final ListenSelectedDeviceUsecase _listenSelectedDeviceUsecase = getIt.get();

  ApplicationInstallerBloc() : super(ApplicationInstallerState()) {
    on<OnAppearing>((event, emit) async {
      await emit.onEach<DeviceEntity?>(
        _listenSelectedDeviceUsecase(),
        onData: (device) {
          emit(state.copyWith(selectedDevice: device));
        },
      );
    });
    //on<OnRefreshDevices>((event, emit) async {
    //  _logger.i("Refresing connected devices");
    //  await _refreshConnectedDevicesUsecase();
    //});
    on<OnInstallApk>((event, emit) async {
      final device = state.selectedDevice;
      if (device == null) {
        _logger.w("No device selected, can't install apk");
        return;
      }

      _logger.i("Installing apk: ${event.apkPath} on device $device");
      await _installApplicationUsecase(event.apkPath, device.deviceId);
    });
  }
}
