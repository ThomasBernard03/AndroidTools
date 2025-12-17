import 'package:android_tools/features/fileexplorer/core/fileexplorer_module.dart';
import 'package:android_tools/features/fileexplorer/presentation/file_explorer_screen.dart';
import 'package:android_tools/features/logcat/core/logcat_module.dart';
import 'package:android_tools/shared/core/shared_module.dart';
import 'package:android_tools/features/logcat/presentation/logcat_screen.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/shared/domain/usecases/listen_connected_devices_usecase.dart';
import 'package:android_tools/shared/domain/usecases/refresh_connected_devices_usecase.dart';
import 'package:android_tools/shared/domain/usecases/set_selected_device_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final getIt = GetIt.instance;

Future<void> main() async {
  LogcatModule.configureDependencies();
  SharedModule.configureDependencies();
  FileExplorerModule.configureDependencies();

  const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

  if (sentryDsn.isEmpty) {
    final logger = getIt.get<Logger>();
    logger.w(
      "sentryDsn not found from environment, launch project with '--dart-define=SENTRY_DSN=your_sentry_dsn'",
    );
  }

  await SentryFlutter.init((options) {
    options.dsn = sentryDsn;
    options.enableLogs = true;
    options.replay.sessionSampleRate = 0.1;
    options.replay.onErrorSampleRate = 1.0;
  }, appRunner: () => runApp(SentryWidget(child: MyApp())));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ListenConnectedDevicesUsecase _listenConnectedDevicesUsecase = getIt
      .get();
  final SetSelectedDeviceUsecase _setSelectedDeviceUsecase = getIt.get();
  final RefreshConnectedDevicesUsecase _refreshConnectedDevicesUsecase = getIt
      .get();
  Iterable<DeviceEntity> devices = const [];
  DeviceEntity? selectedDevice;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _refreshConnectedDevicesUsecase();
  }

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
            leading: Column(
              children: [
                StreamBuilder<List<DeviceEntity>>(
                  stream: _listenConnectedDevicesUsecase(),
                  builder: (context, snapshot) {
                    final devices = snapshot.data ?? [];

                    if (devices.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("No device connected"),
                      );
                    }

                    return DropdownButton<DeviceEntity>(
                      value: selectedDevice,
                      elevation: 16,
                      onChanged: (DeviceEntity? value) {
                        if (value == null || value == selectedDevice) {
                          return;
                        }

                        setState(() {
                          selectedDevice = value;
                        });

                        _setSelectedDeviceUsecase(value);
                      },
                      items: devices.map((device) {
                        return DropdownMenuItem<DeviceEntity>(
                          value: device,
                          child: Row(
                            spacing: 8,
                            children: [
                              const Icon(Icons.mobile_friendly, size: 16),
                              Text(device.name),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
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
