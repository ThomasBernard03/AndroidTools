import 'dart:async';

import 'package:android_tools/features/logcat/domain/entities/process_entity.dart';
import 'package:android_tools/features/logcat/domain/usecases/get_processes_usecase.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/features/logcat/domain/entities/logcat_level.dart';
import 'package:android_tools/features/logcat/domain/usecases/clear_logcat_usecase.dart';
import 'package:android_tools/features/logcat/domain/usecases/listen_logcat_usecase.dart';
import 'package:android_tools/main.dart';
import 'package:android_tools/shared/domain/usecases/listen_selected_device_usecase.dart';
import 'package:android_tools/shared/domain/usecases/refresh_connected_devices_usecase.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:collection/collection.dart';

part 'logcat_event.dart';
part 'logcat_state.dart';
part 'logcat_bloc.mapper.dart';

class LogcatBloc extends Bloc<LogcatEvent, LogcatState> {
  final ListenLogcatUsecase _listenLogcatUsecase = getIt.get();
  final ClearLogcatUsecase _clearLogcatUsecase = getIt.get();
  final GetProcessesUsecase _getProcessesUsecase = getIt.get();
  final RefreshConnectedDevicesUsecase _refreshConnectedDevicesUsecase = getIt
      .get();
  final Logger _logger = getIt.get();
  final ListenSelectedDeviceUsecase _listenSelectedDeviceUsecase = getIt.get();

  StreamSubscription<List<String>>? _logcatSubscription;

  LogcatBloc() : super(LogcatState()) {
    on<OnStartListeningLogcat>((event, emit) async {
      await emit.onEach<DeviceEntity?>(
        _listenSelectedDeviceUsecase(),
        onData: (device) async {
          emit(state.copyWith(selectedProcess: null, logs: []));

          if (device == null) {
            _logger.i("Selected device is null, can't get processes");
            _logcatSubscription?.cancel();
            emit(state.copyWith(selectedDevice: null, processes: []));
            return;
          }

          _logger.i("Received new device : $device, get processes");
          final processes = await _getProcessesUsecase(device.deviceId);
          _logger.i("Found ${processes.length} processes for device $device");
          emit(state.copyWith(selectedDevice: device, processes: processes));
          await _listenLogcat();
        },
      );
    });
    on<OnLogReceived>((event, emit) {
      _logger.d("Adding ${event.lines.length} new lines to logcat lines");
      final updated = List<String>.from(state.logs)..addAll(event.lines);
      _logger.d("Size of logcat lines : ${updated.length}");
      emit(state.copyWith(logs: updated));
    });

    on<OnClearLogcat>((event, emit) async {
      final selectedDevice = state.selectedDevice;
      if (selectedDevice == null) {
        return _logger.w("Can't clear logcat, no device selected");
      }

      _logger.i("Start cleaning logcat");
      emit(state.copyWith(logs: []));
      await _clearLogcatUsecase(selectedDevice.deviceId);
      _logger.i("Logcat cleaned");
    });

    on<OnToggleIsSticky>((event, emit) {
      _logger.i("isSticky changed to ${event.isSticky}");
      emit(state.copyWith(isSticky: event.isSticky));
    });

    on<OnMinimumLogLevelChanged>((event, emit) async {
      _logger.i("Minimum logcat level changed for ${event.minimumLogLevel}");
      emit(state.copyWith(minimumLogLevel: event.minimumLogLevel, logs: []));
      await _listenLogcat();
    });

    on<OnPauseLogcat>((event, emit) {
      _logger.i("Pausing logcat");
      emit(state.copyWith(isPaused: true));
      _logcatSubscription?.pause();
    });
    on<OnResumeLogcat>((event, emit) {
      _logger.i("Resuming logcat");
      emit(state.copyWith(isPaused: false));
      _logcatSubscription?.resume();
    });
    on<OnLogcatMaxLinesChanged>((event, emit) {
      _logger.i("Logcat max lines changed for ${event.maxLines}");
      emit(state.copyWith(maxLogcatLines: event.maxLines));
    });
    on<OnRefreshLogcat>((event, emit) async {
      _logger.i("Refreshing logcat");
      await _refreshConnectedDevicesUsecase();
      final selectedDevice = state.selectedDevice;
      if (selectedDevice == null) {
        _logger.w("Can't refresh logcat, no device selected");
        return;
      }

      final processes = await _getProcessesUsecase(selectedDevice.deviceId);
      final oldProcess = state.selectedProcess;
      // ProcessId can change so we map to update processId
      final selectedProcess = oldProcess == null
          ? null
          : processes.firstWhereOrNull(
              (p) => p.packageName == oldProcess.packageName,
            );
      emit(
        state.copyWith(
          processes: processes,
          selectedProcess: selectedProcess,
          logs: [],
        ),
      );

      await _listenLogcat();
    });
    on<OnRefreshDevices>((event, emit) async {
      _logger.i("Refreshing devices");
      await _refreshConnectedDevicesUsecase();
    });
    on<OnProcessSelected>((event, emit) async {
      _logger.i("Process selected : ${event.process}");
      emit(state.copyWith(logs: [], selectedProcess: event.process));
      await _listenLogcat();
    });
  }
  Future<void> _listenLogcat() async {
    if (state.selectedDevice == null) {
      _logger.w("Can't listen for logcat (No device selcted)");
      return;
    }

    await _logcatSubscription?.cancel();
    final stream = _listenLogcatUsecase(
      state.selectedDevice!.deviceId,
      state.minimumLogLevel,
      state.selectedProcess?.processId,
    );
    _logcatSubscription = stream.listen((lines) {
      add(OnLogReceived(lines: lines));
    });
  }

  @override
  Future<void> close() async {
    _logger.i("Closing logcat bloc");
    await _logcatSubscription?.cancel();
    return super.close();
  }
}
