import 'dart:io';
import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/file_explorer/domain/usecases/download_file_to_cache_usecase.dart';
import 'package:android_tools/main.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/shared/domain/usecases/listen_selected_device_usecase.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

part 'file_preview_event.dart';
part 'file_preview_state.dart';
part 'file_preview_bloc.mapper.dart';

class FilePreviewBloc extends Bloc<FilePreviewEvent, FilePreviewState> {
  final Logger _logger = getIt.get();
  final DownloadFileToCacheUsecase _downloadFileToCacheUsecase = getIt.get();
  final ListenSelectedDeviceUsecase _listenSelectedDeviceUsecase = getIt.get();

  DeviceEntity? _currentDevice;

  FilePreviewBloc() : super(FilePreviewState()) {
    // Listen to device changes
    _listenSelectedDeviceUsecase().listen((device) {
      _currentDevice = device;
    });

    on<OnFilePreviewAppearing>((event, emit) async {
      if (_currentDevice == null) {
        _logger.w("Device is null, can't preview file");
        emit(state.copyWith(
          status: FilePreviewStatus.error,
          errorMessage: "No device selected",
        ));
        return;
      }

      try {
        emit(state.copyWith(
          status: FilePreviewStatus.loading,
          fileEntry: event.fileEntry,
        ));

        final filePath = p.join(event.currentPath, event.fileEntry.name);
        _logger.i("Downloading file $filePath to cache");

        // Download file to cache
        final localFilePath = await _downloadFileToCacheUsecase(
          filePath,
          event.fileEntry.name,
          _currentDevice!.deviceId,
        );

        _logger.i("File downloaded to $localFilePath");

        // Detect file type
        final previewType = _detectPreviewType(localFilePath);
        _logger.i("Detected preview type: $previewType");

        // Read content for text files
        String? content;
        if (previewType == PreviewType.text) {
          final file = File(localFilePath);
          content = await file.readAsString();
          _logger.i("Read ${content.length} characters from file");
        }

        emit(state.copyWith(
          status: FilePreviewStatus.loaded,
          previewType: previewType,
          content: content,
          localFilePath: localFilePath,
        ));
      } catch (e, stackTrace) {
        _logger.e("Error loading file preview", error: e, stackTrace: stackTrace);
        emit(state.copyWith(
          status: FilePreviewStatus.error,
          errorMessage: e.toString(),
        ));
      }
    });
  }

  PreviewType _detectPreviewType(String filePath) {
    final mimeType = lookupMimeType(filePath);
    _logger.i("MIME type for $filePath: $mimeType");

    if (mimeType == null) {
      // Fallback to extension-based detection
      final extension = p.extension(filePath).toLowerCase();
      if (_isTextExtension(extension)) {
        return PreviewType.text;
      }
      return PreviewType.unsupported;
    }

    if (mimeType.startsWith('text/')) {
      return PreviewType.text;
    }

    if (mimeType.startsWith('image/')) {
      return PreviewType.image;
    }

    if (mimeType.startsWith('video/')) {
      return PreviewType.video;
    }

    if (mimeType.startsWith('audio/')) {
      return PreviewType.audio;
    }

    // Check for common text-based formats
    if (mimeType == 'application/json' ||
        mimeType == 'application/xml' ||
        mimeType == 'application/javascript' ||
        mimeType == 'application/x-yaml') {
      return PreviewType.text;
    }

    return PreviewType.unsupported;
  }

  bool _isTextExtension(String extension) {
    const textExtensions = [
      '.txt',
      '.json',
      '.xml',
      '.yaml',
      '.yml',
      '.md',
      '.log',
      '.csv',
      '.html',
      '.css',
      '.js',
      '.ts',
      '.dart',
      '.java',
      '.kt',
      '.py',
      '.rb',
      '.sh',
      '.gradle',
      '.properties',
      '.conf',
      '.config',
      '.ini',
    ];

    return textExtensions.contains(extension);
  }
}
