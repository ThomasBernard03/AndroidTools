import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'logcat_event.dart';
part 'logcat_state.dart';
part 'logcat_bloc.mapper.dart';

class LogcatBloc extends Bloc<LogcatEvent, LogcatState> {
  StreamSubscription<String>? _subscription;

  LogcatBloc() : super(LogcatState()) {
    on<OnStartListeningLogcat>(_onStart);
    on<OnClearLogcat>(_onClear);
    on<OnToggleIsSticky>((event, emit) {
      emit(state.copyWith(isSticky: event.isSticky));
    });
  }

  Future<void> _onClear(OnClearLogcat event, Emitter<LogcatState> emit) async {
    try {
      final adbPath = getAdbPath();
      // Execute la commande pour clear le logcat sur l'appareil
      final process = await Process.run(adbPath, ['logcat', '-c']);
      emit(state.copyWith(logs: []));
      if (process.exitCode != 0) {
        print('Erreur lors du clear logcat : ${process.stderr}');
      } else {
        print('Logcat cleared successfully');
      }
    } catch (e) {
      print('Exception clearing logcat: $e');
    }
  }

  Future<void> _onStart(
    OnStartListeningLogcat event,
    Emitter<LogcatState> emit,
  ) async {
    final stream = await startLogcat();

    await emit.forEach<String>(
      stream,
      onData: (line) {
        final updated = List<String>.from(state.logs)..add(line);
        return state.copyWith(logs: updated);
      },
    );
  }

  Future<Stream<String>> startLogcat() async {
    final adbPath = getAdbPath();

    // Liste les appareils connectés
    final devicesResult = await Process.run(adbPath, ['devices']);
    print(devicesResult.stdout); // Devrait montrer les appareils

    final process = await Process.start(adbPath, ['logcat', '*:E']);

    return process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter());
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  String getAdbPath() {
    final execDir = Directory(Platform.resolvedExecutable).parent;
    final contents = execDir.parent;
    final resources = Directory("${contents.path}/Resources");
    return "${resources.path}/adb";
  }
}
