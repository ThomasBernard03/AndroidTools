import 'package:android_tools/features/apk_inspector/core/apk_inspector_module.dart';
import 'package:android_tools/features/application_installer/core/application_installer_module.dart';
import 'package:android_tools/features/file_explorer/core/file_explorer_module.dart';
import 'package:android_tools/features/home/core/home_module.dart';
import 'package:android_tools/features/home/presentation/home_screen.dart';
import 'package:android_tools/features/information/core/information_module.dart';
import 'package:android_tools/features/logcat/core/logcat_module.dart';
import 'package:android_tools/features/screenshot/core/screenshot_module.dart';
import 'package:android_tools/features/settings/core/settings_module.dart';
import 'package:android_tools/features/settings/presentation/settings_bloc.dart';
import 'package:android_tools/shared/core/constants.dart';
import 'package:android_tools/shared/core/shared_module.dart';
import 'package:android_tools/shared/core/string_extensions.dart';
import 'package:android_tools/shared/domain/helpers/settings_helper.dart';
import 'package:android_tools/shared/presentation/themes.dart';
import 'package:auto_updater/auto_updater.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  ScreenshotModule.configureDependencies();
  ApkInspectorModule.configureDependencies();
  HomeModule.configureDependencies();
  SettingsModule.configureDependencies();
  ApplicationInstallerModule.configureDependencies();
  await getIt.allReady();
  final logger = await getIt.getAsync<Logger>();
  final settingsHelper = getIt.get<SettingsHelper>();
  logger.i("==== Starting application ====");

  // Load crash reporting preference early
  final crashReportingDisabled = await settingsHelper
      .getCrashReportingDisabled();
  logger.i(
    "Crash reporting ${crashReportingDisabled ? 'disabled' : 'enabled'} by user preference",
  );

  const sentryDsn = String.fromEnvironment(
    Constants.environmentSentryDsn,
    defaultValue: '',
  );
  if (sentryDsn.isEmpty) {
    logger.w(
      "${Constants.environmentSentryDsn} not found from environment, launch project with '--dart-define=${Constants.environmentSentryDsn}=your_sentry_dsn'",
    );
  } else {
    logger.i(
      "${Constants.environmentSentryDsn} found: ${sentryDsn.anonymize()}",
    );
  }

  const autoUpdaterFeedUrl = String.fromEnvironment(
    Constants.environmentAutoUpdaterFeedUrl,
    defaultValue: '',
  );
  if (autoUpdaterFeedUrl.isEmpty) {
    logger.w(
      "${Constants.environmentAutoUpdaterFeedUrl} not found from environment, launch project with '--dart-define=${Constants.environmentAutoUpdaterFeedUrl}=your_feed_url'",
    );
  } else {
    logger.i(
      "${Constants.environmentAutoUpdaterFeedUrl} found: ${autoUpdaterFeedUrl.anonymize()}",
    );
    try {
      await autoUpdater.setFeedURL(autoUpdaterFeedUrl);
      await autoUpdater.checkForUpdates(inBackground: true);
    } catch (e) {
      logger.w("Error with autoUpdater: $e");
    }
  }

  // Conditionally initialize Sentry based on user preference
  if (!crashReportingDisabled && sentryDsn.isNotEmpty) {
    logger.i("Initializing Sentry for crash reporting");
    await SentryFlutter.init((options) {
      options.dsn = sentryDsn;
      options.enableLogs = true;
      options.replay.sessionSampleRate = 0.1;
      options.replay.onErrorSampleRate = 1.0;
    }, appRunner: () => runApp(SentryWidget(child: MyApp())));
  } else {
    if (crashReportingDisabled) {
      logger.i(
        "Skipping Sentry initialization - crash reporting disabled by user",
      );
    }
    runApp(MyApp());
  }

  doWhenWindowReady(() {
    appWindow.minSize = Size(800, 50);
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SettingsBloc>()..add(OnLoadThemeMode()),
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Android Tools',
            theme: Themes.lightTheme,
            darkTheme: Themes.darkTheme,
            themeMode: state.themeMode,
            home: HomeScreen(),
          );
        },
      ),
    );
  }
}
