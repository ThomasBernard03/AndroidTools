part of 'logcat_bloc.dart';

@MappableClass()
class LogcatState with LogcatStateMappable {
  final List<String> logs;
  final bool isSticky;

  LogcatState({this.logs = const [], this.isSticky = true});
}
