import 'package:android_tools/features/screenshot/presentation/screenshot_preview_bloc.dart';
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
          final primary = Theme.of(context).colorScheme.primary;

          return OutlinedButton.icon(
            onPressed: widget.device != null && !isCapturing
                ? () {
                    context.read<ScreenshotPreviewBloc>().add(
                      OnCaptureScreenshot(
                        deviceId: widget.device!.deviceId,
                        device: widget.device!,
                      ),
                    );
                  }
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: primary.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            icon: isCapturing
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primary,
                    ),
                  )
                : const Icon(Icons.photo_camera_outlined, size: 15),
            label: Text(isCapturing ? 'Capturing…' : 'Screenshot'),
          );
        },
      ),
    );
  }
}
