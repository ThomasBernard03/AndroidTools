part of 'file_explorer_bloc.dart';

@MappableClass()
class FileExplorerState with FileExplorerStateMappable {
  final List<FileEntry> files;
  final String path;
  final DeviceEntity? device;

  FileExplorerState({this.files = const [], this.path = "/", this.device});
}
