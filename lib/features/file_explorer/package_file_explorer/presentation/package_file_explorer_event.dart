part of 'package_file_explorer_bloc.dart';

sealed class PackageFileExplorerEvent {}

class OnAppearing extends PackageFileExplorerEvent {}

class OnFileEntryTapped extends PackageFileExplorerEvent {
  final FileEntry fileEntry;

  OnFileEntryTapped({required this.fileEntry});
}

class OnGoBack extends PackageFileExplorerEvent {}

class OnUploadFiles extends PackageFileExplorerEvent {
  final Iterable<String> files;

  OnUploadFiles({required this.files});
}

class OnRefreshFiles extends PackageFileExplorerEvent {}

class OnDeleteFile extends PackageFileExplorerEvent {
  final String fileName;

  OnDeleteFile({required this.fileName});
}

class OnDownloadFile extends PackageFileExplorerEvent {
  final String fileName;

  OnDownloadFile({required this.fileName});
}

class OnCreateDirectory extends PackageFileExplorerEvent {
  final String name;

  OnCreateDirectory({required this.name});
}
