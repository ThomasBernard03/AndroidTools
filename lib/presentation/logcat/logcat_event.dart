part of 'logcat_bloc.dart';

sealed class LogcatEvent {}

class OnStartListeningLogcat extends LogcatEvent {}

class OnClearLogcat extends LogcatEvent {}

class OnToggleIsSticky extends LogcatEvent {
  final bool isSticky;

  OnToggleIsSticky({required this.isSticky});
}

class OnMinimumLogLevelChanged extends LogcatEvent {
  final LogcatLevel? minimumLogLevel;

  OnMinimumLogLevelChanged({required this.minimumLogLevel});
}

class OnPauseLogcat extends LogcatEvent {}

class OnResumeLogcat extends LogcatEvent {}

class OnLogReceived extends LogcatEvent {
  final String line;
  OnLogReceived({required this.line});
}
