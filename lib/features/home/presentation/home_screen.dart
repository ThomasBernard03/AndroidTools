import 'package:android_tools/features/application_installer/presentation/application_installer_screen.dart';
import 'package:android_tools/features/file_explorer/presentation/file_explorer_screen.dart';
import 'package:android_tools/features/home/presentation/home_bloc.dart';
import 'package:android_tools/features/home/presentation/widgets/navigation_rail_item.dart';
import 'package:android_tools/features/information/presentation/information_screen.dart';
import 'package:android_tools/features/logcat/presentation/logcat_screen.dart';
import 'package:android_tools/features/screenshot/presentation/screenshot_preview_bloc.dart';
import 'package:android_tools/features/screenshot/presentation/screenshot_preview_screen.dart';
import 'package:android_tools/features/settings/presentation/settings_screen.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _homeBloc = HomeBloc();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _homeBloc.add(OnRefreshDevices());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homeBloc
        ..add(OnListenConnectedDevices())
        ..add(OnListenSelectedDevice())
        ..add(OnRefreshDevices())
        ..add(OnGetVersion()),
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 250,
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // Brand section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              spacing: 8,
                              children: [
                                Icon(
                                  Icons.android,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                Expanded(
                                  child: Text(
                                    "AndroidTools",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Text(
                                  state.version,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Device box
                          _DeviceBox(state: state),

                          const SizedBox(height: 16),

                          Divider(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainer,
                            height: 1,
                          ),

                          const SizedBox(height: 12),

                          // Navigation items
                          NavigationRailItem(
                            selected: _selectedIndex == 0,
                            text: "Device",
                            icon: Icons.memory_outlined,
                            shortcut: "⌘1",
                            onTap: () => setState(() => _selectedIndex = 0),
                          ),
                          const SizedBox(height: 2),
                          NavigationRailItem(
                            selected: _selectedIndex == 1,
                            text: "Apps",
                            icon: Icons.widgets_outlined,
                            shortcut: "⌘2",
                            onTap: () => setState(() => _selectedIndex = 1),
                          ),
                          const SizedBox(height: 2),
                          NavigationRailItem(
                            selected: _selectedIndex == 2,
                            text: "Logcat",
                            icon: Icons.terminal,
                            shortcut: "⌘3",
                            onTap: () => setState(() => _selectedIndex = 2),
                          ),
                          const SizedBox(height: 2),
                          NavigationRailItem(
                            selected: _selectedIndex == 3,
                            text: "Files",
                            icon: Icons.folder_outlined,
                            shortcut: "⌘4",
                            onTap: () => setState(() => _selectedIndex = 3),
                          ),
                          const SizedBox(height: 2),
                          NavigationRailItem(
                            selected: _selectedIndex == 4,
                            text: "Capture",
                            icon: Icons.camera_alt_outlined,
                            shortcut: "⌘5",
                            onTap: () => setState(() => _selectedIndex = 4),
                          ),

                          const Spacer(),

                          Divider(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainer,
                            height: 1,
                          ),
                          const SizedBox(height: 8),

                          NavigationRailItem(
                            selected: _selectedIndex == 5,
                            text: "Settings",
                            icon: Icons.settings_outlined,
                            onTap: () => setState(() => _selectedIndex = 5),
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: switch (_selectedIndex) {
                    0 => InformationScreen(),
                    1 => ApplicationInstallerScreen(),
                    2 => LogcatScreen(),
                    3 => FileExplorerScreen(),
                    4 => _CaptureScreen(device: state.selectedDevice),
                    5 => SettingsScreen(),
                    _ => Placeholder(),
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DeviceBox extends StatelessWidget {
  final HomeState state;
  const _DeviceBox({required this.state});

  @override
  Widget build(BuildContext context) {
    final hasDevice = state.selectedDevice != null;
    final devices = state.devices;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        spacing: 8,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasDevice ? const Color(0xFF4CAF50) : const Color(0xFF6B707A),
              boxShadow: hasDevice
                  ? [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
          ),
          Expanded(
            child: devices.isEmpty
                ? Text(
                    "No device",
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<DeviceEntity>(
                      isDense: true,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      value: state.selectedDevice,
                      items: devices
                          .map(
                            (device) => DropdownMenuItem<DeviceEntity>(
                              value: device,
                              child: Text(
                                device.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (device) {
                        if (device == null) return;
                        // Find HomeBloc in the widget tree
                        context.read<HomeBloc>().add(
                          OnDeviceSelected(device: device),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CaptureScreen extends StatefulWidget {
  final DeviceEntity? device;
  const _CaptureScreen({this.device});

  @override
  State<_CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<_CaptureScreen> {
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
