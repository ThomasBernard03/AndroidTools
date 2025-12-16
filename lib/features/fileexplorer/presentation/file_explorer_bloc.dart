import 'package:android_tools/features/fileexplorer/core/string_extensions.dart';
import 'package:android_tools/features/fileexplorer/domain/entities/file_entry.dart';
import 'package:android_tools/features/fileexplorer/domain/usecases/list_files_usecase.dart';
import 'package:android_tools/main.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/shared/domain/usecases/listen_selected_device_usecase.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

part 'file_explorer_event.dart';
part 'file_explorer_state.dart';
part 'file_explorer_bloc.mapper.dart';

class FileExplorerBloc extends Bloc<FileExplorerEvent, FileExplorerState> {
  final ListFilesUsecase _listFilesUsecase = getIt.get();
  final Logger _logger = getIt.get();
  final ListenSelectedDeviceUsecase _listenSelectedDeviceUsecase = getIt.get();

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
    on<OnGoToFolder>((event, emit) async {
      final device = state.device;
      final path = p.join(state.path, event.folder.name);

      if (device == null) {
        _logger.w("Device is null, can't get files for $path");
        return;
      }

      final files = await _listFilesUsecase(path, device.deviceId);
      emit(state.copyWith(files: files, path: path));
      _logger.i('Fetched ${files.length} file(s) for path $path');
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
      emit(state.copyWith(files: files, path: parentPath));

      _logger.i('Fetched ${files.length} file(s) for path $parentPath');
    });
  }
}
