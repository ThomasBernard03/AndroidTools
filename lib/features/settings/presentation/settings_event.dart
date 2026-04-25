part of 'settings_bloc.dart';

sealed class SettingsEvent {}

class OnOpenLogDirectory extends SettingsEvent {}

class OnOpenGithubProject extends SettingsEvent {}

class OnCreateIssue extends SettingsEvent {}

class OnCheckForUpdates extends SettingsEvent {}

class OnLoadThemeMode extends SettingsEvent {}

class OnThemeModeChanged extends SettingsEvent {
  final ThemeMode themeMode;

  OnThemeModeChanged(this.themeMode);
}

class OnLoadCrashReportingSetting extends SettingsEvent {}

class OnCrashReportingToggled extends SettingsEvent {
  final bool disabled;

  OnCrashReportingToggled(this.disabled);
}
