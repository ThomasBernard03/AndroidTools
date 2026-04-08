part of 'settings_bloc.dart';

@MappableClass()
class SettingsState with SettingsStateMappable {
  final int maxHistorySize;
  final ThemeMode themeMode;

  SettingsState({
    this.maxHistorySize = 10,
    this.themeMode = ThemeMode.system,
  });
}
