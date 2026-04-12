import 'dart:io';

import 'package:android_tools/features/screenshot/domain/entities/screenshot_entity.dart';
import 'package:android_tools/features/screenshot/domain/usecases/copy_screenshot_usecase.dart';
import 'package:android_tools/features/screenshot/domain/usecases/save_screenshot_usecase.dart';
import 'package:android_tools/features/screenshot/domain/usecases/take_screenshot_usecase.dart';
import 'package:android_tools/main.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

part 'screenshot_preview_event.dart';
part 'screenshot_preview_state.dart';
part 'screenshot_preview_bloc.mapper.dart';

class ScreenshotPreviewBloc
    extends Bloc<ScreenshotPreviewEvent, ScreenshotPreviewState> {
  final Logger _logger = getIt.get();
  final TakeScreenshotUsecase _takeScreenshotUsecase = getIt.get();
  final SaveScreenshotUsecase _saveScreenshotUsecase = getIt.get();
  final CopyScreenshotUsecase _copyScreenshotUsecase = getIt.get();

  ScreenshotPreviewBloc({
    ScreenshotEntity? screenshot,
    DeviceEntity? device,
  }) : super(
          ScreenshotPreviewState(
            screenshot: screenshot,
            device: device,
            status: screenshot != null
                ? ScreenshotStatus.success
                : ScreenshotStatus.idle,
          ),
        ) {
    on<OnCaptureScreenshot>(_onCaptureScreenshot);
    on<OnResetState>(_onResetState);
    on<OnSaveScreenshot>((event, emit) async {
      if (state.screenshot == null) return;

      try {
        // Open save dialog
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Screenshot',
          fileName:
              'screenshot_${state.screenshot!.timestamp.millisecondsSinceEpoch}.png',
          type: FileType.custom,
          allowedExtensions: ['png'],
        );

        if (result == null) {
          _logger.i('Save cancelled by user');
          return;
        }

        emit(state.copyWith(status: ScreenshotStatus.loading));

        await _saveScreenshotUsecase(state.screenshot!.filePath, result);

        emit(state.copyWith(
          status: ScreenshotStatus.success,
          successMessage: 'Screenshot saved successfully',
        ));

        // Delete temp file after successful save
        await _deleteScreenshotFile();
      } catch (e, stackTrace) {
        _logger.e('Error saving screenshot', error: e, stackTrace: stackTrace);
        emit(state.copyWith(
          status: ScreenshotStatus.error,
          errorMessage: 'Failed to save screenshot: $e',
        ));
      }
    });

    on<OnCopyToClipboard>((event, emit) async {
      if (state.screenshot == null) return;

      try {
        emit(state.copyWith(status: ScreenshotStatus.loading));

        await _copyScreenshotUsecase(state.screenshot!.filePath);

        emit(state.copyWith(
          status: ScreenshotStatus.success,
          successMessage: 'Screenshot copied to clipboard',
        ));

        // Delete temp file after successful copy
        await _deleteScreenshotFile();
      } catch (e, stackTrace) {
        _logger.e(
          'Error copying to clipboard',
          error: e,
          stackTrace: stackTrace,
        );
        emit(state.copyWith(
          status: ScreenshotStatus.error,
          errorMessage: 'Failed to copy screenshot: $e',
        ));
      }
    });

    on<OnDeleteScreenshot>((event, emit) async {
      await _deleteScreenshotFile();
      emit(state.copyWith(
        status: ScreenshotStatus.idle,
      ));
    });
  }

  Future<void> _onCaptureScreenshot(
    OnCaptureScreenshot event,
    Emitter<ScreenshotPreviewState> emit,
  ) async {
    try {
      _logger.i('Starting screenshot capture for device: ${event.deviceId}');

      emit(state.copyWith(
        status: ScreenshotStatus.capturing,
        device: event.device,
      ));

      final screenshot = await _takeScreenshotUsecase(event.deviceId);

      _logger.i('Screenshot captured successfully');

      emit(state.copyWith(
        status: ScreenshotStatus.success,
        screenshot: screenshot,
      ));
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to capture screenshot',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        status: ScreenshotStatus.error,
        errorMessage: 'Failed to capture screenshot: $e',
      ));
    }
  }

  void _onResetState(
    OnResetState event,
    Emitter<ScreenshotPreviewState> emit,
  ) {
    emit(const ScreenshotPreviewState(status: ScreenshotStatus.idle));
  }

  Future<void> _deleteScreenshotFile() async {
    if (state.screenshot == null) return;

    try {
      final file = File(state.screenshot!.filePath);
      if (await file.exists()) {
        await file.delete();
        _logger.i('Deleted temp screenshot file');
      }
    } catch (e) {
      _logger.w('Failed to delete screenshot file: $e');
    }
  }
}
