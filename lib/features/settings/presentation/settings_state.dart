part of 'settings_bloc.dart';

@MappableClass()
class SettingsState with SettingsStateMappable {
  final int maxHistorySize;

  SettingsState({this.maxHistorySize = 10});
}
