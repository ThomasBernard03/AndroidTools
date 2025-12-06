part of 'logcat_bloc.dart';

@MappableClass()
class LogcatState with LogcatStateMappable {
  final List<String> logs;

  LogcatState({this.logs = const []});
}
