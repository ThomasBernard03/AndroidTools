import 'package:android_tools/main.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

part 'application_installer_event.dart';
part 'application_installer_state.dart';
part 'application_installer_bloc.mapper.dart';

class ApplicationInstallerBloc
    extends Bloc<ApplicationInstallerEvent, ApplicationInstallerState> {
  final Logger _logger = getIt.get();

  ApplicationInstallerBloc() : super(ApplicationInstallerState()) {
    on<OnAppearing>((event, emit) async {});
    on<OnInstallApk>((event, emit) {
      _logger.i("Installing apk: ${event.apkPath}");
    });
  }
}
