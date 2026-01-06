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
                          children: [
                            SizedBox.fromSize(size: Size(0, 20)),
                            Text(
                              "Android Tools",
                              style: TextStyle(
                                fontFamily: 'Nothing',
                                fontSize: 18,
                              ),
                            ),
                            Divider(color: Color(0xFF484A4C)),
                            NavigationRailItem(
                              selected: _selectedIndex == 0,
                              icon: Icons.info_outline_rounded,
                              text: "Device information",
                              onTap: () => setState(() {
                                _selectedIndex = 0;
                              }),
                            ),
                            NavigationRailItem(
                              selected: _selectedIndex == 1,
                              icon: Icons.heart_broken_outlined,
                              text: "Logcat",
                              onTap: () => setState(() {
                                _selectedIndex = 1;
                              }),
                            ),
                            NavigationRailItem(
                              selected: _selectedIndex == 2,
                              icon: Icons.folder_outlined,
                              text: "File explorer",
                              onTap: () => setState(() {
                                _selectedIndex = 2;
                              }),
                            ),
                            NavigationRailItem(
                              selected: _selectedIndex == 4,
                              icon: Icons.phone_android_outlined,
                              text: "App File explorer",
                              onTap: () => setState(() {
                                _selectedIndex = 4;
                              }),
                            ),

                            Divider(),
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
