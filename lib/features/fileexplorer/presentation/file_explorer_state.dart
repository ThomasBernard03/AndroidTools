part of 'file_explorer_bloc.dart';

@MappableClass()
class FileExplorerState with FileExplorerStateMappable {
  final List<FileEntry> files;

  FileExplorerState({this.files = const []});
}
