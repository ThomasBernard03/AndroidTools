import 'dart:async';

import 'package:android_tools/domain/entities/logcat_level.dart';
import 'package:android_tools/domain/usecases/logcat/clear_logcat_usecase.dart';
import 'package:android_tools/domain/usecases/logcat/listen_logcat_usecase.dart';
import 'package:android_tools/main.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

part 'logcat_event.dart';
part 'logcat_state.dart';
part 'logcat_bloc.mapper.dart';

class LogcatBloc extends Bloc<LogcatEvent, LogcatState> {
  final ListenLogcatUsecase listenLogcatUsecase = getIt.get();
  final ClearLogcatUsecase clearLogcatUsecase = getIt.get();
  final Logger logger = getIt.get();

  StreamSubscription<List<String>>? _subscription;

  LogcatBloc() : super(LogcatState()) {
    on<OnStartListeningLogcat>((event, emit) async {
      await _subscription?.cancel();
      final stream = listenLogcatUsecase();
      _subscription = stream.listen((lines) {
        add(OnLogReceived(lines: lines));
      });
    });

    on<OnLogReceived>((event, emit) {
      logger.d("Adding ${event.lines.length} new lines to logcat lines");
      final updated = List<String>.from(state.logs)..addAll(event.lines);
      logger.d("Size of logcat lines : ${updated.length}");
      emit(state.copyWith(logs: updated));
    });

    on<OnClearLogcat>((event, emit) async {
      emit(state.copyWith(logs: []));
      await clearLogcatUsecase();
    });

    on<OnToggleIsSticky>((event, emit) {
      emit(state.copyWith(isSticky: event.isSticky));
    });

    on<OnMinimumLogLevelChanged>((event, emit) async {
      emit(state.copyWith(minimumLogLevel: event.minimumLogLevel));
      await _subscription?.cancel();
      final stream = listenLogcatUsecase(level: event.minimumLogLevel);
      _subscription = stream.listen((lines) {
        add(OnLogReceived(lines: lines));
      });
    });

    on<OnPauseLogcat>((event, emit) {
      emit(state.copyWith(isPaused: true));
      _subscription?.pause();
    });

    on<OnResumeLogcat>((event, emit) {
      emit(state.copyWith(isPaused: false));
      _subscription?.resume();
    });

    on<OnLogcatMaxLinesChanged>((event, emit) {
      emit(state.copyWith(maxLogcatLines: event.maxLines));
    });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
