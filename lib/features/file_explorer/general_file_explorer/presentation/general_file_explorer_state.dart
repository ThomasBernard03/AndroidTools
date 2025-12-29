part of 'general_file_explorer_bloc.dart';

@MappableClass()
class GeneralFileExplorerState with GeneralFileExplorerStateMappable {
  final List<FileEntry> files;
  final FileEntry? selectedFile;
  final String path;
  final DeviceEntity? device;
  final bool isLoading;

  GeneralFileExplorerState({
    this.files = const [],
    this.path = "/",
    this.device,
    this.selectedFile,
    this.isLoading = false,
  });
}
