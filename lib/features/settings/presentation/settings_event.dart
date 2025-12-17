part of 'settings_bloc.dart';

sealed class SettingsEvent {}

class OnAppearing extends SettingsEvent {}

class OnOpenLogDirectory extends SettingsEvent {}
