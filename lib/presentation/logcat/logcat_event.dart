part of 'logcat_bloc.dart';

sealed class LogcatEvent {}

class OnStartListeningLogcat extends LogcatEvent {}

class OnClearLogcat extends LogcatEvent {}

class OnToggleIsSticky extends LogcatEvent {
  final bool isSticky;

  OnToggleIsSticky({required this.isSticky});
}
