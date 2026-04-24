import 'package:android_tools/features/settings/presentation/settings_bloc.dart';
import 'package:android_tools/main.dart';

class SettingsModule {
  static void configureDependencies() {
    getIt.registerFactory(() => SettingsBloc());
  }
}
