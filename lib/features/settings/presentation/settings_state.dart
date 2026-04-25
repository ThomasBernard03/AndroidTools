part of 'settings_bloc.dart';

@MappableClass()
class SettingsState with SettingsStateMappable {
  final ThemeMode themeMode;
  final bool crashReportingDisabled;

  SettingsState({
    this.themeMode = ThemeMode.system,
    this.crashReportingDisabled = false,
  });
}
