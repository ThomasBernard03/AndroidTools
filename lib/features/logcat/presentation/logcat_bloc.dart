import 'dart:async';

import 'package:android_tools/features/logcat/domain/entities/process_entity.dart';
import 'package:android_tools/features/logcat/domain/usecases/get_processes_usecase.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/features/logcat/domain/entities/logcat_level.dart';
import 'package:android_tools/shared/domain/usecases/get_connected_devices_usecase.dart';
import 'package:android_tools/features/logcat/domain/usecases/clear_logcat_usecase.dart';
import 'package:android_tools/features/logcat/domain/usecases/listen_logcat_usecase.dart';
import 'package:android_tools/main.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

part 'logcat_event.dart';
part 'logcat_state.dart';
part 'logcat_bloc.mapper.dart';

class LogcatBloc extends Bloc<LogcatEvent, LogcatState> {
  final ListenLogcatUsecase _listenLogcatUsecase = getIt.get();
  final ClearLogcatUsecase _clearLogcatUsecase = getIt.get();
  final GetConnectedDevicesUsecase _getConnectedDevicesUsecase = getIt.get();
  final GetProcessesUsecase _getProcessesUsecase = getIt.get();
  final Logger logger = getIt.get();

  StreamSubscription<List<String>>? _subscription;

  LogcatBloc() : super(LogcatState()) {
    on<OnStartListeningLogcat>((event, emit) async {
      final devices = await _getConnectedDevicesUsecase();
      final defaultDevice = devices.firstOrNull;

      if (defaultDevice == null) {
        logger.w("No devices connected");
        return;
      }
      final processes = await _getProcessesUsecase(defaultDevice.deviceId);
      emit(
        state.copyWith(
          devices: devices,
          selectedDevice: defaultDevice,
          processes: processes,
        ),
      );

      await _listenLogcat();
    });

    on<OnLogReceived>((event, emit) {
      logger.d("Adding ${event.lines.length} new lines to logcat lines");
      final updated = List<String>.from(state.logs)..addAll(event.lines);
      logger.d("Size of logcat lines : ${updated.length}");
      emit(state.copyWith(logs: updated));
    });

    on<OnClearLogcat>((event, emit) async {
      if (state.selectedDevice == null) {
        return logger.w("Can't clear logcat, no device selected");
      }

      logger.i("Start cleaning logcat");
      emit(state.copyWith(logs: []));
      await _clearLogcatUsecase(state.selectedDevice!.deviceId);
      logger.i("Logcat cleaned");
    });

    on<OnToggleIsSticky>((event, emit) {
      logger.i("isSticky changed to ${event.isSticky}");
      emit(state.copyWith(isSticky: event.isSticky));
    });

    on<OnMinimumLogLevelChanged>((event, emit) async {
      logger.i("Minimum logcat level changed for ${event.minimumLogLevel}");
      emit(state.copyWith(minimumLogLevel: event.minimumLogLevel, logs: []));
      await _listenLogcat();
    });

    on<OnPauseLogcat>((event, emit) {
      logger.i("Pausing logcat");
      emit(state.copyWith(isPaused: true));
      _subscription?.pause();
    });

    on<OnResumeLogcat>((event, emit) {
      logger.i("Resuming logcat");
      emit(state.copyWith(isPaused: false));
      _subscription?.resume();
    });

    on<OnLogcatMaxLinesChanged>((event, emit) {
      logger.i("Logcat max lines changed for ${event.maxLines}");
      emit(state.copyWith(maxLogcatLines: event.maxLines));
    });
    on<OnSelectedDeviceChanged>((event, emit) async {
      logger.i("Selected device changed for ${event.device.name}");
      await _subscription?.cancel();

      emit(state.copyWith(selectedDevice: event.device, logs: []));
      await _listenLogcat();
    });
    on<OnRefreshLogcat>((event, emit) async {
      logger.i("Refreshing logcat");
      final devices = await _getConnectedDevicesUsecase();
      final selectedDevice =
          devices.any((d) => d.deviceId == state.selectedDevice?.deviceId)
          ? state.selectedDevice
          : devices.firstOrNull;
      emit(
        state.copyWith(
          devices: devices,
          selectedDevice: selectedDevice,
          logs: [],
        ),
      );
      await _listenLogcat();
    });
    on<OnRefreshDevices>((event, emit) async {
      logger.i("Refreshing devices");
      final devices = await _getConnectedDevicesUsecase();
      emit(
        state.copyWith(devices: devices, selectedDevice: devices.firstOrNull),
      );
      await _listenLogcat();
    });
    on<OnProcessSelected>((event, emit) async {
      logger.i("Process selected : ${event.process}");
      emit(state.copyWith(logs: [], selectedProcess: event.process));
      await _listenLogcat();
    });
  }

  Future<void> _listenLogcat() async {
    if (state.selectedDevice == null) {
      logger.w("Can't listen for logcat (No device selcted)");
      return;
    }

    await _subscription?.cancel();
    final stream = _listenLogcatUsecase(
      state.selectedDevice!.deviceId,
      state.minimumLogLevel,
      state.selectedProcess?.processId,
    );
    _subscription = stream.listen((lines) {
      add(OnLogReceived(lines: lines));
    });
  }

  @override
  Future<void> close() async {
    logger.i("Closing logcat bloc");
    await _subscription?.cancel();
    return super.close();
  }
}
