part of 'file_explorer_bloc.dart';

@MappableClass()
class FileExplorerState with FileExplorerStateMappable {
  final List<FileEntry> files;
  final FileEntry? selectedFile;
  final String path;
  final DeviceEntity? device;
  final bool isLoading;

  FileExplorerState({
    this.files = const [],
    this.path = "/",
    this.device,
    this.selectedFile,
    this.isLoading = false,
  });
}
