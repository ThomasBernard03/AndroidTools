import 'dart:async';

import 'package:android_tools/features/apk_inspector/domain/entities/apk_info.dart';
import 'package:android_tools/features/apk_inspector/domain/usecases/get_recent_apks_usecase.dart';
import 'package:android_tools/features/apk_inspector/domain/usecases/install_apk_usecase.dart';
import 'package:android_tools/features/apk_inspector/domain/usecases/parse_apk_usecase.dart';
import 'package:android_tools/features/apk_inspector/domain/usecases/save_recent_apk_usecase.dart';
import 'package:android_tools/main.dart';
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
  final Logger _logger = getIt.get();

  ApkInspectorBloc() : super(ApkInspectorState.initial()) {
    on<OnSelectApkFile>(_onSelectApkFile);
    on<OnResetView>(_onResetView);
    on<OnInstallApk>(_onInstallApk);
    on<OnLoadRecentApks>(_onLoadRecentApks);
    on<OnSelectRecentApk>(_onSelectRecentApk);

    add(OnLoadRecentApks());
  }

  Future<void> _onSelectApkFile(
    OnSelectApkFile event,
    Emitter<ApkInspectorState> emit,
  ) async {
    _logger.i('Selected APK file: ${event.apkPath}');

    // Start parsing
    emit(state.copyWith(
      status: ApkInspectorStatus.parsing,
      progress: 0.0,
      errorMessage: null,
    ));

    try {
      // Simulate progress updates for better UX
      final progressTimer = Timer.periodic(
        const Duration(milliseconds: 150),
        (timer) {
          if (state.progress < 0.9) {
            emit(state.copyWith(progress: state.progress + 0.1));
          }
        },
      );

      // Parse the APK
      final apkInfo = await _parseApkUsecase(event.apkPath);

      // Cancel progress timer
      progressTimer.cancel();

      // Emit ready state with parsed info
      emit(state.copyWith(
        status: ApkInspectorStatus.ready,
        apkInfo: apkInfo,
        progress: 1.0,
      ));

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

      emit(state.copyWith(
        status: ApkInspectorStatus.error,
        errorMessage: 'Failed to parse APK: ${e.toString()}',
        progress: 0.0,
      ));
    }
  }

  void _onResetView(
    OnResetView event,
    Emitter<ApkInspectorState> emit,
  ) {
    _logger.i('Resetting APK Inspector view');

    emit(state.copyWith(
      status: ApkInspectorStatus.idle,
      apkInfo: null,
      progress: 0.0,
      errorMessage: null,
    ));
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

    emit(state.copyWith(
      status: ApkInspectorStatus.installing,
      progress: 0.0,
    ));

    try {
      // Simulate progress for installation
      final progressTimer = Timer.periodic(
        const Duration(milliseconds: 200),
        (timer) {
          if (state.progress < 0.9) {
            emit(state.copyWith(progress: state.progress + 0.08));
          }
        },
      );

      // Install the APK
      await _installApkUsecase(state.apkInfo!.filePath, event.deviceId);

      // Cancel progress timer
      progressTimer.cancel();

      emit(state.copyWith(
        status: ApkInspectorStatus.installed,
        progress: 1.0,
      ));

      _logger.i('APK installed successfully');
    } catch (e, stackTrace) {
      _logger.e('Error installing APK', error: e, stackTrace: stackTrace);

      emit(state.copyWith(
        status: ApkInspectorStatus.error,
        errorMessage: 'Failed to install APK: ${e.toString()}',
        progress: 0.0,
      ));
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
}
