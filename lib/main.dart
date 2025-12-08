import 'package:android_tools/data/datasources/shell/shell_datasource.dart';
import 'package:android_tools/data/repositories/device_repository_impl.dart';
import 'package:android_tools/features/logcat/data/repositories/logcat_repository_impl.dart';
import 'package:android_tools/domain/repositories/device_repository.dart';
import 'package:android_tools/features/logcat/domain/repositories/logcat_repository.dart';
import 'package:android_tools/domain/usecases/device/get_connected_devices_usecase.dart';
import 'package:android_tools/domain/usecases/logcat/clear_logcat_usecase.dart';
import 'package:android_tools/domain/usecases/logcat/listen_logcat_usecase.dart';
import 'package:android_tools/features/logcat/presentation/logcat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerLazySingleton<Logger>(() => Logger());
  getIt.registerLazySingleton<ShellDatasource>(() => ShellDatasource());

  getIt.registerLazySingleton<LogcatRepository>(
    () =>
        LogcatRepositoryImpl(logger: getIt.get(), shellDatasource: getIt.get()),
  );
  getIt.registerLazySingleton<DeviceRepository>(
    () =>
        DeviceRepositoryImpl(logger: getIt.get(), shellDatasource: getIt.get()),
  );

  getIt.registerLazySingleton(
    () => ListenLogcatUsecase(logcatRepository: getIt.get()),
  );
  getIt.registerLazySingleton(
    () => ClearLogcatUsecase(logcatRepository: getIt.get()),
  );
  getIt.registerLazySingleton(
    () => GetConnectedDevicesUsecase(deviceRepository: getIt.get()),
  );
}

void main() {
  configureDependencies();
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
