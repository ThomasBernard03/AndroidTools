import 'package:android_tools/features/screenshot/presentation/screenshot_preview_bloc.dart';
import 'package:android_tools/features/screenshot/presentation/screenshot_preview_screen.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CaptureScreen extends StatefulWidget {
  final DeviceEntity? device;
  const CaptureScreen({super.key, this.device});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  late final ScreenshotPreviewBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = ScreenshotPreviewBloc();
  }

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
          if (state.status == ScreenshotStatus.success &&
              state.screenshot != null &&
              context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScreenshotPreviewScreen(
                  screenshot: state.screenshot!,
                  device: state.device!,
                ),
              ),
            );
            _bloc.add(OnResetState());
          }
          if (state.status == ScreenshotStatus.error &&
              state.errorMessage != null &&
              context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
            _bloc.add(OnResetState());
          }
        },
        builder: (context, captureState) {
          final device = widget.device;
          final isCapturing = captureState.status == ScreenshotStatus.capturing;

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 16,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        Text(
                          "Capture",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          device == null
                              ? "No device connected"
                              : "Capture a screenshot of ${device.name}",
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        FilledButton.icon(
                          onPressed: device != null && !isCapturing
                              ? () {
                                  context.read<ScreenshotPreviewBloc>().add(
                                    OnCaptureScreenshot(
                                      deviceId: device.deviceId,
                                      device: device,
                                    ),
                                  );
                                }
                              : null,
                          icon: isCapturing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.photo_camera_outlined),
                          label: Text(
                            isCapturing ? "Capturing…" : "Take Screenshot",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
