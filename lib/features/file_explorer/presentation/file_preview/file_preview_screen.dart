import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/file_explorer/presentation/file_preview/file_preview_bloc.dart';
import 'package:android_tools/features/file_explorer/presentation/file_preview/text_preview_widget.dart';
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
          OnFilePreviewAppearing(
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
              return _buildPreviewContent(context, state);
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
        return _buildTextPreview(context, state);
      case PreviewType.image:
        return _buildImagePreview(context, state);
      case PreviewType.video:
        return _buildVideoPreview(context, state);
      case PreviewType.audio:
        return _buildAudioPreview(context, state);
      case PreviewType.unsupported:
        return _buildUnsupportedPreview(context);
    }
  }

  Widget _buildTextPreview(BuildContext context, FilePreviewState state) {
    return TextPreviewWidget(
      content: state.content ?? "",
      fileName: fileEntry.name,
    );
  }

  Widget _buildImagePreview(BuildContext context, FilePreviewState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Image preview', style: Theme.of(context).textTheme.titleMedium),
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
        children: [
          const Icon(Icons.insert_drive_file, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Preview not available',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'This file type is not supported for preview',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
