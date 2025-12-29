import 'package:android_tools/features/file_explorer/general_file_explorer/data/general_file_repository_impl.dart';
import 'package:android_tools/features/file_explorer/general_file_explorer/domain/repositories/general_file_repository.dart';
import 'package:android_tools/features/file_explorer/general_file_explorer/domain/usecases/create_directory_usecase.dart';
import 'package:android_tools/features/file_explorer/general_file_explorer/domain/usecases/delete_file_usecase.dart';
import 'package:android_tools/features/file_explorer/general_file_explorer/domain/usecases/download_file_usecase.dart';
import 'package:android_tools/features/file_explorer/general_file_explorer/domain/usecases/list_files_usecase.dart';
import 'package:android_tools/features/file_explorer/general_file_explorer/domain/usecases/upload_files_usecase.dart';
import 'package:android_tools/main.dart';

class GeneralFileExplorerModule {
  static void configureDependencies() {
    _registerRepositories();
    _registerUseCases();
  }

  static void _registerRepositories() {
    getIt.registerLazySingleton<GeneralFileRepository>(
      () => GeneralFileRepositoryImpl(getIt.get(), getIt.get()),
    );
  }

  static void _registerUseCases() {
    getIt.registerLazySingleton(() => ListFilesUsecase(getIt.get()));
    getIt.registerLazySingleton(() => UploadFilesUsecase(getIt.get()));
    getIt.registerLazySingleton(() => DeleteFileUsecase(getIt.get()));
    getIt.registerLazySingleton(() => DownloadFileUsecase(getIt.get()));
    getIt.registerLazySingleton(() => CreateDirectoryUsecase(getIt.get()));
  }
}
