import 'package:adb_dart/adb_dart.dart' hide FileEntry;
import 'package:android_tools/features/file_explorer/core/string_extensions.dart';
import 'package:android_tools/features/file_explorer/domain/entities/file_entry.dart';
import 'package:android_tools/features/file_explorer/domain/usecases/create_directory_usecase.dart';
import 'package:android_tools/features/file_explorer/domain/usecases/delete_file_usecase.dart';
import 'package:android_tools/features/file_explorer/domain/usecases/download_file_usecase.dart';
import 'package:android_tools/features/file_explorer/domain/usecases/list_files_usecase.dart';
import 'package:android_tools/features/file_explorer/domain/usecases/upload_files_usecase.dart';
import 'package:android_tools/main.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/shared/domain/usecases/listen_selected_device_usecase.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:file_picker/file_picker.dart' hide FileType;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

part 'file_explorer_event.dart';
part 'file_explorer_state.dart';
part 'file_explorer_bloc.mapper.dart';

class FileExplorerBloc extends Bloc<FileExplorerEvent, FileExplorerState> {
  final Logger _logger = getIt.get();
  final ListFilesUsecase _listFilesUsecase = getIt.get();
  final ListenSelectedDeviceUsecase _listenSelectedDeviceUsecase = getIt.get();
  final UploadFilesUsecase _uploadFilesUsecase = getIt.get();
  final DownloadFileUsecase _downloadFileUsecase = getIt.get();
  final DeleteFileUsecase _deleteFileUsecase = getIt.get();
  final CreateDirectoryUsecase _createDirectoryUsecase = getIt.get();

  FileExplorerBloc() : super(FileExplorerState()) {
    on<OnAppearing>((event, emit) async {
      await emit.onEach<DeviceEntity?>(
        _listenSelectedDeviceUsecase(),
        onData: (device) async {
          emit(state.copyWith(path: "/", device: device, files: []));

          if (device == null) {
            _logger.i("Selected device is null, can't get files");
            return;
          }

          final files = await _listFilesUsecase(state.path, device.deviceId);
          _logger.i('Fetched ${files.length} file(s) for first route');
          emit(state.copyWith(files: files.toList()));
        },
      );
    });
    on<OnFileEntryTapped>((event, emit) async {
      final device = state.device;
      final path = p.join(state.path, event.fileEntry.name);

      if (device == null) {
        _logger.w("Device is null, can't handle OnFileEntryTapped for $path");
        return;
      }

      if (event.fileEntry.type == FileType.directory) {
        final files = await _listFilesUsecase(path, device.deviceId);
        emit(state.copyWith(files: files, path: path, selectedFile: null));
        _logger.i('Fetched ${files.length} file(s) for path $path');
        return;
      }
      if (event.fileEntry.type == FileType.file) {
        emit(
          state.copyWith(
            selectedFile: state.selectedFile == event.fileEntry
                ? null
                : event.fileEntry,
          ),
        );
      }
    });

    on<OnGoBack>((event, emit) async {
      final device = state.device;

      if (device == null) {
        _logger.w("Device is null, can't go back");
        return;
      }

      final currentPath = state.path;

      final parentPath = p.dirname(currentPath);
      if (currentPath.isRootPath()) {
        _logger.i("Already at root, can't go back further");
        return;
      }

      emit(state.copyWith(isLoading: true));
      final files = await _listFilesUsecase(parentPath, device.deviceId);
      emit(
        state.copyWith(
          files: files,
          path: parentPath,
          selectedFile: null,
          isLoading: false,
        ),
      );

      _logger.i('Fetched ${files.length} file(s) for path $parentPath');
    });
    on<OnUploadFiles>((event, emit) async {
      final device = state.device;
      if (device == null) {
        _logger.w("Device is null, can't upload files");
        return;
      }

      emit(state.copyWith(isLoading: true));
      _logger.i("Start uploading ${event.files} to ${state.path}");
      await _uploadFilesUsecase(event.files, state.path, device.deviceId);
      _logger.i("Files uploaded refreshing files");
      add(OnRefreshFiles());
    });
    on<OnRefreshFiles>((event, emit) async {
      final device = state.device;
      if (device == null) {
        _logger.w("Device is null, can't refresh files");
        return;
      }
      emit(state.copyWith(isLoading: true));
      final files = await _listFilesUsecase(state.path, device.deviceId);
      emit(state.copyWith(files: files, selectedFile: null, isLoading: false));
    });
    on<OnDownloadFile>((event, emit) async {
      final device = state.device;
      if (device == null) {
        _logger.w("Device is null, can't download file");
        return;
      }
      final filePath = p.join(state.path, event.fileName);
      final destinationPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save file',
        fileName: event.fileName,
      );

      if (destinationPath == null) {
        _logger.i("User cancelled download");
        return;
      }
      emit(state.copyWith(isLoading: true));

      _logger.i(
        "Downloading file $filePath for device ${device.deviceId}, downloading in $destinationPath",
      );
      await _downloadFileUsecase(filePath, destinationPath, device.deviceId);
      add(OnRefreshFiles());
    });
    on<OnDeleteFile>((event, emit) async {
      final device = state.device;
      if (device == null) {
        _logger.w("Device is null, can't delete file");
        return;
      }
      emit(state.copyWith(isLoading: true));
      final filePath = p.join(state.path, event.fileName);
      _logger.i("Deleting file at $filePath for device ${device.deviceId}");
      await _deleteFileUsecase(filePath, device.deviceId);
      add(OnRefreshFiles());
    });
    on<OnCreateDirectory>((event, emit) async {
      final device = state.device;
      if (device == null) {
        _logger.w("Device is null, can't create directory");
        return;
      }
      _logger.i(
        "Creating directory ${event.name} at ${state.path} for device ${device.deviceId}",
      );
      emit(state.copyWith(isLoading: true));
      await _createDirectoryUsecase(state.path, event.name, device.deviceId);
      add(OnRefreshFiles());
    });
    on<OnGoToDirectory>((event, emit) async {
      final device = state.device;
      if (device == null) {
        _logger.w("Device is null, can't go to directory");
        return;
      }

      final files = await _listFilesUsecase(event.path, device.deviceId);
      emit(state.copyWith(files: files, path: event.path, selectedFile: null));
      _logger.i('Fetched ${files.length} file(s) for path ${event.path}');
      return;
    });
  }
}
