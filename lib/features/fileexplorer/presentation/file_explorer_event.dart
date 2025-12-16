part of 'file_explorer_bloc.dart';

sealed class FileExplorerEvent {}

class OnAppearing extends FileExplorerEvent {}

class OnGoToFolder extends FileExplorerEvent {
  final FileEntry folder;

  OnGoToFolder({required this.folder});
}

class OnGoBack extends FileExplorerEvent {}

class OnUploadFiles extends FileExplorerEvent {
  final Iterable<String> files;

  OnUploadFiles({required this.files});
}

class OnRefreshFiles extends FileExplorerEvent {}
