import 'package:android_tools/features/screenshot/presentation/screenshot_preview_bloc.dart';
import 'package:android_tools/features/screenshot/presentation/screenshot_preview_screen.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/shared/presentation/widgets/action_button.dart';
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
  final _bloc = ScreenshotPreviewBloc();

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<ScreenshotPreviewBloc, ScreenshotPreviewState>(
        listener: (context, state) {
          // Handle success state - navigate to preview
          if (state.status == ScreenshotStatus.success &&
              state.screenshot != null) {
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScreenshotPreviewScreen(
                    screenshot: state.screenshot!,
                    device: state.device!,
                  ),
                ),
              );

              // Reset state after navigation
              _bloc.add(OnResetState());
            }
          }

          // Handle error state - show error message
          if (state.status == ScreenshotStatus.error) {
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
          final isCapturing = state.status == ScreenshotStatus.capturing;

          return ActionButton(
            onPressed: widget.device != null
                ? () {
                    context.read<ScreenshotPreviewBloc>().add(
                      OnCaptureScreenshot(
                        deviceId: widget.device!.deviceId,
                        device: widget.device!,
                      ),
                    );
                  }
                : null,
            icon: Icons.photo_camera_outlined,
            label: 'Screenshot',
            isLoading: isCapturing,
            loadingLabel: 'Capturing…',
          );
        },
      ),
    );
  }
}
