import 'package:android_tools/features/file_explorer/package_file_explorer/data/package_file_repository_impl.dart';
import 'package:android_tools/features/file_explorer/package_file_explorer/domain/repositories/package_file_repository.dart';
import 'package:android_tools/features/file_explorer/package_file_explorer/domain/usecases/create_package_directory_usecase.dart';
import 'package:android_tools/features/file_explorer/package_file_explorer/domain/usecases/delete_package_file_usecase.dart';
import 'package:android_tools/features/file_explorer/package_file_explorer/domain/usecases/download_package_file_usecase.dart';
import 'package:android_tools/features/file_explorer/package_file_explorer/domain/usecases/list_package_files_usecase.dart';
import 'package:android_tools/features/file_explorer/package_file_explorer/domain/usecases/upload_package_files_usecase.dart';
import 'package:android_tools/main.dart';

class PackageFileExplorerModule {
  static void configureDependencies() {
    _registerRepositories();
    _registerUseCases();
  }

  static void _registerRepositories() {
    getIt.registerLazySingleton<PackageFileRepository>(
      () => PackageFileRepositoryImpl(getIt.get(), getIt.get()),
    );
  }

  static void _registerUseCases() {
    getIt.registerLazySingleton(() => ListPackageFilesUsecase(getIt.get()));
    getIt.registerLazySingleton(
      () => CreatePackageDirectoryUsecase(getIt.get()),
    );
    getIt.registerLazySingleton(() => DeletePackageFileUsecase(getIt.get()));
    getIt.registerLazySingleton(() => DownloadPackageFileUsecase(getIt.get()));
    getIt.registerLazySingleton(() => UploadPackageFilesUsecase(getIt.get()));
  }
}
