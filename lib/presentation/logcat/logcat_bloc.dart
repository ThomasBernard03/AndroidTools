import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:android_tools/domain/entities/logcat_level.dart';
import 'package:android_tools/domain/entities/logcat_line_entity.dart';
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
    on<OnMinimumLogLevelChanged>((event, emit) {
      emit(state.copyWith(minimumLogLevel: event.minimumLogLevel));
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

  LogcatLevel _mapLevel(String c) {
    switch (c) {
      case 'V':
        return LogcatLevel.verbose;
      case 'D':
        return LogcatLevel.debug;
      case 'I':
        return LogcatLevel.info;
      case 'W':
        return LogcatLevel.warning;
      case 'E':
        return LogcatLevel.error;
      case 'F':
        return LogcatLevel.fatal;
      default:
        return LogcatLevel.silent;
    }
  }

  final _logRegex = RegExp(r'''^(\d\d)-(\d\d)\s+            # MM-DD
      (\d\d):(\d\d):(\d\d)\.(\d{3})\s+  # HH:mm:ss.mmm
      (\d+)\s+                      # PID
      (\d+)\s+                      # TID
      ([VDIWEF])\s+                 # Level
      (\S+):                        # Tag/package
      (.*)$                         # Message
    ''', multiLine: false);

  LogcatLineEntity? parseLogcatLine(String line) {
    final match = _logRegex.firstMatch(line);
    if (match == null) return null;

    final now = DateTime.now();

    final month = int.parse(match.group(1)!);
    final day = int.parse(match.group(2)!);

    final hour = int.parse(match.group(3)!);
    final minute = int.parse(match.group(4)!);
    final second = int.parse(match.group(5)!);
    final ms = int.parse(match.group(6)!);

    final pid = int.parse(match.group(7)!);
    final tid = int.parse(match.group(8)!);
    final level = _mapLevel(match.group(9)!);

    final package = match.group(10)!;

    final date = DateTime(now.year, month, day, hour, minute, second, ms);

    return LogcatLineEntity(
      dateTime: date,
      level: level,
      processId: pid,
      threadId: tid,
      packageName: package,
    );
  }
}
