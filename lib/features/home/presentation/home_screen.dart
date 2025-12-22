import 'package:android_tools/features/file_explorer/presentation/file_explorer_screen.dart';
import 'package:android_tools/features/home/presentation/home_bloc.dart';
import 'package:android_tools/features/home/presentation/widgets/navigation_rail_item.dart';
import 'package:android_tools/features/information/presentation/information_screen.dart';
import 'package:android_tools/features/logcat/presentation/logcat_screen.dart';
import 'package:android_tools/features/settings/presentation/settings_screen.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _homeBloc = HomeBloc();
  int _selectedIndex = 0;

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
                child: AppBar(
                  actionsPadding: EdgeInsets.only(right: 10),
                  titleSpacing: 90,
                  title: Row(
                    children: [
                      BlocBuilder<HomeBloc, HomeState>(
                        builder: (context, state) {
                          return SizedBox(
                            width: 250,
                            child: DropdownButton(
                              icon: null,
                              underline: SizedBox.shrink(),
                              value: state.selectedDevice,
                              items: state.devices.map((device) {
                                return DropdownMenuItem(
                                  value: device,
                                  child: Text(device.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                context.read<HomeBloc>().add(
                                  OnDeviceSelected(device: value),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      IconButton(
                        onPressed: () =>
                            context.read<HomeBloc>().add(OnRefreshDevices()),
                        icon: Icon(Icons.refresh),
                      ),
                      VerticalDivider(),
                    ],
                  ),
                  actions: [
                    Text(state.version),
                    VerticalDivider(),
                    IconButton(
                      onPressed: () => {
                        setState(() {
                          _selectedIndex = 3;
                        }),
                      },
                      icon: Icon(Icons.settings),
                    ),
                  ],
                ),
              ),
            ),
            body: Row(
              children: [
                SizedBox(
                  width: 250,
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    child: Column(
                      children: [
                        NavigationRailItem(
                          selected: _selectedIndex == 0,
                          icon: Icons.info,
                          text: "Device information",
                          onTap: () => setState(() {
                            _selectedIndex = 0;
                          }),
                        ),
                        NavigationRailItem(
                          selected: _selectedIndex == 1,
                          icon: Icons.pets,
                          text: "Logcat",
                          onTap: () => setState(() {
                            _selectedIndex = 1;
                          }),
                        ),
                        NavigationRailItem(
                          selected: _selectedIndex == 2,
                          icon: Icons.folder,
                          text: "File explorer",
                          onTap: () => setState(() {
                            _selectedIndex = 2;
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: switch (_selectedIndex) {
                    0 => InformationScreen(),
                    1 => LogcatScreen(),
                    2 => FileExplorerScreen(),
                    3 => SettingsScreen(),
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
