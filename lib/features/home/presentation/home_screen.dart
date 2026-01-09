import 'package:android_tools/features/file_explorer/general_file_explorer/presentation/general_file_explorer_screen.dart';
import 'package:android_tools/features/file_explorer/package_file_explorer/presentation/package_file_explorer_screen.dart';
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
            body: Row(
              children: [
                MoveWindow(
                  child: SizedBox(
                    width: 250,
                    child: Container(
                      color: Color(0xFF181E25),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          spacing: 12,
                          children: [
                            SizedBox.fromSize(size: Size(0, 20)),
                            Text(
                              "Android Tools",
                              style: TextStyle(
                                fontFamily: 'Nothing',
                                fontSize: 18,
                              ),
                            ),
                            if (state.devices.isNotEmpty)
                              DropdownButtonFormField(
                                icon: Icon(Icons.keyboard_arrow_down),
                                style: Theme.of(context).textTheme.bodyMedium,
                                initialValue: state.selectedDevice,
                                items: state.devices
                                    .map(
                                      (device) => DropdownMenuItem(
                                        value: device,
                                        child: Text(device.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (device) {
                                  if (device == null) return;
                                  context.read<HomeBloc>().add(
                                    OnDeviceSelected(device: device),
                                  );
                                },
                                decoration: InputDecoration.collapsed(
                                  hintText: "",
                                ),
                              ),
                            NavigationRailItem(
                              selected: _selectedIndex == 0,
                              text: "Device information",
                              onTap: () => setState(() {
                                _selectedIndex = 0;
                              }),
                            ),
                            NavigationRailItem(
                              selected: _selectedIndex == 1,
                              text: "Logcat",
                              onTap: () => setState(() {
                                _selectedIndex = 1;
                              }),
                            ),
                            NavigationRailItem(
                              selected: _selectedIndex == 2,
                              text: "File explorer",
                              onTap: () => setState(() {
                                _selectedIndex = 2;
                              }),
                            ),
                            NavigationRailItem(
                              selected: _selectedIndex == 4,
                              text: "App File explorer",
                              onTap: () => setState(() {
                                _selectedIndex = 4;
                              }),
                            ),

                            Spacer(),

                            Divider(color: Color(0xFF484A4C)),

                            TextButton(
                              onPressed: () => setState(() {
                                _selectedIndex = 3;
                              }),
                              child: Text("Settings"),
                            ),

                            Text(
                              state.version,
                              style: TextStyle(fontFamily: "Nothing"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: switch (_selectedIndex) {
                    0 => InformationScreen(),
                    1 => LogcatScreen(),
                    2 => GeneralFileExplorerScreen(),
                    3 => SettingsScreen(),
                    4 => PackageFileExplorerScreen(),
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
