import 'package:android_tools/features/fileexplorer/core/fileexplorer_module.dart';
import 'package:android_tools/features/fileexplorer/presentation/file_explorer_screen.dart';
import 'package:android_tools/features/logcat/core/logcat_module.dart';
import 'package:android_tools/shared/core/shared_module.dart';
import 'package:android_tools/features/logcat/presentation/logcat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void main() {
  LogcatModule.configureDependencies();
  SharedModule.configureDependencies();
  FileExplorerModule.configureDependencies();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(255, 19, 82, 210),
        ),
      ),
      home: Row(
        children: [
          NavigationRail(
            extended: true,
            onDestinationSelected: (value) {
              setState(() {
                _selectedIndex = value;
              });
            },
            destinations: <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.info_outline),
                label: Text('Device information'),
              ),
              NavigationRailDestination(
                icon: SvgPicture.asset(
                  width: 25,
                  'assets/logcat.svg',
                  semanticsLabel: 'Logcat Logo',
                ),
                label: Text('Logcat'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.folder_open),
                label: Text('File explorer'),
              ),
            ],
            selectedIndex: _selectedIndex,
          ),
          Expanded(
            child: switch (_selectedIndex) {
              1 => LogcatScreen(),
              2 => FileExplorerScreen(),
              _ => Placeholder(),
            },
          ),
        ],
      ),
    );
  }
}
