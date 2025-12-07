import 'package:android_tools/domain/entities/logcat_level.dart';
import 'package:android_tools/domain/usecases/logcat/clear_logcat_usecase.dart';
import 'package:android_tools/domain/usecases/logcat/listen_logcat_usecase.dart';
import 'package:android_tools/main.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'logcat_event.dart';
part 'logcat_state.dart';
part 'logcat_bloc.mapper.dart';

class LogcatBloc extends Bloc<LogcatEvent, LogcatState> {
  final ListenLogcatUsecase listenLogcatUsecase = getIt.get();
  final ClearLogcatUsecase clearLogcatUsecase = getIt.get();

  LogcatBloc() : super(LogcatState()) {
    on<OnStartListeningLogcat>((event, emit) async {
      final stream = listenLogcatUsecase();
      await emit.forEach<String>(
        stream,
        onData: (line) {
          final updated = List<String>.from(state.logs)..add(line);
          return state.copyWith(logs: updated);
        },
      );
    });
    on<OnClearLogcat>((event, emit) async {
      emit(state.copyWith(logs: []));
      await clearLogcatUsecase();
    });
    on<OnToggleIsSticky>((event, emit) {
      emit(state.copyWith(isSticky: event.isSticky));
    });
    on<OnMinimumLogLevelChanged>((event, emit) {
      emit(state.copyWith(minimumLogLevel: event.minimumLogLevel));
    });
  }
}
