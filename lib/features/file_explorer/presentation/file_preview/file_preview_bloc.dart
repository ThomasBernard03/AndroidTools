import 'dart:io';
import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/file_explorer/core/file_extension_helper.dart';
import 'package:android_tools/features/file_explorer/domain/usecases/download_file_to_cache_usecase.dart';
import 'package:android_tools/main.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/shared/domain/usecases/listen_selected_device_usecase.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
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
        emit(
          state.copyWith(
            status: FilePreviewStatus.error,
            errorMessage: "No device selected",
          ),
        );
        return;
      }

      try {
        emit(
          state.copyWith(
            status: FilePreviewStatus.loading,
            fileEntry: event.fileEntry,
          ),
        );

        final filePath = p.join(event.currentPath, event.fileEntry.name);

        // Check if file is previewable before downloading
        final previewType = _canPreviewFile(event.fileEntry.name);
        if (previewType == PreviewType.unsupported) {
          _logger.i(
            "File $filePath cannot be previewed (unsupported extension)",
          );
          emit(
            state.copyWith(
              status: FilePreviewStatus.loaded,
              previewType: PreviewType.unsupported,
            ),
          );
          return;
        }

        _logger.i("Downloading file $filePath to cache");

        // Download file to cache
        final localFilePath = await _downloadFileToCacheUsecase(
          filePath,
          event.fileEntry.name,
          _currentDevice!.deviceId,
        );

        _logger.i("File downloaded to $localFilePath");

        // Read content for text files
        String? content;
        if (previewType == PreviewType.text) {
          final file = File(localFilePath);
          content = await file.readAsString();
          _logger.i("Read ${content.length} characters from file");
        }

        emit(
          state.copyWith(
            status: FilePreviewStatus.loaded,
            previewType: previewType,
            content: content,
            localFilePath: localFilePath,
          ),
        );
      } catch (e, stackTrace) {
        _logger.e(
          "Error loading file preview",
          error: e,
          stackTrace: stackTrace,
        );
        emit(
          state.copyWith(
            status: FilePreviewStatus.error,
            errorMessage: e.toString(),
          ),
        );
      }
    });
  }

  /// Check if a file can be previewed based on its filename/extension
  /// This method doesn't require the file to be downloaded
  PreviewType _canPreviewFile(String filename) {
    final extension = p.extension(filename).toLowerCase();

    // Text extensions
    if (FileExtensionHelper.isTextExtension(extension)) {
      return PreviewType.text;
    }

    // Image extensions
    if (FileExtensionHelper.isImageExtension(extension)) {
      return PreviewType.image;
    }

    // Video extensions
    if (FileExtensionHelper.isVideoExtension(extension)) {
      return PreviewType.video;
    }

    // Audio extensions
    if (FileExtensionHelper.isAudioExtension(extension)) {
      return PreviewType.audio;
    }

    return PreviewType.unsupported;
  }
}
