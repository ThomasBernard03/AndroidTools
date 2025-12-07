import 'package:android_tools/data/repositories/logcat_repository_impl.dart';
import 'package:android_tools/domain/repositories/logcat_repository.dart';
import 'package:android_tools/domain/usecases/logcat/clear_logcat_usecase.dart';
import 'package:android_tools/domain/usecases/logcat/listen_logcat_usecase.dart';
import 'package:android_tools/presentation/logcat/logcat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerSingleton<LogcatRepository>(LogcatRepositoryImpl());

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
            destinations: <NavigationRailDestination>[
              NavigationRailDestination(
                icon: SvgPicture.asset(
                  width: 20,
                  'assets/logcat.svg',
                  semanticsLabel: 'Dart Logo',
                ),
                label: Text('Logcat', style: TextStyle(color: Colors.black)),
              ),
            ],
            selectedIndex: _selectedIndex,
          ),
          Expanded(child: LogcatScreen()),
        ],
      ),
    );
  }
}
