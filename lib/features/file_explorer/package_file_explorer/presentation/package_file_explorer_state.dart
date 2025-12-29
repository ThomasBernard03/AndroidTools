part of 'package_file_explorer_bloc.dart';

@MappableClass()
class PackageFileExplorerState with PackageFileExplorerStateMappable {
  final Iterable<String> packages;
  final String? selectedPackage;

  final List<FileEntry> files;
  final FileEntry? selectedFile;
  final String path;
  final DeviceEntity? device;
  final bool isLoading;

  PackageFileExplorerState({
    this.packages = const [],
    this.selectedPackage,
    this.files = const [],
    this.path = "/",
    this.device,
    this.selectedFile,
    this.isLoading = false,
  });
}
