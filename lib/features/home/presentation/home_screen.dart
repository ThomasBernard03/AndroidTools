import 'package:android_tools/features/file_explorer/presentation/file_explorer_screen.dart';
import 'package:android_tools/features/home/presentation/home_bloc.dart';
import 'package:android_tools/features/information/presentation/information_screen.dart';
import 'package:android_tools/features/logcat/presentation/logcat_screen.dart';
import 'package:android_tools/features/settings/presentation/settings_screen.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

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
      child: Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                trailingAtBottom: true,
                labelType: NavigationRailLabelType.all,
                leading: BlocBuilder<HomeBloc, HomeState>(
                  builder: (context, state) {
                    return Row(
                      children: [
                        Column(
                          children: [
                            state.devices.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text("No device connected"),
                                  )
                                : DropdownButton<DeviceEntity>(
                                    value: state.selectedDevice,
                                    elevation: 16,
                                    onChanged: (DeviceEntity? value) {
                                      if (value == null ||
                                          value == state.selectedDevice) {
                                        return;
                                      }
                                      context.read<HomeBloc>().add(
                                        OnDeviceSelected(device: value),
                                      );
                                    },
                                    items: state.devices.map((device) {
                                      return DropdownMenuItem<DeviceEntity>(
                                        value: device,
                                        child: Row(
                                          spacing: 8,
                                          children: [
                                            const Icon(
                                              Icons.mobile_friendly,
                                              size: 16,
                                            ),
                                            Text(device.name),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ],
                        ),
                        IconButton(
                          onPressed: () =>
                              context.read<HomeBloc>().add(OnRefreshDevices()),
                          icon: Icon(Icons.refresh),
                        ),
                      ],
                    );
                  },
                ),
                onDestinationSelected: (value) {
                  setState(() {
                    _selectedIndex = value;
                  });
                },
                destinations: <NavigationRailDestination>[
                  NavigationRailDestination(
                    icon: Icon(Icons.info_outline),
                    selectedIcon: Icon(Icons.info),
                    label: Text('Device information'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.pets),
                    selectedIcon: Icon(Icons.pets),
                    label: Text('Logcat'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.folder_outlined),
                    selectedIcon: Icon(Icons.folder_rounded),
                    label: Text('File explorer'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: Text('Settings'),
                  ),
                ],
                selectedIndex: _selectedIndex,
                trailing: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: BlocBuilder<HomeBloc, HomeState>(
                    builder: (context, state) {
                      return Text(state.version);
                    },
                  ),
                ),
              ),
              VerticalDivider(),
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
        ),
      ),
    );
  }
}
