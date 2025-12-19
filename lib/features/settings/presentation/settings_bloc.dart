import 'package:android_tools/main.dart';
import 'package:android_tools/shared/core/constants.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

part 'settings_event.dart';
part 'settings_state.dart';
part 'settings_bloc.mapper.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final Logger _logger = getIt.get();

  SettingsBloc() : super(SettingsState()) {
    on<OnOpenLogDirectory>((event, emit) async {
      _logger.i("Opening log directory");
      final logDirectory = await Constants.getApplicationLogsDirectory();
      final uri = Uri.file(logDirectory.path);
      await launchUrl(uri);
    });
    on<OnOpenGithubProject>((event, emit) async {
      _logger.i("Opening github repository");
      final uri = Uri.parse("https://github.com/ThomasBernard03/AndroidTools");
      await launchUrl(uri);
    });
  }
}
