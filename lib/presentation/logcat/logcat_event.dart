part of 'logcat_bloc.dart';

sealed class LogcatEvent {}

class OnStartListeningLogcat extends LogcatEvent {}

class OnClearLogcat extends LogcatEvent {}
