import 'package:android_tools/features/screenshot/domain/entities/screenshot_entity.dart';
import 'package:android_tools/features/screenshot/domain/usecases/take_screenshot_usecase.dart';
import 'package:android_tools/main.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

part 'screenshot_capture_event.dart';
part 'screenshot_capture_state.dart';
part 'screenshot_capture_bloc.mapper.dart';

class ScreenshotCaptureBloc
    extends Bloc<ScreenshotCaptureEvent, ScreenshotCaptureState> {
  final Logger _logger = getIt.get();
  final TakeScreenshotUsecase _takeScreenshotUsecase = getIt.get();

  ScreenshotCaptureBloc()
      : super(
          const ScreenshotCaptureState(status: ScreenshotCaptureStatus.idle),
        ) {
    on<OnCaptureScreenshot>(_onCaptureScreenshot);
    on<OnResetState>(_onResetState);
  }

  Future<void> _onCaptureScreenshot(
    OnCaptureScreenshot event,
    Emitter<ScreenshotCaptureState> emit,
  ) async {
    try {
      _logger.i('Starting screenshot capture for device: ${event.deviceId}');

      emit(
        const ScreenshotCaptureState(status: ScreenshotCaptureStatus.capturing),
      );

      final screenshot = await _takeScreenshotUsecase(event.deviceId);

      _logger.i('Screenshot captured successfully');

      emit(
        ScreenshotCaptureState(
          status: ScreenshotCaptureStatus.success,
          screenshot: screenshot,
        ),
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to capture screenshot',
        error: e,
        stackTrace: stackTrace,
      );

      emit(
        ScreenshotCaptureState(
          status: ScreenshotCaptureStatus.error,
          errorMessage: 'Failed to capture screenshot: $e',
        ),
      );
    }
  }

  void _onResetState(
    OnResetState event,
    Emitter<ScreenshotCaptureState> emit,
  ) {
    emit(const ScreenshotCaptureState(status: ScreenshotCaptureStatus.idle));
  }
}
