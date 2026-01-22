part of 'general_file_explorer_bloc.dart';

sealed class GeneralFileExplorerEvent {}

class OnAppearing extends GeneralFileExplorerEvent {}

class OnFileEntryTapped extends GeneralFileExplorerEvent {
  final FileEntry fileEntry;

  OnFileEntryTapped({required this.fileEntry});
}

class OnGoBack extends GeneralFileExplorerEvent {}

class OnUploadFiles extends GeneralFileExplorerEvent {
  final Iterable<String> files;

  OnUploadFiles({required this.files});
}

class OnRefreshFiles extends GeneralFileExplorerEvent {}

class OnDeleteFile extends GeneralFileExplorerEvent {
  final String fileName;

  OnDeleteFile({required this.fileName});
}

class OnDownloadFile extends GeneralFileExplorerEvent {
  final String fileName;

  OnDownloadFile({required this.fileName});
}

class OnCreateDirectory extends GeneralFileExplorerEvent {
  final String name;

  OnCreateDirectory({required this.name});
}

class OnGoToDirectory extends GeneralFileExplorerEvent {
  final String path;

  OnGoToDirectory({required this.path});
}
