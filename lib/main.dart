import 'package:android_tools/features/file_explorer/core/fileexplorer_module.dart';
import 'package:android_tools/features/home/presentation/home_screen.dart';
import 'package:android_tools/features/information/core/information_module.dart';
import 'package:android_tools/features/logcat/core/logcat_module.dart';
import 'package:android_tools/shared/core/constants.dart';
import 'package:android_tools/shared/core/shared_module.dart';
import 'package:android_tools/shared/core/string_extensions.dart';
import 'package:android_tools/shared/presentation/themes.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final getIt = GetIt.instance;

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  LogcatModule.configureDependencies();
  SharedModule.configureDependencies();
  InformationModule.configureDependencies();
  FileExplorerModule.configureDependencies();
  await getIt.allReady();
  // await windowManager.ensureInitialized();
  // final wm = WindowManager.instance;
  // await wm.setTitleBarStyle(TitleBarStyle.hidden);
  const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  final logger = await getIt.getAsync<Logger>();

  logger.i("==== Starting application ====");

  if (sentryDsn.isEmpty) {
    logger.w(
      "${Constants.environmentSentryDsn} not found from environment, launch project with '--dart-define=${Constants.environmentSentryDsn}=your_sentry_dsn'",
    );
  } else {
    logger.i(
      "${Constants.environmentSentryDsn} found : ${sentryDsn.anonymize()}",
    );
  }

  await SentryFlutter.init((options) {
    options.dsn = sentryDsn;
    options.enableLogs = true;
    options.replay.sessionSampleRate = 0.1;
    options.replay.onErrorSampleRate = 1.0;
  }, appRunner: () => runApp(SentryWidget(child: MyApp())));

  doWhenWindowReady(() {
    appWindow.minSize = Size(600, 450);
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: Themes.lightTheme,
      darkTheme: Themes.darkTheme,
      home: HomeScreen(),
    );
  }
}
