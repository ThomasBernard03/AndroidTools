part of 'settings_bloc.dart';

sealed class SettingsEvent {}

class OnOpenLogDirectory extends SettingsEvent {}

class OnOpenGithubProject extends SettingsEvent {}

class OnCreateIssue extends SettingsEvent {}

class OnCheckForUpdates extends SettingsEvent {}

class OnClearInstalledApplicationHistory extends SettingsEvent {}

class OnLoadMaxHistorySize extends SettingsEvent {}

class OnMaxHistorySizeChanged extends SettingsEvent {
  final int size;

  OnMaxHistorySizeChanged(this.size);
}
