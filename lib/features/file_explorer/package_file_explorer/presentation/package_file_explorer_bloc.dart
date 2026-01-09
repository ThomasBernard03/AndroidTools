import 'package:android_tools/features/file_explorer/package_file_explorer/domain/usecases/create_package_directory_usecase.dart';
import 'package:android_tools/features/file_explorer/package_file_explorer/domain/usecases/delete_package_file_usecase.dart';
import 'package:android_tools/features/file_explorer/package_file_explorer/domain/usecases/download_package_file_usecase.dart';
import 'package:android_tools/features/file_explorer/package_file_explorer/domain/usecases/list_package_files_usecase.dart';
import 'package:android_tools/features/file_explorer/package_file_explorer/domain/usecases/upload_package_files_usecase.dart';
import 'package:android_tools/features/file_explorer/shared/core/string_extensions.dart';
import 'package:android_tools/features/file_explorer/shared/domain/entities/file_entry.dart';
import 'package:android_tools/main.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/shared/domain/usecases/get_packages_usecase.dart';
import 'package:android_tools/shared/domain/usecases/listen_selected_device_usecase.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:file_picker/file_picker.dart' hide FileType;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:android_tools/features/file_explorer/shared/domain/entities/file_type.dart';

part 'package_file_explorer_event.dart';
part 'package_file_explorer_state.dart';
part 'package_file_explorer_bloc.mapper.dart';

class PackageFileExplorerBloc
    extends Bloc<PackageFileExplorerEvent, PackageFileExplorerState> {
  final Logger _logger = getIt.get();
  final GetPackagesUsecase _getPackagesUsecase = getIt.get();
  final ListPackageFilesUsecase _listPackageFilesUsecase = getIt.get();
  final ListenSelectedDeviceUsecase _listenSelectedDeviceUsecase = getIt.get();
  final UploadPackageFilesUsecase _uploadPackageFilesUsecase = getIt.get();
  final DownloadPackageFileUsecase _downloadPackageFileUsecase = getIt.get();
  final DeletePackageFileUsecase _deletePackageFileUsecase = getIt.get();
  final CreatePackageDirectoryUsecase _createPackageDirectoryUsecase = getIt
      .get();

  PackageFileExplorerBloc() : super(PackageFileExplorerState()) {
    on<OnAppearing>((event, emit) async {
      await emit.onEach<DeviceEntity?>(
        _listenSelectedDeviceUsecase(),
        onData: (device) async {
          emit(state.copyWith(path: "", device: device, files: []));

          if (device == null) {
            _logger.i("Selected device is null, can't get packages");
            return;
          }
          final packages = await _getPackagesUsecase(device.deviceId);
          emit(state.copyWith(packages: packages));
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

      final package = state.selectedPackage;
      if (package == null) {
        _logger.w("Package is null, can't handle OnFileEntryTapped for $path");
        return;
      }

      if (event.fileEntry.type == FileType.directory) {
        final files = await _listPackageFilesUsecase(
          package,
          path,
          device.deviceId,
        );
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

      final package = state.selectedPackage;
      if (package == null) {
        _logger.w("Package is null can't go back");
        return;
      }

      emit(state.copyWith(isLoading: true));
      final files = await _listPackageFilesUsecase(
        package,
        parentPath,
        device.deviceId,
      );
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

      final package = state.selectedPackage;
      if (package == null) {
        _logger.w("No package selected, can't upload files");
        return;
      }

      emit(state.copyWith(isLoading: true));
      _logger.i("Start uploading ${event.files} to ${state.path}");
      await _uploadPackageFilesUsecase(
        package,
        event.files,
        state.path,
        device.deviceId,
      );
      _logger.i("Files uploaded refreshing files");
      add(OnRefreshFiles());
    });
    on<OnRefreshFiles>((event, emit) async {
      final device = state.device;
      if (device == null) {
        _logger.w("Device is null, can't refresh files");
        return;
      }
      final package = state.selectedPackage;
      if (package == null) {
        _logger.w("No package selected, can't refresh files");
        return;
      }
      emit(state.copyWith(isLoading: true));
      final files = await _listPackageFilesUsecase(
        package,
        state.path,
        device.deviceId,
      );
      emit(state.copyWith(files: files, selectedFile: null, isLoading: false));
    });
    on<OnDownloadFile>((event, emit) async {
      final device = state.device;
      if (device == null) {
        _logger.w("Device is null, can't download file");
        return;
      }

      final package = state.selectedPackage;
      if (package == null) {
        _logger.w("No package selected, can't download file");
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
      await _downloadPackageFileUsecase(
        package,
        filePath,
        destinationPath,
        device.deviceId,
      );
      add(OnRefreshFiles());
    });
    on<OnDeleteFile>((event, emit) async {
      final device = state.device;
      if (device == null) {
        _logger.w("Device is null, can't delete file");
        return;
      }

      final package = state.selectedPackage;
      if (package == null) {
        _logger.w("No package selected, can't delete file");
        return;
      }

      emit(state.copyWith(isLoading: true));
      final filePath = p.join(state.path, event.fileName);
      _logger.i("Deleting file at $filePath for device ${device.deviceId}");
      await _deletePackageFileUsecase(package, filePath, device.deviceId);
      add(OnRefreshFiles());
    });
    on<OnCreateDirectory>((event, emit) async {
      final device = state.device;
      if (device == null) {
        _logger.w("Device is null, can't create directory");
        return;
      }

      final package = state.selectedPackage;
      if (package == null) {
        _logger.w("No package selected, can't create directory");
        return;
      }

      _logger.i(
        "Creating directory ${event.name} at ${state.path} for device ${device.deviceId}",
      );
      emit(state.copyWith(isLoading: true));
      await _createPackageDirectoryUsecase(
        package,
        state.path,
        event.name,
        device.deviceId,
      );
      add(OnRefreshFiles());
    });
    on<OnPackageSelected>((event, emit) async {
      emit(state.copyWith(selectedPackage: event.package));
      _logger.d("Package selected: ${event.package}");

      final package = event.package;
      if (package == null) {
        return;
      }

      final device = state.device;
      if (device == null) {
        _logger.w("Device is null, can't get package files");
        return;
      }

      final files = await _listPackageFilesUsecase(
        package,
        "",
        device.deviceId,
      );
      emit(state.copyWith(files: files.toList()));
    });
  }
}
