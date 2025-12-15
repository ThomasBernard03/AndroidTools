import 'package:android_tools/features/fileexplorer/domain/entities/file_entry.dart';
import 'package:android_tools/features/fileexplorer/domain/usecases/list_files_usecase.dart';
import 'package:android_tools/main.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

part 'file_explorer_event.dart';
part 'file_explorer_state.dart';
part 'file_explorer_bloc.mapper.dart';

class FileExplorerBloc extends Bloc<FileExplorerEvent, FileExplorerState> {
  final ListFilesUsecase _listFilesUsecase = getIt.get();
  final Logger _logger = getIt.get();

  FileExplorerBloc() : super(FileExplorerState()) {
    on<OnAppearing>((event, emit) async {
      final files = await _listFilesUsecase("");
      _logger.i('Fetched ${files.length} file(s) for first route');
      emit(state.copyWith(files: files));
    });
  }
}
