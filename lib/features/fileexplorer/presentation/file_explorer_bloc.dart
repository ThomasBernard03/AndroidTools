import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'file_explorer_event.dart';
part 'file_explorer_state.dart';
part 'file_explorer_bloc.mapper.dart';

class FileExplorerBloc extends Bloc<FileExplorerEvent, FileExplorerState> {
  FileExplorerBloc() : super(FileExplorerState()) {
    on<OnAppearing>((event, emit) async {});
  }
}
