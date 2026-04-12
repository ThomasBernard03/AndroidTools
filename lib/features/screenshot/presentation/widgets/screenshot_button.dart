import 'package:android_tools/features/screenshot/presentation/screenshot_capture_bloc.dart';
import 'package:android_tools/features/screenshot/presentation/screenshot_preview_screen.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScreenshotButton extends StatefulWidget {
  final DeviceEntity? device;

  const ScreenshotButton({
    super.key,
    required this.device,
  });

  @override
  State<ScreenshotButton> createState() => _ScreenshotButtonState();
}

class _ScreenshotButtonState extends State<ScreenshotButton> {
  final _bloc = ScreenshotCaptureBloc();

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<ScreenshotCaptureBloc, ScreenshotCaptureState>(
        listener: (context, state) {
          // Handle success state - navigate to preview
          if (state.status == ScreenshotCaptureStatus.success) {
            if (state.screenshot != null &&
                widget.device != null &&
                context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScreenshotPreviewScreen(
                    screenshot: state.screenshot!,
                    device: widget.device!,
                  ),
                ),
              );

              // Reset state after navigation
              _bloc.add(OnResetState());
            }
          }

          // Handle error state - show error message
          if (state.status == ScreenshotCaptureStatus.error) {
            if (state.errorMessage != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );

              // Reset state after showing error
              _bloc.add(OnResetState());
            }
          }
        },
        builder: (context, state) {
          final isCapturing = state.status == ScreenshotCaptureStatus.capturing;

          return IconButton(
            onPressed: widget.device != null && !isCapturing
                ? () {
                    context
                        .read<ScreenshotCaptureBloc>()
                        .add(OnCaptureScreenshot(widget.device!.deviceId));
                  }
                : null,
            icon: isCapturing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  )
                : const Icon(Icons.photo_camera_outlined),
          );
        },
      ),
    );
  }
}
