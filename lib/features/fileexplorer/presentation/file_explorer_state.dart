part of 'file_explorer_bloc.dart';

@MappableClass()
class FileExplorerState with FileExplorerStateMappable {
  final List<FileEntry> files;
  final String path;

  FileExplorerState({this.files = const [], this.path = "/"});
}
