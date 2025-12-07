import 'package:android_tools/data/repositories/logcat_repository_impl.dart';
import 'package:android_tools/domain/repositories/logcat_repository.dart';
import 'package:android_tools/domain/usecases/logcat/clear_logcat_usecase.dart';
import 'package:android_tools/domain/usecases/logcat/listen_logcat_usecase.dart';
import 'package:android_tools/presentation/logcat/logcat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerSingleton<LogcatRepository>(LogcatRepositoryImpl());
  getIt.registerSingleton<Logger>(Logger());

  getIt.registerSingleton<ListenLogcatUsecase>(
    ListenLogcatUsecase(logcatRepository: getIt.get()),
  );
  getIt.registerSingleton<ClearLogcatUsecase>(
    ClearLogcatUsecase(logcatRepository: getIt.get()),
  );
}

void main() {
  configureDependencies();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({super.key});

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
              _ => Placeholder(),
            },
          ),
        ],
      ),
    );
  }
}
