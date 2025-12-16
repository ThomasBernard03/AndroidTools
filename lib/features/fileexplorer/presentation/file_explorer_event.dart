part of 'file_explorer_bloc.dart';

sealed class FileExplorerEvent {}

class OnAppearing extends FileExplorerEvent {}

class OnGoToFolder extends FileExplorerEvent {
  final FileEntry folder;

  OnGoToFolder({required this.folder});
}

class OnGoBack extends FileExplorerEvent {}
