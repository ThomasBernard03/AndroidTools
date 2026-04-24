import 'package:android_tools/features/home/presentation/home_bloc.dart';
import 'package:android_tools/main.dart';

class HomeModule {
  static void configureDependencies() {
    getIt.registerFactory(() => HomeBloc());
  }
}
