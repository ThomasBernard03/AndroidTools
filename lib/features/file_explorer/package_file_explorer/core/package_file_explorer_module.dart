import 'package:android_tools/features/file_explorer/package_file_explorer/data/package_file_repository_impl.dart';
import 'package:android_tools/features/file_explorer/package_file_explorer/domain/repositories/package_file_repository.dart';
import 'package:android_tools/features/file_explorer/package_file_explorer/domain/usecases/list_package_files_usecase.dart';
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
  }
}
