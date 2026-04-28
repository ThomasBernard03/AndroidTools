import 'dart:async';

import 'package:android_tools/features/apk_inspector/domain/entities/apk_info.dart';
import 'package:android_tools/features/apk_inspector/domain/usecases/get_recent_apks_usecase.dart';
import 'package:android_tools/features/apk_inspector/domain/usecases/install_apk_usecase.dart';
import 'package:android_tools/features/apk_inspector/domain/usecases/parse_apk_usecase.dart';
import 'package:android_tools/features/apk_inspector/domain/usecases/save_recent_apk_usecase.dart';
import 'package:android_tools/main.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/shared/domain/usecases/listen_selected_device_usecase.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

part 'apk_inspector_event.dart';
part 'apk_inspector_state.dart';
part 'apk_inspector_bloc.mapper.dart';

/// BLoC managing the state and logic for the APK Inspector feature
class ApkInspectorBloc extends Bloc<ApkInspectorEvent, ApkInspectorState> {
  final ParseApkUsecase _parseApkUsecase = getIt.get();
  final InstallApkUsecase _installApkUsecase = getIt.get();
  final GetRecentApksUsecase _getRecentApksUsecase = getIt.get();
  final SaveRecentApkUsecase _saveRecentApkUsecase = getIt.get();
  final ListenSelectedDeviceUsecase _listenSelectedDeviceUsecase = getIt.get();
  final Logger _logger = getIt.get();

  ApkInspectorBloc() : super(ApkInspectorState.initial()) {
    on<OnSelectApkFile>(_onSelectApkFile);
    on<OnResetView>(_onResetView);
    on<OnInstallApk>(_onInstallApk);
    on<OnLoadRecentApks>(_onLoadRecentApks);
    on<OnSelectRecentApk>(_onSelectRecentApk);
    on<OnScreenAppearing>(_onScreenAppearing);

    add(OnLoadRecentApks());
    add(OnScreenAppearing());
  }

  Future<void> _onSelectApkFile(
    OnSelectApkFile event,
    Emitter<ApkInspectorState> emit,
  ) async {
    _logger.i('Selected APK file: ${event.apkPath}');

    // Start parsing
    emit(
      state.copyWith(status: ApkInspectorStatus.parsing, errorMessage: null),
    );

    try {
      // Parse the APK
      final apkInfo = await _parseApkUsecase(event.apkPath);

      // Emit ready state with parsed info
      emit(state.copyWith(status: ApkInspectorStatus.ready, apkInfo: apkInfo));

      _logger.i('APK parsed successfully: ${apkInfo.packageName}');

      // Save to recent APKs
      try {
        await _saveRecentApkUsecase(apkInfo);
        _logger.d('Saved APK to recent history');

        final updatedRecentApks = await _getRecentApksUsecase();
        emit(state.copyWith(recentApks: updatedRecentApks));
      } catch (e) {
        _logger.w('Failed to save recent APK: $e');
      }
    } catch (e, stackTrace) {
      _logger.e('Error parsing APK', error: e, stackTrace: stackTrace);

      emit(
        state.copyWith(
          status: ApkInspectorStatus.error,
          errorMessage: 'Failed to parse APK: ${e.toString()}',
        ),
      );
    }
  }

  void _onResetView(OnResetView event, Emitter<ApkInspectorState> emit) {
    _logger.i('Resetting APK Inspector view');

    emit(
      state.copyWith(
        status: ApkInspectorStatus.idle,
        apkInfo: null,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onInstallApk(
    OnInstallApk event,
    Emitter<ApkInspectorState> emit,
  ) async {
    if (state.apkInfo == null) {
      _logger.w('No APK info available, cannot install');
      return;
    }

    _logger.i('Installing APK to device: ${event.deviceId}');

    emit(state.copyWith(status: ApkInspectorStatus.installing));

    try {
      // Install the APK
      await _installApkUsecase(state.apkInfo!.filePath, event.deviceId);

      emit(state.copyWith(status: ApkInspectorStatus.installed));

      _logger.i('APK installed successfully');

      // Reset to ready state after 2 seconds to show the install button again
      await Future.delayed(const Duration(seconds: 2));
      if (!emit.isDone && state.status == ApkInspectorStatus.installed) {
        emit(state.copyWith(status: ApkInspectorStatus.ready));
      }
    } catch (e, stackTrace) {
      _logger.e('Error installing APK', error: e, stackTrace: stackTrace);

      if (!emit.isDone) {
        // Extract user-friendly error message
        String errorMessage = e.toString();
        if (errorMessage.contains('INSTALL_FAILED_INSUFFICIENT_STORAGE')) {
          errorMessage = 'Insufficient storage on device';
        } else if (errorMessage.contains('INSTALL_FAILED_ALREADY_EXISTS')) {
          errorMessage = 'App already installed';
        } else if (errorMessage.contains('device') &&
            errorMessage.contains('not found')) {
          errorMessage = 'Device not found';
        } else if (errorMessage.contains('Failed to install APK:')) {
          // Keep only the part after "Failed to install APK:"
          errorMessage = errorMessage
              .substring(errorMessage.indexOf('Failed to install APK:') + 22)
              .trim();
        }

        emit(
          state.copyWith(
            status: ApkInspectorStatus.error,
            errorMessage: errorMessage,
          ),
        );

        // Reset to ready state after 3 seconds to show the install button again
        await Future.delayed(const Duration(seconds: 3));
        if (!emit.isDone && state.status == ApkInspectorStatus.error) {
          emit(
            state.copyWith(
              status: ApkInspectorStatus.ready,
              errorMessage: null,
            ),
          );
        }
      }
    }
  }

  Future<void> _onLoadRecentApks(
    OnLoadRecentApks event,
    Emitter<ApkInspectorState> emit,
  ) async {
    _logger.d('Loading recent APKs');

    try {
      final recentApks = await _getRecentApksUsecase();
      emit(state.copyWith(recentApks: recentApks));
      _logger.d('Loaded ${recentApks.length} recent APKs');
    } catch (e, stackTrace) {
      _logger.e('Error loading recent APKs', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _onSelectRecentApk(
    OnSelectRecentApk event,
    Emitter<ApkInspectorState> emit,
  ) async {
    _logger.i('Selected recent APK: ${event.apkPath}');

    add(OnSelectApkFile(apkPath: event.apkPath));
  }

  Future<void> _onScreenAppearing(
    OnScreenAppearing event,
    Emitter<ApkInspectorState> emit,
  ) async {
    await emit.onEach<DeviceEntity?>(
      _listenSelectedDeviceUsecase(),
      onData: (device) {
        emit(state.copyWith(selectedDevice: device));
        _logger.d('Selected device updated: ${device?.deviceId ?? "none"}');
      },
    );
  }
}
