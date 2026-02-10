part of 'file_preview_bloc.dart';

enum FilePreviewStatus { initial, loading, loaded, error }

enum PreviewType { text, image, video, audio, unsupported }

@MappableClass()
class FilePreviewState with FilePreviewStateMappable {
  final FilePreviewStatus status;
  final PreviewType previewType;
  final String? content;
  final String? localFilePath;
  final String? errorMessage;
  final FileEntry? fileEntry;
  final String path;

  FilePreviewState({
    this.status = FilePreviewStatus.initial,
    this.previewType = PreviewType.unsupported,
    this.content,
    this.localFilePath,
    this.errorMessage,
    this.fileEntry,
    this.path = "",
  });
}
