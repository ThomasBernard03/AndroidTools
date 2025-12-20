part of 'file_explorer_bloc.dart';

sealed class FileExplorerEvent {}

class OnAppearing extends FileExplorerEvent {}

class OnFileEntryTapped extends FileExplorerEvent {
  final FileEntry fileEntry;

  OnFileEntryTapped({required this.fileEntry});
}

class OnGoBack extends FileExplorerEvent {}

class OnUploadFiles extends FileExplorerEvent {
  final Iterable<String> files;

  OnUploadFiles({required this.files});
}

class OnRefreshFiles extends FileExplorerEvent {}

class OnDeleteFile extends FileExplorerEvent {
  final String fileName;

  OnDeleteFile({required this.fileName});
}

class OnDownloadFile extends FileExplorerEvent {
  final String fileName;

  OnDownloadFile({required this.fileName});
}
