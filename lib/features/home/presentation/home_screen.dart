import 'package:android_tools/features/apk_inspector/presentation/apk_inspector_screen.dart';
import 'package:android_tools/features/application_installer/presentation/application_installer_screen.dart';
import 'package:android_tools/features/file_explorer/presentation/file_explorer_screen.dart';
import 'package:android_tools/features/home/presentation/home_bloc.dart';
import 'package:android_tools/features/home/presentation/widgets/capture_screen.dart';
import 'package:android_tools/features/home/presentation/widgets/device_box.dart';
import 'package:android_tools/features/home/presentation/widgets/navigation_rail_item.dart';
import 'package:android_tools/features/information/presentation/information_screen.dart';
import 'package:android_tools/features/logcat/presentation/logcat_screen.dart';
import 'package:android_tools/features/settings/presentation/settings_screen.dart';
import 'package:android_tools/main.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _homeBloc = getIt<HomeBloc>();
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
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(kToolbarHeight),
              child: MoveWindow(
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                ),
              ),
            ),
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
                          DeviceBox(state: state),

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
                          const SizedBox(height: 2),
                          NavigationRailItem(
                            selected: _selectedIndex == 5,
                            text: "APK Inspector",
                            icon: Icons.inventory_2_outlined,
                            shortcut: "⌘6",
                            onTap: () => setState(() => _selectedIndex = 5),
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
                            selected: _selectedIndex == 6,
                            text: "Settings",
                            icon: Icons.settings_outlined,
                            onTap: () => setState(() => _selectedIndex = 6),
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
                    4 => CaptureScreen(device: state.selectedDevice),
                    5 => ApkInspectorScreen(),
                    6 => SettingsScreen(),
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
