import 'package:android_tools/features/file_explorer/data/file_repository_impl.dart';
import 'package:android_tools/features/file_explorer/domain/repositories/file_repository.dart';
import 'package:android_tools/features/file_explorer/domain/usecases/create_directory_usecase.dart';
import 'package:android_tools/features/file_explorer/domain/usecases/delete_file_usecase.dart';
import 'package:android_tools/features/file_explorer/domain/usecases/download_file_usecase.dart';
import 'package:android_tools/features/file_explorer/domain/usecases/download_file_to_cache_usecase.dart';
import 'package:android_tools/features/file_explorer/domain/usecases/list_files_usecase.dart';
import 'package:android_tools/features/file_explorer/domain/usecases/upload_files_usecase.dart';
import 'package:android_tools/main.dart';

class FileExplorerModule {
  static void configureDependencies() {
    _registerRepositories();
    _registerUseCases();
  }

  static void _registerRepositories() {
    getIt.registerLazySingleton<FileRepository>(
      () => GeneralFileRepositoryImpl(getIt.get(), getIt.get()),
    );
  }

  static void _registerUseCases() {
    getIt.registerLazySingleton(() => ListFilesUsecase(getIt.get()));
    getIt.registerLazySingleton(() => UploadFilesUsecase(getIt.get()));
    getIt.registerLazySingleton(() => DeleteFileUsecase(getIt.get()));
    getIt.registerLazySingleton(() => DownloadFileUsecase(getIt.get()));
    getIt.registerLazySingleton(() => CreateDirectoryUsecase(getIt.get()));
    getIt.registerLazySingleton(() => DownloadFileToCacheUsecase(getIt.get()));
  }
}
