import 'package:android_tools/features/application_installer/presentation/application_installer_bloc.dart';
import 'package:android_tools/main.dart';

class ApplicationInstallerModule {
  static void configureDependencies() {
    getIt.registerFactory(() => ApplicationInstallerBloc());
  }
}
