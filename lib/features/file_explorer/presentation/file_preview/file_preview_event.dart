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
