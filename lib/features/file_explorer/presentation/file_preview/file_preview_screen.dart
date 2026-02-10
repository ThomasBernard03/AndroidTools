import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/file_explorer/core/int_extensions.dart';
import 'package:android_tools/features/file_explorer/presentation/file_preview/file_preview_bloc.dart';
import 'package:android_tools/features/file_explorer/presentation/file_preview/widgets/file_preview_action_button.dart';
import 'package:android_tools/features/file_explorer/presentation/file_preview/widgets/image_preview_widget.dart';
import 'package:android_tools/features/file_explorer/presentation/file_preview/widgets/text_preview_widget.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_entry_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FilePreviewScreen extends StatelessWidget {
  final FileEntry fileEntry;
  final String currentPath;

  const FilePreviewScreen({
    super.key,
    required this.fileEntry,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FilePreviewBloc()
        ..add(
          OnFilePreviewAppearingEvent(
            fileEntry: fileEntry,
            currentPath: currentPath,
          ),
        ),
      child: Scaffold(
        body: BlocBuilder<FilePreviewBloc, FilePreviewState>(
          builder: (context, state) {
            if (state.status == FilePreviewStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == FilePreviewStatus.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading file',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage ?? 'Unknown error',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (state.status == FilePreviewStatus.loaded) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Expanded(child: _buildPreviewContent(context, state)),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileEntry.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),

                        Divider(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(60),
                        ),

                        Text(
                          fileEntry.size?.toReadableBytes() ?? "",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),

                        Text(
                          fileEntry.date?.toIso8601String() ?? "",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),

                        Text(
                          fileEntry.permissions,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),

                        Divider(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(60),
                        ),

                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                children: [
                                  FilePreviewActionButton(
                                    onPressed: () {
                                      context.read<FilePreviewBloc>().add(
                                        OnDownalodFileEvent(
                                          fileEntry: fileEntry,
                                        ),
                                      );
                                    },
                                    icon: Icons.download,
                                    text: 'Download',
                                  ),
                                  FilePreviewActionButton(
                                    onPressed: () {},
                                    icon: Icons.delete,
                                    text: 'Delete',
                                  ),
                                  FilePreviewActionButton(
                                    onPressed: () {},
                                    icon: Icons.star,
                                    text: 'Set favorite',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return const Center(child: Text('No preview available'));
          },
        ),
      ),
    );
  }

  Widget _buildPreviewContent(BuildContext context, FilePreviewState state) {
    switch (state.previewType) {
      case PreviewType.text:
        return _buildTextPreview(state);
      case PreviewType.image:
        return _buildImagePreview(state);
      case PreviewType.video:
        return _buildVideoPreview(context, state);
      case PreviewType.audio:
        return _buildAudioPreview(context, state);
      case PreviewType.unsupported:
        return _buildUnsupportedPreview(context);
    }
  }

  Widget _buildTextPreview(FilePreviewState state) {
    return TextPreviewWidget(
      content: state.content ?? "",
      fileName: fileEntry.name,
    );
  }

  Widget _buildImagePreview(FilePreviewState state) {
    if (state.localFilePath == null) {
      return const Center(child: Text('No image file path available'));
    }

    return ImagePreviewWidget(
      imagePath: state.localFilePath!,
      fileName: fileEntry.name,
    );
  }

  Widget _buildVideoPreview(BuildContext context, FilePreviewState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_library, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Video preview', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Coming soon...',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPreview(BuildContext context, FilePreviewState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.audio_file, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Audio preview', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Coming soon...',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedPreview(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [fileEntry.icon(width: 200)],
      ),
    );
  }
}
