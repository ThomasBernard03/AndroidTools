part of 'settings_bloc.dart';

sealed class SettingsEvent {}

class OnOpenLogDirectory extends SettingsEvent {}

class OnOpenGithubProject extends SettingsEvent {}

class OnCreateIssue extends SettingsEvent {}

class OnCheckForUpdates extends SettingsEvent {}
