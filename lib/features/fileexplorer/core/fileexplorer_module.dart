import 'package:android_tools/features/fileexplorer/data/repositories/file_repository_impl.dart';
import 'package:android_tools/features/fileexplorer/domain/repositories/file_repository.dart';
import 'package:android_tools/features/fileexplorer/domain/usecases/list_files_usecase.dart';
import 'package:android_tools/main.dart';

class FileExplorerModule {
  static void configureDependencies() {
    _registerRepositories();
    _registerUseCases();
  }

  static void _registerRepositories() {
    getIt.registerLazySingleton<FileRepository>(
      () => FileRepositoryImpl(getIt.get(), getIt.get()),
    );
  }

  static void _registerUseCases() {
    getIt.registerLazySingleton(() => ListFilesUsecase(getIt.get()));
  }
}
