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
import 'package:android_tools/features/file_explorer/domain/entities/file_type.dart';

part 'file_explorer_event.dart';
part 'file_explorer_state.dart';
part 'file_explorer_bloc.mapper.dart';

class FileExplorerBloc extends Bloc<FileExplorerEvent, FileExplorerState> {
  final ListFilesUsecase _listFilesUsecase = getIt.get();
  final Logger _logger = getIt.get();
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
          emit(state.copyWith(files: files));
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

      final files = await _listFilesUsecase(parentPath, device.deviceId);
      emit(state.copyWith(files: files, path: parentPath, selectedFile: null));

      _logger.i('Fetched ${files.length} file(s) for path $parentPath');
    });
    on<OnUploadFiles>((event, emit) async {
      final device = state.device;
      if (device == null) {
        _logger.w("Device is null, can't upload files");
        return;
      }

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
      final files = await _listFilesUsecase(state.path, device.deviceId);
      emit(state.copyWith(files: files, selectedFile: null));
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
      final filePath = p.join(state.path, event.fileName);
      _logger.i("Deleting file at $filePath for device ${device.deviceId}");
      await _deleteFileUsecase(filePath, device.deviceId);
      add(OnRefreshFiles());
    });
  }
}
