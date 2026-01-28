part of 'file_preview_bloc.dart';

sealed class FilePreviewEvent {}

class OnFilePreviewAppearing extends FilePreviewEvent {
  final FileEntry fileEntry;
  final String currentPath;

  OnFilePreviewAppearing({
    required this.fileEntry,
    required this.currentPath,
  });
}
