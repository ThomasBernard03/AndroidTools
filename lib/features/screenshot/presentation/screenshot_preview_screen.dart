import 'package:android_tools/features/screenshot/domain/entities/screenshot_entity.dart';
import 'package:android_tools/features/screenshot/presentation/screenshot_preview_bloc.dart';
import 'package:android_tools/features/screenshot/presentation/widgets/screenshot_action_button.dart';
import 'package:android_tools/features/screenshot/presentation/widgets/screenshot_preview_widget.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ScreenshotPreviewScreen extends StatelessWidget {
  final ScreenshotEntity screenshot;
  final DeviceEntity device;

  const ScreenshotPreviewScreen({
    super.key,
    required this.screenshot,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScreenshotPreviewBloc(
        screenshot: screenshot,
        device: device,
      ),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: MoveWindow(
            child: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'Screenshot - ${device.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ),
        body: BlocConsumer<ScreenshotPreviewBloc, ScreenshotPreviewState>(
          listener: (context, state) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: Colors.green,
                ),
              );
            }
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == ScreenshotStatus.loading) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ScreenshotPreviewWidget(
                    imagePath: state.screenshot.filePath,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Size: ${state.screenshot.width} x ${state.screenshot.height}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Captured: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(state.screenshot.timestamp)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Divider(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(60),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 16,
                        children: [
                          ScreenshotActionButton(
                            icon: Icons.save,
                            text: 'Save As',
                            onPressed: () {
                              context
                                  .read<ScreenshotPreviewBloc>()
                                  .add(OnSaveScreenshot());
                            },
                          ),
                          ScreenshotActionButton(
                            icon: Icons.copy,
                            text: 'Copy',
                            onPressed: () {
                              context
                                  .read<ScreenshotPreviewBloc>()
                                  .add(OnCopyToClipboard());
                            },
                          ),
                          ScreenshotActionButton(
                            icon: Icons.delete,
                            text: 'Delete',
                            onPressed: () {
                              context
                                  .read<ScreenshotPreviewBloc>()
                                  .add(OnDeleteScreenshot());
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
