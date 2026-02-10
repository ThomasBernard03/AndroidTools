part of 'file_preview_bloc.dart';

sealed class FilePreviewEvent {}

class OnFilePreviewAppearingEvent extends FilePreviewEvent {
  final FileEntry fileEntry;
  final String currentPath;

  OnFilePreviewAppearingEvent({
    required this.fileEntry,
    required this.currentPath,
  });
}

class OnDownalodFileEvent extends FilePreviewEvent {
  final FileEntry fileEntry;
  OnDownalodFileEvent({required this.fileEntry});
}

class OnDeleteFileEvent extends FilePreviewEvent {
  final FileEntry fileEntry;
  OnDeleteFileEvent({required this.fileEntry});
}
